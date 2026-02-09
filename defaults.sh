#!/usr/bin/env bash
set -euo pipefail

# ---------- Dock ----------
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 44
defaults write com.apple.dock mru-spaces -bool false

# ---------- Finder ----------
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# ---------- Screenshots ----------
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"

# ---------- Keyboard ----------
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
defaults write -g ApplePressAndHoldEnabled -bool false

# ---------- Trackpad ----------
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Apply immediately (ignore errors if processes not running)
killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true
