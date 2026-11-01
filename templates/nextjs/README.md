# {{PROJECT_TITLE}}

Fullstack TypeScript app: Next.js App Router + NextAuth + Prisma ({{DB_PROVIDER}}).

## Stack

- **Framework**: Next.js App Router, TypeScript
- **Styling**: Tailwind CSS, shadcn/ui
- **Auth**: NextAuth 4 with Google Provider
- **Database**: Prisma ({{DB_PROVIDER}})
- **Package manager**: pnpm

## Setup

1. Copy the split env files, fill them in, and merge:

```bash
cp .env.vars.example .env.vars
cp .env.secrets.example .env.secrets
# fill in real values
pnpm env:merge   # writes .env.local (Next) and .env (Compose)
```

2. Apply database schema:

```bash
pnpm install
pnpm prisma:migrate  # runs prisma migrate dev
```

3. Start the dev server:

```bash
pnpm dev
```

Frontend: http://localhost:{{APP_PORT}}

## Commands

| Command                    | Description                          |
| -------------------------- | ------------------------------------ |
| `pnpm dev`                 | Start dev server                     |
| `pnpm build`               | Production build                     |
| `pnpm start`               | Start production server              |
| `pnpm typecheck`           | TypeScript check                     |
| `pnpm lint`                | ESLint                               |
| `pnpm format`              | Prettier                             |
| `pnpm prisma:migrate`      | Apply migrations (dev)               |
| `pnpm prisma:push`         | Push schema to DB (dev only)         |
| `pnpm prisma:generate`     | Regenerate Prisma client             |
| `pnpm prisma:studio`       | Open Prisma Studio                   |
| `pnpm env:merge`           | Merge `.env.vars` + `.env.secrets` into `.env.local` and `.env` |

## Environment variables

GitHub import: `.env.vars.example` (`gh variable set -f`) and `.env.secrets.example` (`gh secret set -f`), environment `deploy`. Local: fill `.env.vars` + `.env.secrets`, then `pnpm env:merge`.

Key variables:
- `DATABASE_URL`: database connection string
- `NEXTAUTH_SECRET`: generate with `openssl rand -base64 32`
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`: from Google Cloud Console
- `ALLOWED_GOOGLE_DOMAIN`: restrict to a Google Workspace domain (optional)
- `ALLOWED_USERS`: comma-separated list of allowed emails (optional)

## Google OAuth setup

1. Go to Google Cloud Console → APIs & Services → Credentials
2. Create an OAuth 2.0 Client ID (Web application)
3. Add `http://localhost:{{APP_PORT}}/api/auth/callback/google` to Authorized redirect URIs
4. Copy client ID to `.env.vars` and secret to `.env.secrets`, then `pnpm env:merge`

## Production

Docker only. Two schemes: Hostinger (GHCR + Traefik) or Dokploy/Coolify (platform builds Compose). See [`docs/DOCKER.md`](docs/DOCKER.md).

```bash
pnpm prisma:migrate    # commit migration files before the first deploy
docker compose build && docker compose up -d
curl -s http://127.0.0.1:8080/api/health
```
