#!/bin/bash


usage()
{
	cat <<-EOF
	Usage: $0 ENV PROTO...
	Example: $0 stage smtp imap pop https account/443 blog/443 docs/443 www/443

	ENV   environment (dev, stage, prod) - domain will be retrieved from config file
	PROTO a known protocol name (mx, smtp, imap, pop, http) or a pair subdomain/port
	EOF
	exit 1
}

loadenv() {
	while read KEY VALUE;
	do
		declare -g ${KEY}="$VALUE"
	done < <(grep -vE '(^$|^#)' "$1" | sed -r 's~=~ ~')
}

test $# -eq 0 && usage


loadenv ./.env
shift

# check <domain> <port> [starttls]
check()
{
	test -n "$3" && { local STARTTLS="-starttls $3"; M=" with $STARTTLS"; } || M=" without starttls"

	echo "Testing \"$1:$2\"$M:"
	openssl s_client -status -connect $1:$2 $STARTTLS 2>/dev/null | openssl x509 -noout -serial -subject -issuer -email -ocspid -ocsp_uri -dates
	echo
}


while [ $# -gt 0 ]; do
	case $1 in
	mx|MX)
		check mx.$DOMAIN_NAME 25 smtp <<< "QUIT"
		;;
	smtp|SMTP)
		check smtp.$DOMAIN_NAME 587 smtp <<< "QUIT"
		;;
 	imap|IMAP|imapx|IMAPX|imaps|IMAPS)
		check imap.$DOMAIN_NAME 993 <<< "QUIT"
		;;
	pop|POP|pops|POPS|pop3|POP3|pop3s|POP3S)
		check pop.$DOMAIN_NAME 995 <<< "QUIT"
		;;
	http|https|HTTP|HTTPS)
		check $DOMAIN_NAME 443 < /dev/null
		;;
	*/*)
		A=($(cut -d'/' -f1,2 --output-delimiter=' ' - <<< "$1"))
		check ${A[0]}.$DOMAIN_NAME ${A[1]} < /dev/null
		;;
	*)
		echo "Ignoring unknown protocol: $1"
		;;
	esac
	shift
done



