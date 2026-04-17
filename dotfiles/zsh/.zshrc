# Auto-attach tmux on SSH sessions for resilience
if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]] && command -v tmux &>/dev/null; then
  exec tmux new-session -A -s main
fi

export EDITOR="code --wait"
# Antidote (Zsh plugin manager)
if [ -r /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]; then
  source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
  ZSH_PLUGINS_FILE="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
  ZSH_BUNDLE_FILE="${ZDOTDIR:-$HOME}/.zsh_plugins.zsh"
  if [ -f "$ZSH_PLUGINS_FILE" ]; then
    if [ ! -f "$ZSH_BUNDLE_FILE" ] || [ "$ZSH_PLUGINS_FILE" -nt "$ZSH_BUNDLE_FILE" ]; then
      antidote bundle < "$ZSH_PLUGINS_FILE" > "$ZSH_BUNDLE_FILE"
    fi
    source "$ZSH_BUNDLE_FILE"
  fi
fi

# Initialize completions
autoload -Uz compinit && compinit

# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi


setopt autocd
setopt correct

alias ll="ls -lah"
alias gs="git status"
alias gl="git log --oneline --decorate --graph -20"

# 1Password SSH agent socket
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"


# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="/Users/ohk-mini/Library/Application Support/Herd/config/php/84/"


# Herd injected NVM configuration
export NVM_DIR="/Users/ohk-mini/Library/Application Support/Herd/config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

[[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] && builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"

# Herd injected PHP binary.
export PATH="/Users/ohk-mini/Library/Application Support/Herd/bin/":$PATH


# Herd injected PHP 8.3 configuration.
export HERD_PHP_83_INI_SCAN_DIR="/Users/ohk-mini/Library/Application Support/Herd/config/php/83/"

# OneCLI
export PATH="/Users/ohk-mini/.local/bin:$PATH"

# direnv
eval "$(direnv hook zsh)"
