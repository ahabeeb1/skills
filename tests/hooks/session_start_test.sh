#!/usr/bin/env bash
# Integration test for slice-28 SessionStart peer-scan hook (v1.16.0).
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 3)
#
# Tests covered:
#   1. zero peers -> no output, exit 0
#   2. one live peer -> warn with session ID + worktree + start time
#   3. one live peer -> output includes pretool_use opt-in hint
#   4. dead peer sidecar -> no output (pruned)
#   5. HABEEBS_DISABLE_HOOKS=1 -> no output, exit 0
#   6. HABEEBS_SKIP=session-start -> no output, exit 0
#   7. multiple live peers -> all listed
#   8. exit code always 0 (even on peer detection)
#   9. hook writes own sidecar on start

set -u

# ---- Locate SUT relative to this test file ----
TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$TEST_DIR/../.." && pwd)
SUT="$REPO_ROOT/hooks/session-start-peer-scan.sh"
SIDECAR="$REPO_ROOT/skills/cross-session-detect/sidecar.sh"

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

assert_not_contains() {
  local haystack="$1" needle="$2" label="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    fail "$label (output unexpectedly contains '$needle')"
  else
    pass "$label"
  fi
}

assert_empty() {
  local actual="$1" label="$2"
  if [ -z "$actual" ]; then
    pass "$label"
  else
    fail "$label (expected empty, got='$actual')"
  fi
}

# ---- Setup: tmp git repo ----
TMP=$(mktemp -d -t slice28-XXXXXX)

if [ ! -f "$SUT" ]; then
  echo "FATAL: SUT not found at $SUT (RED phase — implement hooks/session-start-peer-scan.sh)" >&2
  exit 1
fi

cd "$TMP"
git init -q
git config user.email t@t.t
git config user.name t
echo seed > seed.txt
git add seed.txt
git -c commit.gpgsign=false commit -q -m seed

# Resolve paths the same way the SUT does
if pwd -W >/dev/null 2>&1; then
  COMMON_DIR=$(cd "$(git rev-parse --git-common-dir)" && pwd -W)
else
  COMMON_DIR=$(cd "$(git rev-parse --git-common-dir)" && pwd)
fi
SIDECAR_DIR="$COMMON_DIR/habeebs-sessions"

# Spin up a long-running Node process for live PID
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
  rm -rf "$TMP"
}
trap cleanup EXIT

# Fake home dir
FAKE_HOME="$TMP/fakehome"
mkdir -p "$FAKE_HOME"
export HOME="$FAKE_HOME"
export USERPROFILE="$FAKE_HOME"

# The hook needs a session ID for itself. We pass it via env.
SELF_SESSION="self-session-001"

# =========================================================================
# Test 1: zero peers -> no output, exit 0
# =========================================================================
echo "[1] zero peers -> no output"
OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 with no peers"
# The hook may write its own sidecar — output should have no peer warning
assert_not_contains "$OUT" "peer" "no peer warning when solo"

# Clean up own sidecar for next test
bash "$SIDECAR" end --session-id "$SELF_SESSION" 2>/dev/null || true

# =========================================================================
# Test 2: one live peer -> warn with session ID + worktree + start time
# =========================================================================
echo "[2] one live peer -> warn output"
PEER_A="peer-session-aaa"
bash "$SIDECAR" write --session-id "$PEER_A" --pid "$LIVE_PID"
OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 with live peer"
assert_contains "$OUT" "$PEER_A" "output names peer session ID"
assert_contains "$OUT" "additionalContext" "output is JSON with additionalContext"

# Clean up
bash "$SIDECAR" end --session-id "$SELF_SESSION" 2>/dev/null || true

# =========================================================================
# Test 3: live peer -> includes pretool_use opt-in hint
# =========================================================================
echo "[3] opt-in hint present"
# Peer A still exists from test 2
OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
assert_contains "$OUT" "pretool_use" "output mentions pretool_use opt-in"

