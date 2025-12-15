#!/usr/bin/env bash

usage() {
	cat <<-EOF
	  $0 ENV_NAME [OPTIONS] [-- COMMAND]

	  ENV_NAME    name of the environment to connect to.
	  OPTIONS     SSH options (see man ssh for help)
	  COMMAND     command to be executed on the remote host (e.g. echo Hello)

	  Notes:
	  - In the first execution, you will be asked to create a symlink to
	        the SSH key (PEM format).
	  - If no COMMAND is given, it starts an interactive shell.
	  - It will enter in the source directory (SRC_DIR in .env.ENV_NAME)
	    before executing COMMAND or starting the interactive shell.
	EOF
	fail 127
}

test $# -ge 1 || usage

# set -x

ENV_NAME="$1"
shift

loadenvfile ".env.${ENV_NAME}" || fail 1 "Could not load env file: .env.${ENV_NAME}"

SSH_PEM_FILE="infra/projetosd.${ENV_NAME}.pem"

if [[ ! -L "${SSH_PEM_FILE}"  ]]
then
	log "Could not find SSH PEM key for host ${DOMAIN_NAME}"
	log "Please create a symlink to it by running this command:"
	log "   ln -s '/path/to/projetosd.${ENV_NAME}.pem' '${SSH_PEM_FILE}'"
	exit 1
fi

SSH_OPT=(
	-o StrictHostKeyChecking=no
	-o UserKnownHostsFile=infra/known_hosts
	-o ServerAliveInterval=20
	-o ServerAliveCountMax=500
	-i "${SSH_PEM_FILE}"
)

while [ $# -gt 0 ]
do
	case "$1" in
		--)
			shift
			break
			;;
		*)
			SSH_OPT+=("$1")
			shift
			;;
		esac
done

SSH_USER="$(test "${ENV_NAME}" = dev && id -un || echo jairsonrodrigues)"

# set -x
if [ $# -gt 0 ]
then
	ssh ${SSH_OPT[@]}    "${SSH_USER}@${DOMAIN_NAME}" cd "${SRC_DIR:-$(pwd)}" '&&' "$@"
else
	ssh ${SSH_OPT[@]} -t "${SSH_USER}@${DOMAIN_NAME}" cd "${SRC_DIR:-$(pwd)}" '&&' exec \$SHELL --login
fi
