# {{PROJECT_TITLE}}

Fullstack TypeScript app — React (Vite) + Express + Prisma (MySQL).

## Stack

- **Frontend**: React, Vite, TypeScript, Tailwind CSS, shadcn/ui
- **Backend**: Express, TypeScript
- **Database**: MySQL via Prisma
- **Auth**: Google OAuth + HMAC-signed httpOnly session cookies
- **Package manager**: pnpm

## Setup

1. Copy `.env.example` to `.env` and fill in the values.
2. Create the MySQL database and run migrations:

```bash
pnpm install
pnpm prisma:migrate  # runs prisma migrate dev
```

3. Start development servers:

```bash
pnpm dev:all
```

Frontend: http://localhost:{{APP_PORT}}
API: http://localhost:{{API_PORT}}

## Commands

| Command                  | Description                        |
| ------------------------ | ---------------------------------- |
| `pnpm dev:all`           | Start Vite + Express concurrently  |
| `pnpm build`             | Production build                   |
| `pnpm start`             | Serve production build             |
| `pnpm typecheck`         | TypeScript check (frontend + server) |
| `pnpm lint`              | ESLint                             |
| `pnpm format`            | Prettier                           |
| `pnpm test`              | Run tests (Vitest)                 |
| `pnpm prisma:migrate`    | Apply migrations (dev)             |
| `pnpm prisma:generate`   | Regenerate Prisma client           |

## Environment variables

See `.env.example` for all required and optional variables.

## Production

The Express server serves the built Vite frontend as static files when `NODE_ENV=production`.

Docker only. Two schemes: Hostinger (GHCR + Traefik) or Dokploy/Coolify (platform builds Compose). See [`docs/DOCKER.md`](docs/DOCKER.md).

```bash
pnpm prisma:migrate    # commit migration files before the first deploy
docker compose build && docker compose up -d
curl -s http://127.0.0.1:8080/api/health
```
