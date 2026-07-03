# 07 — Vercel Deploy Flow (Free Frontend Hosting)

User owns the frontend; WordPress stays where it is (cheap shared host, LocalWP, WP.com Business, etc.).

## End-to-end flow (manual MVP)

```
1. WP admin: install Liefle Headless Bridge
2. Map keys → Export JSON
3. GitHub: "Use template" → liefle-template-cafe
4. Replace data/liefle-export.json
5. git push
6. Vercel: Import repo → Deploy
7. Optional: custom domain on Vercel (or Caddy proxy from ../plan/)
```

**Time target:** under 30 minutes first time; under 5 minutes after practice.

## Vercel free tier constraints (2026-ish)

- Hobby for personal/non-commercial
- Commercial use → Pro ($20/mo) — user’s choice when they monetize
- Bandwidth and build minutes sufficient for small business sites
- Serverless functions for form proxy if needed

## One-click deploy button (template README)

```markdown
[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/you/liefle-template-cafe)
```

After clone, user still must paste export JSON (or use env var — see below).

## Environment variables (optional pattern)

Instead of committing JSON:

```env
LIEFLE_EXPORT_URL=https://mysite.com/wp-json/liefle/v1/export?key=SECRET
```

Build script fetches:

```typescript
// scripts/fetch-export.ts
const url = process.env.LIEFLE_EXPORT_URL;
const res = await fetch(url);
writeFileSync('data/liefle-export.json', await res.text());
```

**Trade-off:** build depends on WP being up; static commit is simpler for MVP.

## Deploy hook automation

In WP plugin settings:

```
Vercel Deploy Hook URL: https://api.vercel.com/v1/integrations/deploy/...
```

On export save → `wp_remote_post($hook_url)`.

User flow becomes: edit WP → click Export → site rebuilds in ~1 min.

## Custom domain

Two paths:

| Path | Setup |
|------|-------|
| **Direct Vercel** | User adds domain in Vercel dashboard |
| **Liefle proxy** | Same as ../plan/03 — customer CNAME to `connect.liefle.io` |

Track B users are technical enough for Vercel DNS initially.

## Multi-site / agency

One template repo per client (fork) OR monorepo with `sites/client-a/data/export.json`.

Start with **one repo per site** — simpler mental model.

## What “free hosting” means in marketing

Be precise:

- ✅ Vercel hosts the **frontend** free/cheap
- ✅ WP stays on their existing host
- ❌ Not “free WordPress hosting”
- ❌ Not “zero redeploy ever” for static mode

Next: [08-learning-path.md](./08-learning-path.md)
