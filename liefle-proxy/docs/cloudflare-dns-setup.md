# Cloudflare DNS setup for Liefle

This guide wires **liefle.com** (or your root domain) to the VPS at **195.35.1.18**, then lets customer domains CNAME through `connect.liefle.com` to Vercel via the reverse proxy.

---

## Architecture

```
Customer registrar
  CNAME www → connect.liefle.com
       │
       ▼
Cloudflare (liefle.com zone)
  A connect → 195.35.1.18  [grey or orange cloud]
       │
       ▼
VPS Caddy :443
  on-demand TLS (allow-api)
  reverse_proxy → liefle.vercel.app
       │
       ▼
Vercel Next.js (Host header → tenant)
```

---

## Step 1 — Add liefle.com to Cloudflare

1. Create a Cloudflare account: https://dash.cloudflare.com/sign-up
2. **Add a site** → enter `liefle.com`
3. Cloudflare scans existing DNS records — review and continue
4. Cloudflare shows **two nameservers** (e.g. `ada.ns.cloudflare.com`, `bob.ns.cloudflare.com`)
5. At your **domain registrar** (Namecheap, GoDaddy, etc.):
   - Open domain → Nameservers
   - Switch to **Custom DNS**
   - Paste Cloudflare nameservers
6. Wait for propagation (usually 5–30 minutes; can take up to 24h)

Verify:

```bash
dig NS liefle.com +short
# Should show cloudflare.com nameservers
```

---

## Step 2 — Infrastructure DNS records (Cloudflare)

In Cloudflare → **liefle.com** → **DNS** → **Records**, add:

| Type | Name | Content | Proxy status | TTL |
|------|------|---------|--------------|-----|
| A | `connect` | `195.35.1.18` | **DNS only** (grey cloud) | Auto |
| A | `proxy` | `195.35.1.18` | DNS only | Auto |
| CNAME | `www` | `connect.liefle.com` | DNS only or Proxied | Auto |

**Why grey cloud first:** Caddy needs HTTP-01 or on-demand TLS to reach your VPS directly for certificate issuance. After everything works, you can orange-cloud `connect` to hide the origin IP.

Optional marketing / app records (liefle.com zone):

| Type | Name | Content | Notes |
|------|------|---------|-------|
| CNAME | `@` | Vercel target or `connect.liefle.com` | Apex; CF supports CNAME flattening |

### Test zone: falcon.codes

Repeat the same steps for **falcon.codes** in Cloudflare (separate zone):

| Type | Name | Content | Proxy status |
|------|------|---------|--------------|
| A | `connect` | `195.35.1.18` | DNS only (grey) |
| CNAME | `*` | `cname.vercel-dns.com` | Auto | Trial subdomains (`myshop.falcon.codes`) |

Verify:

```bash
dig +short A connect.falcon.codes
# 195.35.1.18
```

Save each record.

Verify from your laptop:

```bash
dig +short A connect.liefle.com
# 195.35.1.18

dig +short CNAME www.liefle.com
# connect.liefle.com (if you set it)
```

---

## Step 3 — SSL/TLS mode (when using orange cloud)

When you switch `connect.liefle.com` to **Proxied** (orange cloud):

1. Cloudflare → **SSL/TLS** → Overview
2. Set mode to **Full (strict)**
3. Caddy on the VPS must already have a valid cert for `connect.liefle.com`

If you see redirect loops or 525 errors, temporarily set grey cloud, fix Caddy certs, then re-enable orange cloud.

---

## Step 4 — Deploy proxy on VPS

On the VPS (`195.35.1.18`):

```bash
# From your laptop (after editing .env)
cd liefle-proxy
cp .env.example .env
./deploy.sh
```

Or manually on the VPS:

```bash
ssh root@195.35.1.18
mkdir -p /opt/liefle-proxy && cd /opt/liefle-proxy
# copy files, then:
docker compose up -d --build
```

Test:

```bash
curl -I https://connect.liefle.com
# HTTP/2 200 — "Liefle domain connect..."
```

---

## Step 5 — Customer domain flow (what users do)

When a user connects `www.mybrand.com` in the Liefle dashboard:

### DNS at their registrar

| Type | Name | Value |
|------|------|-------|
| CNAME | `www` | `connect.liefle.com` |
| TXT | `_liefle` | `verify=<token-from-dashboard>` |

### Your backend (later)

1. Verify TXT record via DNS lookup
2. Call allow-api to permit TLS:

```bash
curl -X POST http://127.0.0.1:8080/api/domains \
  -H "Authorization: Bearer $ALLOW_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"domain":"www.mybrand.com"}'
```

3. Customer visits `https://www.mybrand.com` → Caddy issues cert → proxies to Vercel

### If customer uses Cloudflare for their domain

Tell them to set the CNAME to **DNS only** (grey cloud) initially. Orange cloud can work with **Full (strict)** once origin certs are stable.

---

## Step 6 — Hide VPS IP (optional, recommended)

After proxy works with grey cloud:

1. Cloudflare DNS → `connect` A record → toggle **Proxied** (orange)
2. SSL/TLS → **Full (strict)**
3. Caddy already blocks `Host: 195.35.1.18` in the Caddyfile

Visitors see Cloudflare IPs, not `195.35.1.18`.

Advanced: firewall 443 to Cloudflare IP ranges only — see https://www.cloudflare.com/ips/

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `connect.liefle.com` doesn't resolve | Nameservers not updated at registrar |
| Connection refused on 443 | Docker/Caddy not running; check `docker compose ps` |
| Cert error for customer domain | Domain not in allow-api; add via POST /api/domains |
| Vercel 404 | Wrong Host header — check Caddy `header_up Host {host}` |
| 525 SSL error with orange cloud | Set SSL mode Full (strict); ensure Caddy has origin cert |
| Port 80/443 already in use | CloudPanel conflict — see plan/vps-infra/02-reverse-proxy-hands-on.md |

---

## Quick reference

| Resource | Value |
|----------|-------|
| VPS IP | `195.35.1.18` |
| Connect hostname (prod) | `connect.liefle.com` |
| Connect hostname (test) | `connect.falcon.codes` |
| Customer CNAME target | `connect.liefle.com` |
| Trial subdomains | `*.falcon.codes` |
| Vercel origin | `liefle.vercel.app` (set in `.env`) |
| Allow API (local) | `http://127.0.0.1:8080` |
