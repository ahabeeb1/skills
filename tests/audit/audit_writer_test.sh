#!/usr/bin/env bash
# Unit + integration test for slice-27 audit writer (v1.16.0).
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 6)
#
# Tests covered:
#   1. write produces docs/agents/conflicts/<id>.json
#   2. all required schema fields populated
#   3. resolved_by is always "user"
#   4. idempotent on same conflict_id (no overwrite)
#   5. notes field preserved
#   6. .gitkeep ensures directory tracked
#   7. different conflict_id creates separate file

set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$TEST_DIR/../.." && pwd)
SUT="$REPO_ROOT/skills/cross-session-detect/audit.sh"

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
    const keys = process.argv[2].split('.');
    let v = j;
    for (const k of keys) v = v?.[k];
    if (v === undefined) process.stdout.write('undefined');
    else if (typeof v === 'object') process.stdout.write(JSON.stringify(v));
    else process.stdout.write(String(v));
  " "$json" "$field"
}

TMP=$(mktemp -d -t slice27-XXXXXX)
trap 'rm -rf "$TMP"' EXIT

if [ ! -f "$SUT" ]; then
  echo "FATAL: SUT not found at $SUT (RED phase — implement skills/cross-session-detect/audit.sh)" >&2
  exit 1
fi

cd "$TMP"
git init -q
git config user.email t@t.t
git config user.name t
echo seed > seed.txt
git add seed.txt
git -c commit.gpgsign=false commit -q -m seed

# Build a context JSON to pass to the audit writer
CTX_JSON='{"conflict_id":"conflict-001","detected_at_iso":"2026-05-22T20:10:00Z","trigger":"pre-push","session_a":{"session_id":"sess-aaa","worktree_path":"/tmp/repo","branch":"main","last_commit":"abc123"},"session_b":{"session_id":"sess-bbb","worktree_path":"/tmp/repo","branch":"feat/x","intent":"refactor"},"overlap":{"files":["file-a.txt"],"merge_tree_exit_code":1,"conflicted_paths":["file-a.txt"]},"resolution":"worktree-out","resolved_at_iso":"2026-05-22T20:11:00Z","notes":"Session B branched to worktree-out/9f3a2c1b"}'

# =========================================================================
# Test 1: write produces output file
# =========================================================================
echo "[1] write produces output file"
bash "$SUT" write --context "$CTX_JSON"
AUDIT_FILE="$TMP/docs/agents/conflicts/conflict-001.json"
if [ -f "$AUDIT_FILE" ]; then
  pass "audit file created"
else
  fail "audit file not found at $AUDIT_FILE"
fi

# =========================================================================
# Test 2: all required schema fields populated
# =========================================================================
echo "[2] all schema fields populated"
if [ -f "$AUDIT_FILE" ]; then
  CONTENT=$(cat "$AUDIT_FILE")
  assert_eq "conflict-001" "$(json_field "$CONTENT" conflict_id)" "conflict_id"
  assert_eq "2026-05-22T20:10:00Z" "$(json_field "$CONTENT" detected_at_iso)" "detected_at_iso"
  assert_eq "pre-push" "$(json_field "$CONTENT" trigger)" "trigger"
  assert_eq "sess-aaa" "$(json_field "$CONTENT" session_a.session_id)" "session_a.session_id"
  assert_eq "sess-bbb" "$(json_field "$CONTENT" session_b.session_id)" "session_b.session_id"
  assert_contains "$(json_field "$CONTENT" overlap.files)" "file-a.txt" "overlap.files"
  assert_eq "worktree-out" "$(json_field "$CONTENT" resolution)" "resolution"
  assert_eq "2026-05-22T20:11:00Z" "$(json_field "$CONTENT" resolved_at_iso)" "resolved_at_iso"
else
  for _ in 1 2 3 4 5 6 7 8; do fail "skipped (no audit file)"; done
fi

# =========================================================================
# Test 3: resolved_by is always "user"
# =========================================================================
echo "[3] resolved_by is 'user'"
if [ -f "$AUDIT_FILE" ]; then
  CONTENT=$(cat "$AUDIT_FILE")
  assert_eq "user" "$(json_field "$CONTENT" resolved_by)" "resolved_by forced to user"
else
  fail "skipped (no audit file)"
fi

# =========================================================================
# Test 4: idempotent on same conflict_id
# =========================================================================
echo "[4] idempotent — no overwrite"
# Modify the context but keep same conflict_id
CTX_MODIFIED='{"conflict_id":"conflict-001","detected_at_iso":"2026-05-22T21:00:00Z","trigger":"session-start","session_a":{"session_id":"sess-aaa","worktree_path":"/tmp/repo","branch":"main","last_commit":"abc123"},"session_b":{"session_id":"sess-ccc","worktree_path":"/tmp/repo","branch":"feat/y","intent":"other"},"overlap":{"files":["file-b.txt"],"merge_tree_exit_code":1,"conflicted_paths":["file-b.txt"]},"resolution":"abort","resolved_at_iso":"2026-05-22T21:01:00Z","notes":"aborted"}'
bash "$SUT" write --context "$CTX_MODIFIED"
if [ -f "$AUDIT_FILE" ]; then
  CONTENT=$(cat "$AUDIT_FILE")
  # Should still have the original data, not the modified
  assert_eq "2026-05-22T20:10:00Z" "$(json_field "$CONTENT" detected_at_iso)" "original data preserved (idempotent)"
  assert_eq "worktree-out" "$(json_field "$CONTENT" resolution)" "original resolution preserved"
else
  fail "audit file disappeared after idempotent write"
  fail "skipped"
fi

# =========================================================================
# Test 5: notes field preserved
# =========================================================================
echo "[5] notes field preserved"
if [ -f "$AUDIT_FILE" ]; then
  CONTENT=$(cat "$AUDIT_FILE")
  assert_contains "$(json_field "$CONTENT" notes)" "worktree-out/9f3a2c1b" "notes content preserved"
else
  fail "skipped (no audit file)"
fi

# =========================================================================
# Test 6: .gitkeep ensures directory tracked
# =========================================================================
echo "[6] .gitkeep present"
GITKEEP="$TMP/docs/agents/conflicts/.gitkeep"
if [ -f "$GITKEEP" ]; then
  pass ".gitkeep exists"
else
  fail ".gitkeep not found"
fi

# =========================================================================
# Test 7: different conflict_id creates separate file
# =========================================================================
echo "[7] different conflict_id -> new file"
CTX_NEW='{"conflict_id":"conflict-002","detected_at_iso":"2026-05-22T22:00:00Z","trigger":"pre-push","session_a":{"session_id":"sess-ddd","worktree_path":"/tmp/repo","branch":"main","last_commit":"def456"},"session_b":{"session_id":"sess-eee","worktree_path":"/tmp/repo","branch":"feat/z","intent":"bugfix"},"overlap":{"files":["file-c.txt"],"merge_tree_exit_code":1,"conflicted_paths":["file-c.txt"]},"resolution":"merge","resolved_at_iso":"2026-05-22T22:01:00Z","notes":"merged manually"}'
bash "$SUT" write --context "$CTX_NEW"
AUDIT_FILE_2="$TMP/docs/agents/conflicts/conflict-002.json"
if [ -f "$AUDIT_FILE_2" ]; then
  pass "second audit file created"
  CONTENT=$(cat "$AUDIT_FILE_2")
  assert_eq "conflict-002" "$(json_field "$CONTENT" conflict_id)" "second file has correct id"
else
  fail "second audit file not created"
  fail "skipped"
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
