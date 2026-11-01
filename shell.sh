#!/bin/sh
# Open a shell in the running claude container started from this directory,
# or in the container named by $1

if [ -n "$1" ]; then
  container="$1"
else
  ids=$(docker ps --quiet --filter "label=claude.cwd=$PWD")
  case "$ids" in
    '')
      echo "no claude container running for $PWD" >&2
      exit 1
      ;;
    *[!0-9a-f]*)
      echo "multiple claude containers running for $PWD; pass a name:" >&2
      docker ps --filter "label=claude.cwd=$PWD" --format '{{.Names}}\t{{.RunningFor}}' >&2
      exit 1
      ;;
  esac
  container="$ids"
fi

exec docker exec -it \
  --user "$(id -u):$(id -g)" \
  "$container" bash
