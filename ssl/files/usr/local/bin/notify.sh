#!/bin/bash


sendmail() {
	local Destination="$1"
	local Subject="$2"
	local Message="$3"

	cat > /tmp/mail-header.txt <<-EOF
	Subject: EMA notifier: $Subject
	From: <$SSL_NOTIFIER_ADDRESS>
	To: <$Destination>
	Content-Type: text/html
	EOF

	cat > /tmp/mail-body.txt <<-EOF
	<pre>
		${Message}
		--
		$(hostname) $(uptime)
	</pre>
	EOF

	cat /tmp/mail-header.txt /tmp/mail-body.txt | /usr/sbin/ssmtp "$Destination"
}


case "$1" in
    reloaded)
        Body=$(
            printf 'New certificate generated for "%s"' \
            "${DOMAIN_NAME}"
        )
        sendmail "$NOTIFICATION_MAIL_TARGET" "SSL certificate reloaded" "$Body"
        ;;
    *)
        exit 1
        ;;
esac
