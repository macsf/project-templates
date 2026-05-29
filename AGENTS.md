# project-templates — Agent Guidelines

## Repo purpose

Scaffolding library. Contains opinionated project starter templates and a scaffold script.
Not a runnable application.

## Template variable convention

- Format: `{{DOUBLE_BRACES}}` — no spaces inside braces.
- All template files that contain vars will have them replaced by `scaffold.sh` via `sed`.
- Never use single braces `{VAR}` — that conflicts with shell and JSX syntax.

## File naming

- Template folder names: kebab-case (`vite`, `nextjs`).
- Template source files follow the conventions of their framework (PascalCase for React
  components, kebab-case for configs).

## Available templates

| Folder | Framework | Auth | DB | CI/CD tier |
|---|---|---|---|---|
| `vite` | React 19 + Vite + Express | Google OAuth (session cookie) | Prisma + MySQL | fullstack-app |
| `nextjs` | Next.js 15 App Router | Google OAuth (NextAuth) | Prisma + SQLite or MySQL | fullstack-app |

## CI/CD source

`scaffold.sh` reads workflows from `workflow-templates/templates/fullstack-app/` (git submodule at https://github.com/macsf/workflow-templates).

## Adding a template

1. Copy an existing template folder as a starting point.
2. Replace all project-specific strings with `{{VARS}}`.
3. Add a case in `scaffold.sh`.
4. Update `README.md` and this file.

## Template content rules

- Every template must include: `CLAUDE.md`, `AGENTS.md`, `README.md`, `.env.example`
  (or `.env.local.example` for Next.js), `.husky/pre-commit`.
- Every template must have all four package.json scripts: `typecheck`, `lint`, `build`,
  and a dev start script.
- Prisma templates: always include `prisma:migrate` (or `prisma:push`) script.
- Never commit secrets or `.env` files.

## scaffold.sh conventions

- Bash with `set -euo pipefail`.
- Use `sed` substitution for vars (same pattern as `workflow-templates/scaffold.sh`).
- Print each written file with `echo "  wrote <path>"`.
- End with printed next-steps.
