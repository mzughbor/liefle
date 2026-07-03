# 05 — Template & Code Generator

The **code generator** turns `(template + liefle-export.json)` into a **ready-to-deploy Next.js repo** — or patches an existing clone.

This is the business core alongside the OSS plugin.

## What gets generated

Not a whole app from scratch every time — **slot-based templates**:

```
templates/cafe-next/
├── template.manifest.json      # slots, required keys, component map
├── app/
├── components/
│   ├── Hero.tsx                # expects hero.* keys
│   ├── AboutSection.tsx
│   └── ContactForm.tsx
├── data/
│   └── liefle-export.json      # ← replaced per user
└── scripts/
    └── validate-export.ts
```

## Template manifest

```json
{
  "id": "cafe-next",
  "version": "1.0.0",
  "framework": "next-15-app-router",
  "requiredKeys": [
    "hero.title",
    "hero.subtitle",
    "about.body"
  ],
  "optionalKeys": [
    "hero.image",
    "contact.email"
  ],
  "slots": {
    "hero": { "component": "Hero", "keys": ["hero.title", "hero.subtitle", "hero.image"] },
    "about": { "component": "AboutSection", "keys": ["about.body"] }
  }
}
```

Generator validates export against manifest before deploy.

## Generator CLI (future package: `@liefle/generate`)

```bash
npx @liefle/generate \
  --template cafe-next \
  --export ./liefle-export.json \
  --out ./my-cafe-site
```

Steps inside CLI:

1. Copy template skeleton → `out/`
2. Write `data/liefle-export.json`
3. Run `ajv` schema validation
4. Check all `requiredKeys` present
5. Optional: run `next build` locally
6. Print Vercel deploy instructions

## Hosted “codegen as a service” (monetization)

Web UI flow:

1. Upload export JSON (or connect WP plugin API key)
2. Pick template preview
3. Download zip **or** “Deploy to Vercel” OAuth
4. Paid: custom domain hints, AI slot mapping, remove “Built with Liefle” badge

## Mapping unknown WP → template keys

When export keys don’t match template:

| Strategy | Who |
|----------|-----|
| Manual mapper in WP admin | User |
| Suggest keys from template manifest | Plugin UI |
| AI maps `keys` → `slots` | [06-ai-integration.md](./06-ai-integration.md) |

## Codegen vs hand-written SaaS wizard

Same outcome, different source of truth:

| SaaS (`../plan/`) | WP track |
|-------------------|----------|
| User fills Liefle wizard | User edits WP |
| Data in Postgres | Data in export JSON |
| You render template | They build template on Vercel |

**Shared asset:** React template components + manifest format.

## GitHub template repos

Publish each template as **“Use this template”** repo:

- `liefle-template-cafe`
- `liefle-template-studio`
- `liefle-template-saas`

Plugin docs link: “Download export → clone template → paste JSON → deploy.”

## Validation in CI (user repo)

```yaml
# .github/workflows/liefle.yml
on:
  push:
    paths: ['data/liefle-export.json']
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run validate:export && npm run build
```

Plugin can document this snippet — users feel professional instantly.

Next: [06-ai-integration.md](./06-ai-integration.md)
