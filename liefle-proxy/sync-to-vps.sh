#!/usr/bin/env bash
# Push liefle-proxy files to VPS (no git on server needed).
# Usage:
#   SSH_OPTS='-o IdentitiesOnly=yes' ./sync-to-vps.sh
#   ./sync-to-vps.sh root@195.35.1.18
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  source .env
fi

HOST="${1:-${DEPLOY_HOST:-root@195.35.1.18}}"
REMOTE_PATH="${DEPLOY_PATH:-/opt/liefle-proxy}"
SSH_OPTS="${SSH_OPTS:-}"

RSYNC_SSH="ssh ${SSH_OPTS}"
SCP_OPTS=()
if [[ -n "$SSH_OPTS" ]]; then
  # shellcheck disable=SC2206
  SCP_OPTS=($SSH_OPTS)
fi

echo "==> Syncing to ${HOST}:${REMOTE_PATH}"
echo "    SSH_OPTS=${SSH_OPTS:-<none>}"

ssh ${SSH_OPTS} "$HOST" "mkdir -p ${REMOTE_PATH}/{caddy,allow-api,systemd,docs}"

rsync -avz -e "$RSYNC_SSH" --delete \
  --exclude '.env' \
  --exclude 'data/' \
  ./allow-api/ "${HOST}:${REMOTE_PATH}/allow-api/"

rsync -avz -e "$RSYNC_SSH" \
  ./caddy/ \
  ./docs/ \
  ./systemd/ \
  ./docker-compose.yml \
  ./.env.example \
  ./deploy.sh \
  ./setup-vps.sh \
  ./proxy-test-start.sh \
  ./proxy-test-stop.sh \
  ./start-local.sh \
  ./README.md \
  "${HOST}:${REMOTE_PATH}/"

if [[ -f .env ]]; then
  scp "${SCP_OPTS[@]}" .env "${HOST}:${REMOTE_PATH}/.env"
else
  echo "No local .env — server keeps existing .env or copy .env.example on VPS"
fi

echo "==> Sync complete"
echo "On VPS:"
echo "  ssh ${SSH_OPTS} ${HOST}"
echo "  cd ${REMOTE_PATH} && bash proxy-test-start.sh"
