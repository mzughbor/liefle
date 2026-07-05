# 05 — Tech Stack (Concrete Choices)

Picked for: **low cost**, **fast MVP**, **learn React/Next**, **room to grow**.

---

## Frontend / app framework

| Choice | Why |
|--------|-----|
| **Next.js 15+ (App Router)** | Vercel-native, SSR for tenant sites (SEO), API routes built-in |
| **TypeScript** | Catch errors early; worth the learning curve |
| **Tailwind CSS** | Optional; matches your current custom CSS or migrate gradually |

---

## Hosting

| Layer | Service | Cost |
|-------|---------|------|
| App | Vercel Hobby | $0 (non-commercial) / Pro $20 when needed |
| Reverse proxy | Hetzner / DO / Vultr VPS | ~$3–5/mo |
| DB | Neon PostgreSQL free tier | $0 → scale |
| Blob storage | Vercel Blob or Cloudflare R2 | Pennies |
| Email | Resend free tier | 3k emails/mo |

---

## Database & ORM

| Choice | Why |
|--------|-----|
| **PostgreSQL** | JSON columns for site config; reliable; Neon serverless |
| **Drizzle ORM** or **Prisma** | Pick one; Prisma has more tutorials for beginners |

**Core tables (MVP):**

```
users
tenants        (owner_user_id, slug, plan, trial_ends_at)
sites          (tenant_id, template_id, draft_json, published_json)
domains        (tenant_id, hostname, status, verify_token)
templates      (id, name, preview_url, component_key)
```

---

## Auth

| Option | Best for |
|--------|----------|
| **Clerk** | Fastest MVP; hosted UI; free tier |
| **Auth.js (NextAuth)** | More control; you own user table |
| **Supabase Auth** | If you use Supabase for Postgres anyway |

**Recommendation while learning:** Clerk or Auth.js with magic link email.

---

## Multi-tenant routing

```typescript
// Resolve tenant from host
function getTenantHost(host: string): string {
  return host.replace(/^www\./, '').split(':')[0].toLowerCase();
}

// falcon.codes subdomains
// myshop.falcon.codes → slug = myshop

// custom domains
// www.client.com → lookup domains.hostname
```

Use Next.js **`middleware.ts`** at the edge for host-based rewrites.

---

## Template system (simplest approach)

Templates = React components + Zod schema for editable fields:

```typescript
// templates/studio/config.ts
export const studioSchema = z.object({
  businessName: z.string(),
  tagline: z.string(),
  primaryColor: z.string(),
  logoUrl: z.string().url().optional(),
  sections: z.array(z.enum(['hero', 'about', 'contact'])),
});
```

- **Draft** stored in `sites.draft_json`
- **Publish** copies to `published_json`
- Public page reads `published_json` only

No headless CMS needed for MVP.

---

## File uploads (logos)

1. Client requests signed upload URL from `/api/upload`
2. Upload directly to R2/Blob
3. Save URL in `draft_json`

Do not save files on VPS or in Postgres.

---

## Billing (Phase 6)

- **Stripe Checkout** + Customer Portal
- Webhook `checkout.session.completed` → set `tenant.plan`
- Use Stripe test mode until POC done

---

## Observability (minimal)

- Vercel Analytics (free)
- Sentry free tier for errors (optional)
- Caddy access logs on VPS → `journalctl -u caddy`

---

## What to avoid in MVP

| Temptation | Why skip |
|------------|----------|
| Kubernetes | You don’t need it |
| GraphQL | REST/server actions are enough |
| Custom CMS | JSON + forms is faster |
| Microservices | One Next.js app |
| Self-hosted Postgres on VPS | Managed Neon is less ops |
| WebSockets | Polling or server actions for editor |

---

## Environment variables (starter list)

```env
# App
DATABASE_URL=
NEXTAUTH_SECRET=          # or CLERK_SECRET_KEY=
BLOB_READ_WRITE_TOKEN=

# Domain verify
DNS_VERIFY_PREFIX=_liefle

# Vercel
VERCEL_URL=

# Proxy allow API (on VPS)
ALLOW_API_SECRET=

# Stripe (later)
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
```

Next: [06-mvp-checklist.md](./06-mvp-checklist.md)
