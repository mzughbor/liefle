#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example — edit before production deploy."
fi

# shellcheck disable=SC1091
source .env

export PORT=8080
export HOST=0.0.0.0
export ALLOW_API_SECRET="${ALLOW_API_SECRET:-dev-secret-change-me}"
export DOMAINS_FILE="${ROOT_DIR}/allow-api/domains.json"

echo "Starting allow-api on http://127.0.0.1:8080"
exec node "${ROOT_DIR}/allow-api/server.js"
