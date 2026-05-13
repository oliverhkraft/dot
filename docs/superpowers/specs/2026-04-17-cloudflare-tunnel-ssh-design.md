# Cloudflare Tunnel SSH Access — Design Spec

## Goal

Enable reliable, resilient SSH access from an iPad to the Mac Mini via a Cloudflare Tunnel, with port forwarding support for local dev servers and SOCKS proxy browsing. No router ports exposed.

## Context

- The Mac Mini is a stationary headless machine (already configured via `headless.sh` with keep-awake, auto-restart, Wake on LAN).
- Primary work happens on an iPad connecting remotely.
- Jump Desktop already provides GUI access; this adds terminal access.
- The user has an existing Cloudflare account and domain.
- SSH keys are managed via 1Password SSH agent (client side). The iPad SSH client will use its own key, added to `authorized_keys` on the Mini.

## Approach

**Cloudflare Tunnel + SSH + tmux** (Option A from brainstorming).

- `cloudflared` runs on the Mac Mini as a launchd service, maintaining a persistent tunnel to Cloudflare's edge.
- A DNS record (e.g. `ssh.yourdomain.com`) routes through the tunnel to `localhost:22` on the Mini.
- The iPad connects using an SSH client with Cloudflare Access support (Blink Shell or Termius).
- tmux auto-attach on SSH login provides session persistence across disconnects.
- No mosh — mosh requires UDP which Cloudflare Tunnel doesn't proxy. tmux provides ~90% of the practical resilience benefit.

## Architecture

```
iPad (Blink Shell / Termius)
  └─ SSH via ProxyCommand (cloudflared access ssh)
       └─ Cloudflare Edge (ssh.yourdomain.com)
            └─ Cloudflare Tunnel (cloudflared service on Mac Mini)
                 └─ localhost:22 (macOS sshd)
                      └─ tmux auto-attach
```

Port forwarding flows through the same SSH connection:
- `-L 8080:localhost:8000` for dev servers (Herd, Vite, Docker, etc.)
- `-D 1080` for SOCKS proxy browsing

## Components

### 1. Mac Mini: `cloudflared` tunnel as a launchd service

**Install:** Add `cloudflared` to `Brewfile`.

**Setup script:** `scripts/cloudflared-setup.sh` — guided, interactive, one-time:
1. Run `cloudflared tunnel login` (opens browser for Cloudflare auth)
2. Create a named tunnel: `cloudflared tunnel create mac-mini`
3. Write tunnel config to `~/.cloudflared/config.yml`:
   ```yaml
   tunnel: <TUNNEL_UUID>
   credentials-file: /Users/<user>/.cloudflared/<TUNNEL_UUID>.json
   ingress:
     - hostname: ssh.yourdomain.com
       service: ssh://localhost:22
     - service: http_status:404
   ```
4. Create DNS CNAME: `cloudflared tunnel route dns mac-mini ssh.yourdomain.com`
5. Install launchd service: `cloudflared service install`

**Health check script:** `scripts/cloudflared-check.sh` — idempotent, used by `headless.sh`:
- Verify `cloudflared` is installed
- Verify the launchd service is loaded and running
- Warn (don't fail) if not — the one-time setup may not have been run yet

### 2. Mac Mini: SSH server (macOS Remote Login) + hardening

**Added to `headless.sh`:**
- Enable Remote Login: `sudo systemsetup -setremotelogin on`
- Harden sshd:
  - `PasswordAuthentication no`
  - `PubkeyAuthentication yes`
  - `PermitRootLogin no`
- Run cloudflared health check

**Hardening mechanism:** Write a drop-in config to `/etc/ssh/sshd_config.d/99-hardened.conf` (macOS Ventura+ supports this directory). This avoids modifying the system `sshd_config`.

**authorized_keys:** The user manually adds the iPad SSH client's public key. SSH key files (`authorized_keys`, `id_*`, `known_hosts.old`) need to be added to `.gitignore` — they are currently untracked but not ignored.

### 3. tmux auto-attach for SSH resilience

**Install:** Add `tmux` to `Brewfile`.

**Auto-attach:** Add to `dotfiles/zsh/.zshrc`:
```bash
# Auto-attach tmux on SSH sessions for resilience
if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]] && command -v tmux &>/dev/null; then
  exec tmux new-session -A -s main
fi
```

This means: if this is an SSH login, and we're not already inside tmux, attach to the `main` session (or create it). `exec` replaces the shell so exiting tmux exits the SSH session cleanly.

### 4. Makefile / justfile targets

**New target:**
- `make tunnel` / `just tunnel` — runs `scripts/cloudflared-setup.sh`

**Modified targets:**
- `make apply` / `make headless` — unchanged in behavior, but `headless.sh` now also enables Remote Login, hardens sshd, and checks cloudflared status

### 5. iPad side (manual, not in dotfiles)

Not managed by this repo. User documentation only.

1. Install Blink Shell (or Termius) from the App Store
2. Configure an SSH host pointing at `ssh.yourdomain.com` with Cloudflare Access proxy
3. Add the iPad client's public key to `~/.ssh/authorized_keys` on the Mini
4. For dev servers: `ssh -L 8080:localhost:8000 mini`
5. For SOCKS proxy: `ssh -D 1080 mini`, then set iPad Wi-Fi proxy to SOCKS `localhost:1080`

## Files Changed

| File | Change |
|------|--------|
| `Brewfile` | Add `cloudflared`, `tmux` |
| `headless.sh` | Enable Remote Login, harden sshd, cloudflared health check |
| `scripts/cloudflared-setup.sh` | New — guided tunnel setup |
| `scripts/cloudflared-check.sh` | New — idempotent health check |
| `dotfiles/zsh/.zshrc` | Add SSH tmux auto-attach block |
| `Makefile` | Add `tunnel` target |
| `justfile` | Add `tunnel` target |
| `.gitignore` | Add SSH key files (`id_*`, `authorized_keys`, `known_hosts.old`) |
| `README.md` | Add "Remote Access via Cloudflare Tunnel" section |

## What stays manual

1. `make tunnel` (one-time interactive Cloudflare auth + tunnel creation)
2. iPad SSH client install + configuration
3. Adding iPad's public key to `~/.ssh/authorized_keys` on the Mini
4. Choosing the actual hostname (e.g. `ssh.yourdomain.com`)

## Out of scope

- Mosh (requires UDP; Cloudflare Tunnel is TCP-only)
- Cloudflare Access policies / zero-trust auth beyond the tunnel itself
- Managing iPad-side dotfiles or SSH config
- Automating the Cloudflare browser login step
