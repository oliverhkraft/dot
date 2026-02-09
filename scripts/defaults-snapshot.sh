#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME="${1:-snapshot}"
OUT="$ROOT/.defaults-snapshots/$NAME"
mkdir -p "$OUT"

DOMAINS=(
  "NSGlobalDomain"
  "com.apple.dock"
  "com.apple.finder"
  "com.apple.screencapture"
  "com.apple.menuextra.clock"
)

echo "Creating snapshot '$NAME' in: $OUT"
for d in "${DOMAINS[@]}"; do
  defaults export "$d" - > "$OUT/$d.plist" 2>/dev/null || true
done

echo "Snapshot '$NAME' created"
echo "Tip: diff two snapshots with:"
echo "  diff -ru .defaults-snapshots/before .defaults-snapshots/after | less"
