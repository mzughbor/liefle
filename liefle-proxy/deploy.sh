#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo "Missing .env — copy .env.example to .env and edit values."
  exit 1
fi

# shellcheck disable=SC1091
source .env

HOST="${DEPLOY_HOST:-root@195.35.1.18}"
REMOTE_PATH="${DEPLOY_PATH:-/opt/liefle-proxy}"
SSH_OPTS="${SSH_OPTS:-}"
RSYNC_SSH="ssh ${SSH_OPTS}"

echo "==> Deploying liefle-proxy to ${HOST}:${REMOTE_PATH}"

ssh ${SSH_OPTS} "$HOST" "mkdir -p ${REMOTE_PATH}/{caddy,allow-api,data,systemd}"

rsync -avz -e "$RSYNC_SSH" --delete \
  --exclude '.env' \
  --exclude 'data/' \
  --exclude '.git' \
  ./allow-api/ "${HOST}:${REMOTE_PATH}/allow-api/"

rsync -avz -e "$RSYNC_SSH" \
  ./caddy/Caddyfile \
  ./docker-compose.yml \
  ./.env.example \
  ./setup-vps.sh \
  ./proxy-test-start.sh \
  ./proxy-test-stop.sh \
  ./sync-to-vps.sh \
  "${HOST}:${REMOTE_PATH}/"

if [[ -f .env ]]; then
  scp ${SSH_OPTS} .env "${HOST}:${REMOTE_PATH}/.env"
fi

ssh ${SSH_OPTS} "$HOST" bash -s <<EOF
set -euo pipefail
cd ${REMOTE_PATH}

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found on VPS. Install Docker first:"
  echo "  curl -fsSL https://get.docker.com | sh"
  exit 1
fi

COMPOSE="docker compose"
if ! docker compose version >/dev/null 2>&1; then
  if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
  else
    echo "Install Docker Compose plugin: apt install docker-compose-plugin"
    exit 1
  fi
fi

\$COMPOSE pull
\$COMPOSE up -d --build
\$COMPOSE ps
EOF

echo "==> Deploy complete"
echo "Next: curl -I https://connect.liefle.com"
