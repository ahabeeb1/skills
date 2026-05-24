#!/usr/bin/env bash
# Integration test for slice-29 pre-push hook (v1.16.0).
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 5)
#
# Tests covered:
#   1. zero live peers -> exit 0, push allowed
#   2. live peer, no overlap -> exit 0, push allowed
#   3. live peer with overlap -> exit non-zero, push blocked
#   4. blocked output names the conflicting peer + files
#   5. multi-peer: all conflicting peers surfaced in one output
#   6. HABEEBS_DISABLE_HOOKS=1 -> exit 0 (bypass)
#   7. HABEEBS_SKIP=pre-push -> exit 0 (bypass)

set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$TEST_DIR/../.." && pwd)
SUT="$REPO_ROOT/hooks/pre-push.sh"
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

TMP=$(mktemp -d -t slice29-XXXXXX)

if [ ! -f "$SUT" ]; then
  echo "FATAL: SUT not found at $SUT (RED phase — implement hooks/pre-push.sh)" >&2
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

# Resolve paths
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

FAKE_HOME="$TMP/fakehome"
mkdir -p "$FAKE_HOME"
export HOME="$FAKE_HOME"
export USERPROFILE="$FAKE_HOME"

SELF_SESSION="self-push-001"

# =========================================================================
# Test 1: zero live peers -> exit 0
# =========================================================================
echo "[1] zero peers -> exit 0"
OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 with no peers"

# =========================================================================
# Test 2: live peer, no overlap -> exit 0
# =========================================================================
echo "[2] live peer, no overlap -> exit 0"
# Peer edits file-b, we edit file-a -> no overlap
git checkout -q -b peer-clean
echo "peer edit" > file-b.txt
git add file-b.txt
git -c commit.gpgsign=false commit -q -m "peer edits file-b"
PEER_SHA=$(git rev-parse HEAD)

git checkout -q "$DEFAULT_BRANCH"
echo "our edit" > file-a.txt
git add file-a.txt
git -c commit.gpgsign=false commit -q -m "we edit file-a"

PEER_A="peer-no-overlap"
bash "$SIDECAR" write --session-id "$PEER_A" --pid "$LIVE_PID"
# Patch the peer sidecar to have the peer's stash_sha
SIDECAR_FILE="$SIDECAR_DIR/${PEER_A}.json"
node -e "
  const fs = require('fs');
  const p = process.argv[1];
  const s = JSON.parse(fs.readFileSync(p, 'utf8'));
  s.stash_sha = process.argv[2];
  fs.writeFileSync(p, JSON.stringify(s, null, 2));
" "$SIDECAR_FILE" "$PEER_SHA"

OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 with non-overlapping peer"
bash "$SIDECAR" end --session-id "$PEER_A" 2>/dev/null || true

# =========================================================================
# Test 3: live peer with overlap -> exit non-zero
# =========================================================================
echo "[3] live peer with overlap -> exit non-zero"
# Create a peer that conflicts with our file-a edit
git checkout -q -b peer-conflict "$(git rev-list --max-parents=0 HEAD)"
echo "conflicting edit" > file-a.txt
git add file-a.txt
git -c commit.gpgsign=false commit -q -m "peer conflicts on file-a"
PEER_CONFLICT_SHA=$(git rev-parse HEAD)

git checkout -q "$DEFAULT_BRANCH"

PEER_B="peer-overlap"
bash "$SIDECAR" write --session-id "$PEER_B" --pid "$LIVE_PID"
SIDECAR_FILE="$SIDECAR_DIR/${PEER_B}.json"
node -e "
  const fs = require('fs');
  const p = process.argv[1];
  const s = JSON.parse(fs.readFileSync(p, 'utf8'));
  s.stash_sha = process.argv[2];
  fs.writeFileSync(p, JSON.stringify(s, null, 2));
" "$SIDECAR_FILE" "$PEER_CONFLICT_SHA"

OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
RC=$?
assert_eq "1" "$RC" "exit 1 with overlapping peer"

# =========================================================================
# Test 4: blocked output names peer + files
# =========================================================================
echo "[4] blocked output names peer + files"
assert_contains "$OUT" "$PEER_B" "output names conflicting peer"
assert_contains "$OUT" "file-a.txt" "output names conflicting file"

# =========================================================================
# Test 5: multi-peer — all listed
# =========================================================================
echo "[5] multi-peer — all listed"
# Add another conflicting peer
git checkout -q -b peer-conflict-2 "$(git rev-list --max-parents=0 HEAD)"
echo "another conflict" > file-a.txt
git add file-a.txt
git -c commit.gpgsign=false commit -q -m "peer 2 conflicts on file-a"
PEER_CONFLICT_2_SHA=$(git rev-parse HEAD)

git checkout -q "$DEFAULT_BRANCH"

PEER_C="peer-overlap-2"
bash "$SIDECAR" write --session-id "$PEER_C" --pid "$LIVE_PID"
SIDECAR_FILE="$SIDECAR_DIR/${PEER_C}.json"
node -e "
  const fs = require('fs');
  const p = process.argv[1];
  const s = JSON.parse(fs.readFileSync(p, 'utf8'));
  s.stash_sha = process.argv[2];
  fs.writeFileSync(p, JSON.stringify(s, null, 2));
" "$SIDECAR_FILE" "$PEER_CONFLICT_2_SHA"

OUT=$(HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
RC=$?
assert_eq "1" "$RC" "exit 1 with multiple overlapping peers"
assert_contains "$OUT" "$PEER_B" "first conflicting peer listed"
assert_contains "$OUT" "$PEER_C" "second conflicting peer listed"

# Clean up peers
bash "$SIDECAR" end --session-id "$PEER_B" 2>/dev/null || true
bash "$SIDECAR" end --session-id "$PEER_C" 2>/dev/null || true

# =========================================================================
# Test 6: HABEEBS_DISABLE_HOOKS=1 -> exit 0
# =========================================================================
echo "[6] HABEEBS_DISABLE_HOOKS=1 -> bypass"
# Re-create overlapping peer
bash "$SIDECAR" write --session-id "$PEER_B" --pid "$LIVE_PID"
SIDECAR_FILE="$SIDECAR_DIR/${PEER_B}.json"
node -e "
  const fs = require('fs');
  const p = process.argv[1];
  const s = JSON.parse(fs.readFileSync(p, 'utf8'));
  s.stash_sha = process.argv[2];
  fs.writeFileSync(p, JSON.stringify(s, null, 2));
" "$SIDECAR_FILE" "$PEER_CONFLICT_SHA"

OUT=$(HABEEBS_DISABLE_HOOKS=1 HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 when disabled"

# =========================================================================
# Test 7: HABEEBS_SKIP=pre-push -> exit 0
# =========================================================================
echo "[7] HABEEBS_SKIP=pre-push -> bypass"
OUT=$(HABEEBS_SKIP="pre-push" HABEEBS_SESSION_ID="$SELF_SESSION" bash "$SUT" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 when skipped"

bash "$SIDECAR" end --session-id "$PEER_B" 2>/dev/null || true

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
