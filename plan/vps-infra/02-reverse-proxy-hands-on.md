# 02 — Reverse Proxy Hands-On (Your VPS + CloudPanel)

**Target server:** Ubuntu + CloudPanel, public IP `195.35.1.18`  
**Goal:** Caddy as front door → forward Liefle domains to Vercel; CloudPanel sites still work.

---

## Before you start (15 minutes)

SSH into your VPS:

```bash
ssh root@195.35.1.18
```

Run inventory:

```bash
# Who am I on the network?
curl -4 ifconfig.me; echo

# What's using port 80 and 443? (CloudPanel usually owns these)
sudo ss -tlnp | grep -E ':80|:443'

# CloudPanel version / webserver
clpctl --version 2>/dev/null || echo "check CloudPanel docs"

# Disk and RAM (know your budget)
free -h
df -h /
nproc
```

Write down: web server process (nginx/openlitespeed), and whether **80/443 are taken**.

---

## Architecture choice (pick ONE path)

### Path A — Caddy in front, CloudPanel behind (recommended for Liefle + learning)

```
Internet :443 → Caddy → {
  client.com        → https://your-app.vercel.app
  mylocalwp.com     → https://127.0.0.1:8443 (CloudPanel nginx)
  connect.liefle.io → info page or Vercel
}
CloudPanel UI stays on :8443
```

**Pros:** Full control, on-demand TLS for customer domains, one config file.  
**Cons:** Must move CloudPanel off public 80/443 (careful steps below).

### Path B — CloudPanel only, add reverse proxy sites in panel

Use CloudPanel’s **Reverse Proxy** site type (if available in your version) for Vercel targets.  
**Pros:** No port conflict.  
**Cons:** Less flexible for on-demand TLS at scale; panel-centric.

### Path C — Cloudflare → Vercel directly (skip VPS for app traffic)

Use VPS only for mail, WP, experiments; Liefle app on Vercel + Cloudflare.  
**Pros:** Simplest app path.  
**Cons:** Doesn’t use your $780 box for Liefle edge (still fine for learning WP hosting).

**This guide implements Path A** — the real learning path.

---

## Phase 1 — Backup & DNS prep

### Step 1 — Provider snapshot

In your host’s control panel (Hetzner, OVH, etc.): **Create snapshot** of the VM.

### Step 2 — Create DNS records (Cloudflare recommended)

| Type | Name | Value | Proxy |
|------|------|-------|-------|
| A | `connect` | `195.35.1.18` | DNS only (grey) at first* |
| A | `@` or `www` | `195.35.1.18` or Vercel | your choice |

\* For Let’s Encrypt HTTP challenge, grey cloud initially; switch to orange after Caddy works with DNS challenge or on-demand TLS.

### Step 3 — Firewall baseline

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw allow 8443/tcp comment 'CloudPanel'
sudo ufw enable
sudo ufw status verbose
```

Optional: restrict SSH to your home IP later.

---

## Phase 2 — Install Caddy

```bash
sudo apt update
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl

curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg

curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
  | sudo tee /etc/apt/sources.list.d/caddy-stable.list

sudo apt update
sudo apt install -y caddy

caddy version
```

**Do not start Caddy yet** if CloudPanel holds 443.

---

## Phase 3 — Resolve CloudPanel port conflict

CloudPanel and Caddy both want **80** and **443**. Only one listener per port.

### Option 3a — CloudPanel listens internally (typical fix)

1. Open CloudPanel → Settings → check if you can change HTTP/HTTPS ports for **hosted sites** vs panel.
2. Many setups: panel UI = `:8443`, sites = `:443` via nginx.

Inspect nginx:

```bash
sudo nginx -t 2>/dev/null || true
sudo ls /etc/nginx/sites-enabled/ 2>/dev/null || true
# CloudPanel paths may be under /home/clp/ or /etc/nginx/
```

**Goal:** Make CloudPanel’s **site** nginx listen on `127.0.0.1:8080` (HTTP) instead of public `:443`.

This step varies by CloudPanel version. Safe approach:

1. Read CloudPanel docs: “reverse proxy external” or “custom nginx”
2. Or create **new sites only on 8080** for testing while learning

**POC shortcut:** If conflict is too messy, run Caddy on **443** only for `connect.liefle.io` + test domains, leave CloudPanel sites as-is until you schedule maintenance window.

### Option 3b — Use second IP for CloudPanel (if you have/add one)

- `195.35.1.18` → Caddy (Liefle edge)
- `195.35.1.19` (extra IP) → CloudPanel sites directly

See [04-multiple-ips-and-hiding-ip.md](./04-multiple-ips-and-hiding-ip.md).

---

## Phase 4 — First Caddyfile (Vercel proxy only)

Create `/etc/caddy/Caddyfile`:

```caddy
{
	email you@yourdomain.com
	# POC: comment out on_demand_tls until allow API exists
}

