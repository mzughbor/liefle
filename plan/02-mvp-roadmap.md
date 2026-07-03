# 02 — MVP Roadmap (Phases)

Each phase has a **done when** gate. Do not start the next phase until the gate passes.

---

## Phase 0 — Landing + plan (you are here)

**Goal:** Credibility, SEO, clear message while you build.

**Done when:**
- [ ] `index.html` live on your domain with good SEO meta + JSON-LD
- [ ] `plan/` docs read and you agree with architecture
- [ ] Domain purchased (`liefle.io` or similar)
- [ ] Git repo + Vercel project connected (can deploy static site)

**Time:** 1–2 days

---

## Phase 1 — Static → Next.js shell

**Goal:** Same landing page in Next.js; learn App Router.

**Tasks:**
1. `npx create-next-app@latest liefle-app` (TypeScript, App Router, Tailwind optional)
2. Port `index.html` → `app/page.tsx` + components
3. Deploy to Vercel → `app.liefle.io` or `liefle.io`
4. Keep `liefle-front` as archive OR merge into monorepo

**Done when:**
- [ ] Production URL loads the marketing page
- [ ] You can edit copy in React and redeploy in < 2 min

**Time:** 3–5 days (while learning React basics)

**Learn:** Components, props, `Link`, layout, deployment.

---

## Phase 2 — Auth + empty dashboard

**Goal:** User can sign up and see an empty dashboard.

**Stack suggestion:** NextAuth.js (Auth.js) + Google/email magic link OR Clerk (faster, free tier).

**Tasks:**
1. Add `/signup`, `/login`, `/dashboard`
2. Protect `/dashboard/*` with middleware
3. Store `users` table: `id`, `email`, `created_at`
4. Create `tenants` table: `id`, `owner_user_id`, `slug`, `plan`

**Done when:**
- [ ] New user signs up → lands on dashboard
- [ ] Session persists across refresh
- [ ] Logged-out user cannot access dashboard

**Time:** 3–7 days

**Learn:** Server vs client components, middleware, sessions.

---

## Phase 3 — Domain verification (subdomain first)

**Goal:** Free trial on `slug.liefle.app` without custom DNS complexity.

**Tasks:**
1. Wildcard DNS: `*.liefle.app` → Vercel (or proxy later)
2. Middleware reads `Host` header → lookup tenant by slug
3. “Create site” flow: user picks slug → row in DB → placeholder page

**Done when:**
- [ ] `https://myshop.liefle.app` shows tenant placeholder
- [ ] Unknown slug → 404 or marketing redirect

**Time:** 2–4 days

**Learn:** Next.js middleware, multi-tenant routing.

---

## Phase 4 — Template picker + publish

**Goal:** Pick template → filled site goes live on subdomain.

**Tasks:**
1. Define 1–2 templates as React components + JSON config (name, colors, sections)
2. Wizard form: business name, tagline, logo upload
3. `sites` table: `tenant_id`, `template_id`, `draft_json`, `published_json`, `published_at`
4. Public route renders `published_json` into template
5. “Publish” copies draft → published

**Done when:**
- [ ] User completes wizard → sees preview
- [ ] Publish → public URL shows their content
- [ ] Edit logo/text → publish again → public updates

**Time:** 1–2 weeks

**Learn:** Forms, file upload, server actions or API routes.

---

## Phase 5 — Reverse proxy + custom domain

**Goal:** Customer uses `www.theirbrand.com` without seeing Vercel in DNS instructions.

**Tasks:** See [03-reverse-proxy.md](./03-reverse-proxy.md) and [04-dns-and-domains.md](./04-dns-and-domains.md).

**Done when:**
- [ ] Customer adds CNAME to your proxy hostname
- [ ] You verify domain ownership (TXT or HTTP)
- [ ] Proxy forwards to Vercel with correct Host
- [ ] HTTPS works on customer domain (Let’s Encrypt on proxy)

**Time:** 1–2 weeks (SSL + edge cases)

---

## Phase 6 — Admin polish + billing

**Goal:** Charge $1–3/mo and reduce manual work.

**Tasks:**
1. Stripe Checkout + webhooks → update `plan`
2. Enforce limits (1 domain on Starter, etc.)
3. Domain verify UI in dashboard
4. Basic analytics (optional: Plausible embed)

**Done when:**
- [ ] Paid user can connect custom domain
- [ ] Unpaid trial expires subdomain after 24h (cron or Vercel cron)

**Time:** 1–2 weeks

---

## Phase 7 — Scale prep (only when needed)

- Separate DB per paying tenant (Neon API)
- Queue for publish (if builds get slow)
- CDN for assets
- Move proxy to second VPS + floating IP
- Own Kubernetes / load balancers — **not before meaningful revenue**

---

## Recommended order if you’re learning React

```
Phase 0 → 1 → 2 → 3 → 4 → 5 → 6
         ↑ learn React/Next here
                              ↑ your VPS/proxy fear solved here
```

**Do not block Phase 1–4 on the reverse proxy.** Subdomain on Vercel proves the editor loop. Custom domains are Phase 5.

Next: [03-reverse-proxy.md](./03-reverse-proxy.md)
