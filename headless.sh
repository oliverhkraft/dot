#!/usr/bin/env bash
set -euo pipefail

ok() { printf "[OK] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }
info() { printf "\n==> %s\n" "$*"; }

apply_pmset_setting() {
  local key="$1"
  local value="$2"

  if pmset -a "$key" "$value" >/dev/null 2>&1; then
    ok "pmset: $key=$value"
    return
  fi

  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    if sudo -n pmset -a "$key" "$value" >/dev/null 2>&1; then
      ok "pmset: $key=$value (via sudo)"
      return
    fi
  fi

  if command -v sudo >/dev/null 2>&1 && [[ -t 0 ]] && [[ -t 1 ]]; then
    info "Admin permission needed for pmset $key=$value"
    if sudo -v >/dev/null 2>&1 && sudo pmset -a "$key" "$value" >/dev/null 2>&1; then
      ok "pmset: $key=$value (via sudo prompt)"
      return
    fi
  fi

  warn "Could not set pmset $key=$value."
}

login_item_exists() {
  local item_name="$1"
  local result

  result="$(
    osascript - "$item_name" 2>/dev/null <<'APPLESCRIPT' || true
on run argv
  set itemName to item 1 of argv
  tell application "System Events"
    if exists login item itemName then
      return "true"
    end if
  end tell
  return "false"
end run
APPLESCRIPT
  )"

  [[ "$result" == "true" ]]
}

add_login_item() {
  local item_name="$1"
  local app_path="$2"

  if [[ ! -d "$app_path" ]]; then
    warn "Skipping login item '$item_name' (app missing at $app_path)"
    return
  fi

  if login_item_exists "$item_name"; then
    ok "Login item already present: $item_name"
    return
  fi

  if osascript - "$item_name" "$app_path" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
  set itemName to item 1 of argv
  set itemPath to item 2 of argv
  tell application "System Events"
    make login item at end with properties {name:itemName, path:itemPath, hidden:false}
  end tell
end run
APPLESCRIPT
  then
    ok "Added login item: $item_name"
  else
    warn "Could not add login item: $item_name (grant Automation permission if prompted)."
  fi
}

main() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    warn "Not macOS; skipping headless settings."
    exit 0
  fi

  info "Configuring headless/remote settings"

  if command -v pmset >/dev/null 2>&1; then
    # Keep machine reachable remotely and recover after power loss.
    apply_pmset_setting sleep 0
    apply_pmset_setting displaysleep 0
    apply_pmset_setting disksleep 0
    apply_pmset_setting autorestart 1
    apply_pmset_setting womp 1
  else
    warn "pmset not found; skipping power settings."
  fi

  # Enable SSH (Remote Login) for remote access
  if command -v systemsetup >/dev/null 2>&1; then
    if systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
      ok "Remote Login (SSH) already enabled"
    else
      info "Enabling Remote Login (SSH) — requires admin"
      if sudo systemsetup -setremotelogin on >/dev/null 2>&1; then
        ok "Remote Login enabled"
      else
        warn "Could not enable Remote Login. Enable manually: System Settings → General → Sharing → Remote Login"
      fi
    fi
  fi

  # Harden sshd — keys only, no root
  local sshd_drop_in="/etc/ssh/sshd_config.d/99-hardened.conf"
  local sshd_content="PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no"

  if [[ -f "$sshd_drop_in" ]] && [[ "$(cat "$sshd_drop_in")" == "$sshd_content" ]]; then
    ok "sshd hardening config already in place"
  else
    info "Writing sshd hardening config — requires admin"
    if echo "$sshd_content" | sudo tee "$sshd_drop_in" >/dev/null 2>&1; then
      ok "sshd hardening config written to $sshd_drop_in"
    else
      warn "Could not write sshd config. Create $sshd_drop_in manually with: PasswordAuthentication no, PubkeyAuthentication yes, PermitRootLogin no"
    fi
  fi

  # Check cloudflared tunnel status
  local check_script
  check_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/cloudflared-check.sh"
  if [[ -x "$check_script" ]]; then
    bash "$check_script"
  else
    warn "cloudflared-check.sh not found; skipping tunnel status check."
  fi

  if command -v osascript >/dev/null 2>&1; then
    add_login_item "Jump Desktop Connect" "/Applications/Jump Desktop Connect.app"
    add_login_item "BetterDisplay" "/Applications/BetterDisplay.app"
    add_login_item "Amphetamine" "/Applications/Amphetamine.app"
  else
    warn "osascript not found; skipping login item setup."
  fi
}

main "$@"
