#!/usr/bin/env bash
set -euo pipefail

if ! command -v dockutil >/dev/null 2>&1; then
  echo "dockutil not found; skipping Dock layout."
  exit 0
fi

dockutil --remove all --no-restart || true

dockutil --add "/Applications/Safari.app" --no-restart || true
dockutil --add "/Applications/iTerm.app" --no-restart || true
dockutil --add "/Applications/Visual Studio Code.app" --no-restart || true
dockutil --add "/Applications/1Password.app" --no-restart || true
dockutil --add "/Applications/Herd.app" --no-restart || true
dockutil --add "/Applications/Jump Desktop.app" --no-restart || true

dockutil --add "$HOME/Downloads" --view fan --display folder --sort dateadded --no-restart || true

killall Dock >/dev/null 2>&1 || true
