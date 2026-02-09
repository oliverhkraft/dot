# mac-bootstrap

A minimal, repeatable macOS bootstrap repo (Apple Silicon) using:
- Homebrew + Brewfile for apps/tools
- GNU Stow for dotfiles
- `defaults` + `dockutil`, `displayplacer` for macOS UI settings
- 1Password SSH agent (no private keys in repo)

This is intentionally simple and idempotent. Re-running the bootstrap applies the repo’s state.

## What This Repo Does

- Installs CLI tools and GUI apps (including Laravel Herd + Jump Desktop)
- Applies dotfiles (zsh, git, ssh, VS Code, iTerm2)
- Enforces macOS defaults + Dock layout
- Loads iTerm2 preferences from a folder
- Fails fast if FileVault is ON (Jump Desktop policy)

## Requirements

- macOS (Darwin)
- Apple Silicon recommended (`/opt/homebrew`)
- Admin access to install software and change system settings
- 1Password installed (for SSH agent)
- FileVault must be OFF

## Quick Start (New Mac)

1. **Disable FileVault** (required for Jump Desktop)
   - System Settings → Privacy & Security → FileVault → Turn Off
   - Or: `sudo fdesetup disable` (interactive)

2. **Install 1Password** (if not already installed)
   - You can install it manually, or let Brewfile handle it later
   - In 1Password: Settings → Developer → Enable “Use SSH Agent”

3. **Clone this repo**

```bash
git clone <YOUR_REPO_URL> mac-bootstrap
cd mac-bootstrap
```

4. **Edit identity placeholders**

Update:
- `dotfiles/git/.gitconfig`

5. **Run the doctor check**

```bash
make doctor
```

If FileVault is ON, the doctor will fail and explain how to turn it off.

6. **Apply everything**

```bash
make apply
```

## What `make apply` Does (Idempotent)

1. Runs `doctor.sh` (checks prerequisites + FileVault policy)
2. Installs Homebrew (if missing)
3. Installs Brewfile packages and casks
4. Applies dotfiles via Stow
5. Applies macOS defaults
6. Sets Dock layout
7. Sets display configuration (optional)
8. Sets wallpaper (optional)

You can re-run `make apply` at any time. It is safe and will re-apply the repo’s state.

## Commands

- `make apply` – Full bootstrap
- `make doctor` – Prereq + policy checks
- `make brew` – Install/update Brewfile only
- `make stow` – Apply dotfiles only
- `make defaults` – Apply macOS defaults only
- `make dock` – Apply Dock layout only
- `make display` – Apply display configuration
- `make sync-defaults` – Export current UI defaults into `defaults-export/`
- `make snapshot NAME=before` – Snapshot defaults for diffing

(Equivalent `just` commands are available if you prefer `just`.)

## Apps Installed

From `Brewfile`:
- CLI: `git`, `stow`, `dockutil`, `displayplacer`, `jq`, `ripgrep`, `fd`, `mas`, `just`
- Casks: `1password`, `visual-studio-code`, `raycast`, `iterm2`, `herd`, `jump-desktop`

Edit `Brewfile` to add/remove apps. Re-run `make brew` or `make apply`.

## Dotfiles Layout (Stow)

```
dotfiles/
├── git/.gitconfig
├── ssh/.ssh/config
├── ssh/.ssh/known_hosts
├── zsh/.zprofile
├── zsh/.zshrc
├── vscode/Library/Application Support/Code/User/settings.json
└── iterm2/.iterm2/
    ├── com.googlecode.iterm2.plist
    └── DynamicProfiles/Profiles.json
```

Stow command used:

```bash
stow git ssh zsh vscode iterm2
```

## iTerm2 Preferences

This repo sets iTerm2 to load prefs from `~/.iterm2`.

To generate real iTerm2 prefs:
1. Run `make apply`
2. Open iTerm2 → Settings/Preferences → General → “Load preferences from a custom folder”
3. Point it to `~/.iterm2`
4. iTerm2 writes files there — copy/commit them to `dotfiles/iterm2/.iterm2`

## SSH Keys (1Password)

No private keys are stored in this repo.

SSH is configured to use the 1Password SSH agent socket:

```
~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
```

Make sure 1Password → Settings → Developer → “Use SSH Agent” is enabled.

## macOS Defaults & UI Changes

Defaults are enforced from `defaults.sh`. If you change settings in the UI, they will revert
on the next `make apply` unless you update `defaults.sh`.

To capture current UI settings:

```bash
make sync-defaults
```

This writes plist exports into `defaults-export/` for review.

## Dock Layout

Dock is reset every run via `dock.sh`. If you want a custom order, edit `dock.sh`.

## Display Resolution

This repo supports enforcing display resolution via `displayplacer`.

Steps:
1. Run `displayplacer list`
2. Paste a line into `displayplacer.conf`
3. Re-run `make apply` or `make display`

Example `displayplacer.conf` line:

```
id:YOUR_DISPLAY_ID res:2560x1440 hz:60 scaling:on origin:(0,0) degree:0
```

If `displayplacer.conf` is missing or empty, display configuration is skipped.

## Wallpaper

By default, `wallpaper.sh` tries to set:

```
~/Pictures/wallpaper.jpg
```

If you don’t want enforced wallpaper, comment out the wallpaper step in `bootstrap.sh`.

## FileVault Policy (Required)

Jump Desktop requires FileVault to be OFF in this setup.
`doctor.sh` will fail if FileVault is ON.

Disable it:
- System Settings → Privacy & Security → FileVault → Turn Off
- Or: `sudo fdesetup disable`

## Troubleshooting

- **Homebrew install fails**: Run `xcode-select --install` then re-run `make apply`.
- **1Password agent not detected**: Enable it in 1Password Developer settings, then re-run `make doctor`.
- **Dock not updating**: `dockutil` must be installed (in Brewfile). Re-run `make dock`.
- **Display not updating**: `displayplacer` must be installed (in Brewfile). Re-run `make display`.
- **iTerm2 prefs not loading**: Ensure defaults are applied and iTerm2 is pointed to `~/.iterm2`.

## Suggested Workflow for Updates

- Change dotfiles → commit → run `make apply`
- Change macOS UI settings → `make sync-defaults` → update `defaults.sh`
- Add apps → edit `Brewfile` → `make brew`

## License

MIT (or choose your own)
