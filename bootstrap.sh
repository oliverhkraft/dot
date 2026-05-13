#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() { printf "\n==> %s\n" "$*"; }

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi
  log "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
}

ensure_brew_shellenv() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
}

main() {
  cd "$ROOT"

  log "Running doctor checks"
  bash "$ROOT/doctor.sh"

  install_homebrew
  ensure_brew_shellenv

  log "Installing Brewfile packages (idempotent)"
  brew bundle --file "$ROOT/Brewfile"

  log "Installing App Store apps (optional)"
  bash "$ROOT/scripts/mas-install.sh" || true

  log "Applying dotfiles via stow (idempotent)"
  command -v stow >/dev/null 2>&1 || brew install stow
  stow git ssh zsh ghostty starship hammerspoon

  log "Linking VS Code settings.json"
  bash "$ROOT/scripts/vscode-link-settings.sh"

  log "Restoring Stream Deck config (optional)"
  bash "$ROOT/scripts/streamdeck-restore.sh" || true


  log "Applying macOS defaults (idempotent)"
  bash "$ROOT/defaults.sh"

  log "Applying headless remote settings (idempotent)"
  bash "$ROOT/headless.sh"

  log "Setting default browser (optional)"
  bash "$ROOT/browser.sh" || true

  log "Applying Dock layout (idempotent)"
  bash "$ROOT/dock.sh"

  log "Applying display configuration (optional)"
  bash "$ROOT/display.sh" || true

  log "Applying wallpaper (optional)"
  bash "$ROOT/wallpaper.sh" || true

  log "Done"
}

main "$@"
