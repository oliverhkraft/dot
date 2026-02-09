#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DST="$HOME/.iterm2"
ENABLE_FLAG="$DST/.enable_custom_prefs"

# If ~/.iterm2 is a file (not a directory), back it up.
if [ -e "$DST" ] && [ ! -d "$DST" ]; then
  mv "$DST" "${DST}.bak.$(date +%s)"
fi

mkdir -p "$DST/DynamicProfiles"

is_valid_plist() {
  local target="$1"
  [ -s "$target" ] && /usr/bin/plutil -lint "$target" >/dev/null 2>&1
}

write_plist_from_defaults() {
  local target="$1"
  local tmp
  tmp="$(mktemp)"
  if /usr/bin/defaults export com.googlecode.iterm2 - >"$tmp" 2>/dev/null; then
    if /usr/bin/plutil -lint "$tmp" >/dev/null 2>&1; then
      mv "$tmp" "$target"
      return 0
    fi
  fi
  rm -f "$tmp"
  return 1
}

write_minimal_plist() {
  local target="$1"
  cat <<'PLIST' > "$target"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
PLIST
}

ensure_prefs_plist() {
  local target="$1"
  if is_valid_plist "$target"; then
    return 0
  fi
  if write_plist_from_defaults "$target"; then
    return 0
  fi
  # Best-effort: launch iTerm2 once to initialize defaults, then export.
  /usr/bin/open -a iTerm >/dev/null 2>&1 || /usr/bin/open -a iTerm2 >/dev/null 2>&1 || true
  sleep 2
  if write_plist_from_defaults "$target"; then
    /usr/bin/osascript -e 'tell application "iTerm2" to quit' >/dev/null 2>&1 || true
    return 0
  fi
  /usr/bin/osascript -e 'tell application "iTerm2" to quit' >/dev/null 2>&1 || true
  write_minimal_plist "$target"
}

ensure_profiles_json() {
  local target="$1"
  if [ -f "$target" ]; then
    return 0
  fi
  cat <<'JSON' > "$target"
{
  "Profiles": []
}
JSON
}

ensure_prefs_plist "$DST/com.googlecode.iterm2.plist"
ensure_profiles_json "$DST/DynamicProfiles/Profiles.json"

# Only enable custom folder if user opted-in and prefs look real.
# This prevents iTerm2 warnings about malformed/missing files.
prefs_file="$DST/com.googlecode.iterm2.plist"
prefs_size=0
if [ -f "$prefs_file" ]; then
  prefs_size=$(stat -f%z "$prefs_file" 2>/dev/null || echo 0)
fi

if [ -f "$ENABLE_FLAG" ] && is_valid_plist "$prefs_file" && [ "$prefs_size" -gt 512 ]; then
  /usr/bin/defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DST"
  /usr/bin/defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
else
  /usr/bin/defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool false
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
