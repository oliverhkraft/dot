#!/usr/bin/env bash
set -euo pipefail

warn() { printf "[WARN] %s\n" "$*"; }
ok() { printf "[OK] %s\n" "$*"; }

AMPHETAMINE_ID="937984704"

if [[ "$(uname -s)" != "Darwin" ]]; then
  warn "Not macOS; skipping App Store installs."
  exit 0
fi

if [[ -d "/Applications/Amphetamine.app" ]]; then
  ok "Amphetamine already installed"
  exit 0
fi

if ! command -v mas >/dev/null 2>&1; then
  warn "mas not found; skipping Amphetamine install."
  exit 0
fi

set +e
purchase_output="$(mas purchase "$AMPHETAMINE_ID" 2>&1)"
purchase_rc=$?
set -e

if [[ $purchase_rc -eq 0 ]]; then
  ok "Installed Amphetamine"
  exit 0
fi

# On some setups the app might already be associated with the Apple ID;
# install can succeed even when purchase does not.
set +e
install_output="$(mas install "$AMPHETAMINE_ID" 2>&1)"
install_rc=$?
set -e

if [[ $install_rc -eq 0 ]]; then
  ok "Installed Amphetamine"
  exit 0
fi

combined_output="$purchase_output"$'\n'"$install_output"
if echo "$combined_output" | rg -qi "not signed in|sign in|authentication|apple id"; then
  warn "Not signed in to App Store (or auth expired); skipping Amphetamine install."
  warn "Open App Store, sign in, then run: ./scripts/mas-install.sh"
  exit 0
fi

warn "Failed to install Amphetamine via mas."
warn "$combined_output"
