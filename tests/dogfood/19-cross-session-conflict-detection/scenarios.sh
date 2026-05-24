#!/usr/bin/env bash
# End-to-end scenario tests for cross-session conflict detection (v1.16.0).
# Each scenario simulates a real two-session collision with positive + negative controls.

set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$TEST_DIR/../../.." && pwd)
SIDECAR="$REPO_ROOT/skills/cross-session-detect/sidecar.sh"
OVERLAP="$REPO_ROOT/skills/cross-session-detect/overlap.sh"
POLICY="$REPO_ROOT/skills/cross-session-detect/policy.sh"
ACTIONS="$REPO_ROOT/skills/cross-session-detect/actions.sh"
SESSION_START_HOOK="$REPO_ROOT/hooks/session-start-peer-scan.sh"
PREPUSH_HOOK="$REPO_ROOT/hooks/pre-push.sh"
PRETOOL_HOOK="$REPO_ROOT/hooks/pretool-use-peer-scan.sh"

PASS=0
FAIL=0
FAIL_MSGS=()

pass() { PASS=$((PASS + 1)); printf '  PASS  %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); FAIL_MSGS+=("$1"); printf '  FAIL  %s\n' "$1"; }

assert_eq() {
  local e="$1" a="$2" l="$3"
  if [ "$e" = "$a" ]; then pass "$l"; else fail "$l (expected='$e' actual='$a')"; fi
}
assert_contains() {
  if echo "$1" | grep -qF "$2"; then pass "$3"; else fail "$3 (missing '$2')"; fi
}
assert_not_contains() {
  if echo "$1" | grep -qF "$2"; then fail "$3 (has '$2')"; else pass "$3"; fi
}
assert_empty() {
  if [ -z "$1" ]; then pass "$2"; else fail "$2 (got '$1')"; fi
}

TMP=$(mktemp -d -t e2e-XXXXXX)
trap 'rm -rf "$TMP"' EXIT

cd "$TMP"
git init -q
git config user.email t@t.t
git config user.name t

cat > app.js <<'EOF'
function processOrder(order) {
  // line 1: validate
  if (!order.id) throw new Error("missing id");
  // line 3: process
  const result = order.items.map(i => i.price * i.qty);
  // line 5: return
  return { total: result.reduce((a, b) => a + b, 0) };
}
EOF
git add .
git -c commit.gpgsign=false commit -q -m "initial app"
DEFAULT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

FAKE_HOME="$TMP/fakehome"
mkdir -p "$FAKE_HOME"
export HOME="$FAKE_HOME"
export USERPROFILE="$FAKE_HOME"

# Spin up live Node process
LIVE_PID_FILE="$TMP/.live_pid"
node -e "const fs=require('fs');fs.writeFileSync(process.argv[1],String(process.pid));setTimeout(()=>{},120000);" "$LIVE_PID_FILE" &
LIVE_NODE_PID=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$LIVE_PID_FILE" ] && break; sleep 0.1; done
LIVE_PID=$(cat "$LIVE_PID_FILE")
trap 'kill "$LIVE_NODE_PID" 2>/dev/null; wait "$LIVE_NODE_PID" 2>/dev/null; rm -rf "$TMP"' EXIT

if pwd -W >/dev/null 2>&1; then
  COMMON_DIR=$(cd "$(git rev-parse --git-common-dir)" && pwd -W)
else
  COMMON_DIR=$(cd "$(git rev-parse --git-common-dir)" && pwd)
fi
SIDECAR_DIR="$COMMON_DIR/habeebs-sessions"

# =========================================================================
# Scenario (a): clean-tree solo SessionStart — no peers, no noise
# =========================================================================
echo "[a] Solo SessionStart — no noise"
OUT=$(HABEEBS_SESSION_ID="solo-001" bash "$SESSION_START_HOOK" 2>&1)
RC=$?
assert_eq "0" "$RC" "(a) exit 0"
assert_not_contains "$OUT" "peer" "(a) no peer warning"
bash "$SIDECAR" end --session-id "solo-001" 2>/dev/null || true

# =========================================================================
# Scenario (b): two-session bug-fix-vs-refactor on same function
# =========================================================================
echo "[b] Two-session collision on processOrder()"
# Session A: bug fix (modifies line 3)
SESS_A="session-bugfix"
git checkout -q -b bugfix
sed -i 's/order.items.map/order.items.filter(Boolean).map/' app.js 2>/dev/null || \
  node -e "const fs=require('fs');let c=fs.readFileSync('app.js','utf8');c=c.replace('order.items.map','order.items.filter(Boolean).map');fs.writeFileSync('app.js',c);"
git add app.js
git -c commit.gpgsign=false commit -q -m "fix: filter null items"
BUGFIX_SHA=$(git rev-parse HEAD)

# Session B: refactor (modifies same function)
git checkout -q "$DEFAULT_BRANCH"
SESS_B="session-refactor"
git checkout -q -b refactor
sed -i 's/processOrder/calculateOrderTotal/' app.js 2>/dev/null || \
  node -e "const fs=require('fs');let c=fs.readFileSync('app.js','utf8');c=c.replace(/processOrder/g,'calculateOrderTotal');fs.writeFileSync('app.js',c);"
git add app.js
git -c commit.gpgsign=false commit -q -m "refactor: rename processOrder"
REFACTOR_SHA=$(git rev-parse HEAD)

# Write sidecars
git checkout -q "$DEFAULT_BRANCH"
bash "$SIDECAR" write --session-id "$SESS_A" --pid "$LIVE_PID"
SIDECAR_A="$SIDECAR_DIR/${SESS_A}.json"
node -e "const fs=require('fs');const p=process.argv[1];const s=JSON.parse(fs.readFileSync(p,'utf8'));s.stash_sha=process.argv[2];fs.writeFileSync(p,JSON.stringify(s,null,2));" "$SIDECAR_A" "$BUGFIX_SHA"

# Session B's SessionStart should detect Session A
OUT=$(HABEEBS_SESSION_ID="$SESS_B" bash "$SESSION_START_HOOK" 2>&1)
assert_contains "$OUT" "$SESS_A" "(b) SessionStart detects peer"

# Overlap probe confirms conflict on app.js
bash "$SIDECAR" write --session-id "$SESS_B" --pid "$LIVE_PID"
SIDECAR_B="$SIDECAR_DIR/${SESS_B}.json"
node -e "const fs=require('fs');const p=process.argv[1];const s=JSON.parse(fs.readFileSync(p,'utf8'));s.stash_sha=process.argv[2];fs.writeFileSync(p,JSON.stringify(s,null,2));" "$SIDECAR_B" "$REFACTOR_SHA"

# Checkout bugfix to run overlap from its perspective
git checkout -q bugfix
PROBE_OUT=$(bash "$OVERLAP" probe --peer-sha "$REFACTOR_SHA")
assert_contains "$PROBE_OUT" "true" "(b) overlap detected"
assert_contains "$PROBE_OUT" "app.js" "(b) app.js in conflict"

git checkout -q "$DEFAULT_BRANCH"
bash "$SIDECAR" end --session-id "$SESS_A" 2>/dev/null || true
bash "$SIDECAR" end --session-id "$SESS_B" 2>/dev/null || true

# Negative control: non-overlapping sessions
echo "[b-neg] Non-overlapping sessions"
git checkout -q -b readme-edit
echo "# README" > README.md
git add README.md
git -c commit.gpgsign=false commit -q -m "add readme"
README_SHA=$(git rev-parse HEAD)
git checkout -q "$DEFAULT_BRANCH"

PROBE_OUT=$(bash "$OVERLAP" probe --peer-sha "$README_SHA")
assert_contains "$PROBE_OUT" "false" "(b-neg) no overlap on different files"

# =========================================================================
# Scenario (c): pre-push block on overlap
# =========================================================================
echo "[c] pre-push blocks on overlap"
bash "$SIDECAR" write --session-id "$SESS_A" --pid "$LIVE_PID"
node -e "const fs=require('fs');const p=process.argv[1];const s=JSON.parse(fs.readFileSync(p,'utf8'));s.stash_sha=process.argv[2];fs.writeFileSync(p,JSON.stringify(s,null,2));" "$SIDECAR_A" "$BUGFIX_SHA"

git checkout -q refactor
OUT=$(HABEEBS_SESSION_ID="$SESS_B" bash "$PREPUSH_HOOK" 2>&1)
RC=$?
assert_eq "1" "$RC" "(c) pre-push blocks"
assert_contains "$OUT" "$SESS_A" "(c) names conflicting peer"

# Negative: no peers
git checkout -q "$DEFAULT_BRANCH"
bash "$SIDECAR" end --session-id "$SESS_A" 2>/dev/null || true
OUT=$(HABEEBS_SESSION_ID="$SESS_B" bash "$PREPUSH_HOOK" 2>&1)
RC=$?
assert_eq "0" "$RC" "(c-neg) no peers -> push allowed"

# =========================================================================
# Scenario (d): PreToolUse annotate when opt-in
# =========================================================================
echo "[d] PreToolUse annotates when pretool_use: true"
mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{ "pretool_use": true }
EOF
bash "$SIDECAR" write --session-id "$SESS_A" --pid "$LIVE_PID"
node -e "const fs=require('fs');const p=process.argv[1];const s=JSON.parse(fs.readFileSync(p,'utf8'));s.stash_sha=process.argv[2];fs.writeFileSync(p,JSON.stringify(s,null,2));" "$SIDECAR_A" "$BUGFIX_SHA"

git checkout -q refactor
OUT=$(HABEEBS_SESSION_ID="$SESS_B" HABEEBS_TOOL_NAME="Edit" HABEEBS_TOOL_INPUT_FILE="app.js" bash "$PRETOOL_HOOK" 2>&1)
RC=$?
assert_eq "0" "$RC" "(d) exit 0 (annotate-only)"
assert_contains "$OUT" "peer" "(d) annotates overlap"

git checkout -q "$DEFAULT_BRANCH"
bash "$SIDECAR" end --session-id "$SESS_A" 2>/dev/null || true

# =========================================================================
# Scenario (e): PreToolUse silent when opt-out
# =========================================================================
echo "[e] PreToolUse silent when pretool_use: false"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{ "pretool_use": false }
EOF
bash "$SIDECAR" write --session-id "$SESS_A" --pid "$LIVE_PID"
node -e "const fs=require('fs');const p=process.argv[1];const s=JSON.parse(fs.readFileSync(p,'utf8'));s.stash_sha=process.argv[2];fs.writeFileSync(p,JSON.stringify(s,null,2));" "$SIDECAR_A" "$BUGFIX_SHA"

OUT=$(HABEEBS_SESSION_ID="$SESS_B" HABEEBS_TOOL_NAME="Edit" HABEEBS_TOOL_INPUT_FILE="app.js" bash "$PRETOOL_HOOK" 2>&1)
RC=$?
assert_eq "0" "$RC" "(e) exit 0"
assert_empty "$OUT" "(e) silent when opt-out"

bash "$SIDECAR" end --session-id "$SESS_A" 2>/dev/null || true
rm "$TMP/.claude/habeebs-policy.json"

# =========================================================================
# Scenario (f): worktree-out flow end-to-end
# =========================================================================
echo "[f] Worktree-out flow"
CTX='{"conflict_id":"e2e-conflict-001","detected_at_iso":"2026-05-22T20:10:00Z","trigger":"pre-push","session_a":{"session_id":"session-bugfix"},"session_b":{"session_id":"session-refactor"},"overlap":{"files":["app.js"],"conflicted_paths":["app.js"]}}'

git checkout -q "$DEFAULT_BRANCH"
OUT=$(bash "$ACTIONS" worktree-out --session-id "$SESS_B" --peer-session-id "$SESS_A" --context "$CTX" 2>/dev/null)
RC=$?
assert_eq "0" "$RC" "(f) worktree-out exits 0"
assert_contains "$OUT" "worktree-out" "(f) output has worktree-out"

# Clean up worktree
WT_PATH=$(node -e "try{process.stdout.write(JSON.parse(process.argv[1]).worktree_path)}catch{}" "$OUT" 2>/dev/null)
if [ -n "$WT_PATH" ] && [ -d "$WT_PATH" ]; then
  git worktree remove --force "$WT_PATH" 2>/dev/null || rm -rf "$WT_PATH"
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
