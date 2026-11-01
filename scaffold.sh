#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
WORKFLOWS_ROOT="$SCRIPT_DIR/workflow-templates/templates"

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ──────────────────────────────────────────────────────────────────

info()    { echo -e "${CYAN}[info]${RESET} $*"; }
success() { echo -e "${GREEN}[done]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET} $*"; }
error()   { echo -e "${RED}[error]${RESET} $*" >&2; exit 1; }

prompt() {
  local var_name="$1"
  local message="$2"
  local default="${3:-}"
  local value=""

  if [[ -n "$default" ]]; then
    read -r -p "$(echo -e "${BOLD}${message}${RESET} [${default}]: ")" value
    value="${value:-$default}"
  else
    while [[ -z "$value" ]]; do
      read -r -p "$(echo -e "${BOLD}${message}${RESET}: ")" value
    done
  fi

  printf -v "$var_name" '%s' "$value"
}

# Render template vars in all files in a directory (recursive)
render() {
  local dir="$1"
  shift
  local find_args=("-type" "f")

  local sed_expr=""
  while [[ $# -ge 2 ]]; do
    local key="$1"
    local val="$2"
    shift 2
    local escaped_val
    escaped_val=$(printf '%s' "$val" | sed 's|/|\\/|g; s|&|\\&|g')
    sed_expr="${sed_expr}s|${key}|${escaped_val}|g;"
  done

  find "$dir" "${find_args[@]}" | while IFS= read -r file; do
    case "$file" in
      *.png|*.jpg|*.jpeg|*.gif|*.webp|*.ico|*.woff|*.woff2|*.ttf|*.eot|*.zip|*.gz|*.bin)
        continue ;;
    esac
    sed -i.bak "$sed_expr" "$file"
    rm -f "${file}.bak"
  done
}

copy_rendered() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "  wrote $dest"
}

usage() {
  cat <<'EOF'
Usage: scaffold.sh [TARGET_DIR] [options]

Options:
  --template vite|nextjs|cli
  --name NAME                 kebab-case, min 3 chars
  --title TITLE
  --pnpm VERSION              default 10
  --node VERSION              default 24
  --db sqlite|mysql           nextjs only
  --database-url URL
  --app-port N
  --api-port N                vite only
  --deploy hostinger|docker-compose|none
  --ci / --no-ci
  --bump / --no-bump          pnpm update --latest
  --yes, -y                   no prompts; missing values use defaults
  --help, -h

Examples:
  bash scaffold.sh ~/projects/my-app
  bash scaffold.sh ~/projects/my-cli --template cli --name my-cli --yes
EOF
}

# If FLAG_VAL is set, use it. If YES, use DEFAULT (error if empty). Else prompt.
apply_or_prompt() {
  local var_name="$1"
  local message="$2"
  local default="${3:-}"
  local flag_val="${4:-}"

  if [[ -n "$flag_val" ]]; then
    printf -v "$var_name" '%s' "$flag_val"
    return
  fi
  if [[ "$YES" -eq 1 ]]; then
    [[ -n "$default" ]] || error "$message is required (pass a flag or omit --yes)"
    printf -v "$var_name" '%s' "$default"
    return
  fi
  prompt "$var_name" "$message" "$default"
}

apply_yn() {
  local var_name="$1"
  local message="$2"
  local default="$3"
  local flag_val="${4:-}"
  local value=""

  if [[ -n "$flag_val" ]]; then
    printf -v "$var_name" '%s' "$flag_val"
    return
  fi
  if [[ "$YES" -eq 1 ]]; then
    printf -v "$var_name" '%s' "$default"
    return
  fi
  read -r -p "$(echo -e "${BOLD}${message}${RESET} [${default}]: ")" value
  printf -v "$var_name" '%s' "${value:-$default}"
}

require_flag_value() {
  [[ $# -ge 2 ]] || error "$1 requires a value"
}

resolve_template() {
  case "$1" in
    1|vite) TEMPLATE="vite" ;;
    2|nextjs) TEMPLATE="nextjs" ;;
    3|cli) TEMPLATE="cli" ;;
    *) error "Invalid template: $1 (vite, nextjs, or cli)" ;;
  esac
}

