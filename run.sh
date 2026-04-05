#!/bin/sh

docker run -it \
  --rm \
  --name claude \
  -v ./:/workspace \
  claude claude
  #-u "501:20" \
