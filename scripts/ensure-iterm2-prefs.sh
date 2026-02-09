#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/dotfiles/iterm2/.iterm2"
DST="$HOME/.iterm2"

# If ~/.iterm2 is a file (not a directory), back it up.
if [ -e "$DST" ] && [ ! -d "$DST" ]; then
  mv "$DST" "${DST}.bak.$(date +%s)"
fi

mkdir -p "$DST/DynamicProfiles"

# Helper: write a plist from defaults if possible.
write_plist_from_defaults() {
  local target="$1"
  if /usr/bin/defaults export com.googlecode.iterm2 - >/tmp/iterm2-prefs.plist 2>/dev/null; then
    mv /tmp/iterm2-prefs.plist "$target"
    return 0
  fi
  return 1
}

# Prefer repo defaults if present.
if [ -f "$SRC/com.googlecode.iterm2.plist" ]; then
  cp "$SRC/com.googlecode.iterm2.plist" "$DST/com.googlecode.iterm2.plist"
fi

# Ensure plist exists and is valid.
if [ ! -f "$DST/com.googlecode.iterm2.plist" ]; then
  if ! write_plist_from_defaults "$DST/com.googlecode.iterm2.plist"; then
    cat <<'PLIST' > "$DST/com.googlecode.iterm2.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
PLIST
  fi
else
  if ! /usr/bin/plutil -lint "$DST/com.googlecode.iterm2.plist" >/dev/null 2>&1; then
    if ! write_plist_from_defaults "$DST/com.googlecode.iterm2.plist"; then
      cat <<'PLIST' > "$DST/com.googlecode.iterm2.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
PLIST
    fi
  fi
fi

# Ensure DynamicProfiles exists and is valid JSON.
if [ -f "$SRC/DynamicProfiles/Profiles.json" ]; then
  cp "$SRC/DynamicProfiles/Profiles.json" "$DST/DynamicProfiles/Profiles.json"
fi

if [ ! -f "$DST/DynamicProfiles/Profiles.json" ]; then
  cat <<'JSON' > "$DST/DynamicProfiles/Profiles.json"
{
  "Profiles": []
}
JSON
fi

# Restart iTerm2 to pick up preferences, unless disabled.
if pgrep -x "iTerm2" >/dev/null 2>&1 || pgrep -x "iTerm" >/dev/null 2>&1; then
  if [ "${ITERM2_RESTART:-1}" = "1" ]; then
    /usr/bin/osascript -e 'tell application "iTerm2" to quit' >/dev/null 2>&1 || true
    /usr/bin/open -a iTerm >/dev/null 2>&1 || /usr/bin/open -a iTerm2 >/dev/null 2>&1 || true
  else
    echo "iTerm2 is running. Restart it to load updated prefs."
  fi
fi
