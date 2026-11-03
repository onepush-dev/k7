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
# Optional media uploader: dufs (MIT/Apache-2.0), a single static binary that serves
# /data/media over HTTPS on its own Railway domain (port 5000) with upload, resumable
# uploads, delete, search and WebDAV. Only started when MEDIA_UPLOAD_PASSWORD is set.
ARG DUFS_VERSION=0.47.0
ARG DUFS_SHA256=c715c44b195f6133ca0f47e6fdc8d6015ec64b7fd9ac8e1c578ca23a92206aa4
RUN curl -fsSL -o /tmp/dufs.tgz "https://github.com/sigoden/dufs/releases/download/v${DUFS_VERSION}/dufs-v${DUFS_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    && echo "${DUFS_SHA256}  /tmp/dufs.tgz" | sha256sum -c - \
    && tar -xzf /tmp/dufs.tgz -C /usr/local/bin dufs \
    && chmod 755 /usr/local/bin/dufs && rm -f /tmp/dufs.tgz && dufs --version
EXPOSE 7080 5000
COPY --chmod=755 railway/railway-start.sh /railway-start.sh
ENTRYPOINT ["/railway-start.sh"]
