if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

# Created by `pipx` on 2025-06-21 06:14:45
export PATH="$PATH:$HOME/.local/bin"
