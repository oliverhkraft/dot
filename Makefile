.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Targets:"
	@echo " make apply          Run full bootstrap (idempotent)"
	@echo " make doctor         Check prerequisites + FileVault policy"
	@echo " make brew           Install/update Brewfile"
	@echo " make stow           Apply dotfiles via stow"
	@echo " make defaults       Apply macOS defaults"
	@echo " make dock           Apply Dock layout"
	@echo " make sync-defaults  Export current UI defaults and show git diff"
	@echo " make snapshot NAME=before  Take a defaults snapshot"

.PHONY: apply
apply:
	./bootstrap.sh

.PHONY: doctor
doctor:
	./doctor.sh

.PHONY: brew
brew:
	brew bundle --file Brewfile

.PHONY: stow
stow:
	stow git ssh zsh vscode iterm2

.PHONY: defaults
defaults:
	./defaults.sh

.PHONY: dock
dock:
	./dock.sh

.PHONY: sync-defaults
sync-defaults:
	./scripts/defaults-sync.sh

.PHONY: snapshot
snapshot:
	./scripts/defaults-snapshot.sh $(NAME)
