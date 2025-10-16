#!/bin/bash
set -e

if ! docker volume ls | grep -q portainer_data; then
    docker volume create portainer_data
fi

if docker ps -a --format '{{.Names}}' | grep -q '^portainer$'; then
    docker stop portainer
    docker rm portainer
fi

docker run -d \
  -p 9000:9000 \
  --name=portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

sudo chmod 666 /var/run/docker.sock
docker restart portainer

echo "Portainer is now running at http://$(hostname -I | awk '{print $1}'):9000"