# Health check — prove Caddy works
connect.liefle.io {
	respond "Liefle connect OK" 200
}

# Replace with your real Vercel deployment hostname
liefle.vercel.app {
	reverse_proxy https://liefle.vercel.app {
		header_up Host {host}
	}
}

# TEST ONLY — one domain you control
www.yourtestdomain.com {
	reverse_proxy https://liefle.vercel.app {
		header_up Host liefle.vercel.app
		header_up X-Forwarded-Host www.yourtestdomain.com
	}
}
```

Validate and reload:

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl enable caddy
sudo systemctl restart caddy
sudo systemctl status caddy --no-pager
```

---

## Phase 5 — Test from your laptop

```bash
# DNS must point to your VPS first
curl -I https://connect.liefle.io

curl -I https://www.yourtestdomain.com

# Simulate Host header before DNS propagates
curl -I -H "Host: www.yourtestdomain.com" https://195.35.1.18 --resolve www.yourtestdomain.com:443:195.35.1.18 -k
```

**Win condition:** HTTP 200/301/308 from Caddy with valid Let’s Encrypt cert.

---

## Phase 6 — On-demand TLS (production)

When random customer domains point at your IP, you must **not** issue certs for attackers’ domains.

Add to Caddy global block:

```caddy
{
	on_demand_tls {
		ask http://127.0.0.1:8080/allow-domain
	}
}
```

Catch-all site block:

```caddy
:443 {
	tls {
		on_demand
	}
	reverse_proxy https://liefle.vercel.app {
		header_up Host {host}
		header_up X-Forwarded-Host {host}
	}
}
```

Run allow API (minimal Python example):

```python
# /opt/liefle-allow/app.py — run with systemd on 127.0.0.1:8080
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

ALLOWED = {"www.yourtestdomain.com", "www.client.com"}  # later: query Postgres

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        q = parse_qs(urlparse(self.path).query)
        domain = (q.get("domain") or [""])[0].lower()
        if domain in ALLOWED:
            self.send_response(200); self.end_headers()
        else:
            self.send_response(403); self.end_headers()
    def log_message(self, *args): pass

HTTPServer(("127.0.0.1", 8080), H).serve_forever()
```

```bash
sudo apt install -y python3
# create systemd unit liefle-allow.service, then:
sudo systemctl enable --now liefle-allow
```

---

## Phase 7 — Proxy local CloudPanel site (same Caddy)

Once CloudPanel nginx listens on `127.0.0.1:8080`:

```caddy
mywordpress.com {
	reverse_proxy 127.0.0.1:8080
}
```

Caddy gets the public cert; CloudPanel serves the app locally.

---

## Phase 8 — Logs & debug

```bash
# Caddy logs
sudo journalctl -u caddy -f

# Config dump
sudo caddy adapt --config /etc/caddy/Caddyfile --pretty

# TLS issues
sudo caddy list-certificates
```

---

## Common mistakes

| Symptom | Fix |
|---------|-----|
| `bind: address already in use` | CloudPanel still on 443 — resolve Phase 3 |
| Cert fails for customer domain | DNS not pointing here; grey Cloudflare blocking HTTP-01 |
| Vercel 404 | Wrong `Host` header — check `header_up Host` |
| CloudPanel broken | Restore snapshot; redo port change carefully |
| Site works by IP not domain | Missing `server_name` / Caddy site block |

---

## Rollback plan

1. Stop Caddy: `sudo systemctl stop caddy`
2. Restore CloudPanel nginx to 443
3. Provider snapshot restore if needed

---

## What you learned (checklist)

- [ ] Public vs private ports
- [ ] One process owns :443
- [ ] Reverse proxy forwards **Host** header
- [ ] Let’s Encrypt via Caddy
- [ ] On-demand TLS needs allow API
- [ ] CloudPanel + Caddy can coexist with planning

Next: [03-isolation-lxd-docker.md](./03-isolation-lxd-docker.md)
