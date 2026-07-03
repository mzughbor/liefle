# 08 — Learning Path (ADHD-Friendly Level Ladder)

Designed for **short sessions**, **visible wins**, and **clear “done” states**.  
Each level = 1–3 evenings max. Stop at any level and you still have something shippable.

---

## How to use this

- Pick **one level only**; finish before peeking ahead
- Screenshot or screen-record each win (dopamine receipt folder)
- If stuck > 45 min, drop to a smaller sub-task or search one exact query from the level
- **Body doubling:** stream or tell one friend “I’m on Level 3 today”

---

## Level 0 — Spark (2 hours)

**Goal:** See the future site in your head on paper.

- [ ] Draw 3 boxes: WP admin | JSON file | Next page
- [ ] List 5 keys your fake cafe site needs
- [ ] Read [03-export-schema.md](./03-export-schema.md) once

**Win:** One diagram you can explain in 30 seconds.  
**Query if stuck:** `wordpress headless cms beginner diagram`

---

## Level 1 — Plugin skeleton (1 evening)

**Goal:** Plugin appears in WP admin.

- [ ] Install [LocalWP](https://localwp.com/) or Docker WP
- [ ] Create `plugin/liefle-headless-bridge/liefle-headless-bridge.php`
- [ ] Admin menu “Liefle Export” with hello world
- [ ] Zip install on local WP

**Win:** Screenshot of menu in wp-admin.  
**Skill:** PHP basics, WP plugin headers.

---

## Level 2 — First export (1 evening)

**Goal:** Download JSON with real WP page title.

- [ ] Hard-code map: Home page ID → `hero.title`
- [ ] Export button downloads `liefle-export.json`
- [ ] Match [examples/sample-export.json](./examples/sample-export.json) shape

**Win:** Open JSON in VS Code; see your site name.  
**Skill:** `get_post()`, JSON encode.

---

## Level 3 — Next.js mirror (1–2 evenings)

**Goal:** Public page shows `hero.title` from JSON.

- [ ] `npx create-next-app@latest cafe-demo`
- [ ] Copy export to `data/liefle-export.json`
- [ ] Render one `<h1>{data.keys['hero.title']}</h1>`
- [ ] Deploy Vercel

**Win:** Send URL to someone; they see your WP title on Vercel.  
**Skill:** React, deploy, **headless loop closed**.

---

## Level 4 — Mapper UI (2–3 evenings)

**Goal:** No hard-coded page IDs.

- [ ] Admin table: add row key + page dropdown
- [ ] Save to `liefle_mapper_config`
- [ ] Exporter reads config dynamically

**Win:** Change mapping without editing PHP.  
**Skill:** WP settings API, admin JS.

---

## Level 5 — Full static page (2–3 evenings)

**Goal:** Hero + About + footer from export; looks designed.

- [ ] Port one section from `../index.html` into Hero component
- [ ] Mark sections `static` in export
- [ ] `npm run build` produces full page

**Win:** Side-by-side WP edit → re-export → redeploy → visible text change.  
**Skill:** Components, CSS, static generation story.

---

## Level 6 — Forms split (1–2 evenings)

**Goal:** Contact form works; rest stays static.

- [ ] Formspree account + endpoint in export
- [ ] Client component form
- [ ] Document in plugin: “static vs form sections”

**Win:** Test submission email arrives.  
**Skill:** `'use client'`, incremental data flow.

---

## Level 7 — Deploy hook (1 evening)

**Goal:** Export in WP triggers Vercel rebuild.

- [ ] Vercel deploy hook URL in plugin settings
- [ ] `wp_remote_post` on export

**Win:** Edit WP → Export → watch Vercel build → live.  
**Skill:** Webhooks, automation high.

---

## Level 8 — Template manifest + CLI (3–5 evenings)

**Goal:** `@liefle/generate` or simple bash script validates + scaffolds.

- [ ] Write `template.manifest.json`
- [ ] Script fails if required key missing
- [ ] GitHub Action on template repos

**Win:** Friend clones template; validation passes/fails clearly.  
**Skill:** DX, CLI, CI — **product engineering**.

---

## Level 9 — AI patch (optional boss fight)

**Goal:** One automated prop rename from export hints.

- [ ] Script reads export + Hero.tsx
- [ ] LLM returns JSON op OR rule engine renames prop
- [ ] Build must pass

**Win:** Screen recording: “AI fixed my template.”  
**Skill:** LLM ops, ts-morph, the flashy demo for Twitter.

---

## Level 10 — Open source launch

**Goal:** Public GitHub + README + demo video.

- [ ] GPL LICENSE file
- [ ] README with 5-step quickstart
- [ ] Submit to WP forums / Reddit r/wordpress (follow rules)

**Win:** First star or first stranger issue.  
**Skill:** Community, maintenance mindset.

---

## Session templates (25-min pomodoro)

| Block | Activity |
|-------|----------|
| 0–5 min | Re-read level “Win” condition only |
| 5–20 min | One function or one component |
| 20–25 min | Commit + screenshot |

---

## When to switch back to SaaS track

If you need **revenue fast** or **non-WP users**, prioritize `../plan/06-mvp-checklist.md`.  
If you’re **learning and enjoying WP + React**, stay on this ladder — skills transfer directly.

Next: [09-roadmap-checklist.md](./09-roadmap-checklist.md)
