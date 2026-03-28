#!/bin/bash
# Build the Quartz site from the vault.
# Usage: build.sh [--title "World Name"] [--base-url "example.com"]

set -euo pipefail

PAGE_TITLE="${PAGE_TITLE:-Grove}"
BASE_URL="${BASE_URL:-localhost}"

# Parse optional flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) PAGE_TITLE="$2"; shift 2 ;;
    --base-url) BASE_URL="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "[build] Building site: ${PAGE_TITLE}"

# Copy vault content into site/content/
rm -rf site/content/*
cp -r vault/* site/content/

# Build
cd site
PAGE_TITLE="$PAGE_TITLE" BASE_URL="$BASE_URL" node quartz/bootstrap-cli.mjs build

echo "[build] Done. Output in site/public/"
