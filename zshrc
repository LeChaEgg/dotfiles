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
# Restore word navigation in vi insert mode
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
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  elif (( ${+commands[wget]} )); then
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ -r ${ZIM_HOME}/zimfw.zsh && ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source ${ZIM_HOME}/zimfw.zsh init
fi
# Initialize modules.
[[ -r ${ZIM_HOME}/init.zsh ]] && source ${ZIM_HOME}/init.zsh
zmodload -F zsh/terminfo +p:terminfo
# Bind ^[[A/^[[B manually so up/down works both before and after zle-line-init
if (( ${+widgets[history-substring-search-up]} && ${+widgets[history-substring-search-down]} )); then
	for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
	for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
	for key ('k') bindkey -M vicmd ${key} history-substring-search-up
	for key ('j') bindkey -M vicmd ${key} history-substring-search-down
fi
unset key
####Zim-end####

if command -v brew >/dev/null 2>&1; then
	export HOMEBREW_NO_AUTO_UPDATE=1
fi

[ -d /opt/homebrew/opt/node@22/bin ] && export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
####Yazi-start####
if command -v yazi >/dev/null 2>&1; then
	function y() {
		local tmp cwd
		tmp="$(mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXX")" || return
		yazi "$@" --cwd-file="$tmp"
		IFS= read -r -d '' cwd < "$tmp"
		[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
		rm -f -- "$tmp"
	}
fi
#####Yazi# ----------------------------------------

# FZF (Fuzzy Finder) Setup
if [ -d /opt/homebrew/opt/fzf/bin ] && [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
	PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi
if command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
	source <(fzf --zsh)
fi
# -----------------------------------------end#####
[ -d /Library/TeX/texbin ] && export PATH="/Library/TeX/texbin:$PATH"

# Added by Antigravity
[ -d "$HOME/.antigravity/antigravity/bin" ] && export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
