default:
	@just --list

apply:
	./bootstrap.sh

doctor:
	./doctor.sh

brew:
	brew bundle --file Brewfile

stow:
	stow git ssh zsh vscode iterm2 starship

defaults:
	./defaults.sh

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
