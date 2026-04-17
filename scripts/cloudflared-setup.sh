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

  # Step 7: Install launchd service
  log "Installing launchd service"
  if launchctl list com.cloudflare.cloudflared &>/dev/null; then
    ok "Service already running"
  else
    cloudflared service install
    ok "Service installed and started"
  fi

  log "Setup complete!"
  echo ""
  echo "Your tunnel is running. SSH is proxied at: $SSH_HOSTNAME"
  echo ""
  echo "Next steps (on iPad):"
  echo "  1. Install Blink Shell or Termius"
  echo "  2. Add your iPad's public key to ~/.ssh/authorized_keys on this Mac"
  echo "  3. Connect via SSH to $SSH_HOSTNAME"
  echo "  4. For port forwarding: ssh -L 8080:localhost:8000 $SSH_HOSTNAME"
  echo "  5. For SOCKS proxy:    ssh -D 1080 $SSH_HOSTNAME"
}

main "$@"
