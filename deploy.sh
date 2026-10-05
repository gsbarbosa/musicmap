#!/usr/bin/env bash
# Build Flutter Web + deploy completo no Firebase (hosting, database, storage, functions).
# Uso:
#   ./deploy.sh
#   ./deploy.sh --only hosting,database
#   chmod +x deploy.sh   (primeira vez)

set -euo pipefail
cd "$(dirname "$0")"

echo "==> Flutter build web (release)..."
if command -v fvm >/dev/null 2>&1; then
  fvm flutter build web --base-href / --release
else
  flutter build web --base-href / --release
fi

echo "==> Firebase deploy..."
firebase deploy "$@"
