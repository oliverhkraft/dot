#!/usr/bin/env bash
set -euo pipefail

# Always disable custom prefs folder to avoid iTerm2 "missing or malformed" warnings.
/usr/bin/defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool false
/usr/bin/defaults delete com.googlecode.iterm2 PrefsCustomFolder >/dev/null 2>&1 || true

# Restart iTerm2 to pick up preferences, unless disabled.
if pgrep -x "iTerm2" >/dev/null 2>&1 || pgrep -x "iTerm" >/dev/null 2>&1; then
  if [ "${ITERM2_RESTART:-1}" = "1" ]; then
    /usr/bin/osascript -e 'tell application "iTerm2" to quit' >/dev/null 2>&1 || true
    /usr/bin/open -a iTerm >/dev/null 2>&1 || /usr/bin/open -a iTerm2 >/dev/null 2>&1 || true
  else
    echo "iTerm2 is running. Restart it to load updated prefs."
  fi
fi
