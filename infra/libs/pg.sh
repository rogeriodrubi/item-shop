#!/usr/bin/env bash
#echo $BASH_VERSION
require docker


pg-auth() {
	local secrets_dir host ret
	host="${1:-postgres}"
	# TODO read users from .env
	secrets_dir="$(get-cur-envvalue SECRETS_DIR)"
	# user="$(get-cur-envvalue POSTGRES_USER)"
	pgbash- -c "pg_isready -h $host" &&
	pgbash- -c "echo '$host:5432:projetosd:projetosd:$(cat ${secrets_dir}/pgapp_pass)' > ~/.pgpass && chmod 600 ~/.pgpass" &&
	pgbash- -c "psql -h $host -U projetosd -tc \"select 'Ok';\" | xargs echo projetosd auth -" &&
	pgbash- -c "echo '$host:5432:postgres:postgres:$(cat ${secrets_dir}/postgres_pass)' > ~/.pgpass && chmod 600 ~/.pgpass" &&
	pgbash- -c "psql -h $host -U postgres   -tc \"select 'Ok';\" | xargs echo postgres   auth -"
	ret=$?
	pgbash- -c "shred -fuz ~/.pgpass"
	return $ret
}

pgbash() {
	docker exec -ti postgres bash "$@"
}

pgbash-() {
	docker exec postgres bash "$@"
}

psql() {
	docker exec -ti postgres psql -U postgres -d projetosd "$@"
}

sql() {
    docker exec     ƒpostgres psql -U postgres -d projetosd -t -c "$@"
}

sql-i() {
    docker exec -i  postgres psql -U postgres -d projetosd -t -c "$@"
}
# sql-ti() {
#     docker exec -ti postgres psql -U postgres -d projetosd -t -c "$@"
# }


# Params
pg-change-password() {
	local user password
	test $# -ge 2 || fail 1 "User and password required"
	user="$1"
	password="$2"
	test -f "$password" && password="$(cat $password)"  # password in a file
	docker exec postgres psql -U postgres -c "ALTER USER $user PASSWORD '$password';"
}

pg-createdb() {
	# log "Creating databse"
	docker exec -i postgres psql -U postgres -v ON_ERROR_STOP=1 <<-EOF
	CREATE USER projetosd WITH PASSWORD 'admin';
	CREATE DATABASE projetosd;
	GRANT ALL PRIVILEGES ON DATABASE projetosd to projetosd;
	EOF
}

# Params: force
pg-dropdb() {	# local force
	pgbash -c "set -x; dropdb   -U postgres -ei --if-exists projetosd" &&
	pgbash -c "set -x; dropuser -U postgres -ei --if-exists projetosd"
}

# Scale postgres dependents services
# Params: up|down pg|deps|all
pg-scale() {
	local amount deps pg cdeps cpg
	case "${1:-}" in
		up)    amount=1 ;;
		down)  amount=0 ;;
		*)     fail 1 "invalid parameter" ;;
	esac

	case "${2:-}" in
		pg)    cpg=$amount;           cdeps=$(((amount+1)%2)) ;;
		deps)  cpg=$(((amount+1)%2)); cdeps=$amount   ;;
		all)   cpg=$amount; cdeps=$amount   ;;
		*)     fail 1 "invalid parameter" ;;
	esac

	deps="--scale jobs=$cdeps \
	   --scale pgadmin=$cdeps \
	   --scale web=$cdeps"
	pg=" --scale projetosd_db=$cpg"

	test -n "${amount:-}" &&
	( set -x ; docker-compose up -d $deps $pg )
}


# Parameters: plain|cat|gzip|xz|FILEPATH
# Output: filter-command;extension
helper-get-filter-command() {
	local file mime rest
	if [ -f "$1" ]
	then
		IFS=':; ' read file mime rest < <(file --mime "$1")
		case "$mime" in
			text/plain)
				echo "cat;"
				;;
			application/x-xz|application/xz|xz|XZ)
				echo "xz -d;"
				;;
			application/gzip|application/gz|gzip|gz|GZIP)
				echo "gzip -d;"
				;;
			*)
				return 1
				;;
		esac
	else
		case "$1" in
			plain|cat)
				echo "cat;"
				;;
			gzip)
				echo "gzip;gz"
				;;
			xz)
				echo "xz -c;xz"
				;;
			*)
				return 1
				;;
		esac
	fi
}

