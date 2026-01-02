#!/bin/bash

set -e

JELLYFIN_DIR="/opt/jellyfin"
sudo mkdir -p ${JELLYFIN_DIR}/config
sudo mkdir -p ${JELLYFIN_DIR}/cache
sudo mkdir -p /media/movies
sudo mkdir -p /media/tvshows
sudo mkdir -p /media/music

sudo tee ${JELLYFIN_DIR}/docker-compose.yml > /dev/null <<EOF
version: "3.8"
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - ${JELLYFIN_DIR}/config:/config
      - ${JELLYFIN_DIR}/cache:/cache
      - /media/movies:/data/movies
      - /media/tvshows:/data/tvshows
      - /media/music:/data/music
    ports:
      - 8096:8096
      - 8920:8920  # HTTPS port (optional)
      - 7359:7359/udp  # Service discovery
      - 1900:1900/udp  # DLNA discovery
    networks:
      - jellyfin-network

networks:
  jellyfin-network:
    driver: bridge
EOF

sudo chown -R 1000:1000 ${JELLYFIN_DIR}

cd ${JELLYFIN_DIR}
sudo docker compose up -d

sudo ufw allow 8096/tcp comment 'Jellyfin HTTP'
sudo ufw allow 8920/tcp comment 'Jellyfin HTTPS'
sudo ufw allow 7359/udp comment 'Jellyfin Discovery'
sudo ufw allow 1900/udp comment 'Jellyfin DLNA'

echo "=========================================="
echo "Jellyfin installation complete!"
echo "Access Jellyfin at: http://YOUR_SERVER_IP:8096"
echo "=========================================="

