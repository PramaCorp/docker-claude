#!/bin/bash
set -e

if [ -z "$HOST_UID" ] || [ -z "$HOST_GID" ] || [ -z "$HOST_USER" ]; then
    echo "ERROR: HOST_UID, HOST_GID, and HOST_USER must be set." >&2
    echo "  Use run.sh to start the container, or pass them explicitly:" >&2
    echo "  -e HOST_UID=\$(id -u) -e HOST_GID=\$(id -g) -e HOST_USER=\$USER" >&2
    exit 1
fi

# Append the docker-specific system prompt whenever we're launching claude
if [ "$1" = "claude" ]; then
    shift
    set -- claude --append-system-prompt-file /usr/local/share/claude/prompt-docker.md "$@"
fi

# If host is root, skip user setup
if [ "$HOST_UID" = "0" ]; then
    exec "$@"
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
    useradd -u "$HOST_UID" -g "$HOST_GID" -d /home/node -s /bin/zsh --no-create-home "$HOST_USER"
fi

# Passwordless sudo for package management — extend this list as needed
cat > /etc/sudoers.d/user-pkgmgmt << EOF
$HOST_USER ALL=(root) NOPASSWD: /usr/bin/apt-get, /usr/bin/apt, /usr/bin/dpkg
EOF
chmod 0440 /etc/sudoers.d/user-pkgmgmt

# Fix ownership of home dir and history (volumes overlay .claude* so those are fine)
chown -R "$HOST_UID:$HOST_GID" /home/node /commandhistory

export HOME=/home/node

exec gosu "$HOST_UID" "$@"
