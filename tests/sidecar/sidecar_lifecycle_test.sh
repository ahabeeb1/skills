#!/usr/bin/env bash
# Integration test for slice-24 sidecar lifecycle (v1.16.0).
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 1)
# ADR: docs/agents/adrs/0018-amend-adr-0002-for-advisory-in-flight-reads.md
#
# Tests covered:
#   1. write+read roundtrip
#   2. list excludes calling session
#   3. liveness probe alive (current PID)
#   4. liveness probe dead (PID 999999)
#   5. env-mismatch -> inconclusive
#   6. hostname-mismatch -> inconclusive
#   7. TTL pruning of stale inconclusive sidecar
#   8. orphan cleanup on list
#   9. SessionEnd removes own sidecar

set -u

# ---- Locate SUT relative to this test file ----
TEST_DIR=$(cd "$(dirname "$0")" && pwd)
# tests/sidecar/ -> tests/ -> repo root
REPO_ROOT=$(cd "$TEST_DIR/../.." && pwd)
SUT="$REPO_ROOT/skills/cross-session-detect/sidecar.sh"

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

assert_file_exists() {
  if [ -f "$1" ]; then
    pass "file exists: $(basename "$1") ($2)"
  else
    fail "missing file: $1 ($2)"
  fi
}

assert_file_absent() {
  if [ ! -e "$1" ]; then
    pass "file absent: $(basename "$1") ($2)"
  else
    fail "file still present: $1 ($2)"
  fi
}

# ---- Setup: tmp git repo per test invocation ----
TMP=$(mktemp -d -t slice24-XXXXXX)
trap 'rm -rf "$TMP"' EXIT

# Early exit if SUT is absent (RED phase signal)
if [ ! -f "$SUT" ]; then
  echo "FATAL: SUT not found at $SUT (RED phase — implement skills/cross-session-detect/sidecar.sh)" >&2
  exit 1
fi

cd "$TMP"
git init -q
git config user.email t@t.t
git config user.name t
echo seed > seed.txt
git add seed.txt
git -c commit.gpgsign=false commit -q -m seed

# Use the SUT's own notion of the sidecar dir so test assertions resolve to
# the same Win32-style paths the SUT writes to under MSYS / Git Bash.
SIDECAR_DIR_RAW=$(git rev-parse --git-common-dir)
# Resolve to a stable absolute form; prefer Win32-native if available so Node
# can see what bash sees.
if pwd -W >/dev/null 2>&1; then
  COMMON_DIR=$(cd "$SIDECAR_DIR_RAW" && pwd -W)
else
  COMMON_DIR=$(cd "$SIDECAR_DIR_RAW" && pwd)
fi
SIDECAR_DIR="$COMMON_DIR/habeebs-sessions"

START_TS=$(date +%s)

# Spin up a long-running Node process whose PID will stand in for "this
# session is alive" across the whole test. On MSYS / Git Bash, a Node child
# has a Win32-visible PID that another Node process can probe via
# process.kill(pid, 0), unlike bash's $$ which lives in MSYS's namespace.
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

cleanup_live_pid() {
  kill "$LIVE_NODE_PID" 2>/dev/null || true
  wait "$LIVE_NODE_PID" 2>/dev/null || true
}
trap 'cleanup_live_pid; rm -rf "$TMP"' EXIT

# =========================================================================
# Test 1: write+read roundtrip
# =========================================================================
echo "[1] write + read roundtrip"
SESSION_A=01ARZ3NDEKTSV4RRFFQ69G5FAV
bash "$SUT" write --session-id "$SESSION_A" --pid "$LIVE_PID" >/dev/null
SIDECAR_A="$SIDECAR_DIR/${SESSION_A}.json"
assert_file_exists "$SIDECAR_A" "writer creates sidecar"

# Schema fields populated
for field in session_id pid hostname env start_time_iso worktree_path stash_sha mtime_iso; do
  if grep -q "\"$field\"" "$SIDECAR_A"; then
    pass "field present: $field"
  else
    fail "field missing: $field"
  fi
done

