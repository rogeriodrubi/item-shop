#!/usr/bin/env bash
#echo $BASH_VERSION

usage() {
	cat <<-EOF
	  $0 COMMAND [OPTIONS]

	  $0 dump    all|measures [plain|gzip|xz] [FILEPATH]
	  $0 restore all|measures FILEPATH|@last
	  $0 create
	  $0 drop
	  $0 scale      up|down pg|deps|all
	  $0 password
	  $0 isready    [conn|auth]
	  $0 download

	  COMMAND
	    dump        dump database to stdout or to a file (custom or auto generated name)
	    restore     restore whole database or measurements only from a file
	    create
	    drop
	    scale       up/down services which depend on (deps) postgres (pg) or both (all)
	    count       contagem de medições agrupadas por inversor
	    psql        executa psql dentro do container pg em execução
	    bash        executa bash dentro do container pg em execução
	    download    download the most recent database dump (backup)
	    isready     check if postgres is ready to receive connections
	                (conn argument - default) and database authentication
	                works (auth)
	    password    find both postgres and application passwords in
	                secrets directory and update them in database,
	                then restart dependents services
	
	  FILEPATH      path to a local file (host machine) or - for stdin/stdout
	                or @last for last dump discovery (most recent dump)

	  OPTIONS
	    -p, --progress  show progress using pv command (not implemented)
	
	  Notes:
	    dump:     if file is not specified, a unique name will be generated
	    restore:  if input is - (stdin) it must be a plain text stream
	              otherwise file type (xz,gz,plain) is automatically detected

	EOF
	fail 127
}

test $# -ge 1 || usage


import libs/pg.sh

while [ "$#" -gt 0 ];
do
	case "$1" in
		password)
			# set -x
			local secrets_dir
			secrets_dir="$(get-cur-envvalue SECRETS_DIR)"
			test -d "$secrets_dir" || fail 1 "Directory not found: $secrets_dir"
			pg-scale down all &&
			pg-scale up pg &&
			infra/pg wait conn && sleep 1 &&
			pg-change-password postgres "${secrets_dir}/postgres_pass" &&
			pg-change-password projetosd "${secrets_dir}/pgapp_pass" &&
			pg-auth &&
			pg-scale up all
			exit
			;;
		dump|restore)
			local cmd=$1
			shift
			test "$#" -gt 0 || fail 127 "$0:dump: parameters missing"
			case "$1" in
				a|all)
					shift
					pg-$cmd-all "$@"
					;;
				m|measures)
					shift
					pg-$cmd-csv "$@"
					;;
				*)
					fail 127 "Invalid parameter: $1"
					;;
			esac
			exit
			;;
		download)
			pg-download-all
			exit
			;;
		drop|create)
			local cmd=$1
			shift
			pg-${cmd}db
			exit
			;;
		scale)
			shift
			test "$#" -gt 0 || fail 127 "$0:scale: parameters missing"
			pg-scale "$@"
			exit
			;;
		count)
			shift
			sql 'select inverter_id, count(*), min(dh_measure), max(dh_measure) from core_medicaoinversor group by inverter_id;'
			exit
			;;
		bash)
			shift
			pgbash "$@"
			exit
			;;
		psql)
			shift
			psql "$@"
			exit
			;;
		sql)
			shift
			sql "$@"
			exit
			;;
		wait) # wait conn|auth [step-time [max-time]]
			shift
			local what t0 maxtime steptime reset
			# set -x
			what="${1:-}"
			[[ " conn auth " == *" $what "* ]] || fail 1 "Invalid parameter"
			shift
			read steptime maxtime rest <<< "${1:-1} ${2:-600}"
			test "${steptime}" -gt 0 -a "${maxtime}" -gt 0 || fail 1 "Invalid parameters"

			log "Waiting until postgres is ready to receive connections (timeout ${maxtime}s)..."
			t0="$(date +%s)"
			while ! infra/pg isready "$what" >&2 && [ $(( $(date +%s) - t0 )) -le $maxtime ]; do sleep "${steptime}"; done
			exit
			;;
		isready)
			shift
			# set -x
			local host
			host="$(pgbash- -c 'getent hosts postgres | grep -oE "[0-9]+(\.[0-9]+){3}"' | tr -d '\r')"
			case "${1:-conn}" in
				conn|connection)
					pgbash- -c "pg_isready -h $host"
					;;
				auth|authentication)
					pg-auth "$host"
					;;
			esac
			exit
			;;
		*)
			fail 127 "Invalid parameter: $1"
			;;
	esac
	shift
done
