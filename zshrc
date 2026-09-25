#!/usr/bin/env zsh

[[ $- != *i* ]] && return

if command -v nvim >/dev/null 2>&1; then
	export EDITOR="${EDITOR:-nvim}"
else
	export EDITOR="${EDITOR:-vim}"
fi

export PATH="$PATH:$HOME/.local/bin"
export W3M_DIR="$HOME/.cache/w3m"
export PYTHONWARNINGS="ignore:The parameter -j is used more than once:UserWarning:click.core:"

[ -d /opt/homebrew/opt/python@3.13/libexec/bin ] && export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"

# Use one shared Python environment for small, ad-hoc scripts.
# Keep an already-active project environment untouched.
if [[ -z "${VIRTUAL_ENV:-}" && -f "$HOME/.global-env/bin/activate" ]]; then
	source "$HOME/.global-env/bin/activate"
fi

[ -f "$HOME/.config/zsh/aliases" ] && source "$HOME/.config/zsh/aliases"
# 加载隐私环境变量 (仅在交互式模式下)
if [[ $- == *i* ]]; then
    if [ -f "$HOME/.private" ]; then
        source "$HOME/.private"
    fi
fi
# Shell behavior and retained plugins
setopt HIST_IGNORE_ALL_DUPS
# Use a single editing mode and native reverse history search.
bindkey -e
bindkey -M emacs '^R' history-incremental-search-backward
# Restore word navigation.
bindkey '^[f' forward-word      # Option+→
bindkey '^[b' backward-word     # Option+←
bindkey '^A'  beginning-of-line # Ctrl+A
bindkey '^E'  end-of-line       # Ctrl+E

setopt CORRECT
SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '
WORDCHARS=${WORDCHARS//[\/]}
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
source "$HOME/.config/zsh/plugins.zsh"
zmodload -F zsh/terminfo +p:terminfo
# Bind ^[[A/^[[B manually so up/down works both before and after zle-line-init
if (( ${+widgets[history-substring-search-up]} && ${+widgets[history-substring-search-down]} )); then
	for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
	for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
fi
unset key
if command -v brew >/dev/null 2>&1; then
	export HOMEBREW_NO_AUTO_UPDATE=1
fi

[ -d /opt/homebrew/opt/node@22/bin ] && export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
[ -d /Library/TeX/texbin ] && export PATH="/Library/TeX/texbin:$PATH"
