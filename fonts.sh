#!/usr/bin/env bash
set -euo pipefail

FONT_APP="/Applications/Font Book.app"
FONT_DIR="$HOME/Library/Fonts"

if [ -d "$FONT_DIR" ]; then
  echo "Fonts directory: $FONT_DIR"
fi

echo "If fonts were installed via Homebrew, open Font Book to verify."
/usr/bin/open "$FONT_APP" >/dev/null 2>&1 || true
