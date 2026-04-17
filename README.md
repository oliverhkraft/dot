# mac-bootstrap

A minimal, repeatable macOS bootstrap repo (Apple Silicon) using:
- Homebrew + Brewfile for apps/tools
- GNU Stow for dotfiles
- `defaults` + `dockutil` + `displayplacer` for macOS UI settings
- 1Password SSH agent (no private keys in repo)

This repo is intentionally simple and idempotent. Re-running the bootstrap applies the repo’s state.

**Overview**

This repo:
- Installs CLI tools and GUI apps (including Laravel Herd + Jump Desktop tools)
- Applies dotfiles (zsh, git, ssh, VS Code settings, Ghostty, Starship, Hammerspoon)
- Enforces macOS defaults, Dock layout, and display configuration
- Applies headless Mac Mini remote-access settings
- Sets Chrome as the default browser
- Fails fast if FileVault is ON (Jump Desktop requirement)

**Quick Start (New Mac)**

1. Disable FileVault (required for Jump Desktop)

System Settings → Privacy & Security → FileVault → Turn Off

Or:
```bash
sudo fdesetup disable
```

2. Install 1Password and enable the SSH agent

In 1Password: Settings → Developer → Enable “Use SSH Agent”

3. Make sure your SSH keys are in 1Password

If you already have keys on another Mac:
- Open 1Password on the old Mac
- Create a new “SSH Key” item and paste your existing private key
- On the new Mac, sign into 1Password and unlock it

If you don’t have keys yet:
- Generate a key and add it to 1Password

4. Ensure Git is available

On a new macOS install, Git may require Command Line Tools:
```bash
xcode-select --install
```

5. Clone this repo

```bash
git clone <YOUR_REPO_URL> mac-bootstrap
cd mac-bootstrap
```

6. Update identity placeholders

Edit `dotfiles/git/.gitconfig` and set your name/email.

7. Optional: update display configuration

If you want to set a specific screen layout, run:
```bash
displayplacer list
```
Copy the generated command into `displayplacer.conf` (one line).

8. Run the doctor check

```bash
make doctor
```
If FileVault is ON, the doctor will fail and tell you how to turn it off.

9. Apply everything

```bash
make apply
```

**What `make apply` Does**

1. Runs `doctor.sh` (checks prerequisites + FileVault policy)
2. Installs Homebrew (if missing)
3. Installs Brewfile packages and casks
4. Installs App Store apps via `mas` (currently Amphetamine; requires App Store login)
5. Applies dotfiles via Stow
6. Links VS Code `settings.json` only
7. Restores Stream Deck config from `streamdeck-export/` (if present)
8. Applies macOS defaults
9. Applies headless remote settings (`headless.sh`)
10. Sets Chrome as the default browser
11. Sets Dock layout
12. Applies display configuration (if `displayplacer.conf` exists)
13. Applies wallpaper (if `~/Pictures/wallpaper.jpg` exists)

You can re-run `make apply` at any time. It is safe and will re-apply the repo’s state.

**Commands**

- `make apply` – Full bootstrap
- `make doctor` – Prereq + policy checks
- `make brew` – Install/update Brewfile only
- `make stow` – Apply dotfiles only (and link VS Code settings.json)
- `make defaults` – Apply macOS defaults only
- `make headless` – Apply headless remote settings only
- `make tunnel` – Guided Cloudflare tunnel setup (one-time, interactive)
- `make browser` – Set default browser (Chrome)
- `make dock` – Apply Dock layout only
- `make display` – Apply display configuration
- `make fonts` – Open Font Book (optional)
- `make streamdeck-sync` – Export local Stream Deck config into `streamdeck-export/`
- `make streamdeck-restore` – Restore tracked Stream Deck config to this Mac
- `make sync-defaults` – Export current UI defaults into `defaults-export/`
- `make snapshot NAME=before` – Snapshot defaults for diffing

(Equivalent `just` commands are available if you prefer `just`.)

**Apps Installed**

From `Brewfile`:
- CLI: `git`, `stow`, `dockutil`, `displayplacer`, `mas`, `jq`, `ripgrep`, `fd`, `just`, `antidote`, `starship`, `lazygit`, `duti`, `ansible`, `direnv`, `docker`, `docker-compose`, `colima`
- Casks: `1password`, `1password-cli`, `visual-studio-code`, `ghostty`, `hammerspoon`, `raycast`, `herd`, `jump-desktop`, `jump-desktop-connect`, `betterdisplay`, `font-jetbrains-mono-nerd-font`, `google-chrome`, `slack`, `todoist-app`, `codex-app`, `elgato-stream-deck`

Edit `Brewfile` to add/remove apps. Re-run `make brew` or `make apply`.

**Dotfiles Layout (Stow)**

```
dotfiles/
├── git/.gitconfig
├── ssh/.ssh/config
├── ssh/.ssh/known_hosts
├── zsh/.zprofile
├── zsh/.zshrc
├── zsh/.zsh_plugins.txt
├── vscode/Library/Application Support/Code/User/settings.json
├── ghostty/.config/ghostty/config
├── hammerspoon/.hammerspoon/init.lua
└── starship/.config/starship.toml
```

Stow command used:
```bash
stow git ssh zsh ghostty starship hammerspoon
```

VS Code is handled separately so only `settings.json` is linked (no extra VS Code files in the repo).

**Nerd Font (Icons)**

This repo installs JetBrainsMono Nerd Font via Homebrew cask so icons render correctly in Starship.

Ghostty is configured to use this font automatically. If you use a different terminal,
set its font to **JetBrainsMono Nerd Font** manually.

Optional: run `make fonts` to open Font Book and verify the font is installed.

**Prompt (Starship)**

Config lives at:
- `dotfiles/starship/.config/starship.toml`

