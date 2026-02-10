#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SRC_ROOT="$ROOT/streamdeck-export"
SRC_APP="$SRC_ROOT/Library/Application Support/com.elgato.StreamDeck"
SRC_PREF="$SRC_ROOT/Library/Preferences/com.elgato.StreamDeck.plist"

DST_APP="$HOME/Library/Application Support/com.elgato.StreamDeck"
DST_PREF="$HOME/Library/Preferences/com.elgato.StreamDeck.plist"

if [ ! -d "$SRC_APP" ] && [ ! -f "$SRC_PREF" ]; then
  echo "No tracked Stream Deck data found in: $SRC_ROOT"
  exit 0
fi

if pgrep -x "Stream Deck" >/dev/null 2>&1; then
  echo "Please quit Stream Deck before restoring config."
  exit 1
fi

if [ -d "$SRC_APP" ]; then
  mkdir -p "$DST_APP"
  echo "Restoring Stream Deck app data into: $DST_APP"
  rsync -a --delete "$SRC_APP/" "$DST_APP/"
fi

if [ -f "$SRC_PREF" ]; then
  mkdir -p "$(dirname "$DST_PREF")"
  cp "$SRC_PREF" "$DST_PREF"
fi

echo
echo "Stream Deck restore complete."
echo "Open Stream Deck and confirm your Neo profiles/buttons loaded."
