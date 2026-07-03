# 03 — Export Schema (Key-Value Contract)

The export file is the **single contract** between WordPress, the Next template, the codegen tool, and AI.  
Version it strictly: breaking changes → bump `schemaVersion`.

## File name & location in Next repo

```
/data/liefle-export.json          # committed or CI artifact
/schema/liefle-export-v1.schema.json
```

At build time: `import siteData from '@/data/liefle-export.json'`

## Top-level shape

```json
{
  "schemaVersion": 1,
  "exportedAt": "2026-07-04T12:00:00Z",
  "source": {
    "siteUrl": "https://myblog.wordpress.com",
    "wpVersion": "6.5",
    "pluginVersion": "0.1.0",
    "locale": "en_US"
  },
  "site": {
    "name": "My Brand",
    "tagline": "Coffee and code",
    "language": "en"
  },
  "keys": {
    "hero.title": "Welcome",
    "hero.subtitle": "We ship fast",
    "hero.image": "https://example.com/wp-content/uploads/hero.jpg",
    "about.body": "<p>HTML from WP content...</p>",
    "contact.email": "hello@brand.com",
    "seo.home.title": "My Brand — Home",
    "seo.home.description": "..."
  },
  "sections": {
    "hero": { "type": "static", "keys": ["hero.title", "hero.subtitle", "hero.image"] },
    "about": { "type": "static", "keys": ["about.body"] },
    "contact": { "type": "form", "keys": ["contact.email"], "endpoint": "formspree" }
  },
  "media": [
    {
      "id": 42,
      "url": "https://example.com/wp-content/uploads/logo.png",
      "alt": "Logo",
      "width": 512,
      "height": 512
    }
  ],
  "meta": {
    "templateId": "studio-next",
    "templateVersion": "1.0.0"
  }
}
```

## Key naming rules

- Lowercase, dot-separated: `section.field`
- Stable across exports (mapper defines them, not WP slugs)
- **Never** use numeric post IDs as keys in `keys{}` — IDs change on migrate; mapper resolves ID → value at export time

Examples:

```
hero.title
hero.cta.label
hero.cta.href
pricing.tier1.price
footer.copyright
```

## Value types

| Type | JSON | Notes |
|------|------|-------|
| Text | string | Plain text |
| Rich text | string (HTML) | Sanitized on export with `wp_kses_post` |
| URL | string | Absolute URL |
| Image | string URL + entry in `media[]` | Template can use `<Image>` with dimensions |
| Boolean | boolean | |
| List | string[] | e.g. feature bullets |
| Object | object | Nested only when necessary; prefer flat keys |

## Section types (feeds static vs forms doc)

| `sections.*.type` | Meaning |
|-------------------|---------|
| `static` | Baked at `next build` — no runtime fetch |
| `form` | Client component; submits to endpoint |
| `incremental` | ISR / on-demand revalidate or client fetch (Phase 2) |

## JSON Schema (validate in plugin + CI)

Store at `schema/liefle-export-v1.schema.json`. Validate:

- PHP: `justinrainbow/json-schema` in plugin (dev) or lightweight custom checks in MVP
- Node: `ajv` in template repo CI

```bash
npx ajv validate -s schema/liefle-export-v1.schema.json -d data/liefle-export.json
```

## Example minimal export (v0.1 POC)

See [examples/sample-export.json](./examples/sample-export.json).

## Mapping config (stored in WP, not shipped to public)

Separate option `liefle_mapper_config`:

```json
[
  {
    "key": "hero.title",
    "source": "page",
    "id": 12,
    "field": "post_title"
  },
  {
    "key": "about.body",
    "source": "page",
    "id": 34,
    "field": "post_content"
  }
]
```

Exporter walks this array and builds `keys{}`.

## AI-friendly metadata

Add optional `hints` block for codegen/AI:

```json
"hints": {
  "hero.title": { "component": "Hero", "prop": "title", "format": "plain" },
  "about.body": { "component": "AboutSection", "prop": "html", "format": "html" }
}
```

Plugin can auto-generate hints from mapper defaults; user can override in admin.

Next: [04-static-vs-forms.md](./04-static-vs-forms.md)
