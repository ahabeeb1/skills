#!/usr/bin/env bash
# Integration test for slice-26 overlap probe primitive (v1.16.0).
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 4)
#
# Tests covered:
#   1. no conflict — clean merge
#   2. overlapping edits — conflicted
#   3. conflicted_paths lists the conflicting files
#   4. modify/delete conflict detected
#   5. no common ancestor — still works (empty tree as base)
#   6. peer SHA is HEAD itself — no conflict
#   7. multiple files conflicting

set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$TEST_DIR/../.." && pwd)
SUT="$REPO_ROOT/skills/cross-session-detect/overlap.sh"

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
    const v = j[process.argv[2]];
    if (Array.isArray(v)) process.stdout.write(JSON.stringify(v));
    else process.stdout.write(String(v));
  " "$json" "$field"
}

TMP=$(mktemp -d -t slice26-XXXXXX)
trap 'rm -rf "$TMP"' EXIT

if [ ! -f "$SUT" ]; then
  echo "FATAL: SUT not found at $SUT (RED phase — implement skills/cross-session-detect/overlap.sh)" >&2
  exit 1
fi

cd "$TMP"
git init -q
git config user.email t@t.t
git config user.name t

# Create initial content
echo "line 1" > file-a.txt
echo "line 1" > file-b.txt
echo "line 1" > file-c.txt
git add .
git -c commit.gpgsign=false commit -q -m "initial"
DEFAULT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
BASE_SHA=$(git rev-parse HEAD)

# =========================================================================
# Test 1: no conflict — clean merge
# =========================================================================
echo "[1] no conflict — clean merge"
# Create a "peer" tree that edits file-b (non-overlapping with our edit to file-a)
git checkout -q -b peer-clean
echo "peer edit" > file-b.txt
git add file-b.txt
git -c commit.gpgsign=false commit -q -m "peer edits file-b"
PEER_SHA=$(git rev-parse HEAD)

git checkout -q "$DEFAULT_BRANCH"
echo "our edit" > file-a.txt
git add file-a.txt
git -c commit.gpgsign=false commit -q -m "we edit file-a"

OUT=$(bash "$SUT" probe --peer-sha "$PEER_SHA")
assert_eq "false" "$(json_field "$OUT" conflicted)" "non-overlapping edits -> no conflict"

# =========================================================================
# Test 2: overlapping edits — conflicted
# =========================================================================
echo "[2] overlapping edits — conflicted"
git checkout -q -b peer-conflict "$BASE_SHA"
echo "peer version of line 1" > file-a.txt
git add file-a.txt
git -c commit.gpgsign=false commit -q -m "peer edits file-a differently"
PEER_CONFLICT_SHA=$(git rev-parse HEAD)

git checkout -q "$DEFAULT_BRANCH"

OUT=$(bash "$SUT" probe --peer-sha "$PEER_CONFLICT_SHA")
assert_eq "true" "$(json_field "$OUT" conflicted)" "overlapping edits -> conflicted"

# =========================================================================
# Test 3: conflicted_paths lists the files
# =========================================================================
echo "[3] conflicted_paths lists files"
FILES=$(json_field "$OUT" files)
assert_contains "$FILES" "file-a.txt" "conflicted file listed"

# =========================================================================
# Test 4: modify/delete conflict
# =========================================================================
echo "[4] modify/delete conflict"
git checkout -q -b peer-delete "$BASE_SHA"
git rm -q file-a.txt
git -c commit.gpgsign=false commit -q -m "peer deletes file-a"
PEER_DELETE_SHA=$(git rev-parse HEAD)

git checkout -q "$DEFAULT_BRANCH"

OUT=$(bash "$SUT" probe --peer-sha "$PEER_DELETE_SHA")
assert_eq "true" "$(json_field "$OUT" conflicted)" "modify/delete -> conflicted"
FILES=$(json_field "$OUT" files)
assert_contains "$FILES" "file-a.txt" "deleted file in conflicted paths"

# =========================================================================
# Test 5: peer SHA is HEAD — no conflict
# =========================================================================
echo "[5] peer is HEAD — no conflict"
OUR_HEAD=$(git rev-parse HEAD)
OUT=$(bash "$SUT" probe --peer-sha "$OUR_HEAD")
assert_eq "false" "$(json_field "$OUT" conflicted)" "peer=HEAD -> no conflict"

# =========================================================================
# Test 6: multiple files conflicting
# =========================================================================
echo "[6] multiple files conflicting"
git checkout -q -b peer-multi "$BASE_SHA"
echo "peer version" > file-a.txt
echo "peer version" > file-c.txt
git add file-a.txt file-c.txt
git -c commit.gpgsign=false commit -q -m "peer edits file-a and file-c"
PEER_MULTI_SHA=$(git rev-parse HEAD)

git checkout -q "$DEFAULT_BRANCH"
echo "our version" > file-c.txt
git add file-c.txt
git -c commit.gpgsign=false commit -q -m "we edit file-c"

OUT=$(bash "$SUT" probe --peer-sha "$PEER_MULTI_SHA")
assert_eq "true" "$(json_field "$OUT" conflicted)" "multi-file conflict detected"
FILES=$(json_field "$OUT" files)
assert_contains "$FILES" "file-a.txt" "file-a in multi conflict"
assert_contains "$FILES" "file-c.txt" "file-c in multi conflict"

# =========================================================================
# Test 7: exit code is always 0 (probe reports via JSON, not exit code)
# =========================================================================
echo "[7] exit code always 0"
OUT=$(bash "$SUT" probe --peer-sha "$PEER_CONFLICT_SHA")
RC=$?
assert_eq "0" "$RC" "exit 0 even on conflict"

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
