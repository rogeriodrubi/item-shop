#!/usr/bin/env bash

set -x
cd infra/
find . -maxdepth 1 -type l -delete
for c in cmds/*.sh; do ln -s cmds/.main.sh  $(basename ${c/.sh/}); done
