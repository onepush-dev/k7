#!/bin/sh
# Railway start wrapper for K7, then hands over to the image's own /entrypoint.sh
# (chowns /data, drops to appuser, runs the server).
set -eu

# Media libraries live on the same volume as K7's data. Create the usual folders
# once; point K7 libraries at /data/media/<folder> in Admin -> Libraries.
for d in /data/media /data/media/movies /data/media/series /data/media/music; do
	[ -d "$d" ] || mkdir -p "$d"
done

# K7 listens on 7080 (the public domain targets it). Railway runs healthchecks
# against its injected $PORT, so listen there as well when it differs.
if [ -n "${PORT:-}" ] && [ "$PORT" != "7080" ] && [ "${ASPNETCORE_HTTP_PORTS:-7080}" = "7080" ]; then
	export ASPNETCORE_HTTP_PORTS="7080;${PORT}"
fi

# First admin without an open /setup page: K7 bootstraps it from these on first
# start (ignored once setup is complete). Username defaults to "admin".
if [ -n "${K7_ADMIN_PASSWORD:-}" ] && [ -z "${K7_ADMIN_USERNAME:-}" ] && [ -z "${K7_ADMIN_EMAIL:-}" ]; then
	export K7_ADMIN_USERNAME=admin
fi

# BaseUrl from Railway's public domain unless set explicitly.
if [ -z "${BaseUrl:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
	export BaseUrl="https://${RAILWAY_PUBLIC_DOMAIN}"
fi

exec /entrypoint.sh "$@"
