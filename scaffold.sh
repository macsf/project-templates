#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
WORKFLOWS_DIR="$SCRIPT_DIR/../workflow-templates/templates/fullstack-app"

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
  # $@ = pairs of PLACEHOLDER VALUE
  local find_args=("-type" "f")

  # Build sed expression
  local sed_expr=""
  while [[ $# -ge 2 ]]; do
    local key="$1"
    local val="$2"
    shift 2
    # Escape / in value for sed
    local escaped_val
    escaped_val=$(printf '%s' "$val" | sed 's|/|\\/|g; s|&|\\&|g')
    sed_expr="${sed_expr}s|${key}|${escaped_val}|g;"
  done

  find "$dir" "${find_args[@]}" | while IFS= read -r file; do
    # Skip binary files
    if file "$file" | grep -q "text"; then
      sed -i.bak "$sed_expr" "$file"
      rm -f "${file}.bak"
    fi
  done
}

# ── Validate tools ────────────────────────────────────────────────────────────

for cmd in git pnpm sed find cp; do
  command -v "$cmd" >/dev/null 2>&1 || error "'$cmd' is required but not installed."
done

# ── Banner ────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║       Project Template Scaffold       ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}"
echo ""

# ── Prompts ───────────────────────────────────────────────────────────────────

prompt TARGET_DIR  "Target directory (absolute or relative path)"
TARGET_DIR="$(cd "$(dirname "$TARGET_DIR")/.." 2>/dev/null && pwd)/$(basename "$TARGET_DIR")" || TARGET_DIR="$TARGET_DIR"
# Resolve relative paths
if [[ "$TARGET_DIR" != /* ]]; then
  TARGET_DIR="$PWD/$TARGET_DIR"
fi

if [[ -e "$TARGET_DIR" ]]; then
  error "Directory already exists: $TARGET_DIR"
fi

prompt PROJECT_NAME  "Project name (kebab-case)"
# Validate kebab-case
if ! [[ "$PROJECT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  error "Project name must be kebab-case (lowercase letters, numbers, hyphens)"
fi

# Derive title from name: replace hyphens with spaces and title-case
PROJECT_TITLE=$(echo "$PROJECT_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')
prompt PROJECT_TITLE "Project title" "$PROJECT_TITLE"

echo ""
echo -e "Choose template:"
echo "  1) vite    — React + Express + Prisma (MySQL)"
echo "  2) nextjs  — Next.js 15 App Router + NextAuth + Prisma"
echo ""
prompt TEMPLATE_CHOICE "Template" "1"

case "$TEMPLATE_CHOICE" in
  1|vite)   TEMPLATE="vite"   ;;
  2|nextjs) TEMPLATE="nextjs" ;;
  *) error "Invalid template choice: $TEMPLATE_CHOICE" ;;
esac

echo ""
prompt PNPM_VERSION  "pnpm version" "10"
prompt NODE_VERSION  "Node.js version" "22"

# Template-specific prompts
if [[ "$TEMPLATE" == "vite" ]]; then
  APP_PORT="5173"
  API_PORT="3001"
  DB_PROVIDER="mysql"
  API_DIR="server"
  prompt APP_PORT  "Frontend port" "$APP_PORT"
  prompt API_PORT  "API port"      "$API_PORT"
  DATABASE_URL="mysql://root:password@127.0.0.1:3306/${PROJECT_NAME}"
  prompt DATABASE_URL "DATABASE_URL" "$DATABASE_URL"
else
  APP_PORT="3000"
  API_PORT=""
  API_DIR="."
  prompt APP_PORT "App port" "$APP_PORT"

  echo ""
  echo "  Choose database provider:"
  echo "  1) sqlite  — local file, no server required"
  echo "  2) mysql   — requires MySQL server"
  echo ""
  prompt DB_CHOICE "Database" "1"

  case "$DB_CHOICE" in
    1|sqlite)
      DB_PROVIDER="sqlite"
      DATABASE_URL="file:./dev.db"
      ;;
    2|mysql)
      DB_PROVIDER="mysql"
      DATABASE_URL="mysql://root:password@127.0.0.1:3306/${PROJECT_NAME}"
      ;;
    *) error "Invalid database choice: $DB_CHOICE" ;;
  esac

  prompt DATABASE_URL "DATABASE_URL" "$DATABASE_URL"
fi

echo ""
APP_DIR_DEFAULT="/opt/${PROJECT_NAME}"
prompt APP_DIR       "Deployment app dir (for CI/CD)" "$APP_DIR_DEFAULT"
prompt PM2_APP_NAME  "PM2 app name"                   "$PROJECT_NAME"

# CI/CD workflow
echo ""
if [[ -d "$WORKFLOWS_DIR" ]]; then
  read -r -p "$(echo -e "${BOLD}Include CI/CD workflows from workflow-templates?${RESET} [Y/n]: ")" INCLUDE_CICD
  INCLUDE_CICD="${INCLUDE_CICD:-Y}"
else
  warn "workflow-templates not found at $WORKFLOWS_DIR — skipping CI/CD"
  INCLUDE_CICD="n"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Summary${RESET}"
echo "  Template:       $TEMPLATE"
echo "  Name:           $PROJECT_NAME"
echo "  Title:          $PROJECT_TITLE"
echo "  Directory:      $TARGET_DIR"
echo "  App port:       $APP_PORT"
[[ -n "$API_PORT" ]] && echo "  API port:       $API_PORT"
echo "  DB provider:    $DB_PROVIDER"
echo "  Node version:   $NODE_VERSION"
echo "  pnpm version:   $PNPM_VERSION"
echo ""
read -r -p "$(echo -e "${BOLD}Proceed?${RESET} [Y/n]: ")" CONFIRM
CONFIRM="${CONFIRM:-Y}"
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ── Copy template ─────────────────────────────────────────────────────────────

info "Copying template ${TEMPLATE} → ${TARGET_DIR}"
cp -r "$TEMPLATES_DIR/$TEMPLATE" "$TARGET_DIR"

# Remove .gitkeep files (they only exist to track empty dirs in git)
find "$TARGET_DIR" -name ".gitkeep" -delete

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
  "{{APP_DIR}}"       "$APP_DIR" \
  "{{PM2_APP_NAME}}"  "$PM2_APP_NAME" \
  "{{API_DIR}}"       "$API_DIR"

# For SQLite: remove the MYSQL_ONLY shadowDatabaseUrl line from Prisma schema
if [[ "$DB_PROVIDER" == "sqlite" ]]; then
  SCHEMA_FILE="$TARGET_DIR/prisma/schema.prisma"
  if [[ -f "$SCHEMA_FILE" ]]; then
    sed -i.bak '/# MYSQL_ONLY/d' "$SCHEMA_FILE"
    rm -f "${SCHEMA_FILE}.bak"
  fi
fi

# ── CI/CD workflows ────────────────────────────────────────────────────────────

if [[ "$INCLUDE_CICD" =~ ^[Yy]$ ]]; then
  info "Copying CI/CD workflows from workflow-templates"
  mkdir -p "$TARGET_DIR/.github/workflows"
  cp -r "$WORKFLOWS_DIR/." "$TARGET_DIR/.github/workflows/"

  render "$TARGET_DIR/.github" \
    "{{PROJECT_NAME}}"  "$PROJECT_NAME" \
    "{{PROJECT_TITLE}}" "$PROJECT_TITLE" \
    "{{PNPM_VERSION}}"  "$PNPM_VERSION" \
    "{{NODE_VERSION}}"  "$NODE_VERSION" \
    "{{DB_PROVIDER}}"   "$DB_PROVIDER" \
    "{{DATABASE_URL}}"  "$DATABASE_URL" \
    "{{APP_PORT}}"      "$APP_PORT" \
    "{{API_PORT}}"      "$API_PORT" \
    "{{APP_DIR}}"       "$APP_DIR" \
    "{{PM2_APP_NAME}}"  "$PM2_APP_NAME" \
    "{{API_DIR}}"       "$API_DIR"
fi

# ── Git init ───────────────────────────────────────────────────────────────────

info "Initialising git repository"
git -C "$TARGET_DIR" init
git -C "$TARGET_DIR" add .

# ── Done ───────────────────────────────────────────────────────────────────────

echo ""
success "Project scaffolded at ${TARGET_DIR}"
echo ""
echo -e "${BOLD}Next steps:${RESET}"
echo "  cd $(realpath --relative-to="$PWD" "$TARGET_DIR" 2>/dev/null || echo "$TARGET_DIR")"
echo ""

if [[ "$TEMPLATE" == "vite" ]]; then
  echo "  1. Copy .env.example → .env and fill in secrets"
  echo "  2. Create MySQL databases:"
  echo "       CREATE DATABASE \`${PROJECT_NAME}\`;"
  echo "       CREATE DATABASE \`${PROJECT_NAME}_shadow\`;"
  echo "  3. pnpm install"
  echo "  4. pnpm prisma:migrate  # or prisma:migrate:deploy"
  echo "  5. pnpm dev:all"
else
  echo "  1. Copy .env.local.example → .env.local and fill in secrets"
  if [[ "$DB_PROVIDER" == "mysql" ]]; then
    echo "  2. Create MySQL database:"
    echo "       CREATE DATABASE \`${PROJECT_NAME}\`;"
    echo "       CREATE DATABASE \`${PROJECT_NAME}_shadow\`;"
  fi
  echo "  2. pnpm install"
  echo "  3. pnpm prisma:migrate  # or prisma:push for dev"
  echo "  4. pnpm dev"
fi

echo ""
echo "  Google OAuth redirect URI:"
if [[ "$TEMPLATE" == "vite" ]]; then
  echo "    http://localhost:${APP_PORT}  (frontend origin)"
  echo "    (handled by backend — no redirect URI needed for GIS flow)"
else
  echo "    http://localhost:${APP_PORT}/api/auth/callback/google"
fi
echo ""
