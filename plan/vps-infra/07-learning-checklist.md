# 07 — VPS Learning Checklist (Do In Order)

Your server: Ubuntu + CloudPanel, IP `195.35.1.18`.  
**Rule:** snapshot before each major phase.

---

## Phase 0 — Know your box (30 min)

1. [ ] SSH in: `ssh root@195.35.1.18`
2. [ ] Run `curl -4 ifconfig.me` — confirm public IP
3. [ ] Run `free -h`, `df -h`, `nproc` — write specs in a note
4. [ ] Run `sudo ss -tlnp | grep -E ':80|:443|:8443'` — who owns ports?
5. [ ] Create **provider snapshot** labeled `before-caddy`
6. [ ] Read [01-vps-mental-model.md](./01-vps-mental-model.md)

**Win:** You can explain public vs private IP out loud.

---

## Phase 1 — Firewall & hygiene (45 min)

7. [ ] `sudo ufw` setup (22, 80, 443, 8443) — [02-reverse-proxy-hands-on.md](./02-reverse-proxy-hands-on.md)
8. [ ] `sudo apt update && sudo apt upgrade -y`
9. [ ] Create non-root sudo user; test login; disable root SSH password (key only) when ready
10. [ ] Install `fail2ban`
11. [ ] Restrict CloudPanel `:8443` to your home IP (optional but smart)

**Win:** `sudo ufw status` looks intentional.

---

## Phase 2 — Caddy hello world (1–2 hours)

12. [ ] Install Caddy
13. [ ] DNS: `connect.yourdomain.com` A → `195.35.1.18`
14. [ ] Caddyfile: `connect.yourdomain.com { respond "OK" 200 }`
15. [ ] Resolve CloudPanel port conflict (plan maintenance if needed)
16. [ ] `curl -I https://connect.yourdomain.com` works with valid cert

**Win:** Screenshot HTTPS “OK” in browser.

---

## Phase 3 — Reverse proxy to Vercel (1–2 hours)

17. [ ] Add Vercel site block in Caddyfile
18. [ ] Test domain CNAME → your connect hostname
19. [ ] Verify `Host` header with `curl -H "Host: ..."`
20. [ ] Read [../03-reverse-proxy.md](../03-reverse-proxy.md) product section

**Win:** Your test domain shows Vercel app through your VPS.

---

## Phase 4 — On-demand TLS + allow API (2–3 hours)

21. [ ] Python allow API on `127.0.0.1:8080`
22. [ ] Caddy `on_demand_tls` + catch-all `:443`
23. [ ] Test: allowed domain gets cert; random domain gets 403

**Win:** You understand why open proxy = dangerous.

---

## Phase 5 — LXD isolation lab (2–3 hours)

24. [ ] `sudo snap install lxd && sudo lxd init`
25. [ ] Launch `client-a` container with 1GB RAM limit
26. [ ] Nginx hello page inside container
27. [ ] Caddy route `test-a.yourdomain.com` → container private IP
28. [ ] Snapshot container; break it; restore

**Win:** Two isolated sites on one VPS.

---

## Phase 6 — Extra IPs (when provider responds)

29. [ ] Email host: request 2 additional IPv4 on same VM
30. [ ] Add IPs in netplan; `ip addr show` confirms
31. [ ] Caddy `bind` directive for one client test domain
32. [ ] Document IP → client mapping in a spreadsheet

**Win:** Two different public IPs hit same VPS, different sites.

---

## Phase 7 — Hide origin IP (1 hour)

33. [ ] Cloudflare account; add domain
34. [ ] Orange-cloud `connect.yourdomain.com`
35. [ ] SSL Full (strict) on Cloudflare
36. [ ] Block direct IP Host in Caddy (optional)

**Win:** `ping connect.yourdomain.com` shows Cloudflare IP, not yours.

---

## Phase 8 — Analytics (1 hour)

37. [ ] Enable Caddy JSON access log
38. [ ] Install GoAccess
39. [ ] Per-site log file for one test domain
40. [ ] UptimeRobot monitor on connect hostname

**Win:** You see request count for one domain this week.

---

## Phase 9 — CloudPanel coexistence (ongoing)

41. [ ] One WP site on CloudPanel proxied through Caddy
42. [ ] Document which domains go Vercel vs local
43. [ ] Backup CloudPanel site weekly

**Win:** WP on same box as Liefle proxy — no conflict.

---

## When stuck — search these

- `caddy reverse_proxy host header vercel`
- `cloudpanel nginx change port 8080`
- `ubuntu netplan secondary ip address`
- `lxd limits.memory container`
- `caddy on_demand_tls ask`
- `cloudflare full strict origin certificate caddy`
- `ufw allow from specific ip to port`

---

## What NOT to do yet

- ❌ Proxmox on production VPS
- ❌ Kubernetes
- ❌ Nested VMs without provider permission
- ❌ Exposing MySQL port 3306 to internet
- ❌ Running Liefle Postgres on same VPS before backups exist

---

## Definition of done (server operator level)

You’re ready to run Liefle edge traffic when:

✅ Caddy proxies Vercel with customer domains  
✅ CloudPanel still works for your WP sites  
✅ UFW + fail2ban enabled  
✅ You created at least one LXD container with limits  
✅ You know how to get extra IPs from your host  
✅ Snapshot rollback tested once  

That’s real sysadmin progress on the machine you already own.
