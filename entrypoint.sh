#!/bin/bash
set -e


if [ -z "$HOST_UID" ] || [ -z "$HOST_GID" ] || [ -z "$HOST_USER" ]; then
    echo "ERROR: HOST_UID, HOST_GID, and HOST_USER must be set." >&2
    echo "  Use run.sh to start the container, or pass them explicitly:" >&2
    echo "  -e HOST_UID=\$(id -u) -e HOST_GID=\$(id -g) -e HOST_USER=\$USER" >&2
    exit 1
fi

# Run the command, resuming it whenever it stops (e.g. ctrl-z): there's no
# shell in the container to take the terminal back, so it would hang forever.
run() {
    set +e -m
    "$@"
    resume
}

# Recursion rather than a loop: bash breaks out of a loop when a job in it stops
resume() {
    status=$?
    [ -z "$(jobs -p)" ] && exit $status
    echo "No shell to suspend to in this container; resuming automatically." >&2
    fg > /dev/null
    resume
}

# Append the docker-specific system prompt whenever we're launching claude
if [ "$1" = "claude" ]; then
    shift
    set -- claude --append-system-prompt-file /usr/local/share/claude/prompt-docker.md "$@"
fi

# If host is root, skip user setup
if [ "$HOST_UID" = "0" ]; then
    run "$@"
fi

# Create group for HOST_GID, or rename the existing one to match
if getent group "$HOST_GID" > /dev/null 2>&1; then
    EXISTING_GROUP=$(getent group "$HOST_GID" | cut -d: -f1)
    if [ "$EXISTING_GROUP" != "$HOST_USER" ]; then
        groupmod -n "$HOST_USER" "$EXISTING_GROUP"
    fi
else
    groupadd -g "$HOST_GID" "$HOST_USER"
fi

# If a user already exists with HOST_UID (e.g. 'node' at 1000), rename it.
# Otherwise create a new user with home pinned to /home/node.
if getent passwd "$HOST_UID" > /dev/null 2>&1; then
    EXISTING=$(getent passwd "$HOST_UID" | cut -d: -f1)
    if [ "$EXISTING" != "$HOST_USER" ]; then
        usermod -l "$HOST_USER" -d /home/node "$EXISTING"
    fi
else
    useradd -u "$HOST_UID" -g "$HOST_GID" -d /home/node -s /bin/bash --no-create-home "$HOST_USER"
fi

# Passwordless sudo for package management — extend this list as needed
cat > /etc/sudoers.d/user-pkgmgmt << EOF
$HOST_USER ALL=(root) NOPASSWD: /usr/bin/apt-get, /usr/bin/apt, /usr/bin/dpkg
EOF
chmod 0440 /etc/sudoers.d/user-pkgmgmt

# Own the home dir itself (not -R: that's slow) so ~/.cache etc. can be created
chown "$HOST_UID:$HOST_GID" /home/node
export HOME=/home/node

run gosu "$HOST_UID" "$@"
