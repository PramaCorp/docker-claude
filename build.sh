#!/bin/sh

set -e

# Resolve the actual latest claude-code version so Docker's build cache only
# invalidates the install layer when a new version is published, not on every build.
CLAUDE_CODE_VERSION=$(curl -fsSL https://registry.npmjs.org/@anthropic-ai/claude-code/latest 2>/dev/null \
  | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')

BUILD_ARGS=""
if [ -n "$CLAUDE_CODE_VERSION" ]; then
  BUILD_ARGS="--build-arg CLAUDE_CODE_VERSION=$CLAUDE_CODE_VERSION"
else
  echo "warning: could not resolve latest claude-code version, falling back to Dockerfile default" >&2
fi

docker build $BUILD_ARGS -t claude .
