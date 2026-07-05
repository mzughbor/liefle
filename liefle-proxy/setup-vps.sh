#!/usr/bin/env bash
# Run on the VPS as root: bash setup-vps.sh
set -euo pipefail

echo "==> Checking ports 80/443 (CloudPanel may already use these)..."
if ss -tlnp | grep -qE ':80 |:443 '; then
  echo ""
  echo "CloudPanel nginx is using 80/443 (expected)."
  echo "For a reversible test, use instead:"
  echo "  bash proxy-test-start.sh    # stop nginx, start proxy"
  echo "  bash proxy-test-stop.sh     # stop proxy, restore nginx"
  echo ""
  echo "Only continue here if nginx is already stopped. (y/N)"
  read -r ans
  [[ "${ans,,}" == "y" ]] || exit 0
fi

echo "==> Installing Docker..."
if ! command -v docker >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    | tee /etc/apt/sources.list.d/docker.list >/dev/null

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable --now docker
else
  echo "Docker already installed: $(docker --version)"
fi

docker compose version

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env — edit ALLOW_API_SECRET before production."
fi

echo "==> Building and starting liefle-proxy..."
docker compose up -d --build
docker compose ps

echo ""
echo "==> Done. Test with:"
echo "  curl -s http://127.0.0.1:8080/health"
echo "  curl -I https://connect.liefle.com"
echo "  curl -I https://connect.falcon.codes"
