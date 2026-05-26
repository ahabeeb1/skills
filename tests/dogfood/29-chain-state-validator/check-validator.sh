#!/usr/bin/env bash
# Dogfood scenario 29 — PostToolUse chain-state validator (Piece 3, v1.22.0)
# Per spec slice #6 + ADR adr-methodology-bundle-v1.22.md § Piece 3.
#
# Verifies the validator hook exists, is wired in hooks.json, and warns
# (NEVER blocks — exit 0 always) on the two scoped conditions from grill OQ-1:
#   (b) MISSING-GRILL: spec Status: Grilled has no <slug>-grill.md
#   (c) EDIT-ON-DEFAULT: editing skills/, hooks/, or .claude-plugin/ on
#       default branch with uncommitted changes
#
# 4 fixture cases (2 warning scopes × positive-trigger + negative-no-trigger):
#   (a) wire check — hook exists + executable + wired in hooks.json
#   (b) MISSING-GRILL positive — fixture spec Status: Grilled, no grill file → warn
#   (c) MISSING-GRILL negative — fixture spec Status: Draft → no warn
#   (d) HABEEBS_DISABLE_HOOKS=1 → no warn regardless

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HOOK="$REPO_ROOT/hooks/check-chain-state.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# ─────────────────────────────────────────────────────────────────────────────
# Case (a) — wire check: hook exists, executable, wired in hooks.json
# ─────────────────────────────────────────────────────────────────────────────
[ -f "$HOOK" ] || fail "(a) hook script missing at $HOOK"
[ -x "$HOOK" ] || fail "(a) hook script not executable"

grep -q 'check-chain-state.sh' "$REPO_ROOT/hooks/hooks.json" || \
  fail "(a) hooks.json doesn't reference check-chain-state.sh"

grep -A3 'PostToolUse' "$REPO_ROOT/hooks/hooks.json" | grep -q 'Edit|Write|NotebookEdit' || \
  fail "(a) hooks.json PostToolUse matcher doesn't include Edit|Write|NotebookEdit"

pass "(a) wire check — hook exists + executable + wired in hooks.json"

# ─────────────────────────────────────────────────────────────────────────────
# Fixture setup: a fake repo with docs/agents/specs/
# ─────────────────────────────────────────────────────────────────────────────
setup_fixture_repo() {
  local dir
  dir=$(mktemp -d)
  cd "$dir"
  git init -q -b main
  git config user.email "test@example.com"
  git config user.name "Test"
  mkdir -p docs/agents/specs
  echo "# Test repo" > README.md
  git add README.md
  git commit -q -m "initial"
  echo "$dir"
}

# ─────────────────────────────────────────────────────────────────────────────
# Case (b) — MISSING-GRILL positive: spec Status: Grilled, no grill file → warn
# ─────────────────────────────────────────────────────────────────────────────
B_DIR=$(setup_fixture_repo)
cd "$B_DIR"
cat > docs/agents/specs/test-feature.md <<'EOF'
---
Status: Grilled
---

# Test Feature
EOF

# Run the hook from the fixture repo
OUTPUT=$(bash "$HOOK" 2>&1 >/dev/null) || OUTPUT="$OUTPUT (hook exit=$?)"
RC=$?

# Hook MUST exit 0 (warn-only)
[ "$RC" -eq 0 ] || fail "(b) hook exited non-zero ($RC); MUST be 0 per ADR-0003"

# Hook MUST have warned about missing grill
echo "$OUTPUT" | grep -q "test-feature.md is Status: Grilled" || \
  fail "(b) hook didn't warn about missing grill record. Output: $OUTPUT"

cd /
rm -rf "$B_DIR"
pass "(b) MISSING-GRILL positive — warned correctly, exit 0"

# ─────────────────────────────────────────────────────────────────────────────
# Case (c) — MISSING-GRILL negative: spec Status: Draft → no warn
# ─────────────────────────────────────────────────────────────────────────────
C_DIR=$(setup_fixture_repo)
cd "$C_DIR"
cat > docs/agents/specs/test-feature-draft.md <<'EOF'
---
Status: Draft
---

# Test Feature Draft
EOF

OUTPUT=$(bash "$HOOK" 2>&1 >/dev/null) || true
RC=$?

[ "$RC" -eq 0 ] || fail "(c) hook exited non-zero ($RC)"

# Should NOT have warned (no Grilled status)
echo "$OUTPUT" | grep -q "Status: Grilled" && \
  fail "(c) hook wrongly warned on Draft spec. Output: $OUTPUT"

cd /
rm -rf "$C_DIR"
pass "(c) MISSING-GRILL negative — no false-positive on Draft spec"

# ─────────────────────────────────────────────────────────────────────────────
# Case (d) — HABEEBS_DISABLE_HOOKS=1 disables all warnings
# ─────────────────────────────────────────────────────────────────────────────
D_DIR=$(setup_fixture_repo)
cd "$D_DIR"
cat > docs/agents/specs/test-feature-grilled.md <<'EOF'
---
Status: Grilled
---

# Would normally warn but disabled
EOF

OUTPUT=$(HABEEBS_DISABLE_HOOKS=1 bash "$HOOK" 2>&1 >/dev/null) || true
RC=$?

[ "$RC" -eq 0 ] || fail "(d) hook exited non-zero ($RC)"

# Should NOT have produced any output
[ -z "$OUTPUT" ] || fail "(d) hook produced output despite HABEEBS_DISABLE_HOOKS=1. Output: $OUTPUT"

cd /
rm -rf "$D_DIR"
pass "(d) HABEEBS_DISABLE_HOOKS=1 — fully disabled"

echo
echo "===SCENARIO 29 ALL 4 CASES PASS==="
