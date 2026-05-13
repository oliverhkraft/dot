# Cloudflare Tunnel SSH Access — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable reliable SSH access from an iPad to the Mac Mini via a Cloudflare Tunnel, with tmux session persistence and port forwarding support.

**Architecture:** `cloudflared` runs as a launchd service on the Mac Mini, proxying a Cloudflare-managed hostname to `localhost:22`. macOS Remote Login (sshd) is enabled and hardened. tmux auto-attaches on SSH login for session resilience.

**Tech Stack:** Bash scripts, Homebrew, cloudflared, tmux, macOS launchd, GNU Stow

---

### Task 1: Add `cloudflared` and `tmux` to Brewfile

**Files:**
- Modify: `Brewfile`

- [ ] **Step 1: Add brew entries**

Add these two lines after the existing `brew "colima"` line (line 18) in `Brewfile`:

```
brew "cloudflared"
brew "tmux"
```

- [ ] **Step 2: Verify Brewfile syntax**

Run: `brew bundle check --file Brewfile`
Expected: Lists `cloudflared` and `tmux` as missing (not yet installed via bundle), no syntax errors.

- [ ] **Step 3: Install**

Run: `brew bundle --file Brewfile`
Expected: `cloudflared` and `tmux` are installed (or already satisfied).

- [ ] **Step 4: Verify**

Run: `command -v cloudflared && command -v tmux`
Expected: Both print paths (e.g. `/opt/homebrew/bin/cloudflared`, `/opt/homebrew/bin/tmux`).

- [ ] **Step 5: Commit**

```bash
git add Brewfile
git commit -m "feat: add cloudflared and tmux to Brewfile"
```

---

### Task 2: Add SSH key files to `.gitignore`

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add ignore patterns**

Add these lines at the end of `.gitignore`:

```
dotfiles/ssh/.ssh/id_*
dotfiles/ssh/.ssh/authorized_keys
dotfiles/ssh/.ssh/known_hosts.old
```

- [ ] **Step 2: Verify ignored files**

Run: `git status dotfiles/ssh/`
Expected: `id_ed25519`, `id_ed25519.pub`, `authorized_keys`, `known_hosts.old` no longer appear as untracked.

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: gitignore SSH key files and authorized_keys"
```

---

### Task 3: Create `scripts/cloudflared-check.sh`

**Files:**
- Create: `scripts/cloudflared-check.sh`

- [ ] **Step 1: Write the health check script**

Create `scripts/cloudflared-check.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ok() { printf "[OK] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }

check_cloudflared() {
  if ! command -v cloudflared &>/dev/null; then
    warn "cloudflared not installed. Run 'make brew' first."
    return
  fi
  ok "cloudflared installed"

  local plist="$HOME/Library/LaunchAgents/com.cloudflare.cloudflared.plist"
  if [[ ! -f "$plist" ]]; then
    warn "cloudflared launchd service not installed. Run 'make tunnel' to set up."
    return
  fi
  ok "cloudflared launchd plist exists"

  if launchctl list com.cloudflare.cloudflared &>/dev/null; then
    ok "cloudflared service is running"
  else
    warn "cloudflared service is not running. Try: launchctl load $plist"
  fi
}

check_cloudflared
```

- [ ] **Step 2: Make executable**

Run: `chmod +x scripts/cloudflared-check.sh`

- [ ] **Step 3: Verify it runs**

Run: `./scripts/cloudflared-check.sh`
Expected: Prints `[OK] cloudflared installed` (since it was installed in Task 1), then `[WARN]` for the service (since `make tunnel` hasn't been run yet). No errors.

- [ ] **Step 4: Commit**

```bash
git add scripts/cloudflared-check.sh
git commit -m "feat: add cloudflared health check script"
```

---

### Task 4: Create `scripts/cloudflared-setup.sh`

**Files:**
- Create: `scripts/cloudflared-setup.sh`

- [ ] **Step 1: Write the setup script**

Create `scripts/cloudflared-setup.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }
ok() { printf "[OK] %s\n" "$*"; }
err() { printf "[ERROR] %s\n" "$*" >&2; exit 1; }

TUNNEL_NAME="mac-mini"

