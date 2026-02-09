export EDITOR="code --wait"

setopt autocd
setopt correct

alias ll="ls -lah"
alias gs="git status"
alias gl="git log --oneline --decorate --graph -20"

# 1Password SSH agent socket
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
