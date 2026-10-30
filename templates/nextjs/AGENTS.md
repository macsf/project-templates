# {{PROJECT_TITLE}} — AGENTS.md

## Stack

| Layer | Tech |
| --- | --- |
| Framework | Next.js App Router (RSC) |
| Styling | Tailwind CSS (HSL vars), shadcn/ui new-york |
| Auth | NextAuth 4 + Google Provider + PrismaAdapter |
| Database | Prisma ({{DB_PROVIDER}}) |
| Testing | Vitest, jsdom, Testing Library |
| Package Mgr | pnpm |

## Key files

| File | Purpose |
| --- | --- |
| `app/layout.tsx` | Root layout, providers |
| `app/page.tsx` | Home page |
| `app/providers.tsx` | SessionProvider wrapper |
| `app/api/auth/[...nextauth]/route.ts` | NextAuth handler |
| `app/api/health/route.ts` | Docker healthcheck |
| `app/auth/signin/page.tsx` | Custom sign-in page |
| `app/auth/error/page.tsx` | Auth error page |
| `lib/auth.ts` | NextAuth options + callbacks |
| `lib/prisma.ts` | Prisma singleton |
| `lib/utils.ts` | cn() utility |
| `prisma/schema.prisma` | DB schema (User, Account, Session) |
| `components/auth/SignInButton.tsx` | Google sign-in button |
| `components/theme-provider.tsx` | ThemeProvider (dark mode) |
| `next.config.ts` | Next.js config |
| `docs/DOCKER.md` | Hostinger vs Dokploy/Coolify |

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

## File conventions

| Type | Convention | Example |
| --- | --- | --- |
| Page components | `page.tsx` in route folder | `app/dashboard/page.tsx` |
| Layouts | `layout.tsx` in route folder | `app/dashboard/layout.tsx` |
| React components | PascalCase file + export | `components/UserCard.tsx` |
| shadcn/ui primitives | kebab-case | `components/ui/button.tsx` |
| Utility/lib files | kebab-case | `lib/format-date.ts` |
| Hooks | camelCase with `use` prefix | `hooks/useMediaQuery.ts` |
| DB columns | snake_case (via Prisma map) | `@map("created_at")` |

## Patterns

### Server vs client components

- Default: server component (no directive needed)
- Add `"use client"` only when using hooks, event handlers, or browser APIs
- Fetch data in server components; pass down as props

### Protecting a route

```tsx
// app/protected/page.tsx
import { getServerSession } from "next-auth";
import { redirect } from "next/navigation";
import { authOptions } from "@/lib/auth";

export default async function ProtectedPage() {
  const session = await getServerSession(authOptions);
  if (!session) redirect("/auth/signin");
  // ...
}
```

### Adding a new API route

```tsx
// app/api/example/route.ts
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { NextResponse } from "next/server";

export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  return NextResponse.json({ ok: true });
}
```

### Adding a new Prisma model

1. Edit `prisma/schema.prisma`
2. `pnpm prisma:migrate -- --name describe_change`
3. `pnpm prisma:generate`

### Adding a UI component

```bash
pnpm dlx shadcn@latest add <component>
```

Components land in `components/ui/`.

## TypeScript

- All new code is strictly typed. No `any`.
- Import types with `import type { ... }` when the import is type-only.
- Use `zod` for runtime validation at API boundaries.

## Auth flow

1. User visits `/auth/signin` and clicks Continue with Google
2. NextAuth handles the OAuth redirect
3. On success, `signIn` callback checks `ALLOWED_USERS` / `ALLOWED_GOOGLE_DOMAIN`
4. JWT strategy: session is stored in a cookie (no DB session table)
5. Server components: `getServerSession(authOptions)`
6. Client components: `useSession()` from `next-auth/react`

Access control (see `lib/auth.ts`):

- `ALLOWED_GOOGLE_DOMAIN=example.com` restricts to one domain
- `ALLOWED_USERS=a@x.com,b@x.com` restricts to specific emails
- Leave both empty to allow any authenticated Google user

## Critical rules

- pnpm only. No npm, no yarn. Run all commands from repo root.
- Never commit `.env` or `.env.local`.
- Add routes under `app/` following App Router conventions.
- Server components fetch data directly; client components use SWR/React Query.
- Protect routes with `getServerSession(authOptions)`.

## Git & deploy workflow

- Package manager is pnpm (version pinned in `packageManager`).
- Branch off `main` (`feat/...`, `fix/...`, `chore/...`). Do not commit to `main` directly.
- Conventional commits (`feat:`, `fix:`, `chore:`, `style:`, `release:`). No co-author lines.
- Pre-commit (`.husky/pre-commit`) runs `lint-staged` then `pnpm typecheck`. Keep both clean.
- Deploy with Docker (Hostinger or Dokploy/Coolify). See `docs/DOCKER.md`. No pm2.
- Hostinger: merging to `main` deploys only when a commit subject starts with `release:` or `fix:`. `workflow_dispatch` always deploys.
- Local container: `docker compose build && docker compose up -d` (http://127.0.0.1:8080).