main() {
  if ! command -v cloudflared &>/dev/null; then
    err "cloudflared not installed. Run 'make brew' first."
  fi

  # Step 1: Authenticate with Cloudflare
  log "Authenticating with Cloudflare"
  if [[ -f "$HOME/.cloudflared/cert.pem" ]]; then
    ok "Already authenticated (cert.pem exists)"
  else
    echo "A browser window will open. Log in to Cloudflare and authorize cloudflared."
    cloudflared tunnel login
    ok "Authenticated"
  fi

  # Step 2: Create tunnel (skip if it already exists)
  log "Creating tunnel '$TUNNEL_NAME'"
  if cloudflared tunnel info "$TUNNEL_NAME" &>/dev/null; then
    ok "Tunnel '$TUNNEL_NAME' already exists"
  else
    cloudflared tunnel create "$TUNNEL_NAME"
    ok "Tunnel '$TUNNEL_NAME' created"
  fi

  # Step 3: Get tunnel UUID
  TUNNEL_UUID=$(cloudflared tunnel info "$TUNNEL_NAME" 2>&1 | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
  if [[ -z "$TUNNEL_UUID" ]]; then
    err "Could not determine tunnel UUID. Check 'cloudflared tunnel list'."
  fi
  ok "Tunnel UUID: $TUNNEL_UUID"

  # Step 4: Prompt for hostname
  printf "\nEnter the hostname to use for SSH (e.g. ssh.example.com): "
  read -r SSH_HOSTNAME
  if [[ -z "$SSH_HOSTNAME" ]]; then
    err "Hostname cannot be empty."
  fi

  # Step 5: Write config
  log "Writing tunnel config"
  local config_dir="$HOME/.cloudflared"
  local config_file="$config_dir/config.yml"

  if [[ -f "$config_file" ]]; then
    echo "Existing config found at $config_file"
    printf "Overwrite? [y/N]: "
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
      echo "Skipping config write. Edit $config_file manually if needed."
      return
    fi
  fi

  cat > "$config_file" <<EOF
tunnel: $TUNNEL_UUID
credentials-file: $config_dir/$TUNNEL_UUID.json
ingress:
  - hostname: $SSH_HOSTNAME
    service: ssh://localhost:22
  - service: http_status:404
EOF
  ok "Config written to $config_file"

  # Step 6: Route DNS
  log "Routing DNS"
  echo "This will create a CNAME record for $SSH_HOSTNAME pointing to the tunnel."
  echo "Make sure $SSH_HOSTNAME's domain is managed by Cloudflare."
  cloudflared tunnel route dns "$TUNNEL_NAME" "$SSH_HOSTNAME" || {
    warn "DNS routing failed. You may need to add the CNAME manually in Cloudflare dashboard."
  }

  # Step 7: Install launchd service
  log "Installing launchd service"
  if launchctl list com.cloudflare.cloudflared &>/dev/null; then
    ok "Service already running"
  else
    cloudflared service install
    ok "Service installed and started"
  fi

  log "Setup complete!"
  echo ""
  echo "Your tunnel is running. SSH is proxied at: $SSH_HOSTNAME"
  echo ""
  echo "Next steps (on iPad):"
  echo "  1. Install Blink Shell or Termius"
  echo "  2. Add your iPad's public key to ~/.ssh/authorized_keys on this Mac"
  echo "  3. Connect via SSH to $SSH_HOSTNAME"
  echo "  4. For port forwarding: ssh -L 8080:localhost:8000 $SSH_HOSTNAME"
  echo "  5. For SOCKS proxy:    ssh -D 1080 $SSH_HOSTNAME"
}

warn() { printf "[WARN] %s\n" "$*"; }

main "$@"
```

- [ ] **Step 2: Make executable**

Run: `chmod +x scripts/cloudflared-setup.sh`

- [ ] **Step 3: Verify syntax**

Run: `bash -n scripts/cloudflared-setup.sh`
Expected: No output (no syntax errors).

- [ ] **Step 4: Commit**

```bash
git add scripts/cloudflared-setup.sh
git commit -m "feat: add guided cloudflared tunnel setup script"
```

---

### Task 5: Update `headless.sh` — Remote Login, sshd hardening, cloudflared check

**Files:**
- Modify: `headless.sh`

- [ ] **Step 1: Add Remote Login enablement**

Add this block in the `main()` function of `headless.sh`, after the `pmset` section (after line 103 `fi`) and before the login items section (before line 105 `if command -v osascript`):

```bash
  # Enable SSH (Remote Login) for remote access
  if command -v systemsetup >/dev/null 2>&1; then
    if systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
      ok "Remote Login (SSH) already enabled"
    else
      info "Enabling Remote Login (SSH) — requires admin"
      if sudo systemsetup -setremotelogin on >/dev/null 2>&1; then
        ok "Remote Login enabled"
      else
        warn "Could not enable Remote Login. Enable manually: System Settings → General → Sharing → Remote Login"
      fi
    fi
  fi
```

- [ ] **Step 2: Add sshd hardening**

Add this block immediately after the Remote Login block:

```bash
  # Harden sshd — keys only, no root
  local sshd_drop_in="/etc/ssh/sshd_config.d/99-hardened.conf"
  local sshd_content="PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no"

  if [[ -f "$sshd_drop_in" ]] && [[ "$(cat "$sshd_drop_in")" == "$sshd_content" ]]; then
    ok "sshd hardening config already in place"
  else
    info "Writing sshd hardening config — requires admin"
    if echo "$sshd_content" | sudo tee "$sshd_drop_in" >/dev/null 2>&1; then
      ok "sshd hardening config written to $sshd_drop_in"
    else
      warn "Could not write sshd config. Create $sshd_drop_in manually with: PasswordAuthentication no, PubkeyAuthentication yes, PermitRootLogin no"
    fi
  fi
```

- [ ] **Step 3: Add cloudflared health check**

Add this block after the sshd hardening block:

```bash
  # Check cloudflared tunnel status
  local check_script
  check_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/cloudflared-check.sh"
  if [[ -x "$check_script" ]]; then
    bash "$check_script"
  else
    warn "cloudflared-check.sh not found; skipping tunnel status check."
  fi
```

- [ ] **Step 4: Verify headless.sh syntax**

Run: `bash -n headless.sh`
Expected: No output (no syntax errors).

- [ ] **Step 5: Verify headless.sh runs**

Run: `./headless.sh`
Expected: Existing pmset/login-item output, plus new `[OK]` or `[WARN]` lines for Remote Login, sshd hardening, and cloudflared check. No errors.

- [ ] **Step 6: Commit**

```bash
git add headless.sh
git commit -m "feat: enable Remote Login, harden sshd, check cloudflared in headless.sh"
```

---

### Task 6: Add tmux auto-attach to `.zshrc`

**Files:**
- Modify: `dotfiles/zsh/.zshrc`

- [ ] **Step 1: Add tmux auto-attach block**

Add this block at the very top of `dotfiles/zsh/.zshrc`, before the existing `export EDITOR=` line (line 1):

```bash
# Auto-attach tmux on SSH sessions for resilience
if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]] && command -v tmux &>/dev/null; then
  exec tmux new-session -A -s main
