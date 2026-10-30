# Docker

Two production schemes. This project was scaffolded for **{{DEPLOY_SCHEME}}**.
Swap `docker-compose.yml` if you change hosts. Do not mix Traefik labels with a
platform that injects its own.

Local day-to-day work stays on the host (`pnpm dev:all`). Docker is for smoke
tests and production. Express serves the Vite `dist/` SPA and `/api/*`.

MySQL stays **external**. Never start a database container in this stack.

## Layout

| Path | Role |
| --- | --- |
| `Dockerfile` | Multi-stage Node {{NODE_VERSION}} build; migrate-then-serve |
| `docker-compose.yml` | Active production Compose file |
| `docker-compose.hostinger.yml` | Hostinger + Traefik (GHCR pull, loopback ports, labels) |
| `docker-compose.dokploy.yml` | Dokploy / Coolify / generic (build, expose) |
| `docker-compose.override.yml` | Local ports (`127.0.0.1:8080`). Not used by Dokploy/Coolify |
| `docker/entrypoint.sh` | `HOST_UID`/`HOST_GID` drop, then `prisma migrate deploy` |
| `.dockerignore` | Keeps context small; never bakes `.env` |

Container port is always **8080**. `VITE_*` values are Docker build-args (baked
into the SPA). Use `VITE_API_BASE_URL=/api` so the UI talks same-origin.

## Hostinger

GitHub Actions builds `ghcr.io/<owner>/<repo>:<sha>` and `:latest`, then
`hostinger/deploy-on-vps@v2` deploys this compose file.

1. Create GitHub environment `deploy` (see secrets table below).
2. Hostinger `project-name` must be at least 3 characters (use `{{PROJECT_NAME}}`).
3. VPS Traefik uses host networking and reads Docker labels. Publish on `127.0.0.1` only.
4. Private repo: add a VPS SSH deploy key under GitHub **Settings → Deploy keys**.
5. VPS must be able to pull GHCR.
6. Push to `main` deploys only when a commit subject starts with `release:` or `fix:`
   (including `fix(scope):`). `workflow_dispatch` always deploys. `[skip deploy]` skips.

Compose **pulls** `APP_IMAGE`. There is no `build:` key.

### GitHub environment `deploy`

| Kind | Name | Purpose |
| --- | --- | --- |
| Secret | `HOSTINGER_API_KEY` | Hostinger API |
| Variable | `HOSTINGER_VM_ID` | Target VPS |
| Variable | `TRAEFIK_HOST` | Public hostname |
| Variable | `TRAEFIK_ROUTER` / `TRAEFIK_ENTRYPOINT` / `TRAEFIK_CERTRESOLVER` | Traefik labels |
| Variable | `PORT` | Host loopback port (default 8080) |
| Variable | `HOST_UID` / `HOST_GID` | Container user (default 0) |
| Secret | `DATABASE_URL` | Prisma MySQL URL (host reachable from the VPS) |
| Secret | `SESSION_SECRET` | HMAC session secret (min 32 chars) |
| Secret | `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google OAuth |
| Secret | `ALLOWED_EMAILS` | Comma-separated allow list |
| Variable | `VITE_GOOGLE_CLIENT_ID` | Baked into the SPA at image build |

`DEV_BYPASS_AUTH` is forced `false` in Compose.

## Dokploy / Coolify / generic Compose

The platform clones the repo and builds `Dockerfile`. GitHub Actions only runs CI.

1. Create a Compose service, compose path `docker-compose.yml`, branch `main`.
2. Set secrets in the Environment tab (same names as `.env.example`).
3. Domains tab: service `web`, container port `8080`, HTTPS on.
4. `DATABASE_URL` must use a hostname reachable from the container (not `localhost`).
5. Local: `docker compose up --build` (override publishes 8080).

## Local smoke

```bash
pnpm prisma:migrate   # commit the migration files

docker compose build
docker compose up -d
curl -s http://127.0.0.1:8080/api/health
```

Hostinger compose locally:

```bash
docker build -t {{PROJECT_NAME}}:local --build-arg VITE_API_BASE_URL=/api .
APP_IMAGE={{PROJECT_NAME}}:local docker compose -f docker-compose.hostinger.yml up
```

## Entrypoint

Starts as root, drops to `HOST_UID`:`HOST_GID` when those are non-zero, runs
`prisma migrate deploy`, then `node build/server/index.js`. Commit migration
files before the first deploy or the container will exit.

## Out of scope

- MySQL inside Compose
- Docker required for local `pnpm` development
- pm2 inside the container
