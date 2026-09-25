# Load the retained Zsh plugins bundled with this dotfiles repository.
ZSH_PLUGIN_HOME="${${(%):-%N}:A:h}/plugins"

fpath=(
	"${ZSH_PLUGIN_HOME}/utility/functions"
	"${ZSH_PLUGIN_HOME}/git/functions"
	"${ZSH_PLUGIN_HOME}/git-info/functions"
	"${ZSH_PLUGIN_HOME}/duration-info/functions"
	"${ZSH_PLUGIN_HOME}/zsh-completions/src"
	${fpath}
)

autoload -Uz -- mkcd mkpw git-alias-lookup git-branch-current git-branch-delete-interactive \
	git-branch-remote-tracking git-dir git-ignore-add git-root git-stash-clear-interactive \
	git-stash-recover git-submodule-move git-submodule-remove coalesce git-action git-info \
	duration-info-precmd duration-info-preexec

source "${ZSH_PLUGIN_HOME}/environment/init.zsh"
source "${ZSH_PLUGIN_HOME}/input/init.zsh"
source "${ZSH_PLUGIN_HOME}/termtitle/init.zsh"
source "${ZSH_PLUGIN_HOME}/utility/init.zsh"
source "${ZSH_PLUGIN_HOME}/git/init.zsh"
source "${ZSH_PLUGIN_HOME}/duration-info/init.zsh"
source "${ZSH_PLUGIN_HOME}/completion/init.zsh"
source "${ZSH_PLUGIN_HOME}/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "${ZSH_PLUGIN_HOME}/zsh-history-substring-search/zsh-history-substring-search.zsh"
source "${ZSH_PLUGIN_HOME}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

if command -v starship >/dev/null 2>&1; then
	eval "$(starship init zsh)"
fi
