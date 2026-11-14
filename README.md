# dclaude

ganked from https://github.com/anthropics/claude-code/tree/main/.devcontainer
in an attempt to diy our own claude in dev container.


## build

`./build.sh`

builds a local image named "dclaude"

## run 

`./run.sh `

runs claude in the dclaude image

symlink run.sh onto your PATH as `dclaude` to run it from any project:

`ln -s $PWD/run.sh ~/bin/dclaude`

`./run.sh <ARGS>`

if ARGS starts with dash, runs 

claude <ARGS> in the container

othwereise runs <ARGS> as a command in the container (useful for debugging)

examples:

`./run.sh --resume`

runs `claude --resume`

`./run.sh bash`

runs `bash` 

## shell

`./run.sh --shell [container]`

opens a shell in the running dclaude container started from the current
directory, or in the named container if there's more than one.

the shell in the container, both for `--shell` and for claude's own
commands, is zsh if your `$SHELL` is zsh and bash otherwise. override with
`DCLAUDE_SHELL=bash` or `DCLAUDE_SHELL=zsh`. the configs are in `assets/`.

## state

per-project shell history (bash and zsh, separately) is kept in `.dclaude/`
in the project dir, which ignores itself in git. delete it to start fresh.

package caches (uv, npm) are shared across projects in the
`dclaude-cache-<uid>` docker volume. `docker volume rm` it to clear them.