# Parameters: filter-command format target-name [-|FILEPATH]
pg-dump-helper() {
	# set -x
	local filter format name path  cmd ext
	filter="$1"
	format="$2"
	name="$3"
	path="${4:-}"
	IFS=';' read cmd ext < <(helper-get-filter-command "${filter}" || throw "$?" "$$" "Invalid filter: ${filter}")
	ext="${format}${ext:+.}${ext}"

	if [ "$path" = '' ]
	then
		path="$(get-cur-envvalue BACKUP_DIR)"
		path+="/dump-${name}-$(get-cur-envname)-$(date +%Y%m%d-%H%M%S%z)-$(date +%s).${ext}"
	elif [ "$path" = '-' ]
	then
		path=/dev/stdout
	# else
	# 	path="$path"
	fi
	
	echo "$cmd;$path"
}

# Parameters: [filter-command] [-|FILEPATH]
pg-dump-all() {
	# set -x
	local bakfile cmd
	IFS=';' read cmd bakfile < <(pg-dump-helper "${1:-xz}" sql projetosd "${2:-}")

	docker exec -i postgres pg_dump -U postgres -d projetosd |
	   $cmd | pv > "$bakfile" &&
	   log "Backup saved to $bakfile"
}

# Parameters: [filter-command] [-|FILEPATH]
pg-dump-csv() {
	local bakfile cmd
	IFS=';' read cmd bakfile < <(pg-dump-helper "${1:-xz}" csv measurement "${2:-}")
	
	sql "COPY core_medicaoinversor TO stdout DELIMITER ',' CSV HEADER;" |
	    $cmd | pv > "$bakfile" &&
	    log "Backup saved to $bakfile"
}

pg-restore-helper() {
	local path cmd ext
	if [ -f "${1:-}" ]
	then
		path="$1"
	elif [ "${1:-}" = '-' ]
	then
		path=/dev/stdin
	elif [ "${1:-}" = "@last" ]
	then
		path="$(get-cur-envvalue BACKUP_DIR)"
		path="$(ls -t1 "${path}"/dump-projetosd* | head -1)"
	else
		log "Could not find dump file"
		return 1
	fi

	IFS=';' read cmd ext < <(helper-get-filter-command "${path}" || throw "$?" "$$" "Invalid file: ${path}")
	echo "$cmd;$path"
}

# Parameters: FILEPATH
pg-restore-all() {
	local bakfile cmd

	# set -x
	bakfile="${1:-}"
	IFS=';' read cmd bakfile < <(pg-restore-helper "${bakfile}" || throw "$?" "$$" "Invalid file: ${bakfile}")

	log "Detected dump to be used:"
	log "$(stat $bakfile)"
	log "-----"

	pg-scale down deps &&
	pg-dropdb &&
	pg-createdb &&
	log "Restoring dump: $bakfile" &&
	pv "$bakfile" | $cmd |
	  docker exec -i postgres psql -U postgres -d projetosd -v ON_ERROR_STOP=1 &&
	pg-scale up all &&
	pg-auth
}


# Parameters: FILEPATH
pg-restore-csv() {
	local count bakfile cmd columns
	count=$(sql 'select count(*) from core_medicaoinversor;' | xargs)
	test "$count" = 0 || fail 2 'Table contains records; restore aborted'

	# set -x
	bakfile="${1:-}"
	IFS=';' read cmd bakfile < <(pg-restore-helper "${bakfile}" || throw "$?" "$$" "Invalid file: ${bakfile}")

	columns="$(head -1 "$bakfile")"
	log "$count" "($columns)"
	log "$cmd"

	pv $bakfile | $cmd | cat > /dev/null
		# sql-i "COPY core_medicaoinversor($columns) FROM stdin DELIMITER ',' CSV;"
}

pg-download-all() {
	local rpath rfile rhash lpath lfile lhash size rest  # remote and local file/path

	log "This command will download the last production backup into your dev's backup directory."
	read -p "Type enter to continue, ctrl-C to interrupt." >&2
	log "---\n"

	rpath="$(get-envvalue prod BACKUP_DIR)"
	rfile="$(infra/sh prod -- ls -t1 "${rpath}"/dump-projetosd* \| head -1)"

	lpath="$(get-envvalue dev BACKUP_DIR)"
	lfile="$lpath/$(basename $rfile)"
	
	read size rhash rest < <(infra/sh prod -- echo "\$(stat -c %s \"$rfile\")" "\$(sha512sum  \"$rfile\")")
	
	log "Downloading '$rfile' ($size bytes)"

	# true &&
	infra/sh prod -- cat "$rfile" | pv -s "$size" >  "$lfile" &&
		log "File saved to '$lfile'" ||
		return $?

	log "Computing SHA512 sum:"
	lhash="$(shasum -a 512 "$lfile" | cut -d ' ' -f1)"
	log "Remote file: $rhash"
	log "Local file:  $lhash"

	test "$lhash" = "$rhash" || fail 1 "Computed hashes mismatch!"
}