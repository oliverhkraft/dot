.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Targets:"
	@echo " make apply          Run full bootstrap (idempotent)"
	@echo " make doctor         Check prerequisites + FileVault policy"
	@echo " make brew           Install/update Brewfile"
	@echo " make stow           Apply dotfiles via stow"
	@echo " make mas-apps       Install App Store apps (Amphetamine)"
	@echo " make defaults       Apply macOS defaults"
	@echo " make headless       Apply headless remote settings"
	@echo " make tunnel         Run guided Cloudflare tunnel setup (one-time)"
	@echo " make browser        Set default browser"
	@echo " make dock           Apply Dock layout"
	@echo " make display        Apply display configuration"
	@echo " make fonts          Open Font Book (optional)"
	@echo " make streamdeck-sync    Export Stream Deck config into streamdeck-export/"
	@echo " make streamdeck-restore Restore tracked Stream Deck config to this Mac"
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
	stow git ssh zsh ghostty starship hammerspoon
	./scripts/vscode-link-settings.sh

.PHONY: mas-apps
mas-apps:
	./scripts/mas-install.sh

.PHONY: defaults
defaults:
	./defaults.sh

.PHONY: headless
headless:
	./headless.sh

.PHONY: browser
browser:
	./browser.sh

.PHONY: dock
dock:
	./dock.sh

.PHONY: sync-defaults
sync-defaults:
	./scripts/defaults-sync.sh

.PHONY: snapshot
snapshot:
	./scripts/defaults-snapshot.sh $(NAME)

.PHONY: display
display:
	./display.sh

.PHONY: fonts
fonts:
	./fonts.sh

.PHONY: streamdeck-sync
streamdeck-sync:
	./scripts/streamdeck-sync.sh

.PHONY: streamdeck-restore
streamdeck-restore:
	./scripts/streamdeck-restore.sh

.PHONY: tunnel
tunnel:
	./scripts/cloudflared-setup.sh
