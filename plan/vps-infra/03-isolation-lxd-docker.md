# 03 — Isolation: LXD & Docker (“VM inside VPS”)

You want **separate boxes** on one physical VPS — limit CPU/RAM, sandbox experiments, maybe one container per client site.

**Best tool on a rented KVM VPS: LXD** (Linux containers that feel like lightweight VMs).  
**Also learn: Docker** for single-app stacks.

**Avoid first:** Installing Proxmox on your only production VPS (replaces Ubuntu, breaks CloudPanel unless you rebuild).

---

## LXD vs Docker vs full VM

| | LXD | Docker | Full VM (nested KVM) |
|---|-----|--------|---------------------|
| Feels like | Mini Ubuntu server with `ssh` | One app per container | Real separate machine |
| Isolation | Strong | Good | Strongest |
| Resource limits | Built-in | Built-in | Built-in |
| systemd inside | Yes | Usually no | Yes |
| On typical VPS | ✅ Works | ✅ Works | ⚠️ Often disabled |
| Learning sysadmin | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ if allowed |

---

## Check if nested KVM is even allowed (optional)

```bash
# On your VPS
ls -l /dev/kvm 2>/dev/null && echo "nested KVM device present" || echo "no nested KVM"
egrep -c '(vmx|svm)' /proc/cpuinfo
sudo apt install -y cpu-checker 2>/dev/null; kvm-ok 2>/dev/null
```

If `/dev/kvm` missing **inside** your VPS, your provider blocks nested virtualization — **use LXD**, don’t fight it.

---

## Install LXD on Ubuntu (Step-by-step)

### Step 1 — Install

```bash
sudo snap install lxd
sudo lxd init
```

Answer prompts (defaults OK for learning):

- Would you like to use LXD clustering? **no**
- Storage pool: **dir** or **zfs** if available
- IPv4 network: **yes** (creates `lxdbr0` bridge — **private** 10.x network)
- IPv6: optional

### Step 2 — First container (Ubuntu 24.04)

```bash
lxc launch ubuntu:24.04 client-a
lxc list
lxc exec client-a -- bash
# inside container:
apt update && apt install -y nginx
echo "Client A isolated site" > /var/www/html/index.html
exit
```

### Step 3 — Resource limits (the hardware cap you wanted)

```bash
lxc config set client-a limits.cpu 1
lxc config set client-a limits.memory 1GB
lxc config set client-a limits.memory.enforce true
```

Client A cannot eat your whole $780 server.

### Step 4 — Publish container site through Caddy

**Option A — Proxy to container private IP:**

```bash
lxc list client-a -c n4
# note 10.x address, e.g. 10.45.67.10
```

Caddyfile:

```caddy
client-a.example.com {
	reverse_proxy 10.45.67.10:80
}
```

**Option B — LXD proxy device (port forward):**

```bash
lxc config device add client-a http proxy listen=tcp:0.0.0.0:8081 connect=tcp:127.0.0.1:80
```

Only Caddy faces the public internet; container stays on private network.

---

## Docker quick path (alternative)

```bash
sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER
# re-login SSH

mkdir -p ~/stack/client-b && cd ~/stack/client-b
cat > docker-compose.yml <<'EOF'
services:
  web:
    image: nginx:alpine
    ports:
      - "127.0.0.1:8082:80"
    deploy:
      resources:
        limits:
          cpus: "0.50"
          memory: 512M
EOF
docker compose up -d
```

Caddy:

```caddy
client-b.example.com {
	reverse_proxy 127.0.0.1:8082
}
```

---

## Network diagram (one VPS)

```
                    PUBLIC INTERNET
                           │
                    195.35.1.18 :443
                           │
                    ┌──────▼──────┐
                    │    Caddy    │  ← only public entry
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           │               │               │
    ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
    │ Vercel      │ │ LXD         │ │ CloudPanel  │
    │ (external)  │ │ 10.0.0.10   │ │ 127.0.0.1   │
    │             │ │ client-a    │ │ :8080       │
    └─────────────┘ └─────────────┘ └─────────────┘
         PRIVATE / INTERNAL — not directly exposed
```

**Inner IP** = `10.x` inside LXD. **Public** = only what Caddy publishes.

---

## When to use what for Liefle

| Use case | Tool |
|----------|------|
| Liefle SaaS frontend | Vercel (not container) |
| Reverse proxy edge | Caddy on host |
| Your agency WordPress | CloudPanel (simplest) |
| Experiment / untrusted PHP plugin | LXD container |
| CI runner, mail server, Redis | LXD or Docker |
| Per-client full root access | LXD + resource limits (not nested VM) |

---

## Snapshots (undo button)

```bash
lxc snapshot client-a before-wp-install
lxc restore client-a before-wp-install
```

Provider snapshot = whole VPS; LXD snapshot = one container.

---

## Learning exercises

1. [ ] Create 2 LXD containers with different RAM limits
2. [ ] Serve different `index.html` on each via Caddy hostname
3. [ ] Kill CPU inside one container — verify other sites still respond
4. [ ] Delete container — host unchanged

Next: [04-multiple-ips-and-hiding-ip.md](./04-multiple-ips-and-hiding-ip.md)