resolve_deploy() {
  case "$1" in
    1|hostinger)
      DEPLOY_SCHEME="hostinger"
      DEPLOY_SCHEME_LABEL="Hostinger"
      WORKFLOW_TIER="docker-hostinger"
      ;;
    2|docker|docker-compose|dokploy|coolify)
      DEPLOY_SCHEME="docker-compose"
      DEPLOY_SCHEME_LABEL="Dokploy / Coolify"
      WORKFLOW_TIER="docker-compose"
      ;;
    3|none|ci)
      DEPLOY_SCHEME="none"
      DEPLOY_SCHEME_LABEL="CI only"
      WORKFLOW_TIER="library"
      ;;
    *) error "Invalid deploy scheme: $1 (hostinger, docker-compose, or none)" ;;
  esac
}

resolve_db() {
  case "$1" in
    1|sqlite)
      DB_PROVIDER="sqlite"
      DATABASE_URL="file:./dev.db"
      ;;
    2|mysql)
      DB_PROVIDER="mysql"
      DATABASE_URL="mysql://root:password@127.0.0.1:3306/${PROJECT_NAME}"
      ;;
    *) error "Invalid database: $1 (sqlite or mysql)" ;;
  esac
}

# ── Validate tools ────────────────────────────────────────────────────────────

for cmd in git pnpm sed find cp; do
  command -v "$cmd" >/dev/null 2>&1 || error "'$cmd' is required but not installed."
done

# ── Flags ─────────────────────────────────────────────────────────────────────

YES=0
FLAG_TEMPLATE=""
FLAG_NAME=""
FLAG_TITLE=""
FLAG_PNPM=""
FLAG_NODE=""
FLAG_DB=""
FLAG_DATABASE_URL=""
FLAG_APP_PORT=""
FLAG_API_PORT=""
FLAG_DEPLOY=""
FLAG_CI=""
FLAG_BUMP=""
TARGET_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template)      require_flag_value "$@"; FLAG_TEMPLATE="$2"; shift 2 ;;
    --name)          require_flag_value "$@"; FLAG_NAME="$2"; shift 2 ;;
    --title)         require_flag_value "$@"; FLAG_TITLE="$2"; shift 2 ;;
    --pnpm)          require_flag_value "$@"; FLAG_PNPM="$2"; shift 2 ;;
    --node)          require_flag_value "$@"; FLAG_NODE="$2"; shift 2 ;;
    --db)            require_flag_value "$@"; FLAG_DB="$2"; shift 2 ;;
    --database-url)  require_flag_value "$@"; FLAG_DATABASE_URL="$2"; shift 2 ;;
    --app-port)      require_flag_value "$@"; FLAG_APP_PORT="$2"; shift 2 ;;
    --api-port)      require_flag_value "$@"; FLAG_API_PORT="$2"; shift 2 ;;
    --deploy)        require_flag_value "$@"; FLAG_DEPLOY="$2"; shift 2 ;;
    --ci)            FLAG_CI="Y"; shift ;;
    --no-ci)         FLAG_CI="n"; shift ;;
    --bump)          FLAG_BUMP="Y"; shift ;;
    --no-bump)       FLAG_BUMP="n"; shift ;;
    --yes|-y)        YES=1; shift ;;
    --help|-h)       usage; exit 0 ;;
    -*)              error "Unknown flag: $1" ;;
    *)
      if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$1"
        shift
      else
        error "Unexpected argument: $1"
      fi
      ;;
  esac
done

# ── Banner ────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║       Project Template Scaffold       ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}"
echo ""

# ── Prompts ───────────────────────────────────────────────────────────────────

if [[ -z "$TARGET_DIR" ]]; then
  [[ "$YES" -eq 1 ]] && error "Pass a target directory with --yes"
  prompt TARGET_DIR "Target directory (absolute or relative path)"
