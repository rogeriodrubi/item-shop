#!/usr/bin/env bash
#echo $BASH_VERSION
require docker docker-compose

# TODO temp/debug
# set -x
# set -e

# TODO command line not handled yet
usage() {
	cat <<-EOF
	  $(docker-compose logs --help)

	    @      use default options (required if some parameter is given)

      Default: -ft --tail=100
	EOF
	fail 127
}

import libs/deploy.sh

set-constants
# load-host-vars
# cd "$SRC_DIR" &&
loadenvfile .env &&

if [ $# -gt 0 ]
then
    docker-compose logs "$@" || fail 11 "docker stop failed"
else
    docker-compose logs -ft --tail=100 || fail 12 "docker stop failed"
fi
