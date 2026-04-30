#!/bin/sh


case "$1" in
  -*)
    set "claude" "$@"
    ;;
  '')
    set "claude"
    ;;
esac

docker run -it \
  --rm \
  --name claude.$$ \
  -v ./:/workspace \
  -v "$HOME"/.claude:/home/node/.claude \
  -v "$HOME"/.claude.json:/home/node/.claude.json \
  claude "$@"
