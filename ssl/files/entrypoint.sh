#!/bin/bash

# Time, in seconds, between checkings for certificate
# validity using getssl (not used in dev environment)
GETSSL_REFRESH_INTERVAL=3600


fail()
{
	test -n "$2" && echo "$2" 1>&2
	exit $1
}


echo "Loading tools for SSL certificate management..."
source /cert-tool.sh


# if [ "$1" = "gen-local-ca" ]
# then
# 	echo "$@"
# 	shift
# 	test -z "$DOMAIN_NAME" -o $# -gt 0 && { DOMAIN_NAME="$1"; shift; }
# 	test -z "$SSL_SUBDOMAINS" -o $# -gt 0 && SSL_SUBDOMAINS=$(IFS=,; echo -n "$*")
# 	printenv
# 	cert_tool_build_local_ca_cert
# 	sleep 10
# 	exit
# fi



# Start rsyslog
/etc/init.d/rsyslog start || exit 1

# Constructs ADDITIONAL_DOMAIN_NAMES from SSL_SUBDOMAINS variable
build-subdomains-names() {
	local -a array
	# DOMAIN_NAME=foobar.local
	# SSL_SUBDOMAINS=for,bar,www,api
	for sd in $(echo "$SSL_SUBDOMAINS" | tr ',' ' ');
	do
		array+=("${sd}.${DOMAIN_NAME}")
	done
	# echo "${array[*]}" | tr ' ' ','
	(IFS=,; echo -n "${array[*]}")
}

ADDITIONAL_DOMAIN_NAMES="$(build-subdomains-names)"
echo "'additional domain names: $ADDITIONAL_DOMAIN_NAMES'"


replace-template()
{
	# Create environment file for CTPL
	cat > /tmp/ctpl-vars <<-EOF
	SSL_NOTIFIER_USERNAME="$SSL_NOTIFIER_USERNAME";
	SSL_NOTIFIER_PASSWORD="$SSL_NOTIFIER_PASSWORD";
	EOF

	FILEPATH=/etc/ssmtp/ssmtp.conf
	mkdir -p $(dirname $FILEPATH)
	ctpl -e /tmp/ctpl-vars  \
	     -o $FILEPATH  \
	     /templates/$FILEPATH.ctpl
}


build_cert()
{
	# Test if environment variables are set
	test -n "$SSL_CA_DOMAIN" -a \
	     -n "$SSL_ACCOUNT_EMAIL" -a \
	     -n "$ADDITIONAL_DOMAIN_NAMES" -a \
	     -n "$DOMAIN_NAME" -a \
	     -n "$SSL_RELOAD_CMD" ||
	    { echo "Environment variables not set"; return 1; }


	# Build the certificates
	echo "Waiting bootstrap SSL certificates..."
	if cert_tool_nothing_mounted;
	then
		cert_tool_build_self_signed

	elif cert_tool_all_mounted;
	then
		# Checking if Web server is able to answer
		echo "Waiting for web server availability on $DOMAIN_NAME..."
		echo "ssl-cert-service-$(date +%s)" > /data/acme-challenge/ssl-cert-service
		ACME_TEST_FILE_URL="http://${DOMAIN_NAME}/.well-known/acme-challenge/ssl-cert-service"
		until diff \
		   /data/acme-challenge/ssl-cert-service \
		   <(curl -vs --insecure "$ACME_TEST_FILE_URL?$(date +%s)");
		   do sleep 2; done

		# Update certs if needed
		# echo "Working on actual SSL certificates..."
		# rm /data/ssl/*
		cert_tool_build_le_getssl ||
		  fail 1 "Failed on building Let's Encrypt certificate."

		# if [ $(find /data/ssl/ -maxdepth 0 -type d -empty) ]
		# then
		# 	log "Directory /data/ssl/ is empty. Copying certificates..."
		# 	SSL_CERT_CUR_DIR=$(find /root/.getssl/${DOMAIN_NAME}/archive/ \
		# 													-type d | sort | tail -1)
		# 	cp $SSL_CERT_CUR_DIR/${DOMAIN_NAME}.key  /data/ssl/privkey.pem
		# 	cp $SSL_CERT_CUR_DIR/fullchain.crt      /data/ssl/fullchain.pem
		# 	cp $SSL_CERT_CUR_DIR/${DOMAIN_NAME}.crt  /data/ssl/cert.pem
		# 	cp $SSL_CERT_CUR_DIR/chain.crt          /data/ssl/chain.pem

		# 	# postfix reload && service dovecot restart || return 4
		# fi
		# $SSL_RELOAD_CMD || return 4
		echo "-----------------------------------------------"
	elif cert_tool_root_ca_mounted
	then
		cert_tool_build_domain_cert
	else
		log_err "All directories must be mounted accordingly (or none of them for self-signed certificates): /root/.getssl, /data/acme-challenge, /data/ssl. Exiting..."
		return 2
	fi

	return 0
}


# Signal handling
usr1_handler()
{
	echo "USR1 signal received"
	FORCE_REFRESH=1  # this variable does not do anything :)
}

usr2_handler()
{
	echo "USR2 signal received"
	FORCE_RENEWAL=-f
	FORCE_REFRESH=1
}


exit_handler()
{
	echo "QUIT/TERM signal received."
	TERMINATE=1
}

int_handler()
{
	echo "INTerrupt signal received."
	TERMINATE=1
}


trap usr1_handler USR1
trap usr2_handler USR2
trap exit_handler QUIT TERM
trap int_handler  INT


cat <<EOF
This container supports USR1 and USR2 signals:
  USR1 = ask for SSL certificate refresh, without forcing renewal.
  USR2 = ask for SSL certificate refresh, forcing renewal.
EOF


replace-template

# tail -f /var/log/syslog &

case $SSL_ENV in
	dev)
		test -n "${DOMAIN_NAME}" -a \
		     -n "${SSL_ACCOUNT_EMAIL}" || exit 11

		# automatically generate a Root CA if there is no one
		cert_tool_root_ca_mounted ||
			cert_tool_build_local_ca_cert

		FORCE_RENEWAL=-f
		while [ "$TERMINATE" != 1 ];
		do
			test "$FORCE_RENEWAL" = '-f' &&
			  { cert_tool_build_domain_cert || exit 12; } ||
			  { echo "Certificate was not modified"; }

			sleep 600 &
			echo 'Waiting for signals...'
			wait;
		done
		;;
	prod)
		while [ "$TERMINATE" != 1 ];
		do
			build_cert || exit 21

			FORCE_REFRESH=0
			sleep $GETSSL_REFRESH_INTERVAL &
			echo 'Waiting for signals...'
			wait
		done
		;;
	*)
		echo "Unknown environment: $SSL_ENV"
		exit 255
		;;
esac

echo "Exiting container..."
