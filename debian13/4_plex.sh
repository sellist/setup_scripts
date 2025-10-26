#!/usr/bin/env bash
set -euo pipefail

PLEX_CLAIM="${1:-}"
PLEX_NAME="plex"
IMAGE="lscr.io/linuxserver/plex:latest"
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
TZ="${TZ:-Etc/UTC}"
HOST_MEDIA_DIR="/srv/plex"
HOST_MEDIA_DATA="$HOST_MEDIA_DIR/media"
VOLUMES=("plex_config" "plex_transcode")

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker not found. Install Docker or run the basics setup first."
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Warning: not running as root. Ensure your user can run docker commands (docker group or sudo)."
fi

mkdir -p "$HOST_MEDIA_DATA"
mkdir -p "$HOST_MEDIA_DATA/tv" "$HOST_MEDIA_DATA/movies" "$HOST_MEDIA_DATA/library"
chown -R "$PUID:$PGID" "$HOST_MEDIA_DIR"
chmod -R 775 "$HOST_MEDIA_DIR"

for v in "${VOLUMES[@]}"; do
  if ! docker volume ls --format '{{.Name}}' | grep -xq "$v"; then
    docker volume create "$v"
    echo "Created docker volume: $v"
  fi
done

if docker ps -a --format '{{.Names}}' | grep -xq "^${PLEX_NAME}$"; then
  echo "Removing existing container: $PLEX_NAME"
  docker rm -f "$PLEX_NAME"
fi

USERNS_ENABLED=0
if docker info 2>/dev/null | grep -qi 'userns'; then
  USERNS_ENABLED=1
fi

PORT_MAPPINGS=(
  -p 32400:32400/tcp
  -p 32469:32469/tcp
  -p 1900:1900/udp
  -p 32410:32410/udp
  -p 32412:32412/udp
  -p 32413:32413/udp
  -p 32414:32414/udp
)

RUN_CMD=(docker run -d --name "$PLEX_NAME" --restart unless-stopped)

if [ "$USERNS_ENABLED" -eq 0 ]; then
  RUN_CMD+=(--network host)
else
  echo "Docker user namespaces detected; using published ports instead of --network host"
  RUN_CMD+=("${PORT_MAPPINGS[@]}")
fi

RUN_CMD+=(
  -e PUID="$PUID" -e PGID="$PGID" -e TZ="$TZ" -e VERSION="docker"
  -v plex_config:/config
  -v plex_transcode:/transcode
  -v "$HOST_MEDIA_DATA":/data
)

if [ -d /dev/dri ]; then
  RUN_CMD+=("--device" "/dev/dri:/dev/dri")
fi

if [ -n "$PLEX_CLAIM" ]; then
  RUN_CMD+=(-e PLEX_CLAIM="$PLEX_CLAIM")
fi

RUN_CMD+=("$IMAGE")

echo "Starting Plex container..."
"${RUN_CMD[@]}"

echo "Plex deployed."
echo "Config volume: plex_config"
echo "Transcode volume: plex_transcode"
echo "Media bind: $HOST_MEDIA_DATA (tv, movies, library)"
if [ -n "$PLEX_CLAIM" ]; then
  echo "PLEX_CLAIM supplied."
else
  echo "No PLEX_CLAIM supplied; you can add it later via container env or web UI."
fi