#!/usr/bin/env bash
# Integration test for slice-37 PreToolUse hook (v1.16.0).
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 13)
#
# Tests covered:
#   1. pretool_use: false -> exit 0, no work
#   2. pretool_use: true, no peers -> exit 0
#   3. pretool_use: true, peer with overlap on edited file -> annotate-and-allow
#   4. output never contains "deny"
#   5. fires on Edit tool, ignores Read tool
#   6. HABEEBS_SKIP=pretool-use -> exit 0

set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$TEST_DIR/../.." && pwd)
SUT="$REPO_ROOT/hooks/pretool-use-peer-scan.sh"
SIDECAR="$REPO_ROOT/skills/cross-session-detect/sidecar.sh"

PASS=0
FAIL=0
FAIL_MSGS=()

pass() { PASS=$((PASS + 1)); printf '  PASS  %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); FAIL_MSGS+=("$1"); printf '  FAIL  %s\n' "$1"; }

assert_eq() {
  local expected="$1" actual="$2" label="$3"
  if [ "$expected" = "$actual" ]; then pass "$label"; else fail "$label (expected='$expected' actual='$actual')"; fi
}

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if echo "$haystack" | grep -qF "$needle"; then pass "$label"; else fail "$label (output missing '$needle')"; fi
}

assert_not_contains() {
  local haystack="$1" needle="$2" label="$3"
  if echo "$haystack" | grep -qF "$needle"; then fail "$label (output unexpectedly contains '$needle')"; else pass "$label"; fi
}

assert_empty() {
  if [ -z "$1" ]; then pass "$2"; else fail "$2 (expected empty, got='$1')"; fi
}

TMP=$(mktemp -d -t slice37-XXXXXX)

if [ ! -f "$SUT" ]; then
  echo "FATAL: SUT not found at $SUT (RED phase — implement hooks/pretool-use-peer-scan.sh)" >&2
  exit 1
fi

cd "$TMP"
git init -q
git config user.email t@t.t
git config user.name t
echo "line 1" > file-a.txt
echo "line 1" > file-b.txt
git add .
git -c commit.gpgsign=false commit -q -m "initial"
DEFAULT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

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
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$LIVE_PID_FILE" ] && break; sleep 0.1; done
LIVE_PID=$(cat "$LIVE_PID_FILE")

cleanup() {
  kill "$LIVE_NODE_PID" 2>/dev/null || true
  wait "$LIVE_NODE_PID" 2>/dev/null || true
  rm -rf "$TMP"
}
trap cleanup EXIT

FAKE_HOME="$TMP/fakehome"
mkdir -p "$FAKE_HOME"
export HOME="$FAKE_HOME"
export USERPROFILE="$FAKE_HOME"

SELF_SESSION="self-pretool-001"

# =========================================================================
# Test 1: pretool_use: false -> exit 0, no work
# =========================================================================
echo "[1] pretool_use: false -> no work"
mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{ "pretool_use": false }
EOF
OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" HABEEBS_TOOL_NAME="Edit" HABEEBS_TOOL_INPUT_FILE="file-a.txt" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 when pretool_use false"
assert_empty "$OUT" "no output when pretool_use false"

# =========================================================================
# Test 2: pretool_use: true, no peers -> exit 0
# =========================================================================
echo "[2] pretool_use: true, no peers"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{ "pretool_use": true }
EOF
OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" HABEEBS_TOOL_NAME="Edit" HABEEBS_TOOL_INPUT_FILE="file-a.txt" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 with no peers"

# =========================================================================
# Test 3: pretool_use: true, peer with overlapping edit -> annotate
# =========================================================================
echo "[3] peer with overlap -> annotate-and-allow"
# Create a peer branch that conflicts on file-a.txt
git checkout -q -b peer-conflict
echo "peer edit" > file-a.txt
git add file-a.txt
git -c commit.gpgsign=false commit -q -m "peer edits file-a"
PEER_SHA=$(git rev-parse HEAD)
git checkout -q "$DEFAULT_BRANCH"

PEER_A="peer-pretool-aaa"
bash "$SIDECAR" write --session-id "$PEER_A" --pid "$LIVE_PID"
SIDECAR_FILE="$SIDECAR_DIR/${PEER_A}.json"
node -e "
  const fs = require('fs');
  const p = process.argv[1];
  const s = JSON.parse(fs.readFileSync(p, 'utf8'));
  s.stash_sha = process.argv[2];
  fs.writeFileSync(p, JSON.stringify(s, null, 2));
" "$SIDECAR_FILE" "$PEER_SHA"

# Edit file-a.txt ourselves to create overlap
echo "our edit" > file-a.txt
git add file-a.txt
git -c commit.gpgsign=false commit -q -m "we edit file-a"

OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" HABEEBS_TOOL_NAME="Edit" HABEEBS_TOOL_INPUT_FILE="file-a.txt" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 (annotate-and-allow, never blocks)"
assert_contains "$OUT" "peer" "output mentions peer"

# =========================================================================
# Test 4: output never contains "deny"
# =========================================================================
echo "[4] never deny"
assert_not_contains "$OUT" "deny" "output does not contain deny"

# =========================================================================
# Test 5: ignores Read tool
# =========================================================================
echo "[5] ignores Read tool"
OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" HABEEBS_TOOL_NAME="Read" HABEEBS_TOOL_INPUT_FILE="file-a.txt" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 for Read tool"
assert_empty "$OUT" "no output for Read tool"

# Clean up
bash "$SIDECAR" end --session-id "$PEER_A" 2>/dev/null || true

# =========================================================================
# Test 6: HABEEBS_SKIP=pretool-use -> exit 0
# =========================================================================
echo "[6] HABEEBS_SKIP=pretool-use -> bypass"
bash "$SIDECAR" write --session-id "$PEER_A" --pid "$LIVE_PID"
OUT=$(HABEEBS_SKIP="pretool-use" HABEEBS_SESSION_ID="$SELF_SESSION" HABEEBS_TOOL_NAME="Edit" HABEEBS_TOOL_INPUT_FILE="file-a.txt" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 when skipped"
assert_empty "$OUT" "no output when skipped"

bash "$SIDECAR" end --session-id "$PEER_A" 2>/dev/null || true

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
