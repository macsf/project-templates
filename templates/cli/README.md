# {{PROJECT_TITLE}}

TypeScript command-line tool.

## Getting Started

```sh
pnpm install
pnpm dev
```

## Scripts

| Command | Description |
| --- | --- |
| `pnpm dev` | Run with tsx (no build) |
| `pnpm build` | Compile to `dist/` |
| `pnpm start` | Run compiled output |
| `pnpm typecheck` | Type-check without emit |
| `pnpm lint` | Lint with ESLint |
| `pnpm format` | Format with Prettier |
| `pnpm test` | Vitest |

## Bin

After `pnpm build`:

```sh
node dist/index.js
pnpm exec {{PROJECT_NAME}}
```
