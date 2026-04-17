#!/usr/bin/env bash
set -euo pipefail

ok() { printf "[OK] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }

check_cloudflared() {
  if ! command -v cloudflared &>/dev/null; then
    warn "cloudflared not installed. Run 'make brew' first."
    return
  fi
  ok "cloudflared installed"

  local plist="$HOME/Library/LaunchAgents/com.cloudflare.cloudflared.plist"
  if [[ ! -f "$plist" ]]; then
    warn "cloudflared launchd service not installed. Run 'make tunnel' to set up."
    return
  fi
  ok "cloudflared launchd plist exists"

  if launchctl list com.cloudflare.cloudflared &>/dev/null; then
    ok "cloudflared service is running"
  else
    warn "cloudflared service is not running. Try: launchctl load $plist"
  fi
}

check_cloudflared
