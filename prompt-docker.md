# Docker environment

You are running inside this project's devcontainer, not directly on the user's
host machine.

- The current directory is a bind mount of the host directory the container
  was started from, mounted at the same path as on the host — changes here
  are visible on the host immediately, and vice versa.
- `/home/node/.claude` and `/home/node/.claude.json` are bind-mounted from the
  host, so session state and config persist across container restarts.
  Everything else in the image (installed packages, dotfiles baked into the
  image) does not persist — changes there are lost when the container is
  removed.
- The container user is dynamically renamed/remapped at startup to match the
  host user's UID/GID (see `entrypoint.sh`), so file ownership on the mounted
  directory matches the host.
- Passwordless `sudo` is available only for `apt-get`, `apt`, and `dpkg` — use
  it for installing packages, not as a general privilege escalation path.
- `uv`/`uvx`, `git-delta`, and `gh` are preinstalled.
- jq is available for checking processing json
- python3's `yaml` module (python3-yaml) is available for validating yaml
- you are not able to run docker commands because you are already in a docker container

Because the mounted project directory is the only path guaranteed to survive
the container's lifecycle, treat work done outside it (e.g. in `/tmp` or
`$HOME` outside `.claude*`) as ephemeral and not easily visible to the user
