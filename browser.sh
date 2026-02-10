#!/usr/bin/env bash
set -euo pipefail

# Default browser handler (Chrome)
# https://github.com/moretension/duti

if ! command -v duti >/dev/null 2>&1; then
  echo "duti not found; skipping default browser config."
  exit 0
fi

BUNDLE_ID="com.google.Chrome"

duti -s "$BUNDLE_ID" http
duti -s "$BUNDLE_ID" https
duti -s "$BUNDLE_ID" public.url
duti -s "$BUNDLE_ID" public.html
duti -s "$BUNDLE_ID" public.xhtml
