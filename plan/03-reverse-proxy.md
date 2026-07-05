# 03 — Reverse Proxy (Hide Vercel from Customer DNS)

## Problem you’re solving

If you tell customers: “Point CNAME to `cname.vercel-dns.com`” — they see Vercel in their DNS panel. You also tie your brand to Vercel’s infrastructure.

**Better story:** “Point CNAME to `connect.liefle.com`” — everything looks like Liefle.

Technically: customer DNS → **your VPS** → **Vercel origin** → Next.js app.

---

## Architecture

```
Customer browser
      │
      │  https://www.client.com
      ▼
┌──────────────────┐
│  DNS at registrar │  CNAME www → connect.liefle.com
└────────┬─────────┘
         ▼
┌──────────────────┐
│  VPS ($3/mo)      │  Caddy or Nginx
│  connect.liefle.com│  • TLS cert for client.com (on-demand or DNS-01)
│  IP: 1.2.3.4      │  • Lookup tenant in DB/cache
└────────┬─────────┘  • Proxy_pass to Vercel
         │
         │  Host: www.client.com  (critical!)
         ▼
┌──────────────────┐
│  Vercel           │  Your Next.js deployment
│  liefle.vercel.app│  Middleware resolves tenant by Host
└──────────────────┘
```

---

## Why Caddy on the VPS (recommended for you)

| Tool | Pros | Cons |
|------|------|------|
| **Caddy** | Auto HTTPS, simple config, on-demand TLS | Less docs than Nginx |
| **Nginx** | Every tutorial on earth | Manual cert management unless + Certbot |
| **Cloudflare SaaS** | No VPS | Costs money at scale; vendor lock |

For a $3 VPS and solo dev: **Caddy 2**.

---

## Step-by-step: VPS setup

### 1. Buy VPS

- Hetzner CX22 (~€4), DigitalOcean $4 droplet, Vultr $3.50
- Ubuntu 24.04 LTS
- Note the **static IPv4**

### 2. DNS for your infrastructure

At your registrar (Cloudflare recommended):

| Type | Name | Value |
|------|------|-------|
| A | `connect` | `1.2.3.4` (VPS IP) |
| A | `proxy` | `1.2.3.4` (same, alias) |
| CNAME | `www` on marketing | Vercel or `connect` depending on setup |

Customers will use: **`connect.liefle.com`** as their CNAME target.

### 3. Install Caddy

```bash
sudo apt update && sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install caddy
```

### 4. Caddyfile (starting point)

Save as `/etc/caddy/Caddyfile`:

```caddy
{
	# On-demand TLS: only issue cert if your API says domain is allowed
	on_demand_tls {
		ask http://127.0.0.1:8080/allow-domain
	}
}

# Your proxy entry hostname (optional landing)
connect.liefle.com {
	respond "Liefle domain connect — point your CNAME here" 200
}

# Catch-all: any customer domain hitting this server
:443 {
	tls {
		on_demand
	}

	reverse_proxy https://liefle.vercel.app {
		header_up Host {host}
		header_up X-Forwarded-Host {host}
		header_up X-Real-IP {remote_host}
	}
}
```

**Important:** Replace `liefle.vercel.app` with your actual Vercel deployment hostname.

### 5. Domain allow API (security)

On-demand TLS must **not** issue certs for random domains pointing at your IP ( attackers could abuse your IP for free SSL).

Run a tiny sidecar (Node/Python) on `127.0.0.1:8080`:

```
GET /allow-domain?domain=www.client.com
→ 200 if domain exists in your DB and is verified
→ 403 otherwise
```

Caddy calls this before issuing a certificate.

**POC shortcut:** Skip on-demand TLS initially; use **wildcard + manual domain list** in Caddy — only for your own test domains. Add allow API before public launch.

### 6. Vercel configuration

In Vercel project → Settings → Domains:

- Add `liefle.com`, `*.falcon.codes` (wildcard if plan allows)
- For custom domains: you may add them via **Vercel API** when customer verifies, OR rely on Host header routing if using a single deployment (see below)

**Two strategies:**

| Strategy | How | Vercel Pro needed? |
|----------|-----|-------------------|
| **A. Add each domain in Vercel** | API call on verify | Hobby: limited domains; Pro: more |
| **B. Single origin, middleware routing** | All hosts hit one deployment; Next middleware maps Host → tenant | Works on Hobby; proxy sends Host |

For MVP, **Strategy B** + proxy is common. Vercel sees `Host: client.com` and your middleware loads the right site.

Confirm Vercel accepts the forwarded Host (test with `curl -H "Host: test.com" https://liefle.vercel.app`).

### 7. Firewall

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

---

## Request flow (what Next.js must do)

```typescript
// middleware.ts (concept)
const host = request.headers.get('host')?.replace(/^www\./, '');
const tenant = await getTenantByDomain(host);
if (!tenant) return NextResponse.redirect('https://liefle.com');
// rewrite to tenant site route
return NextResponse.rewrite(new URL(`/site/${tenant.slug}`, request.url));
```

---

## SSL options for customer domains

| Method | Customer DNS | Difficulty |
|--------|--------------|------------|
| **CNAME to connect.liefle.com** | CNAME `www` → `connect.liefle.com` | Easy; Caddy on-demand TLS |
| **A record to VPS IP** | A `@` → `1.2.3.4` | Need apex proxy + on-demand TLS |
| **NS delegation** | NS `@` → `ns1.liefle.com` | Full control; harder for customers; use later for “we manage DNS” tier |

**MVP recommendation:** Ask for **`www` CNAME** only. Apex (`client.com` without www) can redirect via registrar or add A record later.

---

## Failure modes to plan for

1. **Customer misconfigured DNS** → Dashboard shows “Pending” + dig instructions
2. **Cert issuance fails** → Log in Caddy; check allow API
3. **VPS down** → All custom domains down; subdomain on Vercel still works as fallback
4. **Too many domains on one VPS** → ~thousands fine for proxy; bottleneck is Vercel/serverless limits first

---

## When to upgrade infrastructure

| Signal | Action |
|--------|--------|
| VPS CPU > 60% sustained | Second proxy + DNS round-robin or Cloudflare load balancing |
| Vercel bandwidth limits | Cloudflare in front of proxy (orange cloud) |
| Need apex + www + email MX on same domain | NS delegation product tier |
| 100+ paying customers | Consider managed proxy (Cloudflare for SaaS) |

---

## Future `liefle-proxy` repo structure

```
liefle-proxy/
  caddy/
    Caddyfile
  allow-api/
    main.go or main.ts   # /allow-domain
  docker-compose.yml     # optional
  deploy.sh              # rsync + systemctl reload caddy
  README.md
```

Keep proxy config in git; deploy with SSH. No customer data on VPS except logs.

Next: [04-dns-and-domains.md](./04-dns-and-domains.md)
