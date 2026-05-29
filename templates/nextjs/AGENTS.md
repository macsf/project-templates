# {{PROJECT_TITLE}} — AGENTS.md

## Stack at a glance

| Layer      | Tech                                          |
| ---------- | --------------------------------------------- |
| Framework  | Next.js 15 App Router (RSC)                   |
| Styling    | Tailwind CSS v4 (HSL vars), shadcn/ui new-york |
| Auth       | NextAuth 4 + Google Provider + PrismaAdapter  |
| Database   | Prisma ({{DB_PROVIDER}})                      |

## File conventions

| Type                    | Convention                   | Example                        |
| ----------------------- | ---------------------------- | ------------------------------ |
| Page components         | `page.tsx` in route folder   | `app/dashboard/page.tsx`       |
| Layouts                 | `layout.tsx` in route folder | `app/dashboard/layout.tsx`     |
| React components        | PascalCase file + export     | `components/UserCard.tsx`      |
| shadcn/ui primitives    | kebab-case                   | `components/ui/button.tsx`     |
| Utility/lib files       | kebab-case                   | `lib/format-date.ts`           |
| Hooks                   | camelCase with `use` prefix  | `hooks/useMediaQuery.ts`       |
| DB columns              | snake_case (via Prisma map)  | `@map("created_at")`           |

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

- All new code is strictly typed — no `any`
- Import types with `import type { ... }` when the import is type-only
- Use `zod` for runtime validation at API boundaries

## Access control

Configured via env vars — see `lib/auth.ts`:
- `ALLOWED_GOOGLE_DOMAIN` — restrict to a single Google Workspace domain
- `ALLOWED_USERS` — comma-separated list of allowed emails
