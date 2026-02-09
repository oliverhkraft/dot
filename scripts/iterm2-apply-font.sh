#!/usr/bin/env bash
set -euo pipefail

FONT_NAME="JetBrainsMono Nerd Font"
FONT_SIZE="13"
PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"

# Ensure iTerm2 has created its plist.
if [ ! -f "$PLIST" ]; then
  /usr/bin/open -a iTerm >/dev/null 2>&1 || /usr/bin/open -a iTerm2 >/dev/null 2>&1 || true
  sleep 2
  /usr/bin/osascript -e 'tell application "iTerm2" to quit' >/dev/null 2>&1 || true
fi

/usr/bin/python3 - <<'PY'
import os
import plistlib
import uuid

font_name = os.environ.get("FONT_NAME", "JetBrainsMono Nerd Font")
font_size = os.environ.get("FONT_SIZE", "13")
font_value = f"{font_name} {font_size}"

path = os.path.expanduser("~/Library/Preferences/com.googlecode.iterm2.plist")

if os.path.exists(path) and os.path.getsize(path) > 0:
    with open(path, "rb") as f:
        try:
            data = plistlib.load(f)
        except Exception:
            data = {}
else:
    data = {}

bookmarks = data.get("New Bookmarks")
if not isinstance(bookmarks, list) or len(bookmarks) == 0:
    guid = str(uuid.uuid4()).upper()
    bookmarks = [{"Name": "Default", "Guid": guid}]
    data["New Bookmarks"] = bookmarks
    data["Default Bookmark Guid"] = guid

# Apply font to all profiles to be safe.
for bm in bookmarks:
    bm["Normal Font"] = font_value
    bm["Non Ascii Font"] = font_value
    bm["Use Non-ASCII Font"] = True

with open(path, "wb") as f:
    plistlib.dump(data, f)
PY

# Restart iTerm2 if running to apply font.
if pgrep -x "iTerm2" >/dev/null 2>&1 || pgrep -x "iTerm" >/dev/null 2>&1; then
  if [ "${ITERM2_RESTART:-1}" = "1" ]; then
    /usr/bin/osascript -e 'tell application "iTerm2" to quit' >/dev/null 2>&1 || true
    /usr/bin/open -a iTerm >/dev/null 2>&1 || /usr/bin/open -a iTerm2 >/dev/null 2>&1 || true
  else
    echo "iTerm2 is running. Restart it to load updated font settings."
  fi
fi
