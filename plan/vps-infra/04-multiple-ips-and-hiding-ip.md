# 04 — Multiple IPs & Hiding Your Server IP

---

## Truth table (read this first)

| Goal | Possible with software only? | How |
|------|------------------------------|-----|
| Many **domains** on one VPS | ✅ Yes | Reverse proxy + SNI (one IP) |
| Many **public IPv4** on one VPS | ⚠️ Need IPs from host | Buy add-on IPs, bind to same NIC |
| **Hide** IP from website visitors | ✅ Mostly | Cloudflare orange cloud |
| **Hide** IP from determined attacker | ⚠️ Hard | Firewall + CF + no IP leaks in email/DNS |
| **Private inner IP** per container | ✅ Yes | LXD `10.x` — not public |

You **do not** need a second VPS or new $780 server to add IPs — ask your **current provider** for additional IPv4 on the **same** KVM.

---

## Strategy 1 — One IP, many domains (free, default)

`195.35.1.18` serves:

- `connect.liefle.com`
- `www.client1.com`
- `www.client2.com`

Browsers use **domain names**; the IP is shared. This is how most of the internet works.

**Customers never type your IP** — they add CNAME to `connect.liefle.com`.

---

## Strategy 2 — Multiple public IPv4 on one VPS (dedicated IP per client)

### Step 1 — Order extra IPs

In your host panel (example names):

- Hetzner: “Primary IP” + “Additional IP”
- OVH: “Additional IP”
- Often **$1–3/month per IPv4**

Request e.g. 2–5 IPs for learning.

### Step 2 — Bind IPs to Ubuntu

Your host routes extra IPs to the same VM. On VPS:

```bash
ip addr show
# You should see eth0 with 195.35.1.18

# Temporary add (until reboot) — replace with your second IP
sudo ip addr add 195.35.1.19/32 dev eth0

# Persistent (Netplan example — filename varies)
sudo nano /etc/netplan/50-cloud-init.yaml
```

Example netplan snippet (adjust interface name `eth0` → `ens3` etc.):

```yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 195.35.1.18/24
        - 195.35.1.19/32
        - 195.35.1.20/32
      gateway4: 195.35.1.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
```

```bash
sudo netplan apply
ip addr show eth0
```

### Step 3 — Caddy listens per IP OR per domain

**Per domain (still one IP):**

```caddy
client1.com {
	reverse_proxy ...
}
```

**Per IP (client gets “their” IP for A record):**

```caddy
http://195.35.1.19 {
	redir https://www.client1.com{uri}
}

www.client1.com {
	bind 195.35.1.19
	reverse_proxy ...
}
```

Client DNS: `A @ → 195.35.1.19` (their dedicated IP on **your** VPS).

### Step 4 — Track IP ownership in your DB

```sql
-- domains table extension
ALTER TABLE domains ADD COLUMN dedicated_ip TEXT;
-- '195.35.1.19' assigned to client1
```

Automate allow-list + IP assignment in Liefle dashboard later.

---

## Strategy 3 — IPv6 (many addresses, one subscription)

Many hosts give `/64` IPv6 free:

```bash
ip -6 addr show
```

Each site can get `2001:db8:....:site1` — dedicated **IPv6** without extra monthly fee.  
Downside: some users/registrars still IPv4-only.

---

## Strategy 4 — Hide `195.35.1.18` with Cloudflare

### Setup

1. Move `connect.liefle.com` DNS to Cloudflare
2. A record → `195.35.1.18`
3. Toggle **Proxied** (orange cloud)
4. SSL/TLS mode: **Full (strict)** — Caddy must have valid cert on origin

Visitors traceroute to **Cloudflare IPs**, not yours.

### Lock down direct IP access

If someone hits `https://195.35.1.18` directly, they bypass Cloudflare. Mitigate:

```caddy
# Default catch: reject requests with IP as Host
:443 {
	@badHost host 195.35.1.18
	handle @badHost {
		respond "Forbidden" 403
	}
	# ... normal sites
}
```

Also firewall: optional allow **443 only from Cloudflare IP ranges** (advanced; breaks Let's Encrypt HTTP unless DNS challenge).

Cloudflare IP list: https://www.cloudflare.com/ips/

---

## Strategy 5 — “Inner IP” for containers (not public)

LXD network `lxdbr0`:

```
Host:     195.35.1.18 (public)
Container client-a: 10.45.67.10 (private)
Container client-b: 10.45.67.11 (private)
```

Public never sees `10.x`. Caddy maps `client-a.com` → `10.45.67.10:80`.

This is **isolation**, not a substitute for dedicated public IPv4.

---

## Comparison for your Liefle clients

| Tier | DNS instruction | Public sees | Good for |
|------|-----------------|-------------|----------|
| Starter | CNAME → connect.liefle.com | Shared IP + domain | MVP |
| Maker | CNAME → connect.liefle.com + CF proxy | Cloudflare IP | Hide origin |
| Pro | A → dedicated `195.35.1.19` | Unique IPv4 | Client wants own IP in DNS panel |
| Agency | IPv6 or extra IPv4 pool | Unique | Many sites |

---

## Action: email your host support

Template:

> I have KVM VPS at 195.35.1.18. Can I add 3 additional IPv4 addresses routed to the same VM? What is the monthly cost and setup procedure?

Save their answer in this folder as `notes-provider-ips.txt` (gitignore if sensitive).

Next: [05-cloudpanel-architecture.md](./05-cloudpanel-architecture.md)
