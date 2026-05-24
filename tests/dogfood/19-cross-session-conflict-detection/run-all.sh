#!/usr/bin/env bash
# Dogfood test suite for cross-session conflict detection (v1.16.0).
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 15)
#
# Runs all scenario tests and the per-slice unit/integration tests.
# Designed for CI-friendly execution (<5 min total).
#
# Scenarios:
#   (a) clean-tree solo SessionStart — no peers, no noise
#   (b) two-session bug-fix-vs-refactor on same function (literal user scenario)
#   (c) pre-push block on overlap
#   (d) PreToolUse annotate when opt-in
#   (e) PreToolUse silent when opt-out
#   (f) worktree-out flow end-to-end

set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$TEST_DIR/../../.." && pwd)

PASS=0
FAIL=0
SUITE_FAILS=()

run_suite() {
  local name="$1" script="$2"
  printf '\n=== %s ===\n' "$name"
  if bash "$script" 2>&1; then
    PASS=$((PASS + 1))
    printf '  SUITE PASS: %s\n' "$name"
  else
    FAIL=$((FAIL + 1))
    SUITE_FAILS+=("$name")
    printf '  SUITE FAIL: %s\n' "$name"
  fi
}

echo "=========================================="
echo "Cross-Session Conflict Detection Dogfood"
echo "=========================================="

# ---- Per-slice unit/integration tests ----
run_suite "Slice 1: Sidecar lifecycle"          "$REPO_ROOT/tests/sidecar/sidecar_lifecycle_test.sh"
run_suite "Slice 2: Policy resolver"             "$REPO_ROOT/tests/policy/policy_resolve_test.sh"
run_suite "Slice 3: SessionStart peer-scan"      "$REPO_ROOT/tests/hooks/session_start_test.sh"
run_suite "Slice 4: Overlap probe"               "$REPO_ROOT/tests/overlap/merge_tree_probe_test.sh"
run_suite "Slice 5: pre-push hook"               "$REPO_ROOT/tests/hooks/pre_push_test.sh"
run_suite "Slice 6: Audit writer"                "$REPO_ROOT/tests/audit/audit_writer_test.sh"
run_suite "Slice 7: Halt UX dispatch"            "$REPO_ROOT/tests/halt-ux/halt_dispatch_test.sh"
run_suite "Slices 8-12: Action handlers"         "$REPO_ROOT/tests/actions/actions_test.sh"
run_suite "Slice 13: PreToolUse hook"            "$REPO_ROOT/tests/hooks/pretool_use_test.sh"
run_suite "Slice 14: Trust mode"                 "$REPO_ROOT/tests/trust/signed_signals_test.sh"

# ---- End-to-end scenario tests ----
run_suite "Scenario (a-f): E2E"                  "$TEST_DIR/scenarios.sh"

# ---- Summary ----
echo
echo "=========================================="
echo "SUITES PASS: $PASS"
echo "SUITES FAIL: $FAIL"
if [ $FAIL -gt 0 ]; then
  echo
  echo "Failed suites:"
  for s in "${SUITE_FAILS[@]}"; do
    echo "  - $s"
  done
  exit 1
fi
echo
echo "All suites passed."
exit 0
