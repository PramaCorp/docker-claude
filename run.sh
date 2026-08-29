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

docker run -it \
  --rm \
  --init \
  --name "claude.$$" \
  --add-host "host.docker.internal:host-gateway" \
  --env HOST_UID="$(id -u)" \
  --env HOST_GID="$(id -g)" \
  --env HOST_USER="$USER" \
  --volume "$PWD:$PWD" \
  --volume "$HOME/.claude":/home/node/.claude \
  --volume "$HOME/.claude.json":/home/node/.claude.json \
  --workdir "$PWD" \
  claude "$@"
