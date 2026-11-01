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

docker run -it \
  --rm \
  --init \
  --name "claude.$dir.$$" \
  --label "claude.cwd=$PWD" \
  --add-host "host.docker.internal:host-gateway" \
  --env HOST_UID="$(id -u)" \
  --env HOST_GID="$(id -g)" \
  --env HOST_USER="$USER" \
  --volume "$PWD:$PWD" \
  --volume "$HOME/.claude":/home/node/.claude \
  --volume "$HOME/.claude.json":/home/node/.claude.json \
  --workdir "$PWD" \
  claude "$@"
