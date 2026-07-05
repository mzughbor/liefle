# 09 — Roadmap Checklist (Numbered Steps)

Cross-track execution order. Items 1–20 = shippable OSS POC. Items 21+ = product/business.

---

## Phase A — Plugin POC (WordPress)

1. [ ] Install LocalWP + blank site
2. [ ] Create plugin folder `plugin/liefle-headless-bridge/`
3. [ ] Register admin page “Liefle Headless Bridge”
4. [ ] Add `class-exporter.php` with hard-coded Home page → `hero.title`
5. [ ] Download JSON on button click
6. [ ] Add `schemaVersion`, `exportedAt`, `source`, `keys` to output
7. [ ] Build mapper UI (key + page dropdown + field type)
8. [ ] Persist mapper in `liefle_mapper_config` option
9. [ ] Support fields: `post_title`, `post_content`, `post_excerpt`, featured image URL
10. [ ] Sanitize HTML in `post_content` with `wp_kses_post`
11. [ ] Add `sections` block with `static` vs `form` types
12. [ ] Ship [examples/sample-export.json](./examples/sample-export.json) in repo
13. [ ] Write `readme.txt` for WordPress.org format
14. [ ] Add GPL LICENSE file

---

## Phase B — Next template POC

15. [ ] Create `templates/cafe-next` (or separate GitHub repo)
16. [ ] Import sample export → render Hero + About
17. [ ] Add `npm run validate:export` using ajv
18. [ ] Deploy to Vercel; document env vars in template README
19. [ ] Add “Deploy with Vercel” button
20. [ ] **Gate:** WP change → export → push → live update within 10 min

---

## Phase C — Automation & DX

21. [ ] Plugin: Vercel deploy hook field + POST on export
22. [ ] GitHub Action template for export validation on push
23. [ ] `template.manifest.json` with `requiredKeys`
24. [ ] CLI: `liefle-generate` copy template + inject JSON + validate
25. [ ] Optional REST: `GET /wp-json/liefle/v1/export` (authenticated)

---

## Phase D — AI & codegen service

26. [ ] Rule-based: list unmapped required keys
27. [ ] AI ops format spec (see [06-ai-integration.md](./06-ai-integration.md))
28. [ ] Script: apply rename-prop op with ts-morph
29. [ ] GitHub Action: AI opens PR on export mismatch (opt-in)
30. [ ] Web UI: upload JSON + pick template + download zip

---

## Phase E — Business & merge with SaaS

31. [ ] Template marketplace page on liefle.com
32. [ ] Pro: AI mapping credits
33. [ ] Pro: priority templates
34. [ ] Shared component library with `../plan/` Next app
35. [ ] Optional: Liefle hosted sync (export stored in your cloud for SaaS users migrating from WP)

---

## Search queries (copy-paste)

- `wordpress plugin add admin settings page tutorial`
- `wordpress get page by id post title`
- `next.js import json static site generation`
- `vercel deploy hook webhook trigger rebuild`
- `ajv validate json schema node`
- `ts-morph rename react component prop`
- `wordpress plugin GPL license wordpress.org submit`

---

## Risk register

| Risk | Mitigation |
|------|------------|
| Scope explosion (Elementor, Woo) | Manifest modules; MVP = native fields only |
| Users hate redeploy for static | Deploy hook; later ISR for blog |
| AI breaks templates | Build gate + human PR review |
| GPL requirement | No proprietary code in plugin; paid service separate |
| Two tracks split focus | Time-box: 4 days/week SaaS, 2 days/week WP until Level 5 |

---

## Definition of done (Track B POC)

- [ ] OSS plugin on GitHub with README
- [ ] One template on Vercel demo URL
- [ ] Video or GIF: WP edit → export → site updates
- [ ] You can explain static vs form flow in one minute

That’s enough to blog, post, and gather emails while SaaS track continues.
