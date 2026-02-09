#!/usr/bin/env bash
set -euo pipefail

GUID="8E8E6B6F-6C3B-4D2C-8C7E-8D3F0C3F9A11"

/usr/bin/defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$GUID" || true
