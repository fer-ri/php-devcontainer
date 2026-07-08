#!/bin/sh
set -e

PUID="${USER_ID:-1000}"
PGID="${GROUP_ID:-1000}"

CURRENT="$(id -u www-data 2>/dev/null || echo "")"
[ "$CURRENT" = "$PUID" ] && exit 0

echo "Remapping www-data -> ${PUID}:${PGID}"
groupmod -g "$PGID" www-data 2>/dev/null || true
usermod  -u "$PUID" -g "$PGID" www-data 2>/dev/null || true
docker-php-serversideup-set-file-permissions --owner "${PUID}:${PGID}" --service nginx 2>/dev/null || true
