#!/bin/bash
# sync-config.sh - Wrapper around the Node implementation
# Usage: ./sync-config.sh "Optional commit message"

set -euo pipefail

if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js is required."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

node "$SCRIPT_DIR/sync-config.js" "$@"
