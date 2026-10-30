# Hostinger deploy

Checklist for a scaffolded web app on the Hostinger VPS. Same story, shorter, lands in the new project as `docs/DOCKER.md`.

Three credentials, easy to mix up:

| What | Where | Why |
|---|---|---|
| Hostinger API key + VM ID | GitHub environment `deploy` | `hostinger/deploy-on-vps@v2` talks to Hostinger |
| VPS SSH deploy key | GitHub **Settings → Deploy keys** | Hostinger Docker Manager clones the repo (compose file) |
| GHCR login on the VPS | `docker login ghcr.io` on the box | Pulls the private image (not the deploy key) |

## Once on the VPS

Traefik and GHCR login are shared. Skip if this box already hosts another of these apps.

1. Traefik running with **host networking** and the Docker provider (reads Compose labels). TLS via the cert resolver you will name in `TRAEFIK_CERTRESOLVER` (usually `letsencrypt`).
2. `docker login ghcr.io` with a GitHub PAT that has `read:packages`, or make the GHCR package public. Actions already pushes with `GITHUB_TOKEN`; the VPS still has to pull.
3. Copy the VPS SSH **public** key (Hostinger Docker Manager shows it). You will add it per repo below.

## Per project

1. Scaffold with the Hostinger scheme. Project name at least **3 characters** (Hostinger API rejects shorter names).
2. Push the repo to GitHub.
3. GitHub **Settings → Environments → New**: name it exactly `deploy`. Put secrets and variables **here**, not at repo level. The workflow uses `environment: deploy`.
4. **Settings → Deploy keys**: add the VPS public key (read-only is enough).
5. DNS: `TRAEFIK_HOST` A record → the VPS public IP.
6. Google Cloud console, production origins:
   - Vite (GIS, no redirect URI): authorized JavaScript origin `https://<TRAEFIK_HOST>`
   - Next.js: authorized redirect `https://<TRAEFIK_HOST>/api/auth/callback/google`
7. Commit Prisma migration files. The container runs `prisma migrate deploy` on start and exits if there are none.
8. Pick a loopback `PORT` that is **unique on this VPS** (Traefik reaches `127.0.0.1:$PORT`).
9. Deploy: push to `main` with a subject starting `release:` or `fix:` (including `fix(scope):`), or run **Deploy (Hostinger)** by hand (`workflow_dispatch`). `[skip deploy]` in any commit of the push skips it. CI must pass first.

Compose **pulls** `APP_IMAGE`. There is no `build:` key. Image is `ghcr.io/<owner>/<repo>:<sha>`.

Project dir on the VPS is `/docker/<project-name>/`. Next.js SQLite bind-mount is `/docker/<project-name>/data/`.

## GitHub environment `deploy`

### Always

| Kind | Name | Where to get it |
|---|---|---|
| Secret | `HOSTINGER_API_KEY` | hPanel → API |
| Variable | `HOSTINGER_VM_ID` | VPS overview URL (same box can host multiple apps) |
| Variable | `TRAEFIK_HOST` | Public hostname |
| Variable | `TRAEFIK_ROUTER` | Compose router name (default: project name) |
| Variable | `TRAEFIK_ENTRYPOINT` | Default `websecure` |
| Variable | `TRAEFIK_CERTRESOLVER` | Default `letsencrypt` |
| Variable | `PORT` | Host loopback publish port (container still listens on 8080) |
| Variable | `HOST_UID` / `HOST_GID` | Container user (default `0`) |
| Secret | `DATABASE_URL` | Prisma URL reachable **from the container**, not `localhost` on your laptop |
| Secret | `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google Cloud console |

`TRAEFIK_ENABLE` is hardcoded `true` in the workflow.

### Vite

| Kind | Name | Purpose |
|---|---|---|
| Secret | `SESSION_SECRET` | HMAC session (min 32 chars) |
| Secret | `ALLOWED_EMAILS` | Comma-separated allow list |
| Variable | `VITE_GOOGLE_CLIENT_ID` | Baked into the SPA at **image build** (build-arg, not a runtime env) |

### Next.js

| Kind | Name | Purpose |
|---|---|---|
| Secret | `NEXTAUTH_SECRET` | NextAuth JWT secret |
| Secret | `ALLOWED_USERS` | Optional email allow list |
| Variable | `GOOGLE_WORKSPACE_DOMAIN` | Optional domain restriction |

`NEXTAUTH_URL` and `FRONTEND_URL` are set by the workflow from `TRAEFIK_HOST`. Do not put `DEV_BYPASS_AUTH=true` on this environment.

## After it ships

- `https://<TRAEFIK_HOST>/api/health` should return ok.
- Later deploys: `release:` / `fix:` on `main`, or **workflow_dispatch**.
- App secrets (API keys, OAuth) stay on the same `deploy` environment. The action writes the project `.env` on the VPS. Never bake tokens into the image.
