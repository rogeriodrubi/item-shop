#!/bin/bash

usage()
{
	cat <<-EOF

	Usage: $0  SIGNAL

	SIGNAL
	  USR1
	    Ask for SSL certificate refresh, without forcing renewal.
	  USR2
	    Ask for SSL certificate refresh, forcing renewal.
	  INT, TERM, QUIT
	    Terminate the container gracefully
EOF
	exit 255
}



fail()
{
	echo "$2" >&2
	exit $1
}

loadenv() {
	while read KEY VALUE;
	do
		declare -g ${KEY}="$VALUE"
	done < <(grep -vE '(^$|^#)' "$1" | sed -r 's~=~ ~')
}

test $# = 1 || usage

SIGNAL=$(awk '{print toupper($0)}' <<< "$1")

shift

loadenv .env  || fail 1 "Could not load config"


SIGNALS="INT TERM QUIT KILL USR1 USR2"
if [[ " $SIGNALS " == *" $SIGNAL "* ]]
then
	docker kill -s $SIGNAL  $(docker ps -f name=ssl -q) >/dev/null || 
	fail 4 "Could not send signal $SIGNAL to ssl"

	echo "Signal '$SIGNAL' sent to 'ssl"
else
	fail 3 "SIGNAL must be one of $SIGNALS. It was: $SIGNAL"
fi
