#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bold() { printf "\n%s\n" "$*"; }
ok() { printf "[OK] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }
fail() { printf "[FAIL] %s\n" "$*"; exit 1; }

bold "Doctor: checking this Mac"

# ---- Basic OS check ----
if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "This repo is for macOS only."
fi
ok "macOS detected"

# ---- Apple Silicon check (informational) ----
arch="$(uname -m)"
if [[ "$arch" == "arm64" ]]; then
  ok "Apple Silicon (arm64)"
else
  warn "Not Apple Silicon (detected: $arch). This setup assumes /opt/homebrew." 
fi

# ---- Homebrew ----
if command -v brew >/dev/null 2>&1; then
  ok "Homebrew installed: $(command -v brew)"
else
  warn "Homebrew not found (bootstrap will install it)."
fi

# ---- Git ----
if command -v git >/dev/null 2>&1; then
  ok "git available"
else
  warn "git not found. You may need Xcode Command Line Tools: xcode-select --install"
fi

# ---- 1Password SSH agent socket ----
OP_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if [[ -S "$OP_SOCK" ]]; then
  ok "1Password SSH agent socket exists"
else
  warn "1Password SSH agent socket not found:"
  warn " $OP_SOCK"
  warn "Open 1Password -> Settings -> Developer -> 'Use SSH agent' (enable)"
fi

# ---- SSH can see keys via agent (best-effort) ----
if [[ -S "$OP_SOCK" ]]; then
  export SSH_AUTH_SOCK="$OP_SOCK"
fi
if command -v ssh-add >/dev/null 2>&1; then
  if ssh-add -L >/dev/null 2>&1; then
    ok "ssh-agent reachable (ssh-add -L succeeded)"
  else
    warn "ssh-agent not providing keys yet. If using 1Password, unlock it."
  fi
else
  warn "ssh-add not found (OpenSSH tools missing?)"
fi

# ---- FileVault status (Jump Desktop requirement) ----
fv_status="$(/usr/bin/fdesetup status 2>/dev/null || true)"
if echo "$fv_status" | grep -qi "FileVault is Off"; then
  ok "FileVault is OFF (required for Jump Desktop)"
else
  warn "FileVault appears ENABLED:"
  warn " $fv_status"
  warn "To turn it off (admin required):"
  warn " System Settings -> Privacy & Security -> FileVault -> Turn Off"
  warn " or (interactive): sudo fdesetup disable"
  fail "FileVault must be OFF per policy"
fi

bold "Doctor checks complete"
