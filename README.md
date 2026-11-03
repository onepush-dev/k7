# K7 on Railway: self-hosted media server for movies, series and music

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/IhqT07)

[K7](https://github.com/kaybi-gh/K7) (AGPL-3.0) is a self-hosted media server for a small circle of family and friends: movies, TV series and music with TMDb metadata, a web app plus mobile/desktop clients, ffmpeg HLS transcoding, SyncPlay, guest access, federation between K7 servers and an OpenSubsonic API for music apps. This template runs the official image next to Postgres 18 (Alpine, the image upstream's compose uses).

Image: `ghcr.io/onepush-dev/k7:1.17.2` = official `ghcr.io/kaybi-gh/k7:1.17.2` (pinned by digest) + a small start wrapper and the [dufs](https://github.com/sigoden/dufs) 0.47.0 binary (MIT/Apache-2.0, checksum-verified) as an optional media uploader. Defaults baked into the image: Postgres connection settings, all K7 paths under `/data`, `Security__ForceHttps=true`, Railway's edge range as a trusted proxy.

## Services
| Service | Image | Notes |
|---|---|---|
| K7 | `ghcr.io/onepush-dev/k7:1.17.2` | public HTTPS domain (port 7080), health `/health`, restart always, ONE volume `/data`: config, metadata/artwork, logs, transcoding cache and your media in `/data/media/{movies,series,music}` |
| Postgres | `postgres:18-alpine` (pinned by digest) | private, volume `/var/lib/postgresql` |

## First run
Zero inputs. Open your Railway domain and sign in as **admin** with the password in the K7 service's `K7_ADMIN_PASSWORD` variable (K7 completes setup from it on first boot, so `/setup` is never open to strangers). Change the password in Settings.

## Adding media
Railway gives a service one volume, so media lives on the same volume as K7's data under `/data/media`. The image ships an optional, password-protected uploader for that folder (dufs: browser upload with resume, folders, delete, search, WebDAV):

1. K7 service → Settings → Networking → **Generate Domain**, target port **5000**.
2. Open that domain, sign in as `admin` / `MEDIA_UPLOAD_PASSWORD` (K7 service Variables), and upload into `movies/`, `series/` or `music/` (e.g. `movies/Big Buck Bunny (2008)/Big Buck Bunny (2008).mp4`). WebDAV clients and `curl -u admin:<password> -T file <url>/movies/...` work too.
3. In K7: Admin → Libraries → add a library on `/data/media/movies` (or series/music). New files are picked up by the folder watcher.

Remove `MEDIA_UPLOAD_PASSWORD` to switch the uploader off. Grow the volume in Railway when your library grows.

## Notes
- Transcoding is CPU-only on Railway (libx264/libx265); give the service enough vCPU for the streams you expect, or prefer direct play.
- `BaseUrl` defaults to `https://<RAILWAY_PUBLIC_DOMAIN>`; set it explicitly if you add a custom domain (needed for OIDC and federation).
- `Security__ApiKeys__HashSecret` is generated per deploy; changing it invalidates API keys.
- Optional: OIDC sign-in, SMTP, registration settings, `Server__Name`. See upstream [configuration](https://github.com/kaybi-gh/K7/blob/main/docs/admin/configuration.md).

## License
K7 is AGPL-3.0 (source: upstream v1.17.2). dufs is MIT/Apache-2.0. This repo only holds Railway packaging.
