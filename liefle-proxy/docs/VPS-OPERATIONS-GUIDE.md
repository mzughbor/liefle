# Liefle Proxy — VPS Operations Guide

Complete reference for installing, deploying, testing, and restoring the Liefle reverse proxy on VPS `195.35.1.18` with CloudPanel.

**Last updated:** July 2026  
**VPS:** `srv471837` / `195.35.1.18`  
**Deploy path:** `/opt/liefle-proxy`  
**Repo mirror (optional):** `/home/deploy/repos/liefle-proxy`

---

## Table of contents

1. [What this is](#what-this-is)
2. [Architecture](#architecture)
3. [Domains we own](#domains-we-own)
4. [File structure](#file-structure)
5. [Environment variables](#environment-variables)
6. [DNS setup](#dns-setup)
7. [Install Docker on VPS](#install-docker-on-vps)
8. [Push files from laptop (no git on server)](#push-files-from-laptop-no-git-on-server)
9. [Run the proxy (CloudPanel conflict)](#run-the-proxy-cloudpanel-conflict)
10. [Stop and restore CloudPanel](#stop-and-restore-cloudpanel)
11. [Verify everything works](#verify-everything-works)
12. [Allow API reference](#allow-api-reference)
13. [Customer domain flow (future)](#customer-domain-flow-future)
14. [Troubleshooting](#troubleshooting)
15. [Test log (July 2026)](#test-log-july-2026)
16. [Long-term plan](#long-term-plan)

---

## What this is

Liefle Proxy sits on your VPS and hides Vercel from customer DNS. Customers point their domain to **you**, not Vercel.

```
Customer browser
      │  https://www.client.com
      ▼
Customer DNS: CNAME www → connect.liefle.com
      ▼
Your VPS (195.35.1.18) — Caddy :443
      │  on-demand TLS (allow-api gate)
      │  reverse_proxy with Host header
      ▼
Vercel: liefle.vercel.app (Next.js tenant routing)
```

**Two containers:**

| Container | Role |
|-----------|------|
| `liefle-allow-api` | Decides which domains get TLS certs (security gate) |
| `liefle-caddy` | HTTPS termination + reverse proxy to Vercel |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  VPS 195.35.1.18                                        │
│                                                         │
│  :8443  CloudPanel UI (always up, unaffected by test)   │
│  :8090  CloudPanel gunicorn (internal)                  │
│                                                         │
│  EITHER nginx OR Caddy on :80 / :443 (not both):        │
│                                                         │
│  Normal mode:  nginx (CloudPanel hosted sites)          │
│  Test mode:    Caddy Docker (Liefle proxy)              │
│                                                         │
│  :8080  allow-api (127.0.0.1 only, Docker)              │
└─────────────────────────────────────────────────────────┘
```

**Critical rule:** Only one process can bind ports **80** and **443**. CloudPanel nginx and Caddy cannot run at the same time on those ports.

---

## Domains we own

We do **not** use `liefle.io`. Real domains:

| Domain | Registrar | DNS | Role |
|--------|-----------|-----|------|
| **liefle.com** | Namecheap | Cloudflare (nameservers) | Production brand |
| **falcon.codes** | GoDaddy | GoDaddy DNS (`ns03/ns04.domaincontrol.com`) | Test / staging zone |

**Infrastructure hostnames (both must A-record to VPS):**

| Hostname | Purpose |
|----------|---------|
| `connect.liefle.com` | Production customer CNAME target |
| `connect.falcon.codes` | Test connect hostname (verified working) |

**Trial subdomains (future):** `*.falcon.codes` → Vercel

---

## File structure

```
liefle-proxy/
├── allow-api/
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js          # /allow-domain + /api/domains
│   └── domains.json       # allowed hostnames list
├── caddy/
│   └── Caddyfile          # Caddy config
├── docs/
│   ├── cloudflare-dns-setup.md
│   └── VPS-OPERATIONS-GUIDE.md   ← this file
├── systemd/
│   └── liefle-allow-api.service  # optional native install
├── docker-compose.yml
├── .env.example
├── .env                   # local + VPS (not in git)
├── deploy.sh              # sync + docker compose up
├── sync-to-vps.sh         # sync files only (no docker start)
├── setup-vps.sh           # install Docker on VPS
├── proxy-test-start.sh    # stop nginx → start proxy
├── proxy-test-stop.sh     # stop proxy → restore nginx
├── start-local.sh         # local dev (allow-api only)
└── README.md
```

---

## Environment variables

Copy `.env.example` to `.env` on laptop and VPS:

```env
VPS_IP=195.35.1.18
VERCEL_ORIGIN=https://liefle.vercel.app
CADDY_EMAIL=admin@liefle.com
ALLOW_API_SECRET=change-me-before-production

DEPLOY_HOST=root@195.35.1.18
DEPLOY_PATH=/opt/liefle-proxy

LIEFLE_DOMAIN=liefle.com
TEST_DOMAIN=falcon.codes

# Required if normal ssh fails:
SSH_OPTS=-o IdentitiesOnly=yes
```

| Variable | Description |
|----------|-------------|
| `VPS_IP` | Public IP; Caddy blocks direct IP access |
| `VERCEL_ORIGIN` | Where Caddy proxies traffic |
| `ALLOW_API_SECRET` | Bearer token for POST/DELETE `/api/domains` |
| `SSH_OPTS` | Passed to ssh/scp/rsync (e.g. `-o IdentitiesOnly=yes`) |

---

## DNS setup

### liefle.com (Namecheap → Cloudflare)

1. Add `liefle.com` in [Cloudflare Dashboard](https://dash.cloudflare.com)
2. At **Namecheap** → Domain List → `liefle.com` → **Domain** tab → **Nameservers** → **Custom DNS**
3. Paste Cloudflare's two nameservers (NOT Advanced DNS records)
4. In **Cloudflare** → DNS → Records:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | `connect` | `195.35.1.18` | Grey cloud first |
| A | `proxy` | `195.35.1.18` | Grey cloud |
| CNAME | `www` | `connect.liefle.com` | Optional |

Verify:

```bash
dig NS liefle.com +short
dig +short A connect.liefle.com
# → 195.35.1.18
```

### falcon.codes (GoDaddy direct DNS)

1. GoDaddy → **falcon.codes** → **DNS** → **Add record**
2. Add:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | `connect` | `195.35.1.18` | 1 Hour |

Do **not** use GoDaddy Forwarding — DNS records only.

Verify:

```bash
dig +short NS falcon.codes
# ns03.domaincontrol.com / ns04.domaincontrol.com

dig +short A connect.falcon.codes
# 195.35.1.18

dig +short A falcon.codes
# may also show 195.35.1.18 if apex A record exists
```

Full Cloudflare guide: [cloudflare-dns-setup.md](./cloudflare-dns-setup.md)

---

## Install Docker on VPS

One-time setup on the VPS as root:

```bash
apt-get update
apt-get install -y ca-certificates curl

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

docker --version
docker compose version
```

Or from synced files:

```bash
cd /opt/liefle-proxy
bash setup-vps.sh
```

---

## Push files from laptop (no git on server)

The VPS does not use git for deploy. Push from your **local machine**.

### SSH connection

Normal ssh may fail; use:

```bash
ssh -o IdentitiesOnly=yes root@195.35.1.18
```

### Recommended: sync-to-vps.sh

```bash
cd /home/mahmoud/liefle/liefle-proxy
SSH_OPTS='-o IdentitiesOnly=yes' ./sync-to-vps.sh
```

This uploads to **`/opt/liefle-proxy`** (where Docker runs).

### Optional: also sync to repo mirror

```bash
rsync -avz -e "ssh -o IdentitiesOnly=yes" \
  /home/mahmoud/liefle/liefle-proxy/ \
  root@195.35.1.18:/home/deploy/repos/liefle-proxy/ \
  --exclude '.env' --exclude '.git'
```

### What gets synced

- `allow-api/` (server.js, domains.json, Dockerfile)
- `caddy/Caddyfile`
- `docker-compose.yml`
- `proxy-test-start.sh`, `proxy-test-stop.sh`
- `setup-vps.sh`, `deploy.sh`, `sync-to-vps.sh`
- `docs/`, `systemd/`, `.env.example`, `README.md`
- `.env` (if present locally)

---

## Run the proxy (CloudPanel conflict)

CloudPanel nginx owns **80/443** by default. You must stop it before Caddy starts.

### Check who owns 80/443

```bash
ss -tlnp | grep -E ':80|:443'
```

**Normal (CloudPanel running):**

```
nginx ... :80, :443
```

**Proxy test running:**

```
docker-proxy ... :80, :443
```

### Start proxy test (recommended)

```bash
ssh -o IdentitiesOnly=yes root@195.35.1.18
cd /opt/liefle-proxy
bash proxy-test-start.sh
```

What `proxy-test-start.sh` does:

1. `systemctl stop nginx` — frees 80/443
2. `docker compose up -d --build` — starts allow-api + Caddy

### Manual start (same thing)

```bash
cd /opt/liefle-proxy
cp .env.example .env    # first time only; edit ALLOW_API_SECRET
systemctl stop nginx
docker compose down     # clean previous failed attempts
docker compose up -d --build
docker compose ps
```

### Expected `docker compose ps`

```
NAME               STATUS                    PORTS
liefle-allow-api   Up (healthy)              127.0.0.1:8080->8080/tcp
liefle-caddy       Up                        0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

### What stays up during test

| Service | Port | Status during test |
|---------|------|-------------------|
| CloudPanel UI | 8443 | ✅ Still works |
| CloudPanel gunicorn | 8090 | ✅ Still works |
| CloudPanel hosted sites | 80/443 | ❌ Temporarily down |
| Liefle proxy (Caddy) | 80/443 | ✅ Running |

---

## Stop and restore CloudPanel

When testing is done, restore nginx and your hosted sites.

### Recommended

```bash
cd /opt/liefle-proxy
bash proxy-test-stop.sh
```

What `proxy-test-stop.sh` does:

1. `docker compose down` — stops Caddy + allow-api
2. `systemctl start nginx` — restores CloudPanel sites

### Manual restore

```bash
cd /opt/liefle-proxy
docker compose down
systemctl start nginx
```

### Confirm restore succeeded

```bash
# nginx back (not docker-proxy)
ss -tlnp | grep -E ':80|:443'

# nginx active
systemctl status nginx --no-pager

# no proxy containers
docker compose ps

# CloudPanel UI
curl -Ik https://195.35.1.18:8443
```

**Nothing is permanently damaged** by start/stop. Only nginx was paused and Docker containers were stopped. Config files in `/opt/liefle-proxy` remain for the next test.

---

## Verify everything works

### On VPS (during proxy test)

```bash
# allow-api health
curl -s http://127.0.0.1:8080/health
# {"ok":true,"service":"liefle-allow-api","domains":2}

# TLS gate for known domains
curl -s -o /dev/null -w "%{http_code}\n" \
  "http://127.0.0.1:8080/allow-domain?domain=connect.falcon.codes"
# 200

# HTTPS via Caddy
curl -I https://connect.falcon.codes
# HTTP/2 200, server: Caddy

curl -I https://connect.liefle.com
# HTTP/2 200 (once DNS is set)
```

### From laptop

```bash
dig +short A connect.falcon.codes
# 195.35.1.18

curl -I https://connect.falcon.codes
curl https://connect.falcon.codes
# "Liefle test connect — point your CNAME here (falcon.codes)"
```

### Success criteria

- [ ] DNS resolves to `195.35.1.18`
- [ ] `docker compose ps` shows both containers healthy/running
- [ ] `curl -I https://connect.falcon.codes` → HTTP 200, `server: Caddy`
- [ ] `curl http://127.0.0.1:8080/health` → `ok: true`
- [ ] After restore: nginx on 80/443, CloudPanel sites load

---

## Allow API reference

Runs on `127.0.0.1:8080` (not public).

| Endpoint | Auth | Response |
|----------|------|----------|
| `GET /health` | No | JSON status |
| `GET /allow-domain?domain=HOST` | No | 200 allowed / 403 denied |
| `GET /api/domains` | Bearer | List allowed domains |
| `POST /api/domains` | Bearer | Add domain |
| `DELETE /api/domains/:domain` | Bearer | Remove domain |

**Default allowed domains** (`allow-api/domains.json`):

```json
{
  "domains": [
    "connect.liefle.com",
    "connect.falcon.codes"
  ]
}
```

**Add a verified customer domain:**

```bash
curl -X POST http://127.0.0.1:8080/api/domains \
  -H "Authorization: Bearer $ALLOW_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"domain":"www.mybrand.com"}'
```

Caddy calls `/allow-domain` before issuing on-demand TLS certificates. Domains not in the list get **403** and no cert.

---

## Customer domain flow (future)

When the Next.js app is built, users connect custom domains like this:

**At their registrar:**

| Type | Name | Value |
|------|------|-------|
| CNAME | `www` | `connect.liefle.com` |
| TXT | `_liefle` | `verify=<token-from-dashboard>` |

**Your backend:**

1. User submits `www.mybrand.com`
2. Verify TXT via DNS lookup
3. `POST /api/domains` to allow-api
4. First HTTPS visit → Caddy issues cert → site live on Vercel via Host header

---

## Troubleshooting

### `address already in use` on port 80

**Cause:** nginx still running.  
**Fix:**

```bash
systemctl stop nginx
docker compose down
docker compose up -d --build
```

### `connect.falcon.codes` does not resolve

**Cause:** Missing A record in GoDaddy.  
**Fix:** Add A record `connect` → `195.35.1.18`, wait 5–30 min.

```bash
dig +short A connect.falcon.codes
# must return 195.35.1.18
```

### Namecheap AI / Advanced DNS confusion (liefle.com)

Do **not** add Cloudflare records on Namecheap Advanced DNS.  
Change **Nameservers** to Cloudflare on the **Domain** tab, then add records in Cloudflare.

### Caddy starts but Vercel returns 404

**Cause:** Wrong Host header or Vercel app not deployed.  
**Check:** Caddyfile has `header_up Host {host}` and `VERCEL_ORIGIN` is correct.

### Cert fails for unknown domain

**Cause:** Domain not in allow-api.  
**Fix:** `POST /api/domains` with the hostname.

### ssh asks for password every time

Use SSH key or add to `~/.ssh/config`:

```
Host liefle-vps
  HostName 195.35.1.18
  User root
  IdentitiesOnly yes
```

Then: `ssh liefle-vps`

### View logs

```bash
docker compose logs -f
docker compose logs caddy --tail=50
docker compose logs allow-api --tail=50
journalctl -u nginx -f   # after restore
```

---

## Test log (July 2026)

Successful test on `srv471837`:

```
✔ Container liefle-allow-api   Healthy
✔ Container liefle-caddy       Started

curl -s http://127.0.0.1:8080/health
→ {"ok":true,"service":"liefle-allow-api","domains":2}

curl -I https://connect.falcon.codes
→ HTTP/2 200, server: Caddy, content-length: 60

ss -tlnp | grep -E ':80|:443'
→ docker-proxy on 80/443 (not nginx)
```

DNS after GoDaddy A record:

```
dig +short A connect.falcon.codes → 195.35.1.18
dig +short NS falcon.codes → ns03/ns04.domaincontrol.com
```

---

## Long-term plan

Current setup is a **reversible test**. Production goal:

```
Internet :443
    → Caddy (always on)
        → connect.liefle.com / customer domains → Vercel
        → mywordpress.com → 127.0.0.1:8080 (CloudPanel nginx internal)
CloudPanel UI stays on :8443
```

Steps for production (later):

1. Move CloudPanel site nginx to `127.0.0.1:8080` (internal only)
2. Caddy permanently owns 80/443
3. Optional: orange-cloud `connect.liefle.com` in Cloudflare
4. Next.js app with middleware tenant routing on Vercel
5. Domain verify API → sync to allow-api

See also:

- [../plan/03-reverse-proxy.md](../../plan/03-reverse-proxy.md)
- [../plan/04-dns-and-domains.md](../../plan/04-dns-and-domains.md)
- [../plan/vps-infra/02-reverse-proxy-hands-on.md](../../plan/vps-infra/02-reverse-proxy-hands-on.md)
- [cloudflare-dns-setup.md](./cloudflare-dns-setup.md)

---

## Quick command cheat sheet

```bash
# ── LAPTOP ──
cd ~/liefle/liefle-proxy
SSH_OPTS='-o IdentitiesOnly=yes' ./sync-to-vps.sh

# ── VPS: START PROXY TEST ──
ssh -o IdentitiesOnly=yes root@195.35.1.18
cd /opt/liefle-proxy && bash proxy-test-start.sh

# ── VPS: VERIFY ──
curl -s http://127.0.0.1:8080/health
curl -I https://connect.falcon.codes
docker compose ps

# ── VPS: RESTORE CLOUDPANEL ──
bash proxy-test-stop.sh

# ── VPS: CONFIRM RESTORE ──
ss -tlnp | grep -E ':80|:443'    # nginx, not docker
systemctl status nginx
curl -Ik https://195.35.1.18:8443
```
