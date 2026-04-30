FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive


RUN \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update

RUN \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get upgrade -y

RUN \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get install -y psmisc less curl zsh

RUN useradd \
  --uid 501 \
  --gid 20 \
  -s /bin/zsh \
  -m \
  fess

USER fess
RUN touch /home/fess/.zshrc
RUN curl -o /home/fess/install_claude.sh  -fsSL https://claude.ai/install.sh 
RUN bash -x /home/fess/install_claude.sh

WORKDIR /proj
