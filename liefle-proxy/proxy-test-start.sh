#!/usr/bin/env bash
# Temporarily stop CloudPanel nginx and start liefle-proxy (Caddy).
# CloudPanel UI on :8443 stays up. Hosted sites on :80/:443 go down during the test.
#
# Usage: bash proxy-test-start.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env — set ALLOW_API_SECRET before production."
fi

echo "==> Current listeners on 80/443:"
ss -tlnp | grep -E ':80|:443' || echo "(none)"

if ss -tlnp | grep -q nginx; then
  echo ""
  echo "==> Stopping CloudPanel nginx (frees ports 80/443)..."
  systemctl stop nginx
  sleep 1
fi

if ss -tlnp | grep -qE ':80 |:443 '; then
  echo "ERROR: Ports 80/443 still in use. Check with: ss -tlnp | grep -E ':80|:443'"
  exit 1
fi

echo "==> Starting liefle-proxy..."
docker compose up -d --build
docker compose ps

echo ""
echo "==> Proxy test is RUNNING"
echo "    CloudPanel panel:  https://195.35.1.18:8443  (still works)"
echo "    Hosted WP/sites:   OFF until you run proxy-test-stop.sh"
echo ""
echo "Test:"
echo "  curl -s http://127.0.0.1:8080/health"
echo "  curl -I https://connect.falcon.codes"
echo "  curl -I https://connect.liefle.com"
echo ""
echo "When done, restore CloudPanel:"
echo "  bash proxy-test-stop.sh"
