#!/bin/sh

# --shell [container]: open a shell in the running dclaude container started
# from this directory, or in the one named
if test "$1" = "--shell"; then
  container="$2"
  if test -z "$container"; then
    container=$(docker ps --quiet --filter "label=dclaude.cwd=$PWD")
    case "$container" in
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
  fi

  # The user's login shell in the container (bash or zsh, per DCLAUDE_SHELL)
  # shellcheck disable=SC2016  # expanded in the container
  exec docker exec -it \
    --user "$(id -u):$(id -g)" \
    "$container" sh -c 'exec "$(getent passwd "$(id -u)" | cut -d: -f7)"'
fi

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
