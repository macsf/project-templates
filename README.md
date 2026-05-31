# project-templates

Opinionated project starters. Two templates, one scaffold script.

## Templates

| Template | Stack | Auth | DB |
|---|---|---|---|
| `vite` | React 19 + Vite 7 + Express 5 + Tailwind v4 + shadcn/ui | Google OAuth (session-based) | Prisma + MySQL |
| `nextjs` | Next.js 15 App Router + Tailwind v4 + shadcn/ui | Google OAuth (NextAuth) | Prisma + SQLite or MySQL |

Both ship with:
- TypeScript strict mode
- ESLint flat config + Prettier
- Husky pre-commit hooks (lint-staged)
- GitHub Actions CI + deploy (fullstack blue-green via [workflow-templates](https://github.com/macsf/workflow-templates))
- `CLAUDE.md` and `AGENTS.md`
- Dev auth bypass (`DEV_BYPASS_AUTH=true`)

## Prerequisites

- Node 22+
- pnpm 10+
- Git (submodules are used; run `git submodule update --init` after cloning)

## Usage

**Without cloning** (recommended):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/macsf/project-templates/main/install.sh)
```

**From a local clone:**

```bash
bash scaffold.sh /path/to/new-project
```

The script will prompt for:
1. Project name (kebab-case)
2. Template: `vite` or `nextjs`
3. pnpm/Node version (defaults: 10 / 22)
4. DB provider: SQLite or MySQL (Next.js only)
5. Deploy config: app dir, PM2 name

Then it copies the template, substitutes all `{{VARS}}`, wires in CI/CD workflows, and runs `git init`.

## After scaffolding

```bash
cd /path/to/new-project
pnpm install
cp .env.example .env          # vite
# or
cp .env.local.example .env.local   # nextjs

# Edit env file, then:
pnpm prisma:migrate            # vite (creates DB + tables)
# or
pnpm prisma:push               # nextjs dev

pnpm dev:all    # vite
pnpm dev        # nextjs
```

## Template variables

| Variable | Description | Default |
|---|---|---|
| `{{PROJECT_NAME}}` | kebab-case name | required |
| `{{PROJECT_TITLE}}` | Title Case display name | derived from name |
| `{{PNPM_VERSION}}` | pnpm version | 10 |
| `{{NODE_VERSION}}` | Node.js version | 22 |
| `{{DB_PROVIDER}}` | `sqlite` or `mysql` (nextjs) | `sqlite` |
| `{{DATABASE_URL}}` | Prisma connection string | per provider |
| `{{APP_PORT}}` | Frontend dev port | 5173 (vite), 3000 (next) |
| `{{API_PORT}}` | Backend API port (vite only) | 3001 |
| `{{APP_DIR}}` | Server deploy directory | `/opt/{{PROJECT_NAME}}` |
| `{{PM2_APP_NAME}}` | PM2 process name | `{{PROJECT_NAME}}` |
| `{{API_DIR}}` | Backend subdir for workflow | `server` (vite), `.` (nextjs) |

## Structure

```
project-templates/
├── scaffold.sh               # Interactive scaffold script
├── templates/
│   ├── vite/                 # Vite + Express + Prisma template
│   └── nextjs/               # Next.js App Router + Prisma template
├── workflow-templates/       # Git submodule (macsf/workflow-templates)
├── README.md
├── CLAUDE.md
└── AGENTS.md
```

## CI/CD

Workflows source: [macsf/workflow-templates](https://github.com/macsf/workflow-templates) (`fullstack-app` tier), included as a git submodule at `workflow-templates/`.
The scaffold script copies and substitutes them into `.github/workflows/`.

Required GitHub secrets for deploy:

| Secret | Description |
|---|---|
| `DO_HOST` | DigitalOcean server IP |
| `DO_SSH_PORT` | SSH port (default 22) |
| `DO_SSH_USER` | SSH user (default `deploy`) |
| `DO_SSH_KEY` | SSH private key (PEM) |
| `PORT` | App listen port (default 3001) |
| `VITE_GOOGLE_CLIENT_ID` | Frontend env var at build time (vite template) |
