#!/usr/bin/env bash
# Integration test for slice-30 halt UX dispatch logic (v1.16.0).
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 7)
#
# Tests the keystroke-to-action dispatch (non-interactive, piped input).
# Pager UX is manual-smoke only.
#
# Tests covered:
#   1. "1" -> merge
#   2. "m" -> merge
#   3. "2" -> sequence
#   4. "s" -> sequence
#   5. "3" -> transfer
#   6. "t" -> transfer
#   7. "4" -> abort
#   8. "a" -> abort
#   9. "5" -> worktree-out
#  10. "w" -> worktree-out
#  11. output includes peer session ID
#  12. output is valid JSON with action field

set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$TEST_DIR/../.." && pwd)
SUT="$REPO_ROOT/skills/cross-session-detect/halt-ux.sh"

# ---- Test harness ----
PASS=0
FAIL=0
FAIL_MSGS=()

pass() {
  PASS=$((PASS + 1))
  printf '  PASS  %s\n' "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  FAIL_MSGS+=("$1")
  printf '  FAIL  %s\n' "$1"
}

assert_eq() {
  local expected="$1" actual="$2" label="$3"
  if [ "$expected" = "$actual" ]; then
    pass "$label"
  else
    fail "$label (expected='$expected' actual='$actual')"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    pass "$label"
  else
    fail "$label (output missing '$needle')"
  fi
}

json_field() {
  local json="$1" field="$2"
  node -e "
    const j = JSON.parse(process.argv[1]);
    process.stdout.write(String(j[process.argv[2]] || ''));
  " "$json" "$field"
}

TMP=$(mktemp -d -t slice30-XXXXXX)
trap 'rm -rf "$TMP"' EXIT

if [ ! -f "$SUT" ]; then
  echo "FATAL: SUT not found at $SUT (RED phase — implement skills/cross-session-detect/halt-ux.sh)" >&2
  exit 1
fi

cd "$TMP"
git init -q
git config user.email t@t.t
git config user.name t
echo seed > seed.txt
git add seed.txt
git -c commit.gpgsign=false commit -q -m seed

FAKE_HOME="$TMP/fakehome"
mkdir -p "$FAKE_HOME"
export HOME="$FAKE_HOME"
export USERPROFILE="$FAKE_HOME"

# Common args for dispatch testing (skip pager via PAGER=cat)
PEER_ID="test-peer-001"
CONFLICT_FILES="file-a.txt,file-b.txt"

# Helper: run the halt UX with piped input, capture the JSON result line
run_halt() {
  local input="$1"
  # PAGER=cat skips interactive paging; HABEEBS_HALT_NO_DIFF=1 skips diff display
  echo "$input" | PAGER=cat HABEEBS_HALT_NO_DIFF=1 bash "$SUT" dispatch \
    --peer-session-id "$PEER_ID" \
    --conflict-files "$CONFLICT_FILES" 2>/dev/null | grep '^{' | tail -1
}

# =========================================================================
# Tests 1-10: keystroke mapping
# =========================================================================
KEYS=("1" "m" "2" "s" "3" "t" "4" "a" "5" "w")
ACTIONS=("merge" "merge" "sequence" "sequence" "transfer" "transfer" "abort" "abort" "worktree-out" "worktree-out")

for i in "${!KEYS[@]}"; do
  key="${KEYS[$i]}"
  expected="${ACTIONS[$i]}"
  idx=$((i + 1))
  echo "[$idx] key '$key' -> $expected"
  OUT=$(run_halt "$key")
  actual=$(json_field "$OUT" action)
  assert_eq "$expected" "$actual" "key '$key' -> $expected"
done

# =========================================================================
# Test 11: output includes peer session ID
# =========================================================================
echo "[11] output includes peer_session_id"
OUT=$(run_halt "m")
assert_eq "$PEER_ID" "$(json_field "$OUT" peer_session_id)" "peer_session_id in output"

# =========================================================================
# Test 12: output is valid JSON
# =========================================================================
echo "[12] output is valid JSON"
OUT=$(run_halt "a")
if node -e "JSON.parse(process.argv[1])" "$OUT" 2>/dev/null; then
  pass "output is valid JSON"
else
  fail "output is not valid JSON: $OUT"
fi

# =========================================================================
# Summary
# =========================================================================
echo
echo "==========================="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
if [ $FAIL -gt 0 ]; then
  echo
  echo "Failed assertions:"
  for m in "${FAIL_MSGS[@]}"; do
    echo "  - $m"
  done
  exit 1
fi
exit 0
