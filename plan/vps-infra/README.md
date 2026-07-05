# VPS Infrastructure — Learning & Operations Plan

Your KVM VPS (`195.35.1.18`) is the **edge server** for Liefle: reverse proxy, optional local sites via CloudPanel, isolation labs, and per-site analytics.

**Read in order:**

| # | Document | Topic |
|---|----------|--------|
| 1 | [01-vps-mental-model.md](./01-vps-mental-model.md) | IPs, isolation, what software does what |
| 2 | [02-reverse-proxy-hands-on.md](./02-reverse-proxy-hands-on.md) | **Step-by-step** Caddy + CloudPanel on your box |
| 3 | [03-isolation-lxd-docker.md](./03-isolation-lxd-docker.md) | “VM inside VPS” without buying new hardware |
| 4 | [04-multiple-ips-and-hiding-ip.md](./04-multiple-ips-and-hiding-ip.md) | Separate IP per site + hide `195.35.1.18` |
| 5 | [05-cloudpanel-architecture.md](./05-cloudpanel-architecture.md) | CloudPanel + proxy + site limits |
| 6 | [06-analytics-and-monitoring.md](./06-analytics-and-monitoring.md) | Per-site traffic, logs, dashboards |
| 7 | [07-learning-checklist.md](./07-learning-checklist.md) | Numbered tasks for your $780 server |

Also see: [../03-reverse-proxy.md](../03-reverse-proxy.md) (product-focused proxy for Vercel).

---

## Your situation (snapshot)

| Item | Value |
|------|--------|
| Public IPv4 | `195.35.1.18` (example — verify with `curl -4 ifconfig.me` on the VPS) |
| Hypervisor | KVM (full VM, good for learning real server ops) |
| OS | Ubuntu + **CloudPanel** already installed |
| Goal | Reverse proxy, isolation, multiple sites, optional IP per site, analytics |
| Budget mindset | Maximize one strong VPS instead of many cheap ones |

---

## Three layers (memorize this)

```
Layer 1 — EDGE (what the internet hits)
  Caddy or Nginx reverse proxy :443
  Optional: Cloudflare in front (hides raw IP from casual lookup)

Layer 2 — CONTROL (what you use to manage)
  CloudPanel UI :8443
  SSH, UFW firewall, fail2ban

Layer 3 — WORKLOADS (isolated sites / apps)
  CloudPanel sites (PHP/Node)
  LXD containers (experiments, per-customer isolation)
  Forward to Vercel (Liefle SaaS frontend)
```

You do **not** need nested full VMs on day one. Start Layer 1 (reverse proxy), then Layer 3 with LXD when curious.

---

## Honest answer: “Separate public IP per site without new hardware?”

**Partially yes, with limits:**

| Method | Separate public IP? | Cost | Notes |
|--------|---------------------|------|-------|
| **One IP + reverse proxy + hostnames** | No — same IP, different domains | $0 | Standard; customers use `connect.liefle.com`, not the IP |
| **Buy extra IPv4 from your host** | Yes — bind many IPs to **same** VPS | ~$1–5/IP/mo | Best real answer for “dedicated IP per client” |
| **IPv6 /64 subnet** | Yes — many IPv6 addresses | Often free | Not all clients/registrars ready |
| **Cloudflare proxy** | Visitors see Cloudflare IP | Free tier | Hides your IP in browser; power users can still find origin if you leak it |
| **Software-only “inner IP”** | Private IP inside VPS only | $0 | `10.x`, `172.x` — **not** public; for container isolation |

You **cannot** invent new public IPv4 addresses in software. Your provider assigns them. One $780 KVM can **hold** many IPs if the host sells add-ons.

---

## What to install (software map)

| Software | Role | When |
|----------|------|------|
| **Caddy 2** | Reverse proxy, auto HTTPS, on-demand certs | Phase 1 — Liefle Vercel bridge |
| **CloudPanel** | Already have — site + DB + SSL management | Keep for PHP/local sites |
| **UFW + fail2ban** | Firewall, brute-force protection | Day 1 |
| **LXD** | Container “VMs” with CPU/RAM/disk limits | Phase 2 — isolation lab |
| **Docker** | Optional; app packaging | When you prefer compose stacks |
| **GoAccess** or **Matomo** | Per-site analytics | Phase 3 |
| **Cloudflare** | CDN + hide origin IP + DDoS | Strongly recommended |

**Skip for now:** Proxmox (replaces your OS), Kubernetes, full nested KVM guests (often blocked by providers).

---

## Safety before you touch production

1. **Snapshot/backup** the VPS in your provider panel before major changes.
2. CloudPanel owns ports **80/443** today — proxy setup must account for that ([02-reverse-proxy-hands-on.md](./02-reverse-proxy-hands-on.md)).
3. Never paste your root password in chat or git.
4. Test with a **throwaway domain** before customer domains.

Start here: [01-vps-mental-model.md](./01-vps-mental-model.md)
