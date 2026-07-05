# 06 — Analytics & Monitoring Per Site

You want to **trace traffic per domain** on one VPS running many sites through Caddy.

---

## Three layers of analytics

| Layer | Tool | What you learn |
|-------|------|----------------|
| **Edge (Caddy)** | Access logs → GoAccess | Requests per domain, bandwidth, status codes |
| **App (Vercel)** | Vercel Analytics | Liefle SaaS tenant pages (when on Vercel) |
| **Product (your DB)** | Events table | Signups, publishes, domain verifies |

This doc focuses on **edge per-site** on your VPS.

---

## Step 1 — Caddy JSON logging with host label

In Caddyfile global or site blocks:

```caddy
{
	log {
		output file /var/log/caddy/access.log {
			roll_size 100mb
			roll_keep 5
		}
		format json
	}
}
```

Each log line includes `"request":{"host":"www.client.com",...}`.

Ensure log dir:

```bash
sudo mkdir -p /var/log/caddy
sudo chown caddy:caddy /var/log/caddy
sudo systemctl reload caddy
```

---

## Step 2 — GoAccess (terminal dashboard, free)

```bash
sudo apt install -y goaccess

# Real-time TUI
sudo goaccess /var/log/caddy/access.log --log-format=JSON -o /tmp/report.html

# Filter mentally by host, or split logs (below)
```

### Split logs per domain (cleaner)

Use Caddy `log` directive per site:

```caddy
www.client1.com {
	log {
		output file /var/log/caddy/client1.log
	}
	reverse_proxy ...
}
```

Now `client1.log` only has that site.

---

## Step 3 — Simple monthly bandwidth script

```bash
#!/bin/bash
# /opt/liefle-stats/monthly-by-host.sh
LOG=/var/log/caddy/access.log
MONTH=$(date +%Y/%m)
echo "=== Requests by host for $MONTH ==="
grep "$MONTH" "$LOG" 2>/dev/null \
  | jq -r '.request.host' 2>/dev/null \
  | sort | uniq -c | sort -rn | head -20
```

Requires `jq`. Run via cron:

```bash
0 0 1 * * /opt/liefle-stats/monthly-by-host.sh | mail -s "Liefle edge stats" you@email.com
```

---

## Step 4 — Uptime monitoring (external)

Free tiers:

- [UptimeRobot](https://uptimerobot.com) — ping `connect.liefle.com` + 2 client domains
- [Better Stack](https://betterstack.com)

Alerts when VPS or Caddy down — don’t rely on checking manually.

---

## Step 5 — Server health (one glance)

Install netdata (optional, visual):

```bash
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
# access via SSH tunnel only, or IP-restricted port
```

Or minimal:

```bash
# Add to cron every 5 min
echo "$(date) load=$(cut -d' ' -f1-3 /proc/loadavg) mem=$(free -m | awk '/Mem:/ {print $3}')" >> /var/log/vps-health.log
```

---

## Step 6 — Liefle product analytics (later)

When SaaS app exists:

- Plausible or Umami self-hosted in LXD (privacy-friendly)
- Or embed Plausible script per tenant site from `published_json`

Per-tenant on Vercel: each site includes analytics ID in template config.

---

## Security monitoring

```bash
sudo apt install -y fail2ban
sudo systemctl enable --now fail2ban

# SSH brute force
sudo fail2ban-client status sshd
```

CloudPanel may ship its own rules — don’t duplicate blindly.

---

## Dashboard dream (Phase 2)

Build small Liefle admin page that:

1. SSHes or reads log files via agent
2. Parses request counts per `domains.hostname`
3. Shows in your dashboard next to “domain verified” status

Not MVP — edge logs + GoAccess enough for learning.

Next: [07-learning-checklist.md](./07-learning-checklist.md)