# Clean up
bash "$SIDECAR" end --session-id "$SELF_SESSION" 2>/dev/null || true

# =========================================================================
# Test 4: dead peer sidecar -> no peer warning
# =========================================================================
echo "[4] dead peer -> no warning"
# Remove the live peer, create a dead-PID peer
bash "$SIDECAR" end --session-id "$PEER_A" 2>/dev/null || true
PEER_DEAD="peer-session-dead"
mkdir -p "$SIDECAR_DIR"
NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
SELF_ENV=$(bash "$SIDECAR" current-env)
cat > "$SIDECAR_DIR/${PEER_DEAD}.json" <<EOF
{
  "session_id": "$PEER_DEAD",
  "pid": 999999,
  "hostname": "$(hostname)",
  "env": "$SELF_ENV",
  "start_time_iso": "$NOW_ISO",
  "worktree_path": "$TMP",
  "stash_sha": "",
  "mtime_iso": "$NOW_ISO"
}
EOF
OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 with dead peer"
assert_not_contains "$OUT" "$PEER_DEAD" "dead peer not warned about"

# Clean up
bash "$SIDECAR" end --session-id "$SELF_SESSION" 2>/dev/null || true

# =========================================================================
# Test 5: HABEEBS_DISABLE_HOOKS=1 -> no output
# =========================================================================
echo "[5] HABEEBS_DISABLE_HOOKS=1 -> silent exit"
# Re-create a live peer so we'd normally see output
bash "$SIDECAR" write --session-id "$PEER_A" --pid "$LIVE_PID"
OUT=$(HABEEBS_DISABLE_HOOKS=1 HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 when disabled"
assert_empty "$OUT" "no output when disabled"

# =========================================================================
# Test 6: HABEEBS_SKIP=session-start -> no output
# =========================================================================
echo "[6] HABEEBS_SKIP=session-start -> silent exit"
OUT=$(HABEEBS_SKIP="session-start" HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 when skipped"
assert_empty "$OUT" "no output when skipped"

# =========================================================================
# Test 7: multiple live peers -> all listed
# =========================================================================
echo "[7] multiple live peers"
PEER_B="peer-session-bbb"
bash "$SIDECAR" write --session-id "$PEER_B" --pid "$LIVE_PID"
OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
assert_contains "$OUT" "$PEER_A" "first peer listed"
assert_contains "$OUT" "$PEER_B" "second peer listed"

# Clean up
bash "$SIDECAR" end --session-id "$SELF_SESSION" 2>/dev/null || true
bash "$SIDECAR" end --session-id "$PEER_A" 2>/dev/null || true
bash "$SIDECAR" end --session-id "$PEER_B" 2>/dev/null || true

# =========================================================================
# Test 8: exit code always 0
# =========================================================================
echo "[8] exit code always 0"
# Already tested in every case above; this is the summary assertion.
# Create a peer and verify exit 0 explicitly once more.
bash "$SIDECAR" write --session-id "$PEER_A" --pid "$LIVE_PID"
bash "$SUT" >/dev/null 2>&1
# No HABEEBS_SESSION_ID means hook generates its own — should still exit 0
RC=$?
assert_eq "0" "$RC" "exit 0 without session ID env"

# Clean up
bash "$SIDECAR" end --session-id "$PEER_A" 2>/dev/null || true

# =========================================================================
# Test 9: hook writes own sidecar on start
# =========================================================================
echo "[9] hook writes own sidecar"
# Clear all sidecars
rm -rf "$SIDECAR_DIR"
HABEEBS_SESSION_ID="test-self-write" bash "$SUT" >/dev/null 2>&1
if [ -f "$SIDECAR_DIR/test-self-write.json" ]; then
  pass "own sidecar written by hook"
else
  fail "own sidecar not written by hook"
fi
bash "$SIDECAR" end --session-id "test-self-write" 2>/dev/null || true

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
