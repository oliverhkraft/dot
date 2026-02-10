#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/dotfiles/vscode/Library/Application Support/Code/User/settings.json"
DST="$HOME/Library/Application Support/Code/User/settings.json"

if [ ! -f "$SRC" ]; then
  echo "VS Code settings source not found: $SRC"
  exit 0
fi

mkdir -p "$(dirname "$DST")"

# If destination exists and is not the correct symlink, back it up.
if [ -e "$DST" ] && [ ! -L "$DST" ]; then
  mv "$DST" "${DST}.bak.$(date +%s)"
elif [ -L "$DST" ]; then
  # If it's a symlink to somewhere else, replace it.
  if [ "$(readlink "$DST")" != "$SRC" ]; then
    rm -f "$DST"
  fi
fi

ln -sfn "$SRC" "$DST"
