#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }
ok() { printf "[OK] %s\n" "$*"; }
err() { printf "[ERROR] %s\n" "$*" >&2; exit 1; }
warn() { printf "[WARN] %s\n" "$*"; }

TUNNEL_NAME="mac-mini"

main() {
  if ! command -v cloudflared &>/dev/null; then
    err "cloudflared not installed. Run 'make brew' first."
  fi

  # Step 1: Authenticate with Cloudflare
  log "Authenticating with Cloudflare"
  if [[ -f "$HOME/.cloudflared/cert.pem" ]]; then
    ok "Already authenticated (cert.pem exists)"
  else
    echo "A browser window will open. Log in to Cloudflare and authorize cloudflared."
    cloudflared tunnel login
    ok "Authenticated"
  fi

  # Step 2: Create tunnel (skip if it already exists)
  log "Creating tunnel '$TUNNEL_NAME'"
  if cloudflared tunnel info "$TUNNEL_NAME" &>/dev/null; then
    ok "Tunnel '$TUNNEL_NAME' already exists"
  else
    cloudflared tunnel create "$TUNNEL_NAME"
    ok "Tunnel '$TUNNEL_NAME' created"
  fi

  # Step 3: Get tunnel UUID
  TUNNEL_UUID=$(cloudflared tunnel info "$TUNNEL_NAME" 2>&1 | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
  if [[ -z "$TUNNEL_UUID" ]]; then
    err "Could not determine tunnel UUID. Check 'cloudflared tunnel list'."
  fi
  ok "Tunnel UUID: $TUNNEL_UUID"

  # Step 4: Prompt for hostname
  printf "\nEnter the hostname to use for SSH (e.g. ssh.example.com): "
  read -r SSH_HOSTNAME
  if [[ -z "$SSH_HOSTNAME" ]]; then
    err "Hostname cannot be empty."
  fi

  # Step 5: Write config
  log "Writing tunnel config"
  local config_dir="$HOME/.cloudflared"
  local config_file="$config_dir/config.yml"

  if [[ -f "$config_file" ]]; then
    echo "Existing config found at $config_file"
    printf "Overwrite? [y/N]: "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
      echo "Skipping config write. Edit $config_file manually if needed."
      return
    fi
  fi

  cat > "$config_file" <<EOF
tunnel: $TUNNEL_UUID
credentials-file: $config_dir/$TUNNEL_UUID.json
ingress:
  - hostname: $SSH_HOSTNAME
    service: ssh://localhost:22
  - service: http_status:404
EOF
  ok "Config written to $config_file"

  # Step 6: Route DNS
  log "Routing DNS"
  echo "This will create a CNAME record for $SSH_HOSTNAME pointing to the tunnel."
  echo "Make sure $SSH_HOSTNAME's domain is managed by Cloudflare."
  cloudflared tunnel route dns "$TUNNEL_NAME" "$SSH_HOSTNAME" || {
    warn "DNS routing failed. You may need to add the CNAME manually in Cloudflare dashboard."
  }

  # Step 7: Add private network route for WARP access
  log "Adding private network route"
  local mac_ip
  mac_ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)
  if [[ -n "$mac_ip" ]]; then
    cloudflared tunnel route ip add "$mac_ip/32" "$TUNNEL_NAME" 2>/dev/null && \
      ok "Private network route added: $mac_ip/32" || \
      ok "Private network route already exists for $mac_ip/32"
  else
    warn "Could not detect local IP. Add route manually: cloudflared tunnel route ip add <IP>/32 $TUNNEL_NAME"
  fi

  # Step 8: Install launchd service
  log "Installing launchd service"
  local plist="$HOME/Library/LaunchAgents/com.cloudflare.cloudflared.plist"
  if launchctl list com.cloudflare.cloudflared &>/dev/null; then
    ok "Service already running"
  else
    # cloudflared service install generates a broken plist (missing 'tunnel run' args)
    # Write it ourselves
    mkdir -p "$(dirname "$plist")"
    cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>com.cloudflare.cloudflared</string>
		<key>ProgramArguments</key>
		<array>
			<string>/opt/homebrew/bin/cloudflared</string>
			<string>tunnel</string>
			<string>run</string>
		</array>
		<key>RunAtLoad</key>
		<true/>
		<key>StandardOutPath</key>
		<string>$HOME/Library/Logs/com.cloudflare.cloudflared.out.log</string>
		<key>StandardErrorPath</key>
		<string>$HOME/Library/Logs/com.cloudflare.cloudflared.err.log</string>
		<key>KeepAlive</key>
		<dict>
			<key>SuccessfulExit</key>
			<false/>
		</dict>
		<key>ThrottleInterval</key>
		<integer>5</integer>
	</dict>
</plist>
PLIST
    launchctl load "$plist"
    ok "Service installed and started"
  fi

  log "Setup complete!"
  echo ""
  echo "Your tunnel is running. SSH is accessible via WARP at: $mac_ip"
  echo ""
  echo "Next steps:"
  echo "  1. In Cloudflare Zero Trust dashboard:"
  echo "     - Settings → WARP Client → Enable device enrollment"
  echo "     - Settings → Network → Firewall → ensure private network routes are enabled"
  echo "     - Settings → WARP Client → Split Tunnels → Include $mac_ip/32"
  echo "  2. On iPad:"
  echo "     - Install 'Cloudflare One' (WARP) app from App Store"
  echo "     - Connect to your Zero Trust organization"
  echo "     - Install Blink Shell or Termius"
  echo "     - Add your iPad's public key to ~/.ssh/authorized_keys on this Mac"
  echo "     - SSH to $mac_ip"
  echo "  3. For port forwarding: ssh -L 8080:localhost:8000 $mac_ip"
  echo "  4. For SOCKS proxy:    ssh -D 1080 $mac_ip"
}

main "$@"
