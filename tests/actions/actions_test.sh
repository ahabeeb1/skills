#!/usr/bin/env bash
# Integration tests for slices 32-36 action handlers (v1.16.0).
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slices 8-12)
#
# Tests covered:
#   1. abort: removes own sidecar
#   2. abort: writes audit record with resolution "abort"
#   3. abort: exits cleanly (exit 0)
#   4. worktree-out: creates worktree on worktree-out/<uuid> branch
#   5. worktree-out: branch name matches pattern
#   6. worktree-out: audit record written
#   7. transfer: writes .transfer.md for peer
#   8. transfer: removes own sidecar
#   9. transfer: audit record with message
#  10. sequence: detects peer removal (fast path)
#  11. sequence: returns resolved status
#  12. merge: returns merge status with files

set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$TEST_DIR/../.." && pwd)
SUT="$REPO_ROOT/skills/cross-session-detect/actions.sh"
SIDECAR="$REPO_ROOT/skills/cross-session-detect/sidecar.sh"

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
    const keys = process.argv[2].split('.');
    let v = j;
    for (const k of keys) v = v?.[k];
    if (v === undefined) process.stdout.write('undefined');
    else if (typeof v === 'object') process.stdout.write(JSON.stringify(v));
    else process.stdout.write(String(v));
  " "$json" "$field"
}

TMP=$(mktemp -d -t actions-XXXXXX)

if [ ! -f "$SUT" ]; then
  echo "FATAL: SUT not found at $SUT (RED phase)" >&2
  exit 1
fi

cd "$TMP"
git init -q
git config user.email t@t.t
git config user.name t
echo "line 1" > file-a.txt
git add .
git -c commit.gpgsign=false commit -q -m "initial"

if pwd -W >/dev/null 2>&1; then
  COMMON_DIR=$(cd "$(git rev-parse --git-common-dir)" && pwd -W)
else
  COMMON_DIR=$(cd "$(git rev-parse --git-common-dir)" && pwd)
fi
SIDECAR_DIR="$COMMON_DIR/habeebs-sessions"

LIVE_PID_FILE="$TMP/.live_pid"
node -e "
  const fs = require('fs');
  fs.writeFileSync(process.argv[1], String(process.pid));
  setTimeout(() => {}, 60000);
" "$LIVE_PID_FILE" &
LIVE_NODE_PID=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do
  [ -s "$LIVE_PID_FILE" ] && break
  sleep 0.1
done
LIVE_PID=$(cat "$LIVE_PID_FILE")

cleanup() {
  kill "$LIVE_NODE_PID" 2>/dev/null || true
  wait "$LIVE_NODE_PID" 2>/dev/null || true
  # Clean up any worktrees we created
  git worktree list --porcelain 2>/dev/null | grep "^worktree " | grep -v "$(pwd)" | while read -r _ wt; do
    git worktree remove --force "$wt" 2>/dev/null || rm -rf "$wt"
  done
  rm -rf "$TMP"
}
trap cleanup EXIT

FAKE_HOME="$TMP/fakehome"
mkdir -p "$FAKE_HOME"
export HOME="$FAKE_HOME"
export USERPROFILE="$FAKE_HOME"

SELF="self-session-001"
PEER="peer-session-001"

CTX='{"conflict_id":"test-conflict-001","detected_at_iso":"2026-05-22T20:10:00Z","trigger":"pre-push","session_a":{"session_id":"peer-session-001","worktree_path":"/tmp","branch":"main","last_commit":"abc123"},"session_b":{"session_id":"self-session-001","worktree_path":"/tmp","branch":"feat/x","intent":"test"},"overlap":{"files":["file-a.txt"],"merge_tree_exit_code":1,"conflicted_paths":["file-a.txt"]}}'

# =========================================================================
# Test 1-3: Abort
# =========================================================================
echo "[1-3] Abort handler"
bash "$SIDECAR" write --session-id "$SELF" --pid "$LIVE_PID"
SELF_SIDECAR="$SIDECAR_DIR/${SELF}.json"

if [ -f "$SELF_SIDECAR" ]; then
  pass "sidecar exists before abort"
else
  fail "sidecar missing before abort"
fi

OUT=$(bash "$SUT" abort --session-id "$SELF" --peer-session-id "$PEER" --context "$CTX" 2>/dev/null)
RC=$?

if [ ! -f "$SELF_SIDECAR" ]; then
  pass "sidecar removed after abort"
else
  fail "sidecar still exists after abort"
fi

assert_eq "0" "$RC" "abort exits 0"

