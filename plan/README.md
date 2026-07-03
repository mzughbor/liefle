# Liefle — Project Plan

This folder is the living blueprint for Liefle: a multi-tenant SaaS where each customer gets a live site on their own domain in minutes.

**Start here, then read in order:**

| # | Document | What it covers |
|---|----------|----------------|
| 1 | [01-architecture-decision.md](./01-architecture-decision.md) | Monolith vs modular — what to build first for MVP |
| 2 | [02-mvp-roadmap.md](./02-mvp-roadmap.md) | Phased roadmap from static landing page → live product |
| 3 | [03-reverse-proxy.md](./03-reverse-proxy.md) | $3 VPS reverse proxy, hide Vercel, SSL, routing |
| 4 | [04-dns-and-domains.md](./04-dns-and-domains.md) | How customers connect domains (CNAME vs NS vs A) |
| 5 | [05-tech-stack.md](./05-tech-stack.md) | Next.js, DB, auth, hosting choices |
| 6 | [06-mvp-checklist.md](./06-mvp-checklist.md) | Numbered step-by-step tasks you can execute today |

---

## One-sentence product

> Customer adds DNS → picks a template → site is live on their domain in under a minute → they edit logo/copy in admin and publish.

---

## Current repo layout (will grow)

```
liefle-front/          ← you are here (static marketing + plan)
  index.html           ← landing page (SEO-optimized for now)
  plan/                ← architecture & execution docs
  wordpress-plugin/    ← parallel track: OSS WP plugin + headless + codegen (see below)
  (future) app/        ← Next.js SaaS app (dashboard + tenant sites)

(future repos or folders)
  liefle-proxy/        ← Caddy/Nginx on $3 VPS
  liefle-api/          ← optional: split backend later
```

---

## Guiding constraints (your stated goals)

- **Cheap to run:** Vercel free/hobby + one $3–5 VPS for reverse proxy until revenue grows.
- **Learn React/Next.js while building:** start simple, add complexity only when pain appears.
- **Hide Vercel from customer DNS:** customer points to *your* proxy hostname/IP, not `*.vercel.app`.
- **Per-tenant data isolation:** each customer gets their own DB (or schema) — design for this early, implement when you have paying users.
- **Validate fast:** ship POC before perfect multi-tenant architecture.

---

## Success criteria for POC (proof of concept)

You can demo this to one real person:

1. They sign up on `liefle.io` (or your domain).
2. They add one DNS record you give them.
3. Within ~60 seconds, `https://their-domain.com` shows a template site.
4. They log into admin, change logo + business name, click Publish.
5. Public site updates without you touching the server manually.

When all five work reliably, you have validated the idea. Everything else (billing, 10 templates, analytics) is Phase 2+.

---

## Parallel track: WordPress headless bridge

If you want the **OSS plugin + export JSON + Next template + Vercel + AI codegen** learning path (separate from hosted SaaS MVP), see [`../wordpress-plugin/README.md`](../wordpress-plugin/README.md). The two tracks share templates and codegen later; start one as primary to avoid split focus.
