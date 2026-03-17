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
