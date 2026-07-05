# 05 — CloudPanel + Liefle Architecture

You already paid for CloudPanel hosting workflow. **Keep it** for WordPress/PHP sites; add **Caddy** as the Liefle edge for Vercel-bound traffic.

---

## Recommended layout on your $780 VPS

```
┌─────────────────────────────────────────────────────────────┐
│ VPS 195.35.1.18                                              │
│                                                              │
│  Caddy :443 ─────────────────────────────────────────────  │
│    │                                                         │
│    ├─ *.falcon.codes / custom domains → Vercel (Liefle SaaS)  │
│    ├─ agency-wp.com → 127.0.0.1:8080 (CloudPanel nginx)     │
│    └─ connect.liefle.com → status / docs                     │
│                                                              │
│  CloudPanel :8443 ─ admin UI (restrict by IP if possible)   │
│                                                              │
│  MySQL/MariaDB ─ CloudPanel managed databases               │
│                                                              │
│  LXD (optional) ─ sandboxes, test stacks, isolated clients    │
└─────────────────────────────────────────────────────────────┘
```

---

## What CloudPanel is good at

- Click-to-add WordPress / PHP site
- MySQL databases, backups, FTP
- Let’s Encrypt for **local** sites
- Multiple PHP versions

## What CloudPanel is NOT (you add)

- On-demand TLS for **unlimited customer domains** pointing at Liefle → **Caddy**
- Forwarding to Vercel with tenant Host routing → **Caddy**
- Container orchestration → **LXD/Docker**

---

## Avoid breaking CloudPanel

| Do | Don't |
|----|-------|
| Snapshot before nginx port changes | `apt remove nginx` blindly |
| Test Caddy on one subdomain first | Bind two programs to :443 without plan |
| Use CloudPanel for WP you host | Move Liefle app off Vercel onto VPS yet (early) |
| Keep panel on 8443 | Expose 8443 to whole internet without IP allowlist |

### Restrict CloudPanel admin

```bash
# UFW: only your home IP can reach panel (replace x.x.x.x)
sudo ufw delete allow 8443/tcp
sudo ufw allow from YOUR.HOME.IP.ADDRESS to any port 8443 proto tcp
```

---

## Per-site resource limits in CloudPanel

In site settings (varies by version):

- **PHP-FPM** — `pm.max_children`, `memory_limit`
- **Process user** — each site runs as separate system user (basic isolation)

For hard caps, move heavy/untrusted site to **LXD container**.

---

## Two product lines on one machine

| Product | Stack | Domain example |
|---------|-------|----------------|
| **Liefle SaaS** | Vercel + Caddy proxy | `client.com` → Vercel |
| **Headless WP track** | CloudPanel WP + export plugin | `wp.client.com` on VPS |
| **Your experiments** | LXD | `lab.internal` via Caddy |

Billing isolation later: separate Stripe products; technically same VPS is fine until CPU saturated.

---

## Disk & RAM budgeting (example for 16 GB RAM VPS)

| Consumer | Allocation |
|----------|------------|
| OS + Caddy | 1 GB |
| CloudPanel + MySQL | 4–6 GB |
| 3–5 WP sites | 2–4 GB |
| LXD lab containers | 2–4 GB |
| Headroom | 20% free |

Monitor:

```bash
htop
df -h
sudo du -sh /home/*/htdocs/* 2>/dev/null
```

---

## Upgrade path when VPS fills up

1. Move Liefle app traffic to Vercel (already planned) — VPS stays edge-only (light)
2. Move heavy WP to container with strict limits
3. Buy extra IPs, not extra $780 servers
4. Second cheap VPS as **secondary proxy** only when needed

Your expensive KVM stays the **control plane** + DB + WP hosting; edge proxy work is lightweight.

Next: [06-analytics-and-monitoring.md](./06-analytics-and-monitoring.md)
