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

# Optional browser/WebDAV uploader for /data/media on port 5000 (its own Railway
# domain). User "admin" (MEDIA_UPLOAD_USER), password MEDIA_UPLOAD_PASSWORD.
# Unset MEDIA_UPLOAD_PASSWORD to turn it off. Files are written world-readable,
# so K7 (running as appuser) can index them.
if [ -n "${MEDIA_UPLOAD_PASSWORD:-}" ]; then
	(
		umask 022
		while :; do
			dufs /data/media --bind 0.0.0.0 --port "${MEDIA_UPLOAD_PORT:-5000}" \
				--auth "${MEDIA_UPLOAD_USER:-admin}:${MEDIA_UPLOAD_PASSWORD}@/:rw" \
				--allow-upload --allow-delete --allow-search --allow-archive \
				--hidden 'lost+found' \
				--log-format '[dufs] $remote_addr "$request" $status' || true
			echo '[dufs] exited; restarting in 5s' >&2
			sleep 5
		done
	) &
	echo "Media uploader (dufs) on :${MEDIA_UPLOAD_PORT:-5000} serving /data/media"
fi

# BaseUrl from Railway's public domain unless set explicitly.
if [ -z "${BaseUrl:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
	export BaseUrl="https://${RAILWAY_PUBLIC_DOMAIN}"
fi

exec /entrypoint.sh "$@"
