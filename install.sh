#!/usr/bin/env bash
# Other machine. Prompts need a TTY; do not `curl | bash`.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/macsf/project-templates/main/install.sh)
#   bash <(curl -fsSL https://raw.githubusercontent.com/macsf/project-templates/main/install.sh) ~/projects/new-app
set -euo pipefail

REPO_HTTPS="https://github.com/macsf/project-templates.git"
SUBMODULE_HTTPS="https://github.com/macsf/workflow-templates.git"
TMP=$(mktemp -d)

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}[info]${RESET} Fetching project-templates..."
git clone --quiet --depth=1 "$REPO_HTTPS" "$TMP/project-templates"
git -C "$TMP/project-templates" submodule set-url workflow-templates "$SUBMODULE_HTTPS"
git -C "$TMP/project-templates" submodule update --init --depth=1 --quiet

bash "$TMP/project-templates/scaffold.sh" "$@"