**Zsh Plugins (Antidote)**

Plugins are loaded from:
- `dotfiles/zsh/.zsh_plugins.txt`

To add/remove plugins, edit the file and restart your shell.

**Window Manager (Hammerspoon)**

Config lives at:
- `dotfiles/hammerspoon/.hammerspoon/init.lua`

Hotkeys (Rectangle-style):
- `ctrl+alt+Left/Right/Up/Down` → halves
- `ctrl+alt+C` → center half
- `ctrl+alt+U/I/J/K` → corners
- `ctrl+alt+D/F/G` → thirds
- `ctrl+alt+E/T/Y` → two-thirds
- `ctrl+alt+Return` → maximize
- `ctrl+alt+'` → almost maximize (90%)
- `ctrl+alt+shift+Up` → maximize height

You must grant Accessibility permissions to Hammerspoon the first time it runs.

**Stream Deck Neo**

This repo tracks Stream Deck app state separately from Stow:
- Source on macOS: `~/Library/Application Support/com.elgato.StreamDeck`
- Tracked copy in repo: `streamdeck-export/Library/Application Support/com.elgato.StreamDeck`

Workflow:
1. Configure your Stream Deck Neo in the Elgato app.
2. Quit Stream Deck.
3. Run `make streamdeck-sync`.
4. Commit `streamdeck-export/` changes.

On a new Mac:
1. Run `make apply` (or `make streamdeck-restore` manually).
2. Open Stream Deck and verify profiles/buttons are loaded.

**Terminal (Ghostty)**

Config lives at:
- `dotfiles/ghostty/.config/ghostty/config`

Restart Ghostty after `make apply`.

**Default Browser (Chrome)**

Default browser is set via `duti` in `browser.sh`.

If it doesn’t take effect immediately:
- Run `make browser` again after Chrome is installed
- Log out and back in

**SSH Keys (1Password)**

No private keys are stored in this repo.

SSH is configured to use the 1Password SSH agent socket:
```
~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
```

If Git over SSH prompts for a password on a new Mac:
- Make sure the key is saved in 1Password
- Make sure 1Password is unlocked
- Run `ssh-add -L` to confirm keys are visible
- Add the public key to GitHub/GitLab if needed

**macOS Defaults & UI Changes**

Defaults are enforced from `defaults.sh`. If you change settings in the UI, they will revert
on the next `make apply` unless you update `defaults.sh`.

To capture current UI settings:
```bash
make sync-defaults
```

This writes plist exports into `defaults-export/` for review.

**Headless Remote Settings**

Headless/remote settings are enforced from `headless.sh` on every `make apply`.

Configured automatically:
- `pmset` keep-awake policy for remote availability (`sleep=0`, `displaysleep=0`, `disksleep=0`)
- `pmset autorestart=1` (auto boot after power failure)
- `pmset womp=1` (Wake on network access)
- Login items for `Jump Desktop Connect`, `BetterDisplay`, and `Amphetamine` (if installed)

Still manual:
- Grant macOS permissions for Jump Desktop Connect/BetterDisplay when prompted
- Configure Jump Desktop account pairing and iPad-only viewer settings
- Choose/create BetterDisplay virtual display profiles
- Sign in to the Mac App Store if you want `make apply` to auto-install Amphetamine

**Remote Access (SSH via Cloudflare Tunnel)**

This repo supports SSH access to the Mac Mini from an iPad (or any device) via a Cloudflare Tunnel.
No router ports are exposed.

Prerequisites:
- A Cloudflare account with a domain
- `make brew` has been run (installs `cloudflared` and `tmux`)

One-time setup:
```bash
make tunnel
```

This guides you through:
1. Authenticating with Cloudflare
2. Creating a named tunnel
3. Configuring the tunnel to proxy SSH
4. Setting up a DNS record
5. Installing the tunnel as a launchd service

After setup, the tunnel runs automatically on boot.

Connecting from iPad:
1. Install Blink Shell or Termius
2. Add your iPad's public key to `~/.ssh/authorized_keys` on this Mac
3. SSH to your chosen hostname (e.g. `ssh.yourdomain.com`)
4. tmux auto-attaches — sessions survive disconnects

Port forwarding:
- Dev servers: `ssh -L 8080:localhost:8000 your-hostname`
- SOCKS proxy: `ssh -D 1080 your-hostname`, then configure iPad Wi-Fi to use SOCKS proxy at `localhost:1080`

Health check:
- `make headless` (or `make apply`) verifies Remote Login is enabled, sshd is hardened, and the cloudflared service is running.

**Dock Layout**

Dock is reset every run via `dock.sh`. If you want a custom order, edit `dock.sh`.

**Display Configuration**

Display config is applied from `displayplacer.conf`. If display IDs change, run:
```bash
displayplacer list
```
Then update `displayplacer.conf` with the new line.

**Wallpaper**

If `~/Pictures/wallpaper.jpg` exists, it is applied. Otherwise the step is skipped.

**Troubleshooting**

- `brew bundle` fails because of missing/renamed casks
  - Run `brew search <name>` and update `Brewfile`

- Stow errors about missing package
  - Ensure the package exists under `dotfiles/` and matches the name in `stow` commands

- Starship icons render as `?`
  - Verify JetBrainsMono Nerd Font is installed
  - Ensure your terminal is using **JetBrainsMono Nerd Font**
  - Restart the terminal app

- Hammerspoon doesn’t move windows
  - Grant Accessibility permissions in System Settings → Privacy & Security → Accessibility

- Default browser doesn’t change
  - Run `make browser` again after Chrome is installed
  - Log out and back in

**Notes**

`make apply` is the superset. You do not need to run `make brew`, `make stow`, or `make dock`
manually unless you want to apply only one part.
