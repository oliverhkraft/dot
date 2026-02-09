#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="${DISPLAYPLACER_CONFIG:-$ROOT/displayplacer.conf}"

if ! command -v displayplacer >/dev/null 2>&1; then
  echo "displayplacer not found; skipping display config."
  exit 0
fi

if [ ! -f "$CONF" ]; then
  echo "displayplacer config not found at: $CONF (skipping)"
  exit 0
fi

mapfile -t lines < <(grep -v '^[[:space:]]*#' "$CONF" | sed '/^[[:space:]]*$/d')
if [ ${#lines[@]} -eq 0 ]; then
  echo "displayplacer config is empty; skipping"
  exit 0
fi

args=()
for line in "${lines[@]}"; do
  if [[ "$line" == displayplacer* ]]; then
    line="${line#displayplacer }"
  fi
  read -r -a parts <<<"$line"
  args+=("${parts[@]}")
done

if [ ${#args[@]} -eq 0 ]; then
  echo "displayplacer config produced no arguments; skipping"
  exit 0
fi

echo "Applying display configuration"
displayplacer "${args[@]}"
