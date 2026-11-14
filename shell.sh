#!/bin/sh
# Open a shell in the running dclaude container started from this directory,
# or in the container named by $1

if [ -n "$1" ]; then
  container="$1"
else
  ids=$(docker ps --quiet --filter "label=dclaude.cwd=$PWD")
  case "$ids" in
    '')
      echo "no dclaude container running for $PWD" >&2
      exit 1
      ;;
    *[!0-9a-f]*)
      echo "multiple dclaude containers running for $PWD; pass a name:" >&2
      docker ps --filter "label=dclaude.cwd=$PWD" --format '{{.Names}}\t{{.RunningFor}}' >&2
      exit 1
      ;;
  esac
  container="$ids"
fi

# Start the user's login shell in the container (bash or zsh, per DCLAUDE_SHELL)
# shellcheck disable=SC2016  # expanded in the container
exec docker exec -it \
  --user "$(id -u):$(id -g)" \
  "$container" sh -c 'exec "$(getent passwd "$(id -u)" | cut -d: -f7)"'
