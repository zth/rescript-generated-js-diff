#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
WORK="${ROOT_DIR}/.rgjd-example-work"
OUT_DIR="${ROOT_DIR}/examples"
TEMPLATE="${ROOT_DIR}/templates/diff2html-wrapper.html"

# Clean up the temporary workdir on exit; keep only the generated HTML
cleanup() {
  rm -rf "$WORK" || true
}
trap cleanup EXIT

rm -rf "$WORK" "$OUT_DIR"
TGT_SAFE="main"
CURR_SAFE="feature-x"
mkdir -p "$WORK/$TGT_SAFE/src" "$WORK/$CURR_SAFE/src" "$OUT_DIR"

cat >"$WORK/$TGT_SAFE/src/Foo.res.mjs" <<'EOF'
export const answer = 41;
export const greet = (name) => `Hello, ${name}!`;
EOF

cat >"$WORK/$CURR_SAFE/src/Foo.res.mjs" <<'EOF'
export const answer = 42;
export const greet = (name) => `Hi, ${name}!`;
export const sum = (a, b) => a + b;
EOF

cat >"$WORK/$TGT_SAFE/src/Old.res.mjs" <<'EOF'
export const legacy = true;
EOF

cat >"$WORK/$CURR_SAFE/src/New.res.mjs" <<'EOF'
export const modern = true;
EOF

(cd "$WORK" && git -c core.quotepath=false -c color.ui=never diff --no-index "$TGT_SAFE" "$CURR_SAFE" > diff.raw.patch || true)

# Use the raw patch for HTML so labels show as `{target → current}`
npx --yes diff2html-cli@5 -i file -s side -F "$OUT_DIR/rescript-branded-diff.html" --hwt "$TEMPLATE" -- "$WORK/diff.raw.patch"

echo "Generated: $OUT_DIR/rescript-branded-diff.html"

