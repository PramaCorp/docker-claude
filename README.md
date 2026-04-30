# docker claude

ganked from https://github.com/anthropics/claude-code/tree/main/.devcontainer
in an attempt to diy our own claude in dev container.


## build

`./build.sh`

builds a local image named "claude"

## run 

`./run.sh `

runs claude the claude image

`./run.sh <ARGS>`

if ARGS starts with dash, runs 

claude <ARGS> in the container

othwereise runs <ARGS> as a command in the container (useful for debugging)

examples:

`./run.sh --resume`

runs `claude --resume`

`./run.sh bash`

runs `bash` 
