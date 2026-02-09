#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/dotfiles/iterm2/.iterm2"
DST="$HOME/.iterm2"

mkdir -p "$DST/DynamicProfiles"

# Copy from repo defaults if missing.
if [ -f "$SRC/com.googlecode.iterm2.plist" ] && [ ! -f "$DST/com.googlecode.iterm2.plist" ]; then
  cp "$SRC/com.googlecode.iterm2.plist" "$DST/com.googlecode.iterm2.plist"
fi
if [ -f "$SRC/DynamicProfiles/Profiles.json" ] && [ ! -f "$DST/DynamicProfiles/Profiles.json" ]; then
  cp "$SRC/DynamicProfiles/Profiles.json" "$DST/DynamicProfiles/Profiles.json"
fi

# Create minimal valid files if still missing.
if [ ! -f "$DST/com.googlecode.iterm2.plist" ]; then
  cat <<'PLIST' > "$DST/com.googlecode.iterm2.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
PLIST
fi

if [ ! -f "$DST/DynamicProfiles/Profiles.json" ]; then
  cat <<'JSON' > "$DST/DynamicProfiles/Profiles.json"
{
  "Profiles": []
}
JSON
fi
