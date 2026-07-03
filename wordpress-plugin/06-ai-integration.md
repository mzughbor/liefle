# 06 — AI Integration (Read Repo + Patch Code)

AI is **not** required for v0.1. It’s the **Level 6+ dopamine unlock** once export + template works manually.

## Problems AI solves

1. **Key mismatch** — WP export has `homepage.heading`, template expects `hero.title`
2. **New section** — User adds `team.member1.name` in mapper; template has no component
3. **Theme migration** — Scan old WP theme files, suggest mapper entries
4. **Tweak copy tone** — Optional; separate from codegen

## Architecture

```
┌──────────────┐     export.json      ┌─────────────────┐
│ WP Plugin    │ ──────────────────►  │ Liefle AI CLI   │
└──────────────┘                      │ or web service  │
                                      └────────┬────────┘
┌──────────────┐   repo files (AST)             │
│ Next template│ ◄────────────────────────────┘
└──────────────┘   patched components + hints
```

## Input bundle (what you send the model)

Keep context small and structured:

```json
{
  "task": "align-export-to-template",
  "export": { "keys": { "...": "..." }, "hints": {} },
  "manifest": { "requiredKeys": [], "slots": {} },
  "files": [
    { "path": "components/Hero.tsx", "content": "..." },
    { "path": "app/page.tsx", "content": "..." }
  ]
}
```

**Do not** send entire `node_modules` or whole WP uploads.

## Output bundle (what AI returns)

Prefer **structured ops**, not full file rewrites:

```json
{
  "ops": [
    {
      "type": "rename-prop",
      "file": "components/Hero.tsx",
      "from": "headline",
      "to": "title",
      "reason": "match key hero.title"
    },
    {
      "type": "add-key-binding",
      "file": "app/page.tsx",
      "line": 12,
      "code": "k['team.member1.name']"
    },
    {
      "type": "update-hints",
      "hints": {
        "team.member1.name": { "component": "Team", "prop": "members.0.name" }
      }
    }
  ]
}
```

Your tooling applies ops → run `tsc` + `next build` → reject if fail → retry with error log.

## Implementation options

| Approach | Pros | Cons |
|----------|------|------|
| **LLM + diff apply** | Fast to ship | Fragile |
| **LLM + AST (ts-morph)** | Safer refactors | More code |
| **Rule engine first, AI fallback** | Predictable | Less magic |

**Recommended path:** rules for rename/map; AI only when validation fails.

## Tools stack (Node)

- `ts-morph` or `@babel/parser` — parse TSX
- `ajv` — schema
- OpenAI / Anthropic API — patch suggestions
- Optional: Cursor CLI / your own agent in CI

## Example prompt (sketch)

```
You are aligning a Next.js template to a WordPress export schema.
Rules:
- Only modify files listed in "files"
- Preserve styling classes
- Map flat keys hero.* to Hero component props
- Output JSON ops array only, no prose
```

## Safety

- Never execute AI output without build test
- User reviews diff in PR (GitHub Action opens branch `liefle/ai-alignment`)
- Rate limit API; plugin stays offline-capable

## Free vs paid AI

| Tier | Feature |
|------|---------|
| Free | Rule-based key validator + suggestions text |
| Pro | AI component patch + auto PR |
| Agency | Batch migrate 10 sites |

## Learning milestone

When AI successfully adds one new section from a new export key, you’ve touched: **LLM orchestration, AST, CI, product UX** — strong portfolio story.

Next: [07-vercel-deploy-flow.md](./07-vercel-deploy-flow.md)
