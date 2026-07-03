# 01 — Architecture: Monolith vs Modular

## Short answer for MVP

**Build a modular monolith in one Next.js repo on Vercel.**  
Do **not** split into microservices yet. Do **not** run your own app server on the VPS — the VPS is **only** the reverse proxy.

This is the fastest path to validate your idea while keeping costs near zero.

---

## What “monolith” means here

One deployable application that contains:

- Marketing pages (`/`, `/pricing`)
- Auth (`/login`, `/signup`)
- Dashboard (`/dashboard/*`)
- Admin/editor for site content
- API routes (`/api/*`) for save, publish, domain verify
- Tenant site rendering (either subdomain or custom domain)

Everything ships as **one Next.js project**, one Vercel project, one git repo (for now).

```
┌─────────────────────────────────────────────────────────┐
│              Next.js on Vercel (monolith)               │
│  ┌──────────┐ ┌───────────┐ ┌────────┐ ┌─────────────┐ │
│  │ Marketing│ │ Dashboard │ │ Editor │ │ /api routes │ │
│  └──────────┘ └───────────┘ └────────┘ └─────────────┘ │
│                         │                               │
│                    PostgreSQL                           │
│              (one DB, tenant_id column                  │
│               OR separate DB per tenant later)          │
└─────────────────────────────────────────────────────────┘
                          ▲
                          │ HTTPS (Host: customer.com)
┌─────────────────────────┴───────────────────────────────┐
│           Reverse proxy on $3 VPS (Caddy)               │
│   customer.com  →  proxy.liefle.io  →  vercel origin    │
└─────────────────────────────────────────────────────────┘
```

---

## Monolith vs microservices (when each wins)

| Approach | MVP / POC | Scale (1000+ tenants) |
|----------|-----------|------------------------|
| **Modular monolith** (recommended) | ✅ Fastest. One deploy. Easy debugging. Learn Next.js in one place. | Still fine for a long time if DB is indexed well |
| **Split frontend + API** | ⚠️ Slower. Two deploys. Only worth it if Vercel limits bite you | Useful if you need long-running jobs off serverless |
| **Microservices** | ❌ Overkill. You will spend months on plumbing | Maybe later: billing service, email service, render farm |
| **Self-hosted Next on VPS** | ❌ You lose Vercel DX; you manage Node, PM2, updates | Only when unit economics force it |

---

## “Modular monolith” folder structure (target)

Keep boundaries clear inside one repo so you *can* split later without rewriting:

```
src/
  app/
    (marketing)/          # public landing
    (auth)/               # login, signup
    (dashboard)/          # logged-in shell
    (tenant)/             # public rendered sites (by host)
    api/
      domains/
      sites/
      publish/
  lib/
    db/                   # Prisma/Drizzle client
    tenant/               # resolve tenant from Host header
    proxy/                # domain verify tokens
  components/
    editor/
    templates/
```

**Rule:** `lib/tenant` never imports React components. API routes never import dashboard UI. That discipline = easy split later.

---

## Per-tenant DB: when and how

You said each user gets their own DB. Two practical levels:

### Level A — POC (start here)

- **One PostgreSQL** (Neon, Supabase, or Vercel Postgres free tier)
- Every table has `tenant_id`
- Row-level security or app-layer checks always filter by `tenant_id`

**Why:** One connection string, one migration, ships in days.

### Level B — “Own DB per tenant” (after revenue)

- Provision DB when customer upgrades (Neon API, Supabase projects, or schema-per-tenant)
- Store `database_url` encrypted in tenant record
- App opens connection per request based on tenant

**Why wait:** Provisioning automation + backups + migrations × N tenants is real ops work. Not needed to prove “site live in 1 minute.”

**Recommendation:** Design tables with `tenant_id` now; migrate to separate DBs when a customer pays enough to justify it.

---

## What lives where (important)

| Component | Where | Why |
|-----------|-------|-----|
| Next.js app | Vercel | Free tier, SSL at origin, git deploy |
| Reverse proxy | $3 VPS (Hetzner/DigitalOcean/Vultr) | Customer DNS points here; you control routing |
| PostgreSQL | Neon / Supabase / Vercel Postgres | Managed, cheap, backups |
| File uploads (logos) | Vercel Blob / Cloudflare R2 / S3 | Don’t store on VPS |
| Email (verify domain, magic link) | Resend / Postmark | Don't build SMTP |
| Billing | Stripe (Phase 2) | |

**The VPS is NOT your app server for MVP.** It only terminates TLS and forwards to Vercel.

---

## Why not put everything on the VPS?

You know Linux well — tempting to run Node + Postgres + Nginx on one box. For this product:

- Vercel gives you preview deploys, edge, automatic HTTPS to origin
- You’d spend time on systemd, Node versions, disk, backups instead of product
- One VPS failure takes down **all** customer domains if app runs there

Use VPS strength (static IP, always-on proxy) without making it your compute layer yet.

---

## Decision summary

1. **One Next.js monolith** on Vercel for MVP.
2. **One VPS** = reverse proxy only.
3. **One Postgres** with `tenant_id` for POC; separate DBs later.
4. Split repos (`liefle-proxy`, `liefle-api`) only when a specific pain forces it — usually after first paying customers.

Next: [02-mvp-roadmap.md](./02-mvp-roadmap.md)
