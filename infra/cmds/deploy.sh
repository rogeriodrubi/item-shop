#!/usr/bin/env bash
#echo $BASH_VERSION
require docker docker-compose

usage() {
	cat <<-EOF
	Usage:
	  $0 COMMAND [OPTIONS] ...
	  
	  $0 config     [OPTIONS] ENV_NAME BRANCH_NAME
	  $0 start      [OPTIONS] ENV_NAME BRANCH_NAME
	  $0 down       [OPTIONS]
	  $0 drop       [OPTIONS]
	  $0 secrets    ENV_NAME SECRETS_PATH

	  COMMAND
	    config      show expanded configuration (YAML). Aliases: conf
	    start       start (pull, build, up) all services/containers
	    up          alias for start command
	    down        stop all services/containers
	    drop        same as down, then drop pgdata directory (take care)
	    secrets     upload secrets files and update containers

	  ENV_NAME      environment name of the host machine: dev, prod
	  BRANCH_NAME   git branch to be checked out (ex. master, main)
	  SECRETS_PATH  path to local directory containing the new secrets

	  OPTIONS
	    --nogit     for start or config: skip git commands (clone, fetch,
	                checkout, merge)
	    --scale     for start: comma separated list of 'service=N' without spaces
	    --force     for drop: force pgdata/ deletion even when backup fails

	EOF
	test $# -gt 0 && log "$@"
	fail 127
}


# Params: pattern
parse-scale-pattern() {
	echo "$1" |
	grep -E '^([a-z0-9_]+=[0-9]+)(,([a-z0-9_]+=[0-9]+))*$' |
	tr ',' '\n' |
	sed -r 's~^([a-z0-9_]+=[0-9]+)$~ --scale \1~g'
}

# Command line parsing
test $# -ge 0 || usage

GIT=1     # --nogit option
FORCE=0   # --force option
BUILD=1
CONFIG=0
FULL=0
CMD=
SCALE=()
while [ "$#" -gt 0 ];
do
	case "$1" in
		--nogit)
			GIT=0
			;;
		--force)
			FORCE=1
			;;
		down)
			CMD=down
			;;
		drop)
			CMD=drop
			;;
		up|start)
			CMD=start
			BUILD=1
			CONFIG=0
			;;
		secrets)
			CMD=secrets
			;;
		--scale)
			if [ -n "$2" ]
			then
				SCALE+=($(parse-scale-pattern "$2" || throw "$?" "$$" "Invalid scale pattern: $2"))
				shift
			else
				usage "Invalid scaling: argument for --scale is missing"
			fi
			# printf '%s*%s\n' "${SCALE[@]}"
			# exit
			;;
		conf|config)
			CMD=config
			BUILD=0
			CONFIG=1
			;;
		*)
			if [ "$CMD" = '' ]
			then
				usage "Invalid argument: $1"
			else
				break
			fi
			;;
	esac
	shift
done

case "$CMD" in
	down)
		import libs/deploy.sh &&
		# set -x
		# cd "$(get-cur-envvalue SRC_DIR $(pwd))" &&
		docker-compose down || fail 22 "docker stop failed"
		exit 0
		;;
	drop)
		import libs/deploy.sh &&
		# load-host-vars &&
		# cd "$SRC_DIR" &&
		loadenvfile .env || fail 26 'could not load variables'
		if [ -d "$BACKUP_DIR" ]
		then
			import libs/pg.sh &&
			sudo chmod -R 777 "$BACKUP_DIR" &&  # TODO insecure
			if ! pg-dump-all
			then
				log 'Backup failed'
				test $FORCE = 1 &&
				log 'warn: drop without backing up' ||
					fail 27 'Drop aborted'
			fi
		else
			log 'Backup failed: backups dir does not exit'
			test $FORCE = 1 &&
			log 'warn: drop without backing up' ||
				fail 25 'Drop aborted';
		fi
		docker-compose down || fail 23 "docker stop failed"
		sudo rm -rf "$PG_DIR" || fail 24 "pgdata remove failed" # TODO apagar ./.data ?
		exit 0
		;;
	up|start|conf|config)   # TODO create deploy-config function
		import libs/deploy.sh &&
		deploy-start "$@"
		;;
	secrets)  # env-name secrets-path
		local envname src secdir
		envname="$1"
		src="$2"
		# set -x
		secdir="$(get-envvalue $envname SECRETS_DIR)"
		if [ -d "$src" ]  # secrets path is dir
		then
			tar -cvf - -C "$src" . |
			infra/sh $envname -- \
			              tar -C "$secdir" -xvf - \&\& \
			              infra/pg password
		elif [ -f "$src" ] && file --mime "$src" | grep -o appliction/x-tar
		then
			fail 1 "Tar file found but feature not yet implemented"
		else
			fail 1 "Invalid source path (must be directory or tar file): $src"
		fi
		;;
	*)
		test -n "$CMD" \
			&& usage "Invalid argument: $CMD" \
			|| usage
		;;
esac