fi
if [[ "$TARGET_DIR" != /* ]]; then
  TARGET_DIR="$PWD/$TARGET_DIR"
fi
TARGET_DIR="$(cd "$(dirname "$TARGET_DIR")" 2>/dev/null && pwd)/$(basename "$TARGET_DIR")"

if [[ -e "$TARGET_DIR" ]]; then
  error "Directory already exists: $TARGET_DIR"
fi

if [[ -n "$FLAG_NAME" ]]; then
  PROJECT_NAME="$FLAG_NAME"
elif [[ "$YES" -eq 1 ]]; then
  PROJECT_NAME="$(basename "$TARGET_DIR")"
else
  prompt PROJECT_NAME "Project name (kebab-case, min 3 chars)"
fi
if ! [[ "$PROJECT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  error "Project name must be kebab-case (lowercase letters, numbers, hyphens)"
fi
if [[ ${#PROJECT_NAME} -lt 3 ]]; then
  error "Project name must be at least 3 characters (Hostinger rejects shorter names)"
fi

DERIVED_TITLE=$(echo "$PROJECT_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')
apply_or_prompt PROJECT_TITLE "Project title" "$DERIVED_TITLE" "$FLAG_TITLE"

if [[ -n "$FLAG_TEMPLATE" ]]; then
  resolve_template "$FLAG_TEMPLATE"
elif [[ "$YES" -eq 1 ]]; then
  error "Pass --template vite|nextjs|cli with --yes"
else
  echo ""
  echo -e "Choose template:"
  echo "  1) vite    — React + Express + Prisma (MySQL)"
  echo "  2) nextjs  — Next.js App Router + NextAuth + Prisma"
  echo "  3) cli     — TypeScript command-line tool (no Docker)"
  echo ""
  prompt TEMPLATE_CHOICE "Template" "1"
  resolve_template "$TEMPLATE_CHOICE"
fi

echo ""
apply_or_prompt PNPM_VERSION "pnpm version" "10" "$FLAG_PNPM"
apply_or_prompt NODE_VERSION "Node.js version" "24" "$FLAG_NODE"

APP_PORT=""
API_PORT=""
DB_PROVIDER=""
DATABASE_URL=""

if [[ "$TEMPLATE" == "vite" ]]; then
  DB_PROVIDER="mysql"
  apply_or_prompt APP_PORT "Frontend port" "5173" "$FLAG_APP_PORT"
  apply_or_prompt API_PORT "API port" "3001" "$FLAG_API_PORT"
  apply_or_prompt DATABASE_URL "DATABASE_URL" \
    "mysql://root:password@127.0.0.1:3306/${PROJECT_NAME}" "$FLAG_DATABASE_URL"
elif [[ "$TEMPLATE" == "nextjs" ]]; then
  apply_or_prompt APP_PORT "App port" "3000" "$FLAG_APP_PORT"

  if [[ -n "$FLAG_DB" ]]; then
    resolve_db "$FLAG_DB"
  elif [[ "$YES" -eq 1 ]]; then
    resolve_db "sqlite"
  else
    echo ""
    echo "  Choose database provider:"
    echo "  1) sqlite  — local file, no server required"
    echo "  2) mysql   — requires MySQL server"
    echo ""
    prompt DB_CHOICE "Database" "1"
    resolve_db "$DB_CHOICE"
  fi

  apply_or_prompt DATABASE_URL "DATABASE_URL" "$DATABASE_URL" "$FLAG_DATABASE_URL"
fi

if [[ "$TEMPLATE" == "cli" ]]; then
  resolve_deploy "none"
elif [[ -n "$FLAG_DEPLOY" ]]; then
  resolve_deploy "$FLAG_DEPLOY"
elif [[ "$YES" -eq 1 ]]; then
  resolve_deploy "docker-compose"
else
  echo ""
  echo "  Deploy scheme:"
  echo "  1) hostinger  — GHCR image + Hostinger VPS (Traefik labels)"
  echo "  2) docker     — Dokploy / Coolify / generic Compose host"
  echo "  3) none       — CI only, no Docker"
  echo ""
  prompt DEPLOY_CHOICE "Deploy scheme" "2"
  resolve_deploy "$DEPLOY_CHOICE"
fi

echo ""
if [[ -d "$WORKFLOWS_ROOT" ]]; then
  apply_yn INCLUDE_CICD "Include CI/CD workflows?" "Y" "$FLAG_CI"
else
  warn "workflow-templates submodule not initialised — run: git submodule update --init"
  INCLUDE_CICD="n"
fi

echo ""
apply_yn BUMP_DEPS "Bump dependencies to npm latest?" "Y" "$FLAG_BUMP"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Summary${RESET}"
echo "  Template:       $TEMPLATE"
echo "  Name:           $PROJECT_NAME"
echo "  Title:          $PROJECT_TITLE"
echo "  Directory:      $TARGET_DIR"
[[ -n "$APP_PORT" ]] && echo "  App port:       $APP_PORT"
[[ -n "$API_PORT" ]] && echo "  API port:       $API_PORT"
[[ -n "$DB_PROVIDER" ]] && echo "  DB provider:    $DB_PROVIDER"
echo "  Deploy:         $DEPLOY_SCHEME_LABEL"
echo "  Node version:   $NODE_VERSION"
echo "  pnpm version:   $PNPM_VERSION"
if [[ "$BUMP_DEPS" =~ ^[Yy]$ ]]; then
  echo "  Deps:           npm latest (pnpm update --latest)"
else
  echo "  Deps:           template pins"
fi
echo ""
if [[ "$YES" -eq 1 ]]; then
  CONFIRM="Y"
else
  apply_yn CONFIRM "Proceed?" "Y"
fi
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ── Copy template ─────────────────────────────────────────────────────────────

info "Copying template ${TEMPLATE} → ${TARGET_DIR}"
cp -r "$TEMPLATES_DIR/$TEMPLATE" "$TARGET_DIR"

# Keep public/.gitkeep so Docker COPY public/ has a directory in git.
find "$TARGET_DIR" -path '*/components/ui/.gitkeep' -delete

if [[ "$DEPLOY_SCHEME" == "none" ]]; then
  rm -rf "$TARGET_DIR/docker" \
    "$TARGET_DIR/Dockerfile" \
    "$TARGET_DIR/docker-compose.hostinger.yml" \
    "$TARGET_DIR/docker-compose.dokploy.yml" \
    "$TARGET_DIR/docker-compose.override.yml" \
    "$TARGET_DIR/.dockerignore" \
    "$TARGET_DIR/docs/DOCKER.md"
  rmdir "$TARGET_DIR/docs" 2>/dev/null || true
elif [[ "$DEPLOY_SCHEME" == "hostinger" ]]; then
  cp "$TARGET_DIR/docker-compose.hostinger.yml" "$TARGET_DIR/docker-compose.yml"
  rm -f "$TARGET_DIR/docker-compose.override.yml"
  chmod +x "$TARGET_DIR/docker/entrypoint.sh"
else
  cp "$TARGET_DIR/docker-compose.dokploy.yml" "$TARGET_DIR/docker-compose.yml"
  chmod +x "$TARGET_DIR/docker/entrypoint.sh"
fi

# ── Render template vars ──────────────────────────────────────────────────────

info "Rendering template variables"
render "$TARGET_DIR" \
  "{{PROJECT_NAME}}"  "$PROJECT_NAME" \
  "{{PROJECT_TITLE}}" "$PROJECT_TITLE" \
  "{{PNPM_VERSION}}"  "$PNPM_VERSION" \
  "{{NODE_VERSION}}"  "$NODE_VERSION" \
  "{{DB_PROVIDER}}"   "$DB_PROVIDER" \
  "{{DATABASE_URL}}"  "$DATABASE_URL" \
  "{{APP_PORT}}"      "$APP_PORT" \
  "{{API_PORT}}"      "$API_PORT" \
  "{{DEPLOY_SCHEME}}" "$DEPLOY_SCHEME_LABEL"

if [[ "$DB_PROVIDER" == "sqlite" ]]; then
  SCHEMA_FILE="$TARGET_DIR/prisma/schema.prisma"
  if [[ -f "$SCHEMA_FILE" ]]; then
    sed -i.bak '/shadowDatabaseUrl/d' "$SCHEMA_FILE"
    rm -f "${SCHEMA_FILE}.bak"
  fi
fi

# ── CI/CD workflows ────────────────────────────────────────────────────────────

if [[ "$INCLUDE_CICD" =~ ^[Yy]$ ]]; then
  info "Copying CI/CD workflows ($WORKFLOW_TIER)"
  mkdir -p "$TARGET_DIR/.github/workflows"
  copy_rendered "$WORKFLOWS_ROOT/$WORKFLOW_TIER/ci.yml" "$TARGET_DIR/.github/workflows/ci.yml"
  copy_rendered "$WORKFLOWS_ROOT/dependabot.yml" "$TARGET_DIR/.github/dependabot.yml"

  if [[ "$WORKFLOW_TIER" == "docker-hostinger" ]]; then
    copy_rendered "$WORKFLOWS_ROOT/docker-hostinger/deploy.yml" "$TARGET_DIR/.github/workflows/deploy.yml"
    mkdir -p "$TARGET_DIR/.github/scripts"
    copy_rendered "$WORKFLOWS_ROOT/scripts/deploy-gate.sh" "$TARGET_DIR/.github/scripts/deploy-gate.sh"
    chmod +x "$TARGET_DIR/.github/scripts/deploy-gate.sh"
  fi

  render "$TARGET_DIR/.github" \
    "{{PROJECT_NAME}}"  "$PROJECT_NAME" \
    "{{PROJECT_TITLE}}" "$PROJECT_TITLE" \
    "{{PNPM_VERSION}}"  "$PNPM_VERSION" \
    "{{NODE_VERSION}}"  "$NODE_VERSION" \
    "{{DB_PROVIDER}}"   "$DB_PROVIDER" \
    "{{DATABASE_URL}}"  "$DATABASE_URL" \
    "{{APP_PORT}}"      "$APP_PORT" \
    "{{API_PORT}}"      "$API_PORT" \
    "{{DEPLOY_SCHEME}}" "$DEPLOY_SCHEME_LABEL"
fi

# ── Env files ────────────────────────────────────────────────────────────────

if [[ "$TEMPLATE" == "vite" || "$TEMPLATE" == "nextjs" ]]; then
  cp "$TARGET_DIR/.env.vars.example" "$TARGET_DIR/.env.vars"
  cp "$TARGET_DIR/.env.secrets.example" "$TARGET_DIR/.env.secrets"
  info "Created .env.vars and .env.secrets from examples"
fi

# ── Git init ───────────────────────────────────────────────────────────────────

info "Initialising git repository"
git -C "$TARGET_DIR" init

if [[ "$BUMP_DEPS" =~ ^[Yy]$ ]]; then
  info "Bumping dependencies to npm latest"
  if ( cd "$TARGET_DIR" && pnpm update --latest ); then
    success "package.json and pnpm-lock.yaml now use current npm latest"
  else
    warn "Bump failed (offline or registry error). Keeping template pins."
    warn "Later: cd ${TARGET_DIR} && pnpm update --latest"
    ( cd "$TARGET_DIR" && pnpm install ) || warn "pnpm install also failed."
  fi
else
  info "Installing dependencies (template pins)"
  if ( cd "$TARGET_DIR" && pnpm install ); then
    success "pnpm-lock.yaml written from template pins"
  else
    warn "pnpm install failed (offline or registry error)."
    warn "Later: cd ${TARGET_DIR} && pnpm install"
  fi
fi

git -C "$TARGET_DIR" add .
git -C "$TARGET_DIR" commit -m "Initial commit."

# ── Done ───────────────────────────────────────────────────────────────────────

echo ""
success "Project scaffolded at ${TARGET_DIR}"
echo ""
REL_DIR="$(realpath --relative-to="$PWD" "$TARGET_DIR" 2>/dev/null || echo "$TARGET_DIR")"
echo -e "${BOLD}Next steps:${RESET}"

if [[ "$TEMPLATE" == "cli" ]]; then
  echo "  1. cd ${REL_DIR}"
  echo "  2. pnpm install"
  echo "  3. pnpm dev"
elif [[ "$TEMPLATE" == "vite" ]]; then
  echo "  1. cd ${REL_DIR}"
  echo "  2. Fill in .env.vars and .env.secrets, then pnpm env:merge"
  echo "  3. Create MySQL databases:"
  echo "       CREATE DATABASE \`${PROJECT_NAME}\`;"
  echo "       CREATE DATABASE \`${PROJECT_NAME}_shadow\`;"
  echo "  4. pnpm install"
  echo "  5. pnpm prisma:migrate  # commit the migration files"
  echo "  6. pnpm dev:all"
else
  echo "  1. cd ${REL_DIR}"
  echo "  2. Fill in .env.vars and .env.secrets, then pnpm env:merge"
  if [[ "$DB_PROVIDER" == "mysql" ]]; then
    echo "  3. Create MySQL database:"
    echo "       CREATE DATABASE \`${PROJECT_NAME}\`;"
    echo "       CREATE DATABASE \`${PROJECT_NAME}_shadow\`;"
    echo "  4. pnpm install"
    echo "  5. pnpm prisma:migrate  # or prisma:push for local-only"
    echo "  6. pnpm dev"
  else
    echo "  3. pnpm install"
    echo "  4. pnpm prisma:migrate"
    echo "  5. pnpm dev"
  fi
fi

if [[ "$TEMPLATE" == "vite" ]]; then
  echo ""
  echo "  Google OAuth: frontend origin http://localhost:${APP_PORT}"
  echo "  (GIS flow; no redirect URI)"
elif [[ "$TEMPLATE" == "nextjs" ]]; then
  echo ""
  echo "  Google OAuth redirect URI:"
  echo "    http://localhost:${APP_PORT}/api/auth/callback/google"
fi

if [[ "$DEPLOY_SCHEME" == "hostinger" ]]; then
  echo ""
  echo "  Docker: see docs/DOCKER.md"
  echo "  Hostinger: GitHub environment 'deploy' (HOSTINGER_*, TRAEFIK_*, app secrets),"
  echo "             VPS deploy key on the repo, docker login ghcr.io on the VPS"
elif [[ "$DEPLOY_SCHEME" == "docker-compose" ]]; then
  echo ""
  echo "  Docker: see docs/DOCKER.md"
  echo "  Dokploy/Coolify: point at this repo, compose path docker-compose.yml, port 8080"
fi
echo ""
