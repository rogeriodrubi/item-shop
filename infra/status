#!/usr/bin/env bash
which basename dirname readlink >/dev/null || { echo "which, basename, dirname and readlink commands must be installed"; exit 1; }

DPLY_CMD=$(basename $0)
#DPLY_DIR="$(dirname $(readlink -f "$0"))/../"
DPLY_DIR="$(dirname $(readlink -f "$0"))"

test -d ./infra -a -d ./infra/cmds -a -d ./infra/libs ||
	{ echo "Infra script \"$(basename "$0")\" must be executed from root source directory" >&2; exit 1; }

${DPLY_DIR}/util/test-version.sh bash "$BASH_VERSION" 4 3 || exit 1

# set -o errtrace
set -o errexit  # exit on error
set -o nounset  # error on unset var
set -o pipefail # error on pipe fail

import() {
	local FILE="$1"
	shift 1
	source "$DPLY_DIR/$FILE" "$@"
}

import libs/common.sh


test -f "$DPLY_DIR/cmds/$DPLY_CMD.sh" || fail 1 "Invalid command: $DPLY_CMD"
import cmds/$DPLY_CMD.sh "$@"
