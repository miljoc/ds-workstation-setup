#!/usr/bin/env bash
set -euo pipefail

create_volume() {
  local name="$1"
  if ! podman volume exists "$name" >/dev/null 2>&1; then
    podman volume create "$name" >/dev/null
  fi
}

create_volume doorapi-percona-data
create_volume doorapi-redis-data

podman rm -f doorapi-percona >/dev/null 2>&1 || true
podman rm -f doorapi-redis >/dev/null 2>&1 || true

podman run -d \
  --name doorapi-percona \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=doorapi_dev \
  -e MYSQL_USER=doorapi \
  -e MYSQL_PASSWORD=doorapi \
  -v doorapi-percona-data:/var/lib/mysql \
  docker.io/percona/percona-server:8.4

podman run -d \
  --name doorapi-redis \
  -p 6379:6379 \
  -v doorapi-redis-data:/data \
  docker.io/redis:7-alpine \
  redis-server --appendonly yes
