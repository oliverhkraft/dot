#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/dotfiles/iterm2/.iterm2"
DST="$HOME/.iterm2"
DST_IS_SYMLINK=0
if [ -L "$DST" ]; then
  DST_IS_SYMLINK=1
fi

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

copy_if_different() {
  local src="$1"
  local dst="$2"
  if [ "$DST_IS_SYMLINK" -eq 1 ]; then
    return 0
  fi
  if [ ! -f "$src" ]; then
    return 0
  fi
  if [ -f "$dst" ]; then
    # Same inode (symlinked target) or identical content — skip copy.
    if [ "$src" -ef "$dst" ] || /usr/bin/cmp -s "$src" "$dst"; then
      return 0
    fi
  fi
  cp "$src" "$dst" 2>/tmp/iterm2-cp.err || {
    if /usr/bin/grep -q "are identical" /tmp/iterm2-cp.err; then
      return 0
    fi
    echo "copy failed: $(cat /tmp/iterm2-cp.err)" >&2
    return 0
  }
}

# Prefer repo defaults if present.
copy_if_different "$SRC/com.googlecode.iterm2.plist" "$DST/com.googlecode.iterm2.plist"

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
copy_if_different "$SRC/DynamicProfiles/Profiles.json" "$DST/DynamicProfiles/Profiles.json"

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
