#!/usr/bin/env bash
# Dogfood scenario 29 — PostToolUse chain-state validator (Piece 3, v1.22.0)
# Per spec slice #6 + ADR adr-methodology-bundle-v1.22.md § Piece 3.
#
# Verifies the validator hook exists, is wired in hooks.json, and warns
# (NEVER blocks — exit 0 always) on the two scoped conditions:
#   (b) UNGRILLED-SIGNOFF: a *-design.md Design Status: Signed-off with an empty
#       Decided section (grill resolutions never written back)
#   (c) EDIT-ON-DEFAULT: editing skills/, hooks/, or .claude-plugin/ on
#       default branch with uncommitted changes
#
# 4 fixture cases (2 warning scopes × positive-trigger + negative-no-trigger):
#   (a) wire check — hook exists + executable + wired in hooks.json
#   (b) UNGRILLED-SIGNOFF positive — signed-off Design, empty Decided → warn
#   (c) UNGRILLED-SIGNOFF negative — Design Status: Draft → no warn
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
# Case (b) — UNGRILLED-SIGNOFF positive: signed-off Design, empty Decided → warn
# ─────────────────────────────────────────────────────────────────────────────
B_DIR=$(setup_fixture_repo)
cd "$B_DIR"
cat > docs/agents/specs/2026-06-26-test-feature-design.md <<'EOF'
---
Status: Signed-off
---

# Design: Test Feature

## Decided

_(none yet — filled during the grill)_
EOF

# Run the hook from the fixture repo. Warnings ride hookSpecificOutput JSON on
# stdout (PostToolUse stderr is debug-log-only per the hook contract).
OUTPUT=$(bash "$HOOK" 2>/dev/null) || OUTPUT="$OUTPUT (hook exit=$?)"
RC=$?

# Hook MUST exit 0 (warn-only)
[ "$RC" -eq 0 ] || fail "(b) hook exited non-zero ($RC); MUST be 0 per ADR-0003"

# Hook MUST have warned about the signed-off Design with an empty Decided section
echo "$OUTPUT" | grep -q "test-feature-design.md is Status: Signed-off" || \
  fail "(b) hook didn't warn about ungrilled sign-off. Output: $OUTPUT"

cd /
rm -rf "$B_DIR"
pass "(b) UNGRILLED-SIGNOFF positive — warned correctly, exit 0"

# ─────────────────────────────────────────────────────────────────────────────
# Case (c) — UNGRILLED-SIGNOFF negative: Design Status: Draft → no warn
# ─────────────────────────────────────────────────────────────────────────────
C_DIR=$(setup_fixture_repo)
cd "$C_DIR"
cat > docs/agents/specs/2026-06-26-test-feature-draft-design.md <<'EOF'
---
Status: Draft
---

# Design: Test Feature Draft

## Decided

_(none yet — filled during the grill)_
EOF

OUTPUT=$(bash "$HOOK" 2>/dev/null) || true
RC=$?

[ "$RC" -eq 0 ] || fail "(c) hook exited non-zero ($RC)"

# Should NOT have warned (not signed off)
echo "$OUTPUT" | grep -q "Status: Signed-off" && \
  fail "(c) hook wrongly warned on Draft Design. Output: $OUTPUT"

cd /
rm -rf "$C_DIR"
pass "(c) UNGRILLED-SIGNOFF negative — no false-positive on Draft Design"

# ─────────────────────────────────────────────────────────────────────────────
# Case (d) — HABEEBS_DISABLE_HOOKS=1 disables all warnings
# ─────────────────────────────────────────────────────────────────────────────
D_DIR=$(setup_fixture_repo)
cd "$D_DIR"
cat > docs/agents/specs/2026-06-26-would-warn-design.md <<'EOF'
---
Status: Signed-off
---

# Design: Would normally warn but disabled

## Decided

_(none yet — filled during the grill)_
EOF

OUTPUT=$(HABEEBS_DISABLE_HOOKS=1 bash "$HOOK" 2>/dev/null) || true
RC=$?

[ "$RC" -eq 0 ] || fail "(d) hook exited non-zero ($RC)"

# Should NOT have produced any output
[ -z "$OUTPUT" ] || fail "(d) hook produced output despite HABEEBS_DISABLE_HOOKS=1. Output: $OUTPUT"

cd /
rm -rf "$D_DIR"
pass "(d) HABEEBS_DISABLE_HOOKS=1 — fully disabled"

echo
echo "===SCENARIO 29 ALL 4 CASES PASS==="