# session_id matches what we passed in
SID=$(node -e "console.log(JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')).session_id)" "$SIDECAR_A")
assert_eq "$SESSION_A" "$SID" "session_id roundtrip"

# pid is our own process tree (probe will say alive in test 3)
PID_VAL=$(node -e "console.log(JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')).pid)" "$SIDECAR_A")
if [ -n "$PID_VAL" ] && [ "$PID_VAL" -gt 0 ]; then
  pass "pid populated ($PID_VAL)"
else
  fail "pid not numeric: $PID_VAL"
fi

# =========================================================================
# Test 2: list excludes calling session
# =========================================================================
echo "[2] list excludes calling session"
SESSION_B=01ARZ3NDEKTSV4RRFFQ69G5FAW
bash "$SUT" write --session-id "$SESSION_B" --pid "$LIVE_PID" >/dev/null
SIDECAR_B="$SIDECAR_DIR/${SESSION_B}.json"
assert_file_exists "$SIDECAR_B" "peer sidecar written"

LIST_OUT=$(bash "$SUT" list --session-id "$SESSION_A")
# Output is newline-separated peer session_ids (live only). Should contain B, not A.
if echo "$LIST_OUT" | grep -q "$SESSION_B"; then
  pass "list shows peer B"
else
  fail "list missing peer B; got: $LIST_OUT"
fi
if echo "$LIST_OUT" | grep -q "$SESSION_A"; then
  fail "list leaked self (A)"
else
  pass "list excludes self (A)"
fi

# =========================================================================
# Test 3: liveness probe — alive case
# =========================================================================
echo "[3] liveness probe: alive"
# Reuse the long-running Node child set up above as the "live" PID.
PROBE_OUT=$(bash "$SUT" probe --pid "$LIVE_PID")
assert_eq "alive" "$PROBE_OUT" "live pid -> alive"

# =========================================================================
# Test 4: liveness probe — dead case
# =========================================================================
echo "[4] liveness probe: dead"
# 999999 is well above typical PID space and is virtually never live
PROBE_OUT=$(bash "$SUT" probe --pid 999999)
assert_eq "dead" "$PROBE_OUT" "dead pid -> dead"

# =========================================================================
# Test 5: env-mismatch -> inconclusive
# =========================================================================
echo "[5] env-mismatch -> inconclusive"
# Hand-craft a sidecar with a different env value
SESSION_C=01ARZ3NDEKTSV4RRFFQ69G5FAX
SIDECAR_C="$SIDECAR_DIR/${SESSION_C}.json"
NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat > "$SIDECAR_C" <<EOF
{
  "session_id": "$SESSION_C",
  "pid": $$,
  "hostname": "$(hostname)",
  "env": "some-other-env-not-mine",
  "start_time_iso": "$NOW_ISO",
  "worktree_path": "$TMP",
  "stash_sha": "",
  "mtime_iso": "$NOW_ISO"
}
EOF
PROBE_OUT=$(bash "$SUT" probe-sidecar --path "$SIDECAR_C")
assert_eq "inconclusive" "$PROBE_OUT" "env mismatch -> inconclusive"

# =========================================================================
# Test 6: hostname-mismatch -> inconclusive
# =========================================================================
echo "[6] hostname-mismatch -> inconclusive"
SESSION_D=01ARZ3NDEKTSV4RRFFQ69G5FAY
SIDECAR_D="$SIDECAR_DIR/${SESSION_D}.json"
# Build a current sidecar by writing then editing hostname to a different value
bash "$SUT" write --session-id "$SESSION_D" >/dev/null
node -e "
const fs=require('fs');
const p=process.argv[1];
const s=JSON.parse(fs.readFileSync(p,'utf8'));
s.hostname='definitely-not-this-host-xyz';
fs.writeFileSync(p, JSON.stringify(s));
" "$SIDECAR_D"
PROBE_OUT=$(bash "$SUT" probe-sidecar --path "$SIDECAR_D")
assert_eq "inconclusive" "$PROBE_OUT" "hostname mismatch -> inconclusive"

