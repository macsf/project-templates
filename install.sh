#!/usr/bin/env bash
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/macsf/project-templates/main/install.sh)
set -euo pipefail

REPO="https://github.com/macsf/project-templates"
TMP=$(mktemp -d)

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# Colors
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}[info]${RESET} Fetching project-templates..."
git clone --quiet --depth=1 --recurse-submodules "$REPO" "$TMP/project-templates"

exec bash "$TMP/project-templates/scaffold.sh" "$@"
