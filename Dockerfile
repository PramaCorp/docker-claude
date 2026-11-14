FROM node:22

ARG TZ
ENV TZ="$TZ"

ARG CLAUDE_CODE_VERSION=latest

RUN \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    less git procps sudo man-db unzip gnupg2 gh \
    iproute2 dnsutils shellcheck jq nano vim gosu python3-yaml

ENV DEVCONTAINER=true
# Updates come from rebuilding the image (build.sh), not in-container self-updates
ENV DISABLE_AUTOUPDATER=1

# Ensure node user has access to npm global dir, workspace, and claude config
RUN mkdir -p /usr/local/share/npm-global /home/node/.claude && \
  chown -R node:node /usr/local/share /home/node/.claude

COPY --from=ghcr.io/astral-sh/uv:0.11.28 /uv /uvx /bin/

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget -q "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

USER node

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin
ENV SHELL=/bin/bash
ENV EDITOR=vim
ENV VISUAL=vim

# Drop npm's download cache: owned by node, it'd be unwritable at runtime
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} && \
  rm -rf /home/node/.npm

# ~/.cache is a per-user volume shared across containers (see run.sh):
# keep npm's cache there too, and copy rather than hardlink from it into
# project venvs, which are on a different filesystem. Set after the npm
# install so the build's cache doesn't land in the image's ~/.cache, which
# docker would copy into a new volume.
ENV npm_config_cache=/home/node/.cache/npm
ENV UV_LINK_MODE=copy

USER root

# Lower UID_MIN so useradd doesn't warn about macOS-range UIDs (501+)
RUN sed -i 's/^UID_MIN.*/UID_MIN\t\t100/' /etc/login.defs && \
    sed -i 's/^GID_MIN.*/GID_MIN\t\t10/' /etc/login.defs

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY prompt-docker.md /usr/local/share/claude/prompt-docker.md

RUN \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get install -y --no-install-recommends zsh

# UTF-8 rather than POSIX, so shells measure characters like the prompt's ❯
ENV LANG=C.UTF-8

# Shell configs, keeping history in the per-project dir run.sh mounts
COPY assets/bashrc /home/node/.bashrc
COPY assets/zshrc /home/node/.zshrc

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["claude"]
