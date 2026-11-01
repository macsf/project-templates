# {{PROJECT_TITLE}} — AGENTS.md

## Stack

| Layer | Tech |
| --- | --- |
| Frontend | React + Vite + TypeScript |
| Styling | Tailwind CSS (oklch), shadcn/ui new-york |
| Backend | Express + TypeScript (tsx, NodeNext) |
| Database | MySQL via Prisma |
| Auth | Google OAuth + HMAC SHA-256 session cookies |
| Testing | Vitest + jsdom + Testing Library |
| Package Mgr | pnpm |

## Key files

| File | Purpose |
| --- | --- |
| `src/App.tsx` | Root component, routing, auth |
| `src/lib/theme.tsx` | ThemeProvider (dark mode) |
| `server/src/index.ts` | Express entry point |
| `server/src/config/env.ts` | Validated env vars (zod) |
| `server/src/auth/session.ts` | HMAC session cookies |
| `server/src/auth/google.ts` | Google ID token verification |
| `server/src/routes/auth.ts` | `/api/auth/*` routes |
| `server/src/middleware/require-auth.ts` | Auth guard middleware |
| `server/src/lib/prisma.ts` | Prisma singleton |
| `prisma/schema.prisma` | DB schema (User + Session) |
| `vite.config.ts` | Vite config (proxy, plugins) |
| `docs/DOCKER.md` | Hostinger vs Dokploy/Coolify |

## Commands

```bash
pnpm dev:all          # Start both Vite and Express (concurrently)
pnpm dev:web          # Vite only
pnpm dev:server       # Express only
pnpm build            # Production build (web + server TypeScript)
pnpm typecheck        # Type-check frontend + server
pnpm lint             # ESLint
pnpm format           # Prettier
pnpm test             # Vitest
pnpm prisma:migrate   # Run migrations (dev)
pnpm prisma:generate  # Regenerate Prisma client
```

## File conventions

| Type | Convention | Example |
| --- | --- | --- |
| React components | PascalCase file + export | `UserCard.tsx` |
| shadcn/ui primitives | kebab-case | `components/ui/button.tsx` |
| Utility/lib files | kebab-case | `lib/format-date.ts` |
| Server routes | kebab-case | `server/src/routes/user.ts` |
| Hooks | camelCase with `use` prefix | `hooks/useMediaQuery.ts` |
| DB columns | snake_case (via Prisma map) | `@map("created_at")` |

## Patterns

### Adding a new API route

1. Create `server/src/routes/<name>.ts` with an Express Router
2. Import and mount in `server/src/index.ts` as `/api/<name>`
3. Use `requireAuth` for protected endpoints

### Adding a new Prisma model

1. Edit `prisma/schema.prisma`
2. Run `pnpm prisma:migrate -- --name describe_change`
3. Run `pnpm prisma:generate`

### Adding a UI component

```bash
pnpm dlx shadcn@latest add <component>
```

Components land in `src/components/ui/`.

### TypeScript

- All new code is strictly typed. No `any`.
- Import types with `import type { ... }` when the import is type-only.
- Use `zod` for runtime validation at API boundaries.
- Prefer `type` over `interface` for local shape definitions.

## Auth flow

1. Frontend renders the Google Identity Services button (or the dev bypass button if `VITE_GOOGLE_CLIENT_ID` is unset)
2. On success, POST `/api/auth/google` with `credential` (JWT from Google)
3. Server verifies JWT, upserts user, sets HMAC-signed httpOnly session cookie
4. Subsequent requests carry the cookie; `loadSession` middleware resolves `req.user`
5. Protected routes use `requireAuth` after `loadSession`
6. `req.user` is typed as `SessionUser` when authenticated
7. Session cookie is httpOnly, HMAC-signed, 7-day expiry

When `DEV_BYPASS_AUTH=true`, every request is authenticated as `DEV_USER_EMAIL`. The frontend falls back to a plain Continue (dev) button when `VITE_GOOGLE_CLIENT_ID` is unset. Dev bypass is local only. Never production.

## Testing

- Tests live alongside source: `src/foo.test.ts` or `src/__tests__/foo.test.ts`
- Vitest + jsdom for component tests; no browser needed
- Mock only at system boundaries (network, filesystem, clock)
- Run: `pnpm test`

## Critical rules

- pnpm only. No npm, no yarn. Run all commands from repo root.
- Never commit `.env`.
- `DEV_BYPASS_AUTH=true` is for local dev only.
- Add routes in `server/src/routes/`, protect with `requireAuth`.
- Database: MySQL only. Use `prisma:migrate` (not `db push`) for schema changes.

## Git & deploy workflow

- Package manager is pnpm.
- Branch off `main` (`feat/...`, `fix/...`, `chore/...`). Do not commit to `main` directly.
- Conventional commits (`feat:`, `fix:`, `chore:`, `style:`, `release:`). No co-author lines.
- Pre-commit (`.husky/pre-commit`) runs `lint-staged` then `pnpm typecheck`. Keep both clean.
- Deploy with Docker (Hostinger or Dokploy/Coolify). See `docs/DOCKER.md`. No pm2.
- Hostinger: merging to `main` deploys only when a commit subject starts with `release:` or `fix:`. `workflow_dispatch` always deploys.
- Local container: `docker compose build && docker compose up -d` (http://127.0.0.1:8080). Production Express serves `dist/`.
