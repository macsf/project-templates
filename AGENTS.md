# project-templates — Agent Guidelines

Scaffolding library. Starters: `templates/vite/`, `templates/nextjs/`, `templates/cli/`. Plus `scaffold.sh`. Not a runnable application; do not `pnpm dev` at the root.

## Commands

```bash
bash scaffold.sh /path/to/new-project
bash scaffold.sh /path/to/new-cli --template cli --name my-cli --yes
```

## Structure

```
templates/vite/       # React + Vite + Express + Prisma + shadcn/ui
templates/nextjs/     # Next.js App Router + Prisma + NextAuth + shadcn/ui
templates/cli/        # TypeScript ESM CLI (adapted from new-cli-project)
scaffold.sh           # Copies template, substitutes vars, wires CI/CD
workflow-templates/   # Git submodule (macsf/workflow-templates)
```

## Template variable convention

- Format: `{{DOUBLE_BRACES}}`. No spaces inside braces.
- `scaffold.sh` substitutes with `sed`. Never use single braces `{VAR}` (conflicts with shell and JSX).
- Leave GitHub / Docker-metadata expressions alone (`${{ github.sha }}`, `{{is_default_branch}}`).

Key vars: `{{PROJECT_NAME}}`, `{{PROJECT_TITLE}}`, `{{PNPM_VERSION}}`, `{{NODE_VERSION}}`,
`{{DB_PROVIDER}}`, `{{DATABASE_URL}}`, `{{APP_PORT}}`, `{{API_PORT}}`, `{{DEPLOY_SCHEME}}`.

## File naming

- Template folder names: kebab-case (`vite`, `nextjs`).
- Template source files follow the conventions of their framework (PascalCase for React
  components, kebab-case for configs).

## Available templates

| Folder | Framework | Auth | DB | CI/CD tier |
|---|---|---|---|---|
| `vite` | React + Vite + Express | Google OAuth (session cookie) | Prisma + MySQL | `docker-hostinger`, `docker-compose`, or `library` |
| `nextjs` | Next.js App Router | Google OAuth (NextAuth) | Prisma + SQLite or MySQL | `docker-hostinger`, `docker-compose`, or `library` |
| `cli` | TypeScript ESM CLI | none | none | `library` |

## CI/CD source

`scaffold.sh` reads workflows from `workflow-templates/templates/<tier>/` (git submodule at https://github.com/macsf/workflow-templates).

Docker schemes:

- **Hostinger:** GHCR image, `hostinger/deploy-on-vps@v2`, Traefik labels, loopback ports. Compose has no `build:` key.
- **Dokploy / Coolify:** CI only. Platform builds Compose (`build:` + `expose:`, no Traefik labels). SQLite uses a named volume.
- **none:** CI only (`library` tier). Docker files are not copied (CLI) or stripped (web).

Do not add a PM2 / DigitalOcean tarball deploy. That path is retired.

## When editing templates

- Edit files in `templates/vite/`, `templates/nextjs/`, or `templates/cli/`. Those are the sources.
- Keep `{{VARS}}` as-is. `scaffold.sh` substitutes them at project creation time.
- After editing, copy the template to a scratch dir, run `pnpm install` and `pnpm typecheck`.

## Adding a template

1. Copy an existing template folder as a starting point.
2. Replace all project-specific strings with `{{VARS}}`.
3. Add a case in `scaffold.sh`.
4. Update `README.md` and this file.

## Template content rules

- Every template must include: `AGENTS.md`, `README.md`, `.husky/pre-commit`.
- Web templates: `.env.example` (or `.env.local.example`), `Dockerfile`,
  `docker-compose.hostinger.yml`, `docker-compose.dokploy.yml`, `docs/DOCKER.md`.
- CLI template: no Docker, no env file. `bin` → `./dist/index.js`.
- Every template must have all four package.json scripts: `typecheck`, `lint`, `build`,
  and a dev start script. Pin `packageManager` and `engines.node`.
- Prisma templates: always include `prisma:migrate` (or `prisma:push`) script.
  Entrypoint runs `prisma migrate deploy`; commit migration files before first deploy.
- Never commit secrets or `.env` files.
- Husky pre-commit: `lint-staged` then `pnpm typecheck`.
- Conventional commits. Hostinger deploys only on `release:` / `fix:` subjects.

## scaffold.sh conventions

- Bash with `set -euo pipefail`.
- Use `sed` substitution for vars (same pattern as `workflow-templates/scaffold.sh`).
- Reads `workflow-templates/templates/docker-hostinger/` or `docker-compose/` for CI/CD.
- Copies `docker-compose.hostinger.yml` or `docker-compose.dokploy.yml` to `docker-compose.yml`.
- Runs `git init` + initial commit in the new project dir.
- Prompts: name, template, pnpm/Node version, DB provider, deploy scheme, bump deps to npm latest.
- Flags skip prompts (`--template`, `--name`, `--yes`, `--no-bump`, …). `--yes` requires a target dir and `--template`.
- After copy, `pnpm update --latest` (bump) or `pnpm install` (pins). Both need network. Do not store `"latest"` as a version in template package.json.
- Print each written file with `echo "  wrote <path>"`.
- End with printed next-steps.
- Project name minimum 3 characters (Hostinger API).
