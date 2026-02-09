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

  log "Applying dotfiles via stow (idempotent)"
  command -v stow >/dev/null 2>&1 || brew install stow
  stow git ssh zsh vscode iterm2 starship


  log "Applying macOS defaults (idempotent)"
  bash "$ROOT/defaults.sh"

  log "Ensuring iTerm2 prefs folder is valid"
  bash "$ROOT/scripts/ensure-iterm2-prefs.sh"

  log "Setting iTerm2 font (Nerd Font)"
  bash "$ROOT/scripts/iterm2-apply-font.sh" || true

  log "Applying Dock layout (idempotent)"
  bash "$ROOT/dock.sh"

  log "Applying display configuration (optional)"
  bash "$ROOT/display.sh" || true

  log "Applying wallpaper (optional)"
  bash "$ROOT/wallpaper.sh" || true

  log "Done"
}

main "$@"
