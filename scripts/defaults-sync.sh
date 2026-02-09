#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/defaults-export"
mkdir -p "$OUT"

DOMAINS=(
  "NSGlobalDomain"
  "com.apple.dock"
  "com.apple.finder"
  "com.apple.screencapture"
  "com.apple.trackpad"
  "com.apple.AppleMultitouchTrackpad"
  "com.apple.menuextra.clock"
  "com.googlecode.iterm2"
)

echo "Exporting current macOS defaults to: $OUT"
for d in "${DOMAINS[@]}"; do
  f="$OUT/$d.plist"
  echo " - $d"
  defaults export "$d" - > "$f" 2>/dev/null || {
    echo "   (could not export $d; skipping)"
    rm -f "$f" || true
    continue
  }
done

echo
printf "Diff vs repo:\n"
git -C "$ROOT" diff -- "$OUT" || true

echo
printf "Next steps:\n"
printf " 1) Review the diff above\n"
printf " 2) Commit defaults-export/*.plist if you want an audit trail\n"
printf " 3) Promote important changes into defaults.sh (enforced)\n"
