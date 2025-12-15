# Docker image for Nginx with HTTPS

This project creates a docker container which allow multiple configurations from template files using ctpl tool. The nginx is automatically reloaded when a certificate update is detected.

## Requirements

Requires git 2.7+, docker 19.03+.

## Running

See *readme* file in the parent directory.

## Utility

watch -d -n1 'find /data/cache/ && du -hs /data/cache && uptime'
