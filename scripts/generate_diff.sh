#!/usr/bin/env bash
set -euo pipefail

# Env inputs:
# - INPUT_DIFF_STYLE
# - IN_NAME (may be empty)
# - CURR_SAFE
# - TGT_SAFE
# - RUNNER_TEMP
# - GITHUB_OUTPUT

CURR_ZIP="$1"
PREV_ZIP="$2"

WORK="${RUNNER_TEMP:-$PWD}/rgjd-work"
# Use branch-safe names as directory labels so diff2html can display `{target → current}`
mkdir -p "$WORK/$TGT_SAFE" "$WORK/$CURR_SAFE"

unzip -q "$PREV_ZIP" -d "$WORK/$TGT_SAFE"
unzip -q "$CURR_ZIP" -d "$WORK/$CURR_SAFE"

RAW_PATCH="$WORK/diff.raw.patch"
(
  cd "$WORK"
  git -c core.quotepath=false -c color.ui=never diff --no-index \
    "$TGT_SAFE" "$CURR_SAFE" > "$RAW_PATCH" || true
)

if [ ! -s "$RAW_PATCH" ]; then
  echo "has_changes=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

# Produce a cleaned patch for artifacts by stripping the first path component
# after a/ and b/ so paths are repo-relative (independent of the labels used).
CLEAN_PATCH="$WORK/diff.patch"
TMP_DIFF="$WORK/diff.tmp.patch"
sed -E \
  -e 's|^(diff --git )a/[^/]+/|\1a/|' \
  -e 's| b/[^/]+/| b/|' \
  -e 's|^--- a/[^/]+/|--- a/|' \
  -e 's|^\+\+\+ b/[^/]+/|+++ b/|' \
  -e 's|^rename from [^/]+/|rename from |' \
  -e 's|^rename to [^/]+/|rename to |' \
  -e 's|^(diff --git )a/|\1|' \
  -e 's| b/| |' \
  -e 's|^--- a/|--- |' \
  -e 's|^\+\+\+ b/|+++ |' \
  "$RAW_PATCH" > "$TMP_DIFF" || true
mv "$TMP_DIFF" "$CLEAN_PATCH"

STYLE=$(echo "${INPUT_DIFF_STYLE:-side}" | tr 'A-Z' 'a-z')
if [ "$STYLE" != "side" ] && [ "$STYLE" != "line" ]; then STYLE="side"; fi

NAME="${IN_NAME:-}"
if [ -z "$NAME" ]; then
  NAME="latest-diff--${TGT_SAFE}-vs-${CURR_SAFE}.html"
fi

PATCH_NAME="$NAME"
if [[ "$PATCH_NAME" == *.html ]]; then
  PATCH_NAME="${PATCH_NAME%.html}.patch"
else
  PATCH_NAME="${PATCH_NAME}.patch"
fi

OUT_HTML="$WORK/$NAME"
OUT_PATCH="$WORK/$PATCH_NAME"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_TEMPLATE="${SCRIPT_DIR}/../templates/diff2html-wrapper.html"
npx --yes diff2html-cli@5 -i file -s "$STYLE" -F "$OUT_HTML" --hwt "$WRAPPER_TEMPLATE" -- "$RAW_PATCH"
mv "$CLEAN_PATCH" "$OUT_PATCH"


echo "diff_html_path=$OUT_HTML" >> "$GITHUB_OUTPUT"
echo "diff_patch_path=$OUT_PATCH" >> "$GITHUB_OUTPUT"
echo "html_name=$NAME" >> "$GITHUB_OUTPUT"
echo "patch_name=$PATCH_NAME" >> "$GITHUB_OUTPUT"
echo "has_changes=true" >> "$GITHUB_OUTPUT"

