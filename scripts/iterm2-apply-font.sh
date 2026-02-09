#!/usr/bin/env bash
set -euo pipefail

FONT_NAME="${ITERM_FONT_NAME:-}"
FONT_SIZE="${ITERM_FONT_SIZE:-13}"
PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"

export FONT_NAME
export FONT_SIZE

# Ensure iTerm2 has created its plist.
if [ ! -f "$PLIST" ]; then
  /usr/bin/open -a iTerm >/dev/null 2>&1 || /usr/bin/open -a iTerm2 >/dev/null 2>&1 || true
  sleep 2
  /usr/bin/osascript -e 'tell application "iTerm2" to quit' >/dev/null 2>&1 || true
fi

FONT_NAME="$FONT_NAME" FONT_SIZE="$FONT_SIZE" /usr/bin/python3 - <<'PY'
import os
import plistlib
import uuid
import subprocess

font_name = os.environ.get("FONT_NAME")
font_size = os.environ.get("FONT_SIZE", "13")
def detect_font():
    try:
        out = subprocess.check_output(
            ["/usr/sbin/system_profiler", "SPFontsDataType"],
            text=True,
            errors="ignore",
        )
    except Exception:
        return None

    fonts = []
    current = {}
    for raw in out.splitlines():
        line = raw.strip()
        if line.startswith("Full Name:"):
            current["full"] = line.split("Full Name:", 1)[1].strip()
        elif line.startswith("PostScript Name:"):
            current["ps"] = line.split("PostScript Name:", 1)[1].strip()
        elif line.startswith("Family:"):
            current["family"] = line.split("Family:", 1)[1].strip()
        elif line == "" and current:
            fonts.append(current)
            current = {}
    if current:
        fonts.append(current)

    def score(f):
        name = " ".join([f.get("full",""), f.get("family",""), f.get("ps","")]).lower()
        if "nerd font" not in name and " nf" not in name and "nf " not in name:
            return -1
        s = 0
        if "jetbrainsmono" in name:
            s += 5
        if "regular" in name:
            s += 3
        if "medium" in name:
            s += 2
        if "italic" in name:
            s -= 2
        if "propo" in name:
            s -= 1
        return s

    best = None
    best_score = -1
    for f in fonts:
        sc = score(f)
        if sc > best_score:
            best_score = sc
            best = f

    if not best or best_score < 0:
        return None

    # Prefer PostScript Name when available (iTerm2 uses it in prefs).
    return best.get("ps") or best.get("full")

if not font_name:
    font_name = detect_font()

if not font_name:
    # No Nerd Font available; abort gracefully.
    raise SystemExit("No Nerd Font detected")

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
