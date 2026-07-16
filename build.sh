#!/bin/sh

set -e

VERSION_CACHE="$(dirname "$0")/.build-claude-version"
MAX_AGE_SECS=86400

if test -f "$VERSION_CACHE"; then
  CACHE_AGE=$(( $(date +%s) - $(date -r "$VERSION_CACHE" +%s) ))
else
  CACHE_AGE=$MAX_AGE_SECS
fi

if test "$CACHE_AGE" -ge "$MAX_AGE_SECS"; then
  FETCHED_VERSION=$(curl -fsSL https://registry.npmjs.org/@anthropic-ai/claude-code/latest 2>/dev/null \
    | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')
  if test -n "$FETCHED_VERSION"; then
    echo "$FETCHED_VERSION" > "$VERSION_CACHE"
  fi
fi

CLAUDE_CODE_VERSION=""
test -f "$VERSION_CACHE" && CLAUDE_CODE_VERSION=$(cat "$VERSION_CACHE")

BUILD_ARGS=""
if test -n "$CLAUDE_CODE_VERSION"; then
  BUILD_ARGS="--build-arg CLAUDE_CODE_VERSION=$CLAUDE_CODE_VERSION"
else
  echo "warning: could not resolve latest claude-code version, falling back to Dockerfile default" >&2
fi

docker build $BUILD_ARGS -t claude .
