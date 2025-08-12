#!/usr/bin/env bash
set -euo pipefail

# Env:
# - BRANCH
# - TARGET
# - RUN_URL
# - HTML_ART_ID
# - PATCH_ART_ID

{
  echo "### Diff of generated JS for \`$BRANCH\` vs \`$TARGET\`"
  echo
  if [ "${IS_SAME_BRANCH:-false}" = "true" ]; then
    echo "- On target branch; diff generation skipped."
  elif [ "${PREV_FOUND:-false}" != "true" ]; then
    echo "- No previous artifact found for target branch; diff HTML was not generated."
  elif [ "${HAS_CHANGES:-false}" != "true" ]; then
    echo "- No changes detected; diff HTML was not generated."
  else
    HTML_URL="$RUN_URL/artifacts/$HTML_ART_ID"
    PATCH_URL="$RUN_URL/artifacts/$PATCH_ART_ID"
    echo "- Diff HTML: [open]($HTML_URL)"
    echo "- Patch file: [open]($PATCH_URL)"
    echo
    MAX_BYTES=200000
    PATCH_BYTES=$(wc -c < "${PATCH_PATH}" || echo 0)
    if [ "${PATCH_BYTES}" -gt "${MAX_BYTES}" ]; then
      echo "#### Inline diff (first 200 KB, truncated)"
    else
      echo "#### Inline diff"
    fi
    echo '```diff'
    # Hide file header lines in inline summary for readability
    head -c "${MAX_BYTES}" "${PATCH_PATH}" \
      | sed -E '/^(diff --git|index [0-9a-f]+\.[0-9a-f]+|--- |\+\+\+ |rename from |rename to )/d' || true
    echo
    echo '```'
  fi
} >> "$GITHUB_STEP_SUMMARY"

