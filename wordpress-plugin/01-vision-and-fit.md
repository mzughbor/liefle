# 01 — Vision & How This Fits Liefle

## The problem (WordPress side)

Millions of sites run on WordPress. Owners want:

- Modern frontend (fast, React, Vercel, no jQuery theme bloat)
- Keep WP admin for content (they already know it)
- Own hosting / avoid lock-in
- Not pay for another SaaS CMS

**Headless WP** solves this — but today it’s expert-only: REST API, GraphQL, custom Next app, dev team.

## Your solution

An **open-source plugin** that:

1. Lets any WP admin **map content to named keys** (`hero.title`, `about.body`, `contact.email`)
2. **Exports** a versioned JSON file (and optional webhook push)
3. Feeds a **Liefle template** (Next.js) that knows how to read those keys
4. User **deploys template to their Vercel** (free hobby tier)
5. **Static sections** bake export into the build → no DB hit on every page view
6. **Forms / dynamic bits** stay incremental → POST to WP REST, Formspree, or Liefle API later

## Why this is “sexy” for learning (your words)

Each level unlocks a new skill + visible win:

| Win | Skill | Dopamine |
|-----|-------|----------|
| JSON file appears in WP admin | PHP, WP options API | “I built a real plugin” |
| Next page shows WP title | React props, fetch/build | “Headless works” |
| Change WP → re-export → redeploy | CI, static generation | “I control the pipeline” |
| AI renames a component to match keys | LLM + AST | “The machine edited my code” |
| Friend’s blog on Vercel | End-to-end story | “Shipped” |

## Relationship to main SaaS (`../plan/`)

| | SaaS track | WP plugin track |
|---|------------|-----------------|
| **Customer** | Non-technical, no WP | Has WP or agency client |
| **Content storage** | Your Postgres | Their WordPress |
| **Frontend host** | You (Vercel + proxy) | Their Vercel |
| **Revenue** | Subscriptions | Pro templates, AI credits, support, hosted sync |
| **Open source** | Maybe client SDK | **Plugin = OSS marketing** |

**Convergence point:** The **template + codegen + AI patch engine** you build for Track B becomes the engine behind Track A’s “pick a template” — instead of hand-written wizards, you generate tenant sites from structured data (whether source is WP export or your dashboard forms).

## Functional goal (“any site in the world”)

Realistic phasing:

- **v0.1** — Export posts + pages + media URLs for one site
- **v0.5** — Custom key mapper UI (ACF-compatible, native fields)
- **v1.0** — WooCommerce product fields (optional module)
- **v2.0** — Webhook on `save_post` → trigger Vercel redeploy via deploy hook
- **v3.0** — AI suggests key mapping from theme scan

“Any site” is the **direction**, not day-one scope. Ship v0.1 to a real WP install first.

## What you are NOT building (MVP)

- Full page builder inside WP
- Real-time sync without rebuild (that’s Phase 2+ with ISR)
- Replacing WP admin
- Competing with WP Engine headless bundles

## Success criteria (Track B POC)

1. Install plugin on a test WP (LocalWP or cheap host)
2. Map 5 keys across Home + About
3. Export `liefle-export.json`
4. Drop into Next template → `npm run build` → deploy Vercel
5. Public site shows WP content; edit in WP → re-export → redeploy → updated

When that works, invite one WP user from Reddit/Facebook group to try it.

Next: [02-plugin-architecture.md](./02-plugin-architecture.md)
