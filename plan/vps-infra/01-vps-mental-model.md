# 01 — VPS Mental Model (Beginner → Operator)

You paid for a **KVM VPS**. Think of it as a real small computer in a datacenter — not shared hosting, not “a folder on someone else’s server.”

---

## What you actually bought

```
┌─────────────────────────────────────────────────────────────┐
│  Datacenter physical server                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Your KVM VPS (virtual machine)                        │  │
│  │  • Ubuntu Linux                                        │  │
│  │  • vCPU, RAM, disk (your $780 plan)                    │  │
│  │  • ONE (or more) public IPv4: 195.35.1.18              │  │
│  │  • CloudPanel installed inside                         │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**KVM** = hardware-style virtualization. Good CPU/RAM isolation from other customers on the same physical machine.

---

## IP addresses explained (the #1 confusion)

### Public IP (`195.35.1.18`)

- Visible on the internet
- What DNS points to when you set an **A record**
- **Limited globally** — your host assigns it; you don’t create new ones in Ubuntu

### Private / “inner” IP (`10.0.0.5`, `172.18.0.2`)

- Used **inside** your VPS (containers, Docker bridge, LXD network)
- **Not** reachable from the internet unless you port-forward
- Great for isolation between sites — **not** a replacement for public IP per customer

### What customers should see

For Liefle, customers configure:

```
CNAME  www  →  connect.liefle.io
```

They never need `195.35.1.18` in your docs. You put the IP only on **your** DNS A record for `connect.liefle.io`.

To **hide** the IP from visitors who inspect traffic: put **Cloudflare** in front (see [04-multiple-ips-and-hiding-ip.md](./04-multiple-ips-and-hiding-ip.md)).

---

## Reverse proxy in one paragraph

A **reverse proxy** is a program on your VPS that:

1. Receives HTTPS requests first (port 443)
2. Reads the **Host** header (`www.client.com`)
3. Forwards the request to the right **backend** (Vercel, or a local CloudPanel site)
4. Returns the response to the visitor

It’s a **smart door**, not the whole house.

```
Visitor → Caddy (your VPS) → Vercel OR local site → back to visitor
```

---

## “VM inside VM” — what’s realistic on a rented KVM?

| Approach | Isolation | Resource limits | Nested KVM? | Best for you |
|----------|-----------|-----------------|-------------|--------------|
| **CloudPanel site user** | Medium (separate Linux user, PHP pool) | Partial | No | Hosting PHP/WordPress sites |
| **LXD container** | High (own root FS, network) | Yes (CPU/RAM/disk) | No | Learning “mini servers” per project |
| **Docker container** | Medium–High | Yes (cgroups) | No | Single-app stacks |
| **Full VM (QEMU/KVM guest)** | Very high | Yes | **Often blocked** on VPS | Homelab, not first choice |

**Recommendation:** Use **LXD** when you want “a small isolated OS-like box” for experiments or one client. Don’t fight nested virtualization unless your provider explicitly allows it (`/dev/kvm` visible inside VPS).

---

## CloudPanel’s role

CloudPanel is a **control panel** — it installs and manages:

- Web server (Nginx/OpenLiteSpeed)
- PHP versions, MySQL/MariaDB
- Site vhosts, SSL (Let’s Encrypt)
- FTP, backups UI

It is **not** a reverse proxy to Vercel by default, but it **can** host local sites while Caddy handles Liefle customer domains.

---

## Traffic types on one VPS

| Traffic | Backend | Managed by |
|---------|---------|------------|
| `liefle.io` marketing | Vercel or local static | Caddy route |
| `*.liefle.app` tenants | Vercel | Caddy → Vercel |
| `www.client.com` (custom) | Vercel | Caddy → Vercel + on-demand TLS |
| `blog.myagency.com` (your WP) | PHP on same VPS | CloudPanel |
| `panel.yourdomain.com` | CloudPanel UI | Port 8443, don’t expose publicly without IP allowlist |

---

## Resource limits (fair sharing on one big VPS)

Linux uses **cgroups** to cap CPU/RAM per container or systemd slice.

Example: Client A container max 1 GB RAM, 50% of one CPU — if their site spikes, **your** main proxy and other sites stay stable.

Tools:

- **LXD** — `limits.cpu`, `limits.memory` per container
- **systemd** — `MemoryMax=` for services
- **CloudPanel** — per-site PHP-FPM pool settings (lighter isolation)

---

## Vocabulary cheat sheet

| Term | Meaning |
|------|---------|
| **Origin** | Backend server (Vercel URL or localhost:8080) |
| **SNI** | TLS feature: many domains on **one IP** (normal) |
| **vhost** | Virtual host — route by domain name |
| **Edge** | First server internet hits (your proxy) |
| **Bind / listen** | Which IP:port a program uses |
| **UFW** | Uncomplicated Firewall on Ubuntu |

Next: [02-reverse-proxy-hands-on.md](./02-reverse-proxy-hands-on.md) — actual commands on your server.
