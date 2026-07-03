# 04 — Static Sections vs Forms (Incremental Data)

This is the core performance story: **marketing content is static; interactions stay live.**

## Two data flows

```
┌─────────────────────────────────────────────────────────────┐
│                    BUILD TIME (static)                      │
│  liefle-export.json  →  next build  →  HTML on Vercel CDN   │
│  hero, about, pricing copy, images, SEO                     │
│  ✅ No WordPress DB query per visitor                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                 RUNTIME (incremental)                       │
│  Contact form POST  →  Formspree / WP REST / Liefle API   │
│  Newsletter signup    →  Mailchimp webhook                  │
│  Optional: blog posts   →  ISR revalidate every N minutes   │
└─────────────────────────────────────────────────────────────┘
```

## Why this matches React/Next mental model

| Pattern | Next.js feature | WP plugin role |
|---------|-----------------|----------------|
| Static marketing | SSG / static export | Export keys marked `static` |
| Contact form | Client Component + `fetch` POST | Export `form` section + endpoint |
| “Blog still in WP” | ISR `revalidate: 3600` | Webhook on publish → redeploy or revalidate |
| Preview draft | Preview API route + secret | Export draft flag (later) |

## Section type reference

### `static`

- All keys resolved at export
- Template uses server components reading JSON import
- Change in WP → user re-exports → CI rebuild → deploy

**User message:** “Content updates require a rebuild (~1 min on Vercel).”

### `form`

- Only **config** is static (field labels, recipient email display)
- Submission never hits your Postgres unless you add Liefle API later

Options for endpoint:

1. **Formspree / Getform** — zero backend (MVP)
2. **WP REST** — `POST /wp-json/liefle/v1/contact` (keeps mail in WP)
3. **Liefle cloud** — unified inbox (paid feature)

### `incremental` (Phase 2)

- Latest posts fetched at runtime or ISR
- Plugin exports `postsEndpoint` + `categories` config
- Use when client insists “blog must update without redeploy”

## Template code pattern

```tsx
// app/page.tsx — static
import data from '@/data/liefle-export.json';
import { Hero } from '@/components/Hero';
import { ContactForm } from '@/components/ContactForm';

export default function Home() {
  const k = data.keys;
  return (
    <>
      <Hero title={k['hero.title']} subtitle={k['hero.subtitle']} image={k['hero.image']} />
      <ContactForm email={k['contact.email']} action={data.sections.contact.endpoint} />
    </>
  );
}
```

```tsx
// components/ContactForm.tsx — client
'use client';
export function ContactForm({ email, action }: { email: string; action: string }) {
  async function onSubmit(e: React.FormEvent<HTMLFormElement>) { /* fetch(action, ...) */ }
  return <form onSubmit={onSubmit}>...</form>;
}
```

## Redeploy triggers (automation ladder)

| Level | Trigger | Tool |
|-------|---------|------|
| Manual | User downloads JSON, commits, pushes | Git |
| Semi-auto | WP webhook → GitHub Action `repository_dispatch` | Plugin + GH Action |
| Auto | WP webhook → Vercel Deploy Hook URL | Plugin settings field |
| Fancy | WP save → Liefle cloud → PR on user repo | Track A + B merge |

Start **manual** for learning; add deploy hook at Level 4 in learning path.

## Caching cheat sheet

- Static pages: `Cache-Control` from Vercel edge — effectively forever until new deploy
- Form POST: never cached
- ISR blog: `revalidate` in `fetch` or segment config

Next: [05-code-generator.md](./05-code-generator.md)
