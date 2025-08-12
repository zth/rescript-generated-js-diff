#!/usr/bin/env bash
set -euo pipefail

# Inputs via env:
# - CURRENT_BRANCH
# - INPUT_TARGET_BRANCH
# - GITHUB_BASE_REF
# - GITHUB_HEAD_REF
# - RUNNER_TEMP
# - GITHUB_OUTPUT

BRANCH_NAME="${CURRENT_BRANCH}"
if [ -n "${GITHUB_HEAD_REF:-}" ]; then BRANCH_NAME="$GITHUB_HEAD_REF"; fi

# Sanitize branch name for filenames and artifact names
BRANCH_SAFE=${BRANCH_NAME//\//-}
ZIP_NAME="latest-diff--${BRANCH_SAFE}.zip"
OUT_DIR="${RUNNER_TEMP:-$PWD}/rgjd-out"
mkdir -p "$OUT_DIR"
ZIP_PATH="$OUT_DIR/$ZIP_NAME"

echo "branch_name=$BRANCH_NAME" >> "$GITHUB_OUTPUT"
echo "branch_safe=$BRANCH_SAFE" >> "$GITHUB_OUTPUT"

# Determine target branch: explicit input > PR base > main
TARGET_BRANCH="${INPUT_TARGET_BRANCH}"
if [ -z "$TARGET_BRANCH" ] && [ -n "${GITHUB_BASE_REF:-}" ]; then TARGET_BRANCH="$GITHUB_BASE_REF"; fi
if [ -z "$TARGET_BRANCH" ]; then TARGET_BRANCH="main"; fi
TARGET_SAFE=${TARGET_BRANCH//\//-}
echo "target_branch=$TARGET_BRANCH" >> "$GITHUB_OUTPUT"
echo "target_safe=$TARGET_SAFE" >> "$GITHUB_OUTPUT"

echo "zip_name=$ZIP_NAME" >> "$GITHUB_OUTPUT"
echo "zip_path=$ZIP_PATH" >> "$GITHUB_OUTPUT"

# Whether we are on the target branch (skip diffing in that case)
if [ "$BRANCH_NAME" = "$TARGET_BRANCH" ]; then
  echo "is_same_branch=true" >> "$GITHUB_OUTPUT"
else
  echo "is_same_branch=false" >> "$GITHUB_OUTPUT"
fi