AUDIT_FILE="$TMP/docs/agents/conflicts/test-conflict-001.json"
if [ -f "$AUDIT_FILE" ]; then
  AUDIT_CONTENT=$(cat "$AUDIT_FILE")
  assert_eq "abort" "$(json_field "$AUDIT_CONTENT" resolution)" "audit resolution is abort"
else
  fail "audit file not written"
fi

assert_contains "$OUT" '"abort"' "output contains abort action"

# Clean up audit for next tests
rm -rf "$TMP/docs/agents/conflicts"

# =========================================================================
# Test 4-6: Worktree-out
# =========================================================================
echo "[4-6] Worktree-out handler"
OUT=$(bash "$SUT" worktree-out --session-id "$SELF" --peer-session-id "$PEER" --context "$CTX" 2>/dev/null)
RC=$?

assert_eq "0" "$RC" "worktree-out exits 0"
assert_contains "$OUT" "worktree-out" "output mentions worktree-out"

# Check branch name pattern
BRANCH=$(json_field "$OUT" branch)
if echo "$BRANCH" | grep -qE '^worktree-out/[a-f0-9]{8}$'; then
  pass "branch name matches worktree-out/<8-char-uuid>"
else
  fail "branch name doesn't match pattern: $BRANCH"
fi

# Check audit
AUDIT_FILE="$TMP/docs/agents/conflicts/test-conflict-001.json"
if [ -f "$AUDIT_FILE" ]; then
  AUDIT_CONTENT=$(cat "$AUDIT_FILE")
  assert_eq "worktree-out" "$(json_field "$AUDIT_CONTENT" resolution)" "audit resolution is worktree-out"
else
  fail "audit file not written for worktree-out"
fi

# Clean up worktree
WT_PATH=$(json_field "$OUT" worktree_path)
if [ -n "$WT_PATH" ] && [ -d "$WT_PATH" ]; then
  git worktree remove --force "$WT_PATH" 2>/dev/null || rm -rf "$WT_PATH"
fi
rm -rf "$TMP/docs/agents/conflicts"

# =========================================================================
# Test 7-9: Transfer
# =========================================================================
echo "[7-9] Transfer handler"
bash "$SIDECAR" write --session-id "$SELF" --pid "$LIVE_PID"
bash "$SIDECAR" write --session-id "$PEER" --pid "$LIVE_PID"

OUT=$(bash "$SUT" transfer --session-id "$SELF" --peer-session-id "$PEER" --context "$CTX" --message "Please finish the refactor" 2>/dev/null)
RC=$?

TRANSFER_FILE="$SIDECAR_DIR/${PEER}.transfer.md"
if [ -f "$TRANSFER_FILE" ]; then
  pass "transfer note written"
  TRANSFER_CONTENT=$(cat "$TRANSFER_FILE")
  assert_contains "$TRANSFER_CONTENT" "Please finish the refactor" "transfer message preserved"
else
  fail "transfer note not found"
  fail "skipped (no file)"
fi

if [ ! -f "$SIDECAR_DIR/${SELF}.json" ]; then
  pass "own sidecar removed after transfer"
else
  fail "own sidecar still present after transfer"
fi

AUDIT_FILE="$TMP/docs/agents/conflicts/test-conflict-001.json"
if [ -f "$AUDIT_FILE" ]; then
  AUDIT_CONTENT=$(cat "$AUDIT_FILE")
  assert_eq "transfer" "$(json_field "$AUDIT_CONTENT" resolution)" "audit resolution is transfer"
else
  fail "audit file not written for transfer"
fi

# Clean up
bash "$SIDECAR" end --session-id "$PEER" 2>/dev/null || true
rm -f "$TRANSFER_FILE"
rm -rf "$TMP/docs/agents/conflicts"

# =========================================================================
# Test 10-11: Sequence (fast path — peer removed immediately)
# =========================================================================
echo "[10-11] Sequence handler (fast path)"
# No peer sidecar exists → peer is already gone → resolved immediately
OUT=$(bash "$SUT" sequence --session-id "$SELF" --peer-session-id "$PEER" --context "$CTX" 2>/dev/null)
RC=$?

assert_eq "0" "$RC" "sequence exits 0"
assert_contains "$OUT" '"resolved"' "sequence resolves when peer absent"

rm -rf "$TMP/docs/agents/conflicts"

# =========================================================================
# Test 12: Merge (returns status with files)
# =========================================================================
echo "[12] Merge handler"
OUT=$(EDITOR=true bash "$SUT" merge --session-id "$SELF" --peer-session-id "$PEER" --context "$CTX" 2>/dev/null)
RC=$?

assert_eq "0" "$RC" "merge exits 0"
assert_contains "$OUT" "file-a.txt" "merge output includes conflicted file"

rm -rf "$TMP/docs/agents/conflicts"

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
