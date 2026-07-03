# 04 — DNS & Custom Domains (Customer-Facing)

## What the customer experiences

1. Dashboard: “Connect your domain”
2. They enter `www.mybrand.com`
3. You show **exactly one** DNS record to add
4. They click **Verify**
5. Status: Pending → Verified → Live (with HTTPS)

Keep copy simple. Most users fail on step 3 if you show three options.

---

## Recommended MVP: CNAME method

**Tell the customer:**

| Field | Value |
|-------|-------|
| Type | CNAME |
| Name / Host | `www` |
| Value / Points to | `connect.liefle.io` |
| TTL | 3600 (or Auto) |

**Why www first:**
- CNAME at `www` is supported everywhere
- Apex (`@`) cannot be CNAME on many registrars (needs A record or ALIAS)
- You avoid “email broke because they changed NS” support tickets

**Apex redirect (optional helper text):**  
“Want `mybrand.com` without www? Add a redirect at your registrar from `@` → `https://www.mybrand.com`”

---

## Domain ownership verification (before going live)

Prove they control DNS **before** you issue TLS and route traffic.

### Option A — TXT record (recommended)

| Type | Name | Value |
|------|------|-------|
| TXT | `_liefle` | `verify=<random-token>` |

Your backend:
1. Generate `token` per tenant + domain
2. Poll DNS (Google `8.8.8.8` or Cloudflare DNS API) for TXT
3. On match → mark `domains.status = verified`

### Option B — HTTP file (harder with proxy)

Less ideal when proxy sits in middle. Prefer TXT for MVP.

---

## Subdomain trial (`*.liefle.app`)

**Your DNS (one-time setup):**

| Type | Name | Value |
|------|------|-------|
| CNAME | `*` | `cname.vercel-dns.com` (or your proxy) |

**Flow:**
1. User picks `myshop` → you create tenant slug `myshop`
2. Site live at `https://myshop.liefle.app`
3. Cron deletes after 24h if no payment

No customer DNS step — fastest path to demo.

---

## NS delegation (advanced tier — not MVP)

Your landing page mock shows NS records. That’s a **power user / Pro** feature:

| Type | Name | Value |
|------|------|-------|
| NS | `@` | `ns1.liefle.io` |
| NS | `@` | `ns2.liefle.io` |

**Pros:** You control all records (apex, www, ACME DNS-01).  
**Cons:** Customer may break email if they had existing MX; scary for beginners.

**Ship this in Phase 6+, not POC.**

---

## Database schema (domains)

```sql
CREATE TABLE domains (
  id            UUID PRIMARY KEY,
  tenant_id     UUID NOT NULL REFERENCES tenants(id),
  hostname      TEXT NOT NULL UNIQUE,  -- www.mybrand.com
  status        TEXT NOT NULL DEFAULT 'pending', -- pending | verified | live | error
  verify_token  TEXT,
  verified_at   TIMESTAMPTZ,
  ssl_status    TEXT DEFAULT 'pending',
  created_at    TIMESTAMPTZ DEFAULT now()
);
```

---

## Verify flow (backend steps)

1. User submits `www.mybrand.com`
2. Validate format; reject if already claimed
3. Insert row `status=pending`, generate `verify_token`
4. Show DNS instructions in UI
5. User clicks Verify → server runs DNS lookup:

```bash
dig +short TXT _liefle.mybrand.com
# expect: "verify=abc123"
```

6. If OK → `status=verified`
7. Trigger: notify proxy allow-list (if using on-demand TLS)
8. First HTTPS request → Caddy gets cert → `status=live`

**Automated polling:** Also run a cron every 5 min to check pending domains so user doesn’t have to click Verify twice.

---

## Registrar-specific UI tips

Show collapsible “Help for GoDaddy / Namecheap / Cloudflare” with screenshots later. For MVP, generic table is enough.

**Cloudflare users:** Warn them to set CNAME to “DNS only” (grey cloud) initially if orange cloud causes cert loops — or embrace orange cloud once you understand SSL modes.

---

## What NOT to ask customers to do (MVP)

- ❌ Change nameservers (unless Pro tier)
- ❌ Add 5 different records
- ❌ Point directly to `vercel.app`
- ❌ Edit A record unless they need apex

---

## Testing checklist (you, before launch)

1. Buy cheap domain ($1 promo) on Namecheap
2. Add CNAME `www` → `connect.liefle.io`
3. Add TXT `_liefle` → your token
4. Verify in dashboard
5. `curl -I https://www.yourtestdomain.com` → 200, valid cert
6. Wrong tenant domain → 404, no cert issued (allow API returns 403)

Next: [05-tech-stack.md](./05-tech-stack.md)
