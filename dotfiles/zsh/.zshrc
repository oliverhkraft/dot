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
