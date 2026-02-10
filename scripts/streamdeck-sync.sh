#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SRC_APP="$HOME/Library/Application Support/com.elgato.StreamDeck"
SRC_PREF="$HOME/Library/Preferences/com.elgato.StreamDeck.plist"

DST_ROOT="$ROOT/streamdeck-export"
DST_APP="$DST_ROOT/Library/Application Support/com.elgato.StreamDeck"
DST_PREF="$DST_ROOT/Library/Preferences/com.elgato.StreamDeck.plist"

if pgrep -x "Stream Deck" >/dev/null 2>&1; then
  echo "Please quit Stream Deck before syncing to avoid partial files."
  exit 1
fi

if [ ! -d "$SRC_APP" ]; then
  echo "Stream Deck data not found at: $SRC_APP"
  echo "Open the Stream Deck app once, create or import profiles, then run sync again."
  exit 1
fi

mkdir -p "$DST_APP"
mkdir -p "$(dirname "$DST_PREF")"

echo "Syncing Stream Deck app data into: $DST_APP"
rsync -a --delete \
  --exclude "Logs/" \
  --exclude "Cache/" \
  --exclude "Crashpad/" \
  --exclude "*.lock" \
  "$SRC_APP/" "$DST_APP/"

if [ -f "$SRC_PREF" ]; then
  cp "$SRC_PREF" "$DST_PREF"
fi

echo
echo "Stream Deck sync complete."
echo "Review changes with: git -C \"$ROOT\" status --short streamdeck-export"
