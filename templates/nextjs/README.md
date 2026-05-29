# {{PROJECT_TITLE}}

Fullstack TypeScript app — Next.js 15 App Router + NextAuth + Prisma ({{DB_PROVIDER}}).

## Stack

- **Framework**: Next.js 15 App Router, TypeScript
- **Styling**: Tailwind CSS v4, shadcn/ui
- **Auth**: NextAuth 4 with Google Provider
- **Database**: Prisma ({{DB_PROVIDER}})
- **Package manager**: pnpm

## Setup

1. Copy `.env.local.example` to `.env.local` and fill in the values.
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

## Environment variables

See `.env.local.example` for all required and optional variables.

Key variables:
- `DATABASE_URL` — database connection string
- `NEXTAUTH_SECRET` — generate with `openssl rand -base64 32`
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` — from Google Cloud Console
- `ALLOWED_GOOGLE_DOMAIN` — restrict to a Google Workspace domain (optional)
- `ALLOWED_USERS` — comma-separated list of allowed emails (optional)

## Google OAuth setup

1. Go to Google Cloud Console → APIs & Services → Credentials
2. Create an OAuth 2.0 Client ID (Web application)
3. Add `http://localhost:{{APP_PORT}}/api/auth/callback/google` to Authorized redirect URIs
4. Copy client ID and secret to `.env.local`
