#!/usr/bin/env bash
set -euo pipefail

FONT_NAME="${ITERM_FONT_NAME:-}"
FONT_SIZE="${ITERM_FONT_SIZE:-13}"
PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"

detect_font() {
  # Returns the best matching installed font full name.
  local installed
  installed=$(/usr/sbin/system_profiler SPFontsDataType 2>/dev/null | awk -F': ' '/Full Name/ {print $2}')

  # Helper: first match from a regex list
  pick() {
    local pattern="$1"
    local match
    match=$(echo "$installed" | /usr/bin/grep -m1 -E "$pattern" || true)
    if [ -n "$match" ]; then
      echo "$match"
      return 0
    fi
    return 1
  }

  # Prefer JetBrainsMono Nerd Font variants (Regular/Medium first).
  pick 'JetBrainsMono.*(Nerd Font|NF).*Regular' && return 0
  pick 'JetBrainsMono.*(Nerd Font|NF).*Medium' && return 0
  pick 'JetBrainsMono.*(Nerd Font|NF).*' && return 0

  # Then any Nerd Font with Regular/Medium.
  pick '.*Nerd Font.*Regular' && return 0
  pick '.*Nerd Font.*Medium' && return 0

  # Then any Nerd Font / NF.
  pick '.*Nerd Font.*' && return 0
  pick '.*\\bNF\\b.*' && return 0

  return 1
}

if [ -z "$FONT_NAME" ]; then
  FONT_NAME="$(detect_font || true)"
fi

if [ -z "$FONT_NAME" ]; then
  echo "No Nerd Font detected; skipping iTerm2 font setup."
  exit 0
fi

export FONT_NAME
export FONT_SIZE

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
