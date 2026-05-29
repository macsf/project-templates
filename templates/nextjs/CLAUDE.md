# {{PROJECT_TITLE}} — CLAUDE.md

## What is this project?

{{PROJECT_TITLE}} is a fullstack TypeScript app using Next.js 15 App Router + NextAuth 4 + Prisma.

## Stack

| Layer      | Tech                                  |
| ---------- | ------------------------------------- |
| Framework  | Next.js 15 App Router                 |
| Styling    | Tailwind CSS v4, shadcn/ui            |
| Auth       | NextAuth 4 (Google Provider, Prisma Adapter) |
| Database   | Prisma ({{DB_PROVIDER}})              |
| Testing    | Vitest (if added), Playwright (if added) |
| Package Mgr| pnpm                                  |

## Key files

| File                                | Purpose                          |
| ----------------------------------- | -------------------------------- |
| `app/layout.tsx`                    | Root layout, providers           |
| `app/page.tsx`                      | Home page                        |
| `app/providers.tsx`                 | SessionProvider wrapper          |
| `app/api/auth/[...nextauth]/route.ts` | NextAuth handler               |
| `app/auth/signin/page.tsx`          | Custom sign-in page              |
| `app/auth/error/page.tsx`           | Auth error page                  |
| `lib/auth.ts`                       | NextAuth options + callbacks     |
| `lib/prisma.ts`                     | Prisma singleton                 |
| `lib/utils.ts`                      | cn() utility                     |
| `prisma/schema.prisma`              | DB schema (User, Account, Session) |
| `components/auth/SignInButton.tsx`  | Google sign-in button            |
| `components/theme-provider.tsx`     | ThemeProvider (dark mode)        |
| `next.config.ts`                    | Next.js config                   |

## Commands

```bash
pnpm dev              # Start dev server
pnpm build            # Production build (prisma generate + next build)
pnpm start            # Start production server
pnpm typecheck        # TypeScript check
pnpm lint             # ESLint
pnpm format           # Prettier
pnpm prisma:migrate   # Run migrations (dev)
pnpm prisma:push      # Push schema to DB (dev, no migration file)
pnpm prisma:generate  # Regenerate Prisma client
pnpm prisma:studio    # Prisma Studio GUI
```

## Critical rules

- pnpm only — no npm, no yarn
- Run all commands from repo root
- Never commit `.env.local`
- Add routes under `app/` following App Router conventions
- Server components fetch data directly; client components use SWR/React Query
- Protect routes by checking session with `getServerSession(authOptions)`

## Auth flow

1. User visits `/auth/signin` and clicks "Continue with Google"
2. NextAuth handles OAuth redirect flow
3. On success, `signIn` callback checks `ALLOWED_USERS` / `ALLOWED_GOOGLE_DOMAIN`
4. JWT strategy: session is stored in a cookie (no DB session table)
5. Access session in server components: `getServerSession(authOptions)`
6. Access session in client components: `useSession()` from next-auth/react

## Access control

- Set `ALLOWED_GOOGLE_DOMAIN=example.com` to restrict to one domain
- Set `ALLOWED_USERS=a@x.com,b@x.com` to restrict to specific emails
- Leave both empty to allow any authenticated Google user
