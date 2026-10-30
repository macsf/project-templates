# {{PROJECT_TITLE}} — AGENTS.md

TypeScript CLI. No web UI, no Docker. GitHub Actions is the `library` tier (typecheck, lint, test, build).

## Stack

| Layer | Tech |
| --- | --- |
| Runtime | Node {{NODE_VERSION}}+ (ESM) |
| Language | TypeScript |
| Package Mgr | pnpm |
| Testing | Vitest (node) |

## Commands

```bash
pnpm dev          # tsx src/index.ts
pnpm build        # tsc → dist/
pnpm start        # node dist/index.js
pnpm typecheck
pnpm lint
pnpm test
```

Install the bin locally: `pnpm link --global` after `pnpm build`, or `pnpm exec {{PROJECT_NAME}}`.

## Layout

| Path | Role |
| --- | --- |
| `src/index.ts` | CLI entry (`bin` → `dist/index.js`) and exported helpers |
| `src/index.test.ts` | Vitest |

## Rules

- pnpm only. Run commands from repo root.
- Keep the public surface in `src/index.ts` (or split files under `src/` as the tool grows).
- `bin` points at `./dist/index.js`. Keep the shebang on the entry file.
- Pre-commit: `lint-staged` then `pnpm typecheck`.
- Conventional commits. Branch off `main`. No co-author lines.
