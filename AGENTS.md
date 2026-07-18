# AGENTS.md

## Cursor Cloud specific instructions

This repo is lightweight: static marketing sites plus one runnable Node service
(`liefle-proxy/allow-api`). There are no build steps and no third-party npm
dependencies, so no dependency install is required to develop or test.

### Runnable services (dev)

- **Static marketing sites** — plain HTML/CSS/JS, no build step.
  - Liefle landing (repo root): `python3 -m http.server 8000` then open
    `http://127.0.0.1:8000/index.html`.
  - `falcon-codes/` is an alternate-brand clone of the same page (serve from that
    dir on a different port if needed).
  - The domain-check form in `script.js` is a client-side demo only (no backend).
- **allow-api** (`liefle-proxy/allow-api/server.js`) — zero-dependency Node HTTP
  service (Caddy on-demand-TLS gate + domain management). Run with
  `cd liefle-proxy && bash start-local.sh` (listens on `127.0.0.1:8080`).
  - Endpoints: `GET /health`, `GET /allow-domain?domain=...` (200/403),
    and `GET|POST|DELETE /api/domains` (Bearer auth). See `liefle-proxy/README.md`.
  - Gotcha: the Bearer token for `/api/domains` comes from `ALLOW_API_SECRET` in
    `liefle-proxy/.env`. `start-local.sh` auto-creates `.env` from `.env.example`
    on first run, so the default secret is `change-me-before-production`
    (NOT the `dev-secret-change-me` fallback). Use the value in `.env`.
  - Gotcha: `POST`/`DELETE` on `/api/domains` rewrite `allow-api/domains.json`
    (reformats + adds `updatedAt`), which shows as a git diff. Run
    `git checkout liefle-proxy/allow-api/domains.json` to restore it after testing.

### Not locally runnable end-to-end

- The full Caddy reverse-proxy stack (`liefle-proxy/docker-compose.yml`) needs
  Docker plus real DNS, ports 80/443, and a live external `VERCEL_ORIGIN` with
  Let's Encrypt on-demand TLS — it cannot complete E2E in this sandbox. Docker is
  not installed by default. For local work, run `allow-api` on its own.
- The planned Next.js SaaS app and the WordPress plugin do not exist in this repo
  yet (see `plan/` and `wordpress-plugin/`), so there is nothing to run for them.

### Lint / test / build

There are no linters, automated test suites, or build scripts committed in this
repo. Validate changes by running the service/site above and exercising them
(e.g. `curl` the `allow-api` endpoints, or use the landing page domain-check UI).
