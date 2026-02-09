#!/usr/bin/env bash
set -euo pipefail

WALLPAPER="$HOME/Pictures/wallpaper.jpg"
if [ ! -f "$WALLPAPER" ]; then
  echo "Wallpaper not found at: $WALLPAPER (skipping)"
  exit 0
fi

/usr/bin/osascript <<OSA
tell application "System Events"
  tell every desktop
    set picture to "$WALLPAPER"
  end tell
end tell
OSA
