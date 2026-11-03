# K7 on Railway: the official image (pinned by digest) plus a small start wrapper.
# Railway allows one volume per service, so config, metadata, logs, transcoding cache
# AND the media libraries all live under /data (upstream mounts /data and /media).
FROM ghcr.io/kaybi-gh/k7:1.17.2@sha256:99b5f37d0b6ff97e6a7a967d1f5f5b5bdd6f258214894a667cec516821024588
LABEL org.opencontainers.image.source="https://github.com/onepush-dev/k7" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.opencontainers.image.description="K7 1.17.2 media server packaged for Railway"
# Defaults baked into the image because Railway templates drop plain variable values.
# Any of them can still be overridden in the service Variables.
ENV Database__Provider=Postgres \
    Database__Port=5432 \
    Database__UserID=postgres \
    Database__Name=postgres \
    Paths__Config=/data/config \
    Paths__Metadatas=/data/metadatas \
    Paths__Logs=/data/logs \
    Paths__Transcoding=/data/transcoding \
    Security__ForceHttps=true \
    Security__KnownProxies__0=100.64.0.0/10 \
    Security__KnownProxies__1=10.0.0.0/8 \
    Security__KnownProxies__2=172.16.0.0/12 \
    Security__KnownProxies__3=192.168.0.0/16 \
    Security__KnownProxies__4=127.0.0.1 \
    Security__KnownProxies__5=fd00::/8 \
    PUID=911 \
    PGID=911 \
    TZ=UTC
COPY --chmod=755 railway/railway-start.sh /railway-start.sh
ENTRYPOINT ["/railway-start.sh"]
