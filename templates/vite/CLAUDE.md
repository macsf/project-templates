# {{PROJECT_TITLE}} — CLAUDE.md

## What is this project?

{{PROJECT_TITLE}} is a fullstack TypeScript app using Vite (React) + Express + Prisma (MySQL).

## Stack

| Layer      | Tech                          |
| ---------- | ----------------------------- |
| Frontend   | React 19, Vite 7, TypeScript  |
| Styling    | Tailwind CSS v4, shadcn/ui    |
| Backend    | Express 5, TypeScript         |
| Database   | MySQL via Prisma               |
| Auth       | Google OAuth (HMAC sessions)  |
| Testing    | Vitest, jsdom, Testing Library|
| Package Mgr| pnpm                          |

## Key files

| File                              | Purpose                          |
| --------------------------------- | -------------------------------- |
| `src/App.tsx`                     | Root component, routing, auth    |
| `src/lib/theme.tsx`               | ThemeProvider (dark mode)        |
| `server/src/index.ts`             | Express entry point              |
| `server/src/config/env.ts`        | Validated env vars (zod)         |
| `server/src/auth/session.ts`      | HMAC session cookies             |
| `server/src/auth/google.ts`       | Google ID token verification     |
| `server/src/routes/auth.ts`       | /api/auth/* routes               |
| `server/src/middleware/require-auth.ts` | Auth guard middleware       |
| `server/src/lib/prisma.ts`        | Prisma singleton                 |
| `prisma/schema.prisma`            | DB schema (User + Session)       |
| `vite.config.ts`                  | Vite config (proxy, plugins)     |

## Commands

```bash
pnpm dev:all          # Start both Vite dev server and Express (concurrently)
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

## Critical rules

- pnpm only — no npm, no yarn
- Run all commands from repo root
- Never commit `.env`
- `DEV_BYPASS_AUTH=true` is for local dev only — never production
- Add routes in `server/src/routes/`, protect with `requireAuth` middleware
- Add UI components via `pnpm dlx shadcn@latest add <component>`
- Database: MySQL only; use `prisma:migrate` (not `db push`) for schema changes

## Auth flow

1. Frontend renders Google Identity Services button (or dev bypass button if `VITE_GOOGLE_CLIENT_ID` unset)
2. On success, POST `/api/auth/google` with `credential` (JWT from Google)
3. Server verifies JWT, upserts user, sets HMAC-signed httpOnly session cookie
4. Subsequent requests carry cookie; `loadSession` middleware resolves `req.user`
5. Protected routes use `requireAuth` middleware

## Dev bypass

When `DEV_BYPASS_AUTH=true`, every request is automatically authenticated as the user in `DEV_USER_EMAIL`. The frontend falls back to a plain "Continue (dev)" button when `VITE_GOOGLE_CLIENT_ID` is unset.
