# Dotfiles Ubuntu bash profile

export PATH="$HOME/.local/bin:/snap/bin:$PATH"

if command -v nvim >/dev/null 2>&1; then
  export EDITOR="${EDITOR:-nvim}"
else
  export EDITOR="${EDITOR:-vim}"
fi

alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias lh='ls -alht'
alias mv='mv -i'
alias cp='cp -i'

alias v='nvim'
alias vo='nvim -O'
alias vd='nvim -d'

alias tm='tmux new -A -s main'
alias tn='tmux new-session -s main'
alias ta='tmux attach'
alias tls='tmux ls'
alias tk='tmux kill-session -t'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias cf='cd ~/dotfiles/'

alias gg='git status'
alias gdiff='git diff'
alias gco='git checkout'
alias gcm='git commit -m'
alias gpull='git pull'
alias gpush='git push'
alias gbr='git branch'

alias vv='nvim ~/.config/nvim'
alias vt='nvim ~/.config/tmux/tmux.conf'
alias vs='nvim ~/.ssh/config'
alias sb='source ~/.bashrc'
alias reload='exec bash'

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
  alias zz='z -'
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

if command -v fzf >/dev/null 2>&1 && fzf --bash >/dev/null 2>&1; then
  source <(fzf --bash)
fi

if command -v yazi >/dev/null 2>&1; then
  y() {
    local tmp cwd
    tmp="$(mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXX")" || return
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
fi

[ -f "$HOME/.config/bash/aliases.local" ] && source "$HOME/.config/bash/aliases.local"
