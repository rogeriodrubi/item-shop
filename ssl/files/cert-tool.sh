#!/bin/bash

log()
{
	echo "$@" >&2
}

log_err()
{
	echo "$@" >&2
}


cert_tool_exists_cert()
{
	log "Checking certificate existence..."
	test -f /data/ssl/privkey.pem -a -f /data/ssl/fullchain.pem
}


cert_tool_build_self_signed()
{
	log "Building self-signed certificate..."

	openssl req -x509 -nodes \
	  -days 365 -newkey rsa:2048 \
	  -keyout /data/ssl/privkey.pem \
	  -out /data/ssl/fullchain.pem <<-EOF
	ZZ
	My state or province
	My City
	Example Company Ltd.
	Example Company Ltd. - Security Division
	${DOMAIN_NAME}
	${SSL_ACCOUNT_EMAIL}
	EOF
	
	test $? -eq 0 || exit 1

	openssl x509 \
	   -in /data/ssl/fullchain.pem \
	   -text -noout

	FORCE_RENEWAL=
}

cert_tool_configure_openssl()
{
	test -n "$SSL_SUBDOMAINS" \
	  -a -n "$DOMAIN_NAME" ||
	  	{ log "DOMAIN_NAME and SSL_SUBDOMAINS variables must be set"; return 1; }

	local count=$(echo $SSL_SUBDOMAINS | tr -cd ',' | wc -c)

	cat > /tmp/ctpl-vars <<-EOF
	DOMAIN_NAME="${DOMAIN_NAME}";
	SSL_SUBDOMAINS=["$(echo $SSL_SUBDOMAINS | sed -r 's~,~","~g')"];
	INDEXES=[$( seq -s, 0 $count )];
	EOF

	ctpl -e /tmp/ctpl-vars  \
			-o /etc/openssl.cnf  \
			/templates/etc/openssl.cnf ||
		{ log "template replacement failed"; return 1; }

	# echo ---------
	# cat /tmp/ctpl-vars
	# echo ---------
	# cat /etc/openssl.cnf
	# echo ---------
}

cert_tool_build_local_ca_cert()
{
	# SSL_CA_PASS=1 # if you what openssl asks a pass phrase for CA key
	log "Building local Root CA certificate..."
	cert_tool_configure_openssl &&
	cd /data/ssl/ &&
	openssl genrsa $(test "$SSL_CA_PASS" = 1 && echo -aes256) -out ca.key.pem 2048 &&
	chmod 400 ca.key.pem &&
	openssl req -x509 \
	   -subj "/CN=local-ca" \
	   -extensions v3_ca \
	   -days 3650 \
	   -key ca.key.pem \
	   -sha256 -new \
	   -out ca.pem \
	   -config /etc/openssl.cnf
}

cert_tool_build_domain_cert()
{
	log "Building domain certificate..."
	cert_tool_configure_openssl &&
	cd /data/ssl/ &&
	openssl genrsa -out domain.key.pem 2048 &&
	openssl req \
	   -subj "/CN=$DOMAIN_NAME" \
	   -extensions v3_req \
	   -sha256 -new \
	   -key domain.key.pem \
	   -out domain.csr &&
	openssl x509 \
	   -req \
	   -extensions v3_req \
	   -days 30 \
	   -sha256 \
	   -in domain.csr \
	   -CA ca.pem -CAkey ca.key.pem -CAcreateserial \
	   -out domain.crt -extfile /etc/openssl.cnf &&
	cat domain.crt ca.pem > ./fullchain.pem &&
	cat domain.key.pem > ./privkey.pem
}

cert_tool_build_le_getssl()
{
	log "Building Let's Encrypt certificate..."

	# Replace CTPL templates
	if [ ! -f /root/.getssl/getssl.cfg \
		 -o \
		 ! -f /root/.getssl/${DOMAIN_NAME}/getssl.cfg ];
	then
		echo "Building configuration files by template replacement..."

		# Create environment file for CTPL
		cat > /tmp/ctpl-vars <<-EOF
		SSL_CA_DOMAIN="$SSL_CA_DOMAIN";
		SSL_ACCOUNT_EMAIL="$SSL_ACCOUNT_EMAIL";
		ADDITIONAL_DOMAIN_NAMES="$ADDITIONAL_DOMAIN_NAMES";
		SSL_RELOAD_CMD="$SSL_RELOAD_CMD";
		EOF

		ctpl -e /tmp/ctpl-vars  \
		     -o /root/.getssl/getssl.cfg  \
		     /templates/root/.getssl/getssl.cfg.ctpl

		mkdir -p /root/.getssl/${DOMAIN_NAME}

		ctpl -e /tmp/ctpl-vars  \
		     -o /root/.getssl/${DOMAIN_NAME}/getssl.cfg  \
		     /templates/root/.getssl/domain-getssl.cfg.ctpl

		MODE=$(stat -c "%a" /templates/root/.getssl/getssl.cfg.ctpl)
		chmod $MODE /root/.getssl/getssl.cfg \
		            /root/.getssl/${DOMAIN_NAME}/getssl.cfg
	else
		echo "Configuration files for getssl/LE already exist."
	fi

	echo "Configuration directory content:"
	find /root/.getssl

	echo
	echo "Starting getssl..."
	/usr/local/bin/getssl ${FORCE_RENEWAL} "${DOMAIN_NAME}"
	FORCE_RENEWAL=
}


cert_tool_all_mounted()
{
	test ! -f /root/.getssl/.default \
	  -a ! -f /data/acme-challenge/.default \
	  -a ! -f /data/ssl/.default
}


cert_tool_nothing_mounted()
{
	test -f /root/.getssl/.default \
	  -a -f /data/acme-challenge/.default \
	  -a -f /data/ssl/.default
}


cert_tool_root_ca_mounted()
{
	test -f /data/ssl/ca.key.pem \
	  -a -f /data/ssl/ca.pem
}
