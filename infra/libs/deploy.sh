#!/usr/bin/env bash
#echo $BASH_VERSION

deploy-validate-envname() {
	local ENV_NAME
	if [[ " dev prod " == *" $1 "* ]]
	then
		ENV_NAME="$1"
	else
		log "Invalid Env name: $1"
		return 1
	fi
}

# parameters: env-name?
# load-host-vars() {
# 	local ENV_NAME
# 	if [ $# = 0 ];
# 	then
# 		ENV_NAME="$(get-cur-envname || throw "$?" "$$" "Env name unset")"
# 	else
# 		ENV_NAME="$1"
# 	fi
# 	case $ENV_NAME in
# 		dev)
# 			# local BASE_DIR=/home/expedit/data/devel/ngk/poc/src/deploytest
# 			# export SRC_DIR="$BASE_DIR/git-src"
# 			export SRC_DIR="$(pwd)"
# 			# export PG_DIR="${SRC_DIR}/pgdata"
# 			;;
# 		prod)
# 			export SRC_DIR="/home/ubuntu/src/projetosd-web"
# 			# export PG_DIR=/mnt/data/pgdata
# 			;;
# 		*)
# 			log "invalid env name: $ENV_NAME"
# 			return 1
# 			;;
# 	esac
# }

# parameters: env-name
set-env-file() {
	local ENV_NAME
	ENV_NAME="$1"
	deploy-validate-envname "$ENV_NAME"
	# load-host-vars "$ENV_NAME" || return
	# cd "$SRC_DIR" || { log "cd to src dir failed"; return 1; }
	test -f .env || ln -s ".env.$ENV_NAME" .env
}

# parameters: src-dir branch-name
# deploy-get() {
# }

# deploy-config() {
# }

# envvars: BUILD(0,1) CONFIG(0,1) GIT(0,1) SCALE(array)
# params: env-name branch-name
# SCALE: --scale arguments for docker-compose up
deploy-start() {
	local ENV_NAME branch populate
	# set -x
	set-constants

	test -n "$1" || fail 1 "Env name is required"
	deploy-validate-envname "$1" || fail 1 "Invalid env name: $1"
	
	ENV_NAME="$1" &&
	# load-host-vars "$ENV_NAME" || return 1

	if [ $GIT = 1 ] # -o ! -d "$SRC_DIR"
	then
		test -n "$2" || fail 3 "branch is required when git is active"
		branch="$2"

		# if [ ! -d $SRC_DIR ]
		# then
		# 	git clone "$GIT_URL"  "$SRC_DIR" || return 1
		# fi

		# cd "$SRC_DIR" &&
		git config credential.helper 'cache --timeout=86400' &&
		git fetch origin &&
		git checkout "$branch" &&
		git merge "origin/$branch" || return 1
	fi

	set-env-file "$ENV_NAME" || return 1
	test "$(get-cur-envname)" = "$ENV_NAME" || fail 1 "Env name mismatch: $(get-cur-envname) vs. $ENV_NAME"

	# TODO create deploy-config function (needs refactoring)
	if [ $BUILD = 0 -o  $CONFIG = 1 ]
	then
		# cd "$SRC_DIR" &&
		loadenvfile .env || { log "env file load failed"; return 1; }
		docker-compose config
	fi

	if [ $BUILD = 1 ]
	then
		# cd "$SRC_DIR" &&
		loadenvfile .env || { log "env file load failed"; return 1; }

		if [ ! -d "$PG_DIR" ]
		then
			log "Directory $PG_DIR does not exist, it will be created"
			populate=1
		else
			log "Directory $PG_DIR already exists, it will not be touched"
			populate=0
		fi

		# cd "$SRC_DIR" &&
		mkdir -p "$BACKUP_DIR" "$SSL_DIR" &&
		sudo chmod -R 777 "$BACKUP_DIR" && # TODO insecure
		log "\n\nBuilding images:\n"
		docker-compose build &&
		log "\n\nImages built!\n" &&
		docker-compose up -d ${SCALE[@]:-} ||  # TODO do not use quotes in bash < 4.4 (unbound variable bug)
		   return 1

		if [ "$populate" = 1 ]
		then
			infra/pg wait conn || fail 12 "database not running"
			sleep 1
			
			log 'Populating database...'
			# shell/fiatlux.sh "$ENV_NAME"
			# infra/pg create &&
			infra/pg restore all @last || fail 13 "database build failed"

			log 'Restarting docker services'
			docker-compose down &&
			sleep 5 &&
			docker-compose up -d  "${SCALE[@]:-}" ||  # TODO do not use quotes in bash < 4.4 (unbound variable bug)
				fail 14 "docker restart failed"
		else
			log 'pgdata directory already exists'
			sudo ls -lha "$PG_DIR"
		fi
	fi


	# if [ $FULL = 1 ]
	# then
	# 	test -f "$1" || fail 30 'backup file not found'
	# 	cd "$SRC_DIR" &&
	# 	infra/deploy up --scale jobs=0,pgadmin=0,web=0 --nogit dev . &&
	# 	infra/pg restore - < "$1" &&
	# 	infra/deploy up --scale jobs=1 pgadmin=1 web=1 --nogit dev . &&
	# 	finra/status
	# fi
}
