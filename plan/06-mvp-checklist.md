# 06 — MVP Checklist (Do These In Order)

Print this. Check boxes as you go. Search docs when stuck — each step is one focused Google/ChatGPT query away.

---

## Week 1 — Foundation

### Day 1–2: Domain & static presence

1. [ ] Buy domain (`liefle.io` or similar)
2. [ ] Push `liefle-front` to GitHub
3. [ ] Deploy static `index.html` to Vercel
4. [ ] Point domain apex/`www` to Vercel (marketing site)
5. [ ] Verify SEO: [Google Rich Results Test](https://search.google.com/test/rich-results)
6. [ ] Read `plan/01` through `plan/05` once

### Day 3–5: Next.js bootstrap

7. [ ] Create Next.js app: `npx create-next-app@latest` (TS, App Router, ESLint)
8. [ ] Copy marketing content from `index.html` into `app/page.tsx`
9. [ ] Split into components: `Hero`, `Pricing`, `FAQ`, `Nav`
10. [ ] Deploy Next app to Vercel (same or new project)
11. [ ] **Learn:** [Next.js App Router docs](https://nextjs.org/docs/app) — Pages 1–3

### Day 6–7: Database

12. [ ] Create free [Neon](https://neon.tech) PostgreSQL project
13. [ ] Install Prisma or Drizzle
14. [ ] Define schema: `users`, `tenants`, `sites`, `domains`
15. [ ] Run first migration
16. [ ] **Test:** connect from local `.env` and query `SELECT 1`

---

## Week 2 — Auth & dashboard

17. [ ] Add Clerk **or** Auth.js (pick one, don’t both)
18. [ ] Create `/login` and `/signup` routes
19. [ ] Add middleware protecting `/dashboard`
20. [ ] On first login: create `tenant` row with default slug
21. [ ] Dashboard page: “Your site: not published yet”
22. [ ] **Test:** incognito signup → see dashboard

---

## Week 3 — Subdomain tenant sites

23. [ ] Add wildcard domain `*.liefle.app` in Vercel DNS settings
24. [ ] Write `middleware.ts`: if host ends with `.liefle.app`, extract slug
25. [ ] Lookup tenant by slug in DB
26. [ ] Rewrite to `/site/[slug]` route
27. [ ] Show placeholder: “Site coming soon” for new tenants
28. [ ] **Test:** create tenant `demo` → open `https://demo.liefle.app`

---

## Week 4 — Template + editor

29. [ ] Build **one** template component (e.g. “Studio” one-pager)
30. [ ] Define JSON schema for editable fields (name, tagline, color, logo)
31. [ ] Wizard UI at `/dashboard/setup` (multi-step form)
32. [ ] Save form to `sites.draft_json` via Server Action or POST `/api/sites`
33. [ ] Preview route: `/dashboard/preview` (renders draft)
34. [ ] Publish button: copy draft → `published_json`, set `published_at`
35. [ ] Public site reads `published_json`
36. [ ] Logo upload to Vercel Blob or R2
37. [ ] **Test:** full loop signup → wizard → publish → public subdomain shows content

**🎯 POC milestone:** Steps 1–37 = demoable product without custom domains.

---

## Week 5–6 — Reverse proxy & custom domain

38. [ ] Rent $3–5 VPS (Ubuntu 24.04)
39. [ ] Create DNS A record: `connect.liefle.io` → VPS IP
40. [ ] Install Caddy on VPS
41. [ ] Configure reverse proxy to Vercel origin (see `plan/03`)
42. [ ] Build allow-domain API (even a 50-line Express app)
43. [ ] Domain UI: user enters `www.mybrand.com`
44. [ ] Show CNAME instructions (`www` → `connect.liefle.io`)
45. [ ] TXT verify record generation
46. [ ] DNS verify endpoint (use `dns.promises.resolveTxt` in Node)
47. [ ] On verify: add domain to allow API + DB `status=verified`
48. [ ] Extend middleware: custom host → tenant lookup via `domains` table
49. [ ] Buy $1 test domain and run full custom domain test
50. [ ] **Test:** `https://www.testdomain.com` serves correct tenant with valid SSL

---

## Week 7 — Billing & trial (optional before launch)

51. [ ] Stripe account + test products ($1, $3, $6)
52. [ ] Checkout session from dashboard
53. [ ] Webhook updates `tenant.plan`
54. [ ] Cron: delete expired 24h trial subdomains (Vercel Cron)
55. [ ] Gate custom domain feature on paid plan

---

## Week 8 — Launch prep

56. [ ] Privacy + Terms pages (templates from Termly or simple markdown)
57. [ ] Error monitoring (Sentry optional)
58. [ ] Manual QA script: signup, publish, custom domain, publish again
59. [ ] Ask 3 friends to try; watch where they get stuck
60. [ ] Fix top 3 confusion points in UI copy

---

## Daily learning rhythm (while building)

| Day | Build (30–90 min) | Learn (30 min) |
|-----|-------------------|----------------|
| Mon | Dashboard UI | React components + props |
| Tue | API route | Next.js Server Actions |
| Wed | Middleware | Multi-tenant routing article |
| Thu | Template | TypeScript generics basics |
| Fri | Deploy / fix | Vercel docs |

---

## Search queries when stuck

Copy-paste these:

- `next.js middleware custom domain multi tenant`
- `caddy on demand tls ask endpoint`
- `vercel reverse proxy custom host header`
- `neon postgres prisma next.js tutorial`
- `next.js server actions form upload`
- `stripe checkout subscription webhook next.js`

---

## Red flags (stop and simplify)

- You’re configuring Kubernetes → stop, use Vercel
- You’re building a drag-and-drop page builder → use fixed templates + forms
- You’re supporting apex + NS + CNAME on day 1 → www CNAME only
- You haven’t demoed subdomain publish yet but you’re on VPS SSL → go back to Week 4 milestone

---

## Definition of done (MVP)

You’re MVP-complete when:

✅ Subdomain site live in < 5 minutes after signup  
✅ Custom domain works via proxy for paying user  
✅ Edit + publish without deploy help  
✅ You can explain the stack in one diagram  
✅ Monthly infra cost < $25 total  

Then iterate on templates, pricing, and SEO — not architecture.
