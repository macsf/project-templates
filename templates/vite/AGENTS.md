# {{PROJECT_TITLE}} — AGENTS.md

## Stack at a glance

| Layer      | Tech                                      |
| ---------- | ----------------------------------------- |
| Frontend   | React 19 + Vite 7 + TypeScript            |
| Styling    | Tailwind CSS v4 (oklch), shadcn/ui new-york |
| Backend    | Express 5 + TypeScript (tsx, NodeNext)    |
| Database   | MySQL via Prisma 6                        |
| Auth       | Google OAuth + HMAC SHA-256 session cookies |
| Testing    | Vitest + jsdom + Testing Library          |

## File conventions

| Type                    | Convention                   | Example                        |
| ----------------------- | ---------------------------- | ------------------------------ |
| React components        | PascalCase file + export     | `UserCard.tsx`                 |
| shadcn/ui primitives    | kebab-case                   | `components/ui/button.tsx`     |
| Utility/lib files       | kebab-case                   | `lib/format-date.ts`           |
| Server routes           | kebab-case                   | `server/src/routes/user.ts`    |
| Hooks                   | camelCase with `use` prefix  | `hooks/useMediaQuery.ts`       |
| DB columns              | snake_case (via Prisma map)  | `@map("created_at")`           |

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

- All new code is strictly typed — no `any`
- Import types with `import type { ... }` when the import is type-only
- Use `zod` for runtime validation at API boundaries
- Prefer `type` over `interface` for local shape definitions

## Auth pattern

- `loadSession` middleware is applied globally in auth router
- Protected routes call `requireAuth` after `loadSession`
- `req.user` is typed as `SessionUser` when authenticated
- Session cookie is httpOnly, HMAC-signed, 7-day expiry

## Testing

- Tests live alongside source: `src/foo.test.ts` or `src/__tests__/foo.test.ts`
- Vitest + jsdom for component tests; no browser needed
- Mock only at system boundaries (network, filesystem, clock)
- Run: `pnpm test`
