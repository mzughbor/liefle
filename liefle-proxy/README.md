# Liefle Proxy

Reverse proxy stack for custom domains: **customer DNS → Cloudflare → VPS (195.35.1.18) → Vercel**.

```
www.client.com  ──CNAME──►  connect.liefle.com  ──A──►  195.35.1.18
                                                              │
                                                         Caddy :443
                                                              │
                                                    allow-api (TLS gate)
                                                              │
                                                    liefle.vercel.app
```

## Components

| Path | Purpose |
|------|---------|
| `caddy/Caddyfile` | On-demand TLS, reverse proxy to Vercel, block direct IP access |
| `allow-api/` | `/allow-domain` for Caddy; `/api/domains` to manage allowed hostnames |
| `docker-compose.yml` | Run Caddy + allow-api on the VPS |
| `deploy.sh` | Rsync + `docker compose up` on VPS |
| `docs/cloudflare-dns-setup.md` | Step-by-step Cloudflare + customer DNS guide |

## Quick start (local)

```bash
cd liefle-proxy
cp .env.example .env
# edit VERCEL_ORIGIN, ALLOW_API_SECRET

# Start allow-api only (no root ports needed)
node allow-api/server.js

# Or full stack (requires ports 80/443 free)
docker compose up -d --build
```

## Allow API

| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /health` | No | Health check |
| `GET /allow-domain?domain=www.example.com` | No | Caddy on-demand TLS gate (200/403) |
| `GET /api/domains` | Bearer token | List allowed domains |
| `POST /api/domains` | Bearer token | Add domain `{"domain":"www.example.com"}` |
| `DELETE /api/domains/:domain` | Bearer token | Remove domain |

Example:

```bash
export ALLOW_API_SECRET=dev-secret-change-me

curl http://127.0.0.1:8080/health

curl "http://127.0.0.1:8080/allow-domain?domain=connect.liefle.com"
# 200

curl -X POST http://127.0.0.1:8080/api/domains \
  -H "Authorization: Bearer $ALLOW_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"domain":"www.mybrand.com"}'
```

## Deploy to VPS

1. Configure DNS — see [docs/cloudflare-dns-setup.md](./docs/cloudflare-dns-setup.md)
2. Copy env: `cp .env.example .env` and set `VPS_IP`, `VERCEL_ORIGIN`, `ALLOW_API_SECRET`
3. Deploy:

```bash
chmod +x deploy.sh
./deploy.sh
```

4. Verify:

```bash
curl -I https://connect.liefle.com
```

## Domains

| Domain | Role |
|--------|------|
| `liefle.com` | Production brand + customer CNAME target (`connect.liefle.com`) |
| `falcon.codes` | Test DNS zone + trial subdomains (`*.falcon.codes`) |

## Cloudflare checklist

- [ ] Add `liefle.com` to Cloudflare; update registrar nameservers
- [ ] Add `falcon.codes` to Cloudflare (test zone)
- [ ] A record `connect` → `195.35.1.18` on both zones (grey cloud first)
- [ ] Deploy proxy on VPS
- [ ] Test `https://connect.liefle.com` and `https://connect.falcon.codes`
- [ ] Optional: orange-cloud `connect` + SSL Full (strict)

## Customer DNS (MVP)

Users add at their registrar:

| Type | Name | Value |
|------|------|-------|
| CNAME | `www` | `connect.liefle.com` |
| TXT | `_liefle` | `verify=<token>` |

After verification, your app calls `POST /api/domains` so Caddy can issue a certificate.

## CloudPanel note

If CloudPanel already uses ports 80/443 on the VPS, resolve that before running Caddy — see `plan/vps-infra/02-reverse-proxy-hands-on.md`. Docker publishing 80/443 will conflict with existing listeners.

## Related docs

- `plan/03-reverse-proxy.md` — architecture
- `plan/04-dns-and-domains.md` — verification flow
- `plan/vps-infra/02-reverse-proxy-hands-on.md` — VPS hands-on
