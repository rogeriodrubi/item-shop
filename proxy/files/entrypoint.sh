#!/bin/bash

echo "$(date) Starting nginx-lb..."

ssl_certs_missing()
{
	test ! -f /certs/fullchain.pem -o ! -f /certs/privkey.pem -o "$NG_ENV" != dev -a ! -f /certs/chain.pem
}


build_conf_files()
{
	echo "###############################"
	echo "Building configuration files..."

	# TODO Create environment file for CTPL
	echo "--"
	echo "Relevant environment variables:"
	cat > /tmp/ctpl-vars <<-EOF
	NG_ENV="$NG_ENV";
	DNS_RESOLVER="$(cat /etc/resolv.conf | grep nameserver | cut -d ' ' -f2 | head -1)";
	EOF
	printenv | grep -E '^NG_TPL_' | sed -r 's~^([^=]+)=(.*)$~\1 \2~' |
	while read A B;
	do
		if [ "${A: -1}" == "_" ];
		then echo "$A=[\"${B/ /\",\"}\"];"
		else echo "$A=\"$B\";"
		fi
	done >> /tmp/ctpl-vars
	cat /tmp/ctpl-vars


	# Replace CTPL templates
	echo "--"
	echo "Replacing templates..."
	for f in $(find /templates -type f | sort)
	do
		g=${f/\/templates/}
		g=${g/.ctpl/}
		mkdir -p "$(dirname "$g")"
		echo "$f -> $g"
		ctpl -e /tmp/ctpl-vars -o "$g" "$f"
		chmod $(stat -c "%a %n" $f) $g
	done
}

nginx_reload()
{
	echo "$(date) - Reloading nginx settings..."
	sleep $1
	nginx -s reload
}

ssl_cert_monitor()
{
	echo "$(date) - Starting SSL certificate monitor..."
	while true;
	do
		if ssl_certs_missing; then
			echo "Waiting for creation of SSL certificate..."
			inotifywait \
			    --event CREATE --event MODIFY \
			    --recursive  /certs
			sleep 5
			if ! ssl_certs_missing; then
				build_conf_files
				nginx_reload 5
			fi
		else
			echo "Monitoring SSL certificate changes..."
			inotifywait \
			    --event CREATE --event MODIFY \
			    /certs/privkey.pem
			nginx_reload 5
		fi
	done
}


if ssl_certs_missing
then
	echo "#########"
	echo "SSL certificate missing: one or more PEM file(s) do(es) not exist."
	echo "Starting nginx on single site mode."
else
	build_conf_files
fi



echo "###################################"
echo "Starting SSL certificate monitor..."
ssl_cert_monitor 2>&1 | tee -a /var/log/ssl_cert_monitor.log &


echo "###################################"
echo "Starting SSH server..."
service ssh restart || fail 21


# Start nginx in foreground
echo "#################"
echo "Starting nginx..."
nginx -g 'daemon off;'

