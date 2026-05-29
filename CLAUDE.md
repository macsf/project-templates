# project-templates — Claude Instructions

## What this repo is

A scaffolding repo. It contains two opinionated project templates (`templates/vite/`, `templates/nextjs/`) and a `scaffold.sh` script that copies a chosen template to a target directory, substitutes `{{VARS}}`, and wires in CI/CD from the `workflow-templates/` git submodule (https://github.com/macsf/workflow-templates).

This repo is **not** a runnable application — do not attempt `pnpm dev` at the root.

## Commands

```bash
bash scaffold.sh /path/to/new-project   # scaffold a new project
```

## Structure

```
templates/vite/       # React 19 + Vite + Express + Prisma + shadcn/ui
templates/nextjs/     # Next.js 15 App Router + Prisma + NextAuth + shadcn/ui
scaffold.sh           # Interactive scaffold (copies template, subs vars, wires CI/CD)
```

## Template variable format

All placeholders use `{{DOUBLE_BRACES}}`.

Key vars: `{{PROJECT_NAME}}`, `{{PROJECT_TITLE}}`, `{{PNPM_VERSION}}`, `{{NODE_VERSION}}`,
`{{DB_PROVIDER}}`, `{{DATABASE_URL}}`, `{{APP_PORT}}`, `{{API_PORT}}`, `{{APP_DIR}}`,
`{{PM2_APP_NAME}}`, `{{API_DIR}}`.

## When editing templates

- Edit files in `templates/vite/` or `templates/nextjs/` — these are the sources.
- Keep `{{VARS}}` as-is — `scaffold.sh` substitutes them at project creation time.
- After editing, verify no TypeScript errors by temporarily copying the template to a test
  dir, running `pnpm install` and `pnpm typecheck`.

## Adding a new template

1. Create `templates/<name>/` with all required files.
2. Add a new case in `scaffold.sh` for the template choice.
3. Update the README with the new template entry.
4. Document it in `AGENTS.md`.

## scaffold.sh key behaviours

- Reads `workflow-templates/templates/fullstack-app/` (git submodule) for CI/CD.
- Uses `sed` for variable substitution (simple, no templating engine).
- Runs `git init` + initial commit in the new project dir.
- Prompts: name, template, pnpm/Node version, DB provider, deploy config.