fi

```

This must be at the top so tmux takes over before any other shell config runs — the full `.zshrc` will run again inside the tmux session.

- [ ] **Step 2: Verify syntax**

Run: `zsh -n dotfiles/zsh/.zshrc`
Expected: No output (no syntax errors).

- [ ] **Step 3: Commit**

```bash
git add dotfiles/zsh/.zshrc
git commit -m "feat: auto-attach tmux on SSH login for session resilience"
```

---

### Task 7: Add `tunnel` target to Makefile and justfile

**Files:**
- Modify: `Makefile`
- Modify: `justfile`

- [ ] **Step 1: Add to Makefile**

Add the help text in the `help` target, after the `make headless` line (line 13):

```
	@echo " make tunnel         Run guided Cloudflare tunnel setup (one-time)"
```

Add the target at the end of `Makefile`:

```makefile
.PHONY: tunnel
tunnel:
	./scripts/cloudflared-setup.sh
```

- [ ] **Step 2: Add to justfile**

Add at the end of `justfile`:

```just
tunnel:
	./scripts/cloudflared-setup.sh
```

- [ ] **Step 3: Verify targets exist**

Run: `make help | grep tunnel && just --list | grep tunnel`
Expected: Both show the `tunnel` target.

- [ ] **Step 4: Commit**

```bash
git add Makefile justfile
git commit -m "feat: add 'tunnel' target for cloudflared setup"
```

---

### Task 8: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add to Commands section**

Add after the `make headless` line (around line 110) in the Commands section:

```markdown
- `make tunnel` – Guided Cloudflare tunnel setup (one-time, interactive)
```

- [ ] **Step 2: Add Remote Access section**

Add a new section after the "Headless Remote Settings" section (after line 261) and before "Dock Layout":

```markdown
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
```

- [ ] **Step 3: Verify README renders**

Skim the file to make sure markdown is valid and the new section is in the right place.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add Cloudflare Tunnel SSH remote access section"
```

---

## Self-Review

**Spec coverage:**
- `cloudflared` + `tmux` in Brewfile → Task 1
- `.gitignore` for SSH keys → Task 2
- `scripts/cloudflared-check.sh` → Task 3
- `scripts/cloudflared-setup.sh` → Task 4
- `headless.sh` (Remote Login, sshd hardening, cloudflared check) → Task 5
- tmux auto-attach in `.zshrc` → Task 6
- Makefile/justfile `tunnel` target → Task 7
- README update → Task 8
- iPad side (manual) → documented in Task 4 script output + Task 8 README

All spec sections covered.

**Placeholder scan:** No TBD, TODO, or vague "add appropriate" language. All code blocks are complete.

**Type consistency:** Function names (`ok`, `warn`, `log`, `err`) are consistent across scripts and match the existing style in `headless.sh`.
