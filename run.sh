#!/bin/sh

case "$1" in
  -*)
    set "claude" "$@"
    ;;
  '')
    set "claude"
    ;;
esac

claude_json="$HOME/.claude.json"
test -f "$claude_json" || echo '{}' > "$claude_json"

# Name the container after the cwd; shell out to sanitize if needed
dir="${PWD##*/}"
case "$dir" in
  *[!a-zA-Z0-9_.-]*) dir=$(printf '%s' "$dir" | tr -c 'a-zA-Z0-9_.-' '_') ;;
esac

_uid="$(id -u)"

# Per-project state, ignored by git without touching the repo's .gitignore.
# Create it here: docker would create a missing bind source as root.
history_dir="$PWD/.dclaude/history"
mkdir -p "$history_dir"
test -f "$PWD/.dclaude/.gitignore" || echo '*' > "$PWD/.dclaude/.gitignore"

# Container shell: DCLAUDE_SHELL if set (the entrypoint validates it),
# else yours if it's zsh, else bash
if test -z "$DCLAUDE_SHELL"; then
  case "${SHELL##*/}" in
    zsh) DCLAUDE_SHELL=zsh ;;
    *) DCLAUDE_SHELL=bash ;;
  esac
fi

docker run -it \
  --rm \
  --init \
  --name "dclaude.$dir.$$" \
  --label "dclaude.cwd=$PWD" \
  --add-host "host.docker.internal:host-gateway" \
  --env HOST_UID="$_uid" \
  --env HOST_GID="$(id -g)" \
  --env HOST_USER="$USER" \
  --env DCLAUDE_SHELL="$DCLAUDE_SHELL" \
  --volume "$PWD:$PWD" \
  --volume "$HOME/.claude":/home/node/.claude \
  --volume "$HOME/.claude.json":/home/node/.claude.json \
  --volume "$HOME/.gitconfig":/home/node/.gitconfig \
  --volume "dclaude-cache-$_uid":/home/node/.cache \
  --volume "$history_dir":/home/node/.history \
  --workdir "$PWD" \
  dclaude "$@"
