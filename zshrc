#!/usr/bin/env zsh

[[ $- != *i* ]] && return
export EDITOR="nvim"
export PATH="$PATH:$HOME/.local/bin"
export W3M_DIR="$HOME/.cache/w3m"
export PYTHONWARNINGS="ignore:The parameter -j is used more than once:UserWarning:click.core:"
[ -f "$HOME/.config/zsh/aliases" ] && source "$HOME/.config/zsh/aliases"
[ -f "$HOME/.config/zsh/fzf.zsh" ] && source "$HOME/.config/zsh/fzf.zsh" 
# 加载隐私环境变量 (仅在交互式模式下)
if [[ $- == *i* ]]; then
    if [ -f "$HOME/.private" ]; then
        source "$HOME/.private"
    fi
fi
####Zim-start####
export ZIM_CONFIG_FILE="${HOME}/.config/zim/zimrc"
setopt HIST_IGNORE_ALL_DUPS
# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -v
setopt CORRECT
SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '
WORDCHARS=${WORDCHARS//[\/]}
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source ${ZIM_HOME}/zimfw.zsh init
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh
zmodload -F zsh/terminfo +p:terminfo
# Bind ^[[A/^[[B manually so up/down works both before and after zle-line-init
for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key
####Zim-end####

export HOMEBREW_NO_AUTO_UPDATE=1
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
####Yazi-start####
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
#####Yazi# ----------------------------------------

# FZF (Fuzzy Finder) Setup
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi
source <(fzf --zsh)
# -----------------------------------------end#####
