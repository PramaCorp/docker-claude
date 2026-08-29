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
  -e HOST_UID="$(id -u)" \
  -e HOST_GID="$(id -g)" \
  -e HOST_USER="$USER" \
  -v "$PWD:$PWD" \
  -v "$HOME/.claude":/home/node/.claude \
  -v "$HOME/.claude.json":/home/node/.claude.json \
  claude "$@"
