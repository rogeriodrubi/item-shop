#!/usr/bin/env bash

is_executable_file()
{
	# echo test if "$1" is executable file
	test -x "$1" -a -f "$1"
}

is_valid_filepath()
{
	# echo test if "$1" is valid filename
	if [[ -e "$1" || -d $(dirname "$1") ]];
	then
		return 0
	else
		return 1
	fi
}


pv() {
	which pv >/dev/null 2>/dev/null && command pv "$@" || cat
}

sha512sum() {
	which sha512sum >/dev/null 2>/dev/null && command sha512sum "$@" || echo "---"
}


# Params: message...
log() {
	test $# -gt 0 && echo -e "$@" >&2
}

# Params: [exit-code [message...]]
fail() {
	ret="${1:-1}"
	shift
	test $# -gt 0 && log "$@"
	exit $ret
}

# No Params
exception-trap() {
	log "Exception occurred. Exiting..."
	fail 99
}

# Params: return-code parent-pid [message...]
throw() {
	local ret pid
	ret="$1"
	pid="$2"
	shift 2
	log "$@"
	kill -TRAP "$pid"
	return "$ret"
}

require() {
	while [ $# -gt 0 ]
	do
		which $1 >/dev/null || fail 1 "$1 not installed"
		shift
	done
}

# Load all variables from environment file into global variables
# Parameters: env-file
loadenvfile() {
	test -f "$1" || return 1
	while read KEY VALUE;
	do
		declare -g ${KEY}="$VALUE"
	done < <(grep -vE '(^$|^#)' "$1" | sed -r 's~=~ ~')
}

# Params: env-name env-var-name [default-value]
get-envvalue() {
	local envname envvarname envfilename defaultvalue
	test $# -ge 2 || return 1
	envname="$1"
	envvarname="$2"
	defaultvalue="${3:-}"

	test -n "$envname" || return 1
	test -n "$envvarname" || return 1

	envfilename=".env.$envname"

	test -f "$envfilename" || fail 1 "Environment file does not exists: $envfilename"
	cat "$envfilename" | grep -oE "^$envvarname=[^$]+$" |
	    sed -r 's~^'"$envvarname"'=~~' ||
	    echo "$defaultvalue"
}


# Params: env-var-name [default-value]
get-cur-envvalue() {
	local envvarname defaultvalue
	envvarname="$1"
	defaultvalue="${2:-}"
	test -n "$envvarname" || return 1
	test -f .env || fail 1 "Current environment not defined (.env file)"
	cat .env | grep -oE "^$envvarname=[^$]+$" |
	    sed -r 's~^'"$envvarname"'=~~' ||
	    echo "$defaultvalue"
}


get-cur-envname() {
	get-cur-envvalue 'ENV_NAME'
}


# parameters: none
set-constants() {
	export GIT_URL=ssh://jairsonrodrigues@gmail.com@source.developers.google.com:2022/p/projetosd-342602/r/projetosd
}


# TODO
jobs() {
	# cd "$SRC_DIR" && . .env || failed 1 "env file load failed"
	# docker exec -ti jobs ./agent.py "$@"
	case "$1" in
		pause)
			docker-compose kill -s STOP jobs
			;;
		resume)
			docker-compose kill -s CONT jobs
			;;
	esac
}


trap exception-trap TRAP
