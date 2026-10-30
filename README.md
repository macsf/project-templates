# project-templates

Opinionated project starters. Three templates, one scaffold script.

## Templates

| Template | Stack | Auth | DB |
|---|---|---|---|
| `vite` | React 19 + Vite 7 + Express 5 + Tailwind v4 + shadcn/ui | Google OAuth (session-based) | Prisma + MySQL |
| `nextjs` | Next.js 15 App Router + Tailwind v4 + shadcn/ui | Google OAuth (NextAuth) | Prisma + SQLite or MySQL |
| `cli` | TypeScript ESM CLI (`bin` → `dist/index.js`) | none | none |

Web templates ship with Docker unless you pick **none**. The CLI template is CI only (no Docker).

Shared:

- TypeScript strict mode
- ESLint flat config + Prettier
- Husky pre-commit (`lint-staged` + `pnpm typecheck`)
- GitHub Actions CI (+ Hostinger deploy when that scheme is chosen)
- Dependabot (npm weekly, actions/docker monthly, majors ignored)
- `AGENTS.md`

## Prerequisites

- Node 24+
- pnpm 10+
- Git (submodules are used; run `git submodule update --init` after cloning)

## Usage

**Other machine** (no local clone). Needs git, pnpm, Node 24+. Do not `curl | bash`; prompts need a TTY.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/macsf/project-templates/main/install.sh)
# or with a target dir:
bash <(curl -fsSL https://raw.githubusercontent.com/macsf/project-templates/main/install.sh) ~/projects/new-app
```

Shallow-clones into a temp dir, runs the scaffold, then deletes the clone. Lives on pushed `main`.

**This machine** (local clone already at `~/Developer/personal/project-templates`):

```bash
bash ~/Developer/personal/project-templates/scaffold.sh ~/projects/new-app
```

The script will prompt for:

1. Project name (kebab-case, min 3 chars)
2. Template: `vite`, `nextjs`, or `cli`
3. pnpm/Node version (defaults: 10 / 24)
4. DB provider: SQLite or MySQL (Next.js only)
5. Deploy scheme (web only): Hostinger, Dokploy/Coolify, or none
6. Bump dependencies to npm latest (default yes: `pnpm update --latest`)

Then it copies the template, substitutes all `{{VARS}}`, wires CI/CD, optionally bumps deps, and runs `git init`.

Do not put `"next": "latest"` in the template `package.json`. Packages have a `latest` dist-tag, not an LTS tag (that is a Node thing). Scaffold-time `pnpm update --latest` rewrites pins and writes the lockfile. It can jump majors. After that, Dependabot keeps minors/patches.

## After scaffolding

```bash
cd /path/to/new-project
pnpm install
cp .env.example .env          # vite
# or
cp .env.local.example .env.local   # nextjs

# Edit env file, then:
pnpm prisma:migrate            # web; commit migration files before the first Docker deploy
pnpm dev:all    # vite
pnpm dev        # nextjs or cli
```

Local container smoke (Docker schemes): `docker compose build && docker compose up -d` → http://127.0.0.1:8080

## Deploy schemes

| Scheme | What GitHub does | What the host does | Compose shape |
| --- | --- | --- | --- |
| **Hostinger** | CI, build/push GHCR, `hostinger/deploy-on-vps@v2` | Pulls `APP_IMAGE`, Traefik labels | no `build:`, ports on `127.0.0.1`, Traefik labels |
| **Dokploy / Coolify** | CI only | Builds `Dockerfile` from the repo | `build:` + `expose:`, no Traefik labels |
| **none** | CI only (`library` tier) | You run it (or publish the CLI) | Docker files stripped |

Push to `main` deploys on Hostinger only when a commit subject starts with `release:` or `fix:` (including `fix(scope):`). `workflow_dispatch` always deploys. Details: `docs/DOCKER.md` in the scaffolded project, and [workflow-templates](https://github.com/macsf/workflow-templates).

Hostinger `project-name` must be at least 3 characters. Secrets live in GitHub environment `deploy`.

## Template variables

| Variable | Description | Default |
|---|---|---|
| `{{PROJECT_NAME}}` | kebab-case name | required |
| `{{PROJECT_TITLE}}` | Title Case display name | derived from name |
| `{{PNPM_VERSION}}` | pnpm version | 10 |
| `{{NODE_VERSION}}` | Node.js version | 24 |
| `{{DB_PROVIDER}}` | `sqlite` or `mysql` (nextjs) | `sqlite` |
| `{{DATABASE_URL}}` | Prisma connection string | per provider |
| `{{APP_PORT}}` | Frontend dev port | 5173 (vite), 3000 (next) |
| `{{API_PORT}}` | Backend API port (vite only) | 3001 |
| `{{DEPLOY_SCHEME}}` | `Hostinger`, `Dokploy / Coolify`, or `CI only` | chosen at scaffold |

## Structure

```
project-templates/
├── scaffold.sh               # Interactive scaffold script
├── templates/
│   ├── vite/                 # Vite + Express + Prisma template
│   ├── nextjs/               # Next.js App Router + Prisma template
│   └── cli/                  # TypeScript CLI (from new-cli-project)
├── workflow-templates/       # Git submodule (macsf/workflow-templates)
├── README.md
└── AGENTS.md
```

## CI/CD

Workflows source: [macsf/workflow-templates](https://github.com/macsf/workflow-templates), included as a git submodule at `workflow-templates/`.

The scaffold copies the matching tier (`docker-hostinger`, `docker-compose`, or `library`) into `.github/`.
