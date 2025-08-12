#!/usr/bin/env bash
set -euo pipefail

# Env:
# - GITHUB_OUTPUT

PREV_ZIP=$(find .rgjd-cache/prev -type f -name "*.zip" -print -quit || true)
if [ -z "$PREV_ZIP" ]; then
  echo "found=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

echo "found=true" >> "$GITHUB_OUTPUT"
echo "zip_path=$(realpath "$PREV_ZIP")" >> "$GITHUB_OUTPUT"

