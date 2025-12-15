
# Docker image for SSL certificate managemnet

This project create a docker container which takes care of managing SSL certificates. The certificate is renewed automatically 1 month before expiration using *Let's Encrypt* service. For *development* environment, a local root CA certificate and a domain certificate signed by the root one are built.

## Requirements

Requires git 2.7+, docker 19.03+.

## Running

See *readme* file in the parent directory.


## Checking certificate

Type `./cert-check.sh` without parameters for usage help and example.
This script is not automatically integrated to this service yet, then should be invoked manually on developer machine (even for stage or prod checking).

Or access the domain from your browser (for development, you need to import the generated root CA certificate).


## Refreshing and renewing certificates

For development environment, the root CA certificate is generated when not found and the domain certificate is renewed every 10 minutes.

For other environments, this service will check if renewal is need every hour. You may anticipate or change this behaviour by sending USR1 or USR2 signals via `docker kill`. To do it, SSH to the machine where container is running, then:

- Ask for certificate refreshing, renewing if needed (without forcing):
```
docker kill -s USR1 $(docker ps -f name=ssl -q)
```

- Ask for certificate refreshing, forcing renewal:
```
docker kill -s USR2 $(docker ps -f name=ssl -q)
```

- If you want to force renewal with a different configuration:
```
docker exec -ti $(docker ps -f name=ssl -q) \
  find /root/.getssl/ -name getssl.cfg -delete
docker kill -s USR2 $(docker ps -f name=ssl -q)
```

