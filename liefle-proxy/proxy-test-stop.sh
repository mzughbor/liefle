#!/usr/bin/env bash
# Stop liefle-proxy and restore CloudPanel nginx on 80/443.
#
# Usage: bash proxy-test-stop.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Stopping liefle-proxy containers..."
docker compose down 2>/dev/null || true

echo "==> Starting CloudPanel nginx..."
systemctl start nginx
sleep 1

echo ""
echo "==> Restored. Current listeners:"
ss -tlnp | grep -E ':80|:443' || true

echo ""
echo "CloudPanel sites should be back on 80/443."
echo "Panel UI: https://195.35.1.18:8443"
