# Liefle Headless Bridge — WordPress Plugin Track

**Parallel idea to the main SaaS plan (`../plan/`).**  
Same brand, different wedge: open-source WP plugin → structured export → Next.js template codegen → deploy on Vercel (free tier).

> **Functional north star:** Any WordPress site owner can export their content as a stable key-value map, pick a modern frontend template, and ship a headless site on their own Vercel — without rewriting posts in a new CMS.

---

## Read in order

| # | Document | What it covers |
|---|----------|----------------|
| 1 | [01-vision-and-fit.md](./01-vision-and-fit.md) | Why this path exists, how it connects to Liefle SaaS |
| 2 | [02-plugin-architecture.md](./02-plugin-architecture.md) | Open-source WP plugin structure (100% GPL) |
| 3 | [03-export-schema.md](./03-export-schema.md) | Key-value JSON contract between WP and Next |
| 4 | [04-static-vs-forms.md](./04-static-vs-forms.md) | Static sections vs incremental form/API data |
| 5 | [05-code-generator.md](./05-code-generator.md) | Template repo, codegen, “slot” system |
| 6 | [06-ai-integration.md](./06-ai-integration.md) | AI reads repo + WP export → patches components |
| 7 | [07-vercel-deploy-flow.md](./07-vercel-deploy-flow.md) | From export zip → live URL |
| 8 | [08-learning-path.md](./08-learning-path.md) | ADHD-friendly dopamine ladder (levels, wins) |
| 9 | [09-roadmap-checklist.md](./09-roadmap-checklist.md) | Numbered build steps |

---

## Two products, one universe

```
┌─────────────────────────────────────────────────────────────────┐
│                        LIEFLE UNIVERSE                          │
├────────────────────────────┬────────────────────────────────────┤
│  Track A: ../plan/         │  Track B: wordpress-plugin/ (here)│
│  Full SaaS                 │  Headless bridge + codegen          │
│  You host everything       │  User keeps WP + owns Vercel        │
│  $1–6/mo hosted builder    │  Plugin free; paid templates/AI?    │
│  Fastest revenue POC       │  Fastest OSS + learning POC         │
└────────────────────────────┴────────────────────────────────────┘
                              │
                    Shared later: template library, design tokens,
                    reverse proxy patterns, AI patch engine
```

**You can run both tracks.** They teach different skills and merge when the codegen + template system from Track B feeds Track A’s template picker.

---

## One-sentence pitch (Track B)

> Install our WP plugin → map your pages to sections → export `liefle.json` → paste into a Next template → deploy to Vercel → static marketing pages load instantly; forms still talk to WP or a webhook.

---

## Repo layout (this folder grows into code)

```
wordpress-plugin/
  README.md                 ← you are here
  docs/                     ← (optional) move *.md here later
  plugin/                   ← future: actual WP plugin (PHP)
    liefle-headless-bridge/
      liefle-headless-bridge.php
      includes/
      admin/
  schema/
    liefle-export-v1.schema.json
  examples/
    sample-export.json
  templates/                ← future: starter Next.js repos (git submodules or separate repos)
    studio-next/
    cafe-next/
```

---

## Honest complexity note

This is **more moving parts** than “wizard + publish” in `../plan/`.  
The payoff is **huge learning surface** (PHP, WP APIs, JSON schema, React, codegen, AI tooling, Vercel) and an **open-source wedge** into the WordPress ecosystem (millions of sites).

Start small: **export one page’s title + body + featured image** → render on one Next page. That’s Level 1 in [08-learning-path.md](./08-learning-path.md).
