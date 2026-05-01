#!/bin/sh

bail () {
  echo "$@"
  exit 1
}

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
test -f "$claude_json" || bail "problem with $claude_json" 


docker run -it \
  --rm \
  --init \
  --name claude.$$ \
  --user "$(id -u):$(id -g)" \
  --env USER="$USER" \
  -v ./:/workspace \
  -v "$HOME"/.claude:/home/node/.claude \
  -v "$HOME"/.claude.json:/home/node/.claude.json \
  claude "$@"

#  -e UV_THREADPOOL_SIZE=4 --cpus=4 \
#  --ulimit nofile=65535:65535 \
