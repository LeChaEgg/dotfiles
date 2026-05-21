#!/usr/bin/env bash
# Wrapper around tmux-nerd-font-window-name to handle commands whose
# process title is dynamic (e.g. Claude Code sets argv[0] to its version,
# so pane_current_command shows up as "2.1.146" instead of "claude").

NAME="$1"
PANES="$2"

if [[ "$NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-].*)?$ ]]; then
  NAME="claude"
fi

exec "$HOME/.tmux/plugins/tmux-nerd-font-window-name/bin/tmux-nerd-font-window-name" "$NAME" "$PANES"
