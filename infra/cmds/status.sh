#!/usr/bin/env bash
#echo $BASH_VERSION
require docker docker-compose

usage() {
	cat <<-EOF
	  $0

      Execute docker-compose's top and ps commands
	EOF
	fail 127
}

import libs/deploy.sh

set-constants &&
# load-host-vars &&
# cd "$SRC_DIR" &&
loadenvfile .env || fail 10 'failed to load vars'

if [ $# -gt 1 ]
then
    docker-compose top &&
    echo -e '\n==============\n' &&
    docker-compose ps "$@" || fail 11 "docker stop failed"
else
    docker-compose top &&
    echo -e '\n==============\n' &&
    docker-compose ps || fail 12 "docker stop failed"
fi