# =========================================================================
# Test 7: TTL pruning of stale inconclusive sidecar on read
# =========================================================================
echo "[7] TTL pruning"
SESSION_E=01ARZ3NDEKTSV4RRFFQ69G5FAZ
SIDECAR_E="$SIDECAR_DIR/${SESSION_E}.json"
# Make a sidecar that is inconclusive (env mismatch) AND well past the TTL
# Set TTL low (5s) via policy file so we don't have to time-travel by 24h
POLICY_FILE="$TMP/.claude/habeebs-policy.json"
mkdir -p "$TMP/.claude"
cat > "$POLICY_FILE" <<'EOF'
{
  "pretool_use": false,
  "liveness_ttl_seconds": 5,
  "require_signed_signals": false
}
EOF

OLD_ISO=$(date -u -d "@$((START_TS - 3600))" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || \
          node -e "console.log(new Date(($START_TS - 3600) * 1000).toISOString().replace(/\..*/,'Z'))")
cat > "$SIDECAR_E" <<EOF
{
  "session_id": "$SESSION_E",
  "pid": 999998,
  "hostname": "$(hostname)",
  "env": "some-other-env-to-force-inconclusive",
  "start_time_iso": "$OLD_ISO",
  "worktree_path": "$TMP",
  "stash_sha": "",
  "mtime_iso": "$OLD_ISO"
}
EOF
# Backdate file mtime as well so TTL check based on mtime_iso (or filesystem mtime) prunes it.
touch -d "1 hour ago" "$SIDECAR_E" 2>/dev/null || true

# A list call should prune it
bash "$SUT" list --session-id "$SESSION_A" >/dev/null
assert_file_absent "$SIDECAR_E" "stale inconclusive sidecar pruned on read"

# Sanity: a fresh inconclusive sidecar within TTL is NOT pruned
SESSION_F=01ARZ3NDEKTSV4RRFFQ69G5FB0
SIDECAR_F="$SIDECAR_DIR/${SESSION_F}.json"
FRESH_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat > "$SIDECAR_F" <<EOF
{
  "session_id": "$SESSION_F",
  "pid": 999997,
  "hostname": "$(hostname)",
  "env": "some-other-env-to-force-inconclusive",
  "start_time_iso": "$FRESH_ISO",
  "worktree_path": "$TMP",
  "stash_sha": "",
  "mtime_iso": "$FRESH_ISO"
}
EOF
bash "$SUT" list --session-id "$SESSION_A" >/dev/null
if [ -f "$SIDECAR_F" ]; then
  pass "fresh inconclusive sidecar NOT pruned"
else
  fail "fresh inconclusive sidecar wrongly pruned"
fi

# =========================================================================
# Test 8: orphan cleanup — dead-PID sidecar pruned on list
# =========================================================================
echo "[8] orphan cleanup of dead-PID sidecar"
SESSION_G=01ARZ3NDEKTSV4RRFFQ69G5FB1
SIDECAR_G="$SIDECAR_DIR/${SESSION_G}.json"
NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat > "$SIDECAR_G" <<EOF
{
  "session_id": "$SESSION_G",
  "pid": 999996,
  "hostname": "$(hostname)",
  "env": "$(bash "$SUT" current-env)",
  "start_time_iso": "$NOW_ISO",
  "worktree_path": "$TMP",
  "stash_sha": "",
  "mtime_iso": "$NOW_ISO"
}
EOF
bash "$SUT" list --session-id "$SESSION_A" >/dev/null
assert_file_absent "$SIDECAR_G" "dead-pid orphan sidecar pruned"

# =========================================================================
# Test 9: SessionEnd removes own sidecar
# =========================================================================
echo "[9] SessionEnd removes own sidecar"
SESSION_H=01ARZ3NDEKTSV4RRFFQ69G5FB2
bash "$SUT" write --session-id "$SESSION_H" >/dev/null
SIDECAR_H="$SIDECAR_DIR/${SESSION_H}.json"
assert_file_exists "$SIDECAR_H" "sidecar written before end"
bash "$SUT" end --session-id "$SESSION_H" >/dev/null
assert_file_absent "$SIDECAR_H" "sidecar removed on SessionEnd"

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
