FROM ubuntu:18.04
LABEL maintainer="Admin Projeto SD <admin@projetosd.center>"

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -q --fix-missing && \
    apt-get -y install --no-install-recommends \
        bsd-mailx \
        ca-certificates \
        curl \
        ctpl \
        dnsutils \
        gzip \
        iproute2 \
        less \
        nano \
        net-tools \
        netcat \
        p7zip \
        rsyslog \
        ssmtp \
        unzip \
        wget
RUN apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/locale/* && \
    rm -rf /usr/share/man/* && \
    rm -rf /usr/share/doc/* && \
    touch /var/log/auth.log

# Install bash script tool for Let's Encrypt
WORKDIR /usr/local/bin
ENV GETSSL_VERSION=2.35
RUN update-ca-certificates && \
    wget \
      https://raw.githubusercontent.com/srvrco/getssl/v${GETSSL_VERSION}/getssl && \
    chmod 700 getssl && \
    mkdir -p /root/.getssl /data/acme-challenge /data/ssl && \
    touch /root/.getssl/.default \
          /data/acme-challenge/.default \
          /data/ssl/.default \
    getssl --help | head -1

COPY files /
COPY templates /templates
# COPY templates/*getssl.cfg.ctpl /data/templates/root/.getssl/
RUN  chmod +x /entrypoint.sh /cert-tool.sh

WORKDIR /
ENTRYPOINT ["/entrypoint.sh"]
