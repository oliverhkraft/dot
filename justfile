default:
	@just --list

apply:
	./bootstrap.sh

doctor:
	./doctor.sh

brew:
	brew bundle --file Brewfile

stow:
	stow git ssh zsh ghostty starship hammerspoon
	./scripts/vscode-link-settings.sh

defaults:
	./defaults.sh

browser:
	./browser.sh

dock:
	./dock.sh

sync-defaults:
	./scripts/defaults-sync.sh

snapshot name="snapshot":
	./scripts/defaults-snapshot.sh {{name}}

display:
	./display.sh

fonts:
	./fonts.sh

streamdeck-sync:
	./scripts/streamdeck-sync.sh

streamdeck-restore:
	./scripts/streamdeck-restore.sh
