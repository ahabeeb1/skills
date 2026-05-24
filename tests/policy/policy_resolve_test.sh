#!/usr/bin/env bash
# Unit test for slice-25 policy resolver (v1.16.0).
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 2)
# ADR: docs/agents/adrs/0018-amend-adr-0002-for-advisory-in-flight-reads.md
#
# Tests covered:
#   1. no policy files -> all defaults
#   2. project-scope file overrides defaults
#   3. user-scope file provides base, project overrides
#   4. local-scope (.claude/settings.local.json) overrides project
#   5. managed-scope (env HABEEBS_MANAGED_POLICY) overrides all
#   6. full 4-scope precedence chain
#   7. unknown key rejected with v1.1 deferral message
#   8. prefer_worktree specifically rejected with deferral message
#   9. partial policy file fills missing fields from defaults
#  10. invalid JSON -> error, does not crash
#  11. HABEEBS_SKIP env recognized and returned in output
#  12. liveness_ttl_seconds must be positive finite integer

set -u

# ---- Locate SUT relative to this test file ----
TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$TEST_DIR/../.." && pwd)
SUT="$REPO_ROOT/skills/cross-session-detect/policy.sh"

# ---- Test harness (same pattern as sidecar_lifecycle_test.sh) ----
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

assert_exit_code() {
  local expected="$1" actual="$2" label="$3"
  if [ "$expected" = "$actual" ]; then
    pass "$label"
  else
    fail "$label (exit expected=$expected actual=$actual)"
  fi
}

# Helper: extract a JSON field value via Node (avoids jq dependency)
json_field() {
  local json="$1" field="$2"
  node -e "
    const j = JSON.parse(process.argv[1]);
    const v = j[process.argv[2]];
    process.stdout.write(String(v));
  " "$json" "$field"
}

# ---- Setup: tmp git repo ----
TMP=$(mktemp -d -t slice25-XXXXXX)
trap 'rm -rf "$TMP"' EXIT

if [ ! -f "$SUT" ]; then
  echo "FATAL: SUT not found at $SUT (RED phase — implement skills/cross-session-detect/policy.sh)" >&2
  exit 1
fi

cd "$TMP"
git init -q
git config user.email t@t.t
git config user.name t
echo seed > seed.txt
git add seed.txt
git -c commit.gpgsign=false commit -q -m seed

# Fake home dir so user-scope tests don't touch the real ~/.claude/
FAKE_HOME="$TMP/fakehome"
mkdir -p "$FAKE_HOME"
export HOME="$FAKE_HOME"
# Also set USERPROFILE for Windows
export USERPROFILE="$FAKE_HOME"

# =========================================================================
# Test 1: no policy files -> all defaults
# =========================================================================
echo "[1] no policy files -> defaults"
OUT=$(bash "$SUT" resolve)
assert_eq "false" "$(json_field "$OUT" pretool_use)" "default pretool_use"
assert_eq "86400" "$(json_field "$OUT" liveness_ttl_seconds)" "default liveness_ttl_seconds"
assert_eq "false" "$(json_field "$OUT" require_signed_signals)" "default require_signed_signals"

# =========================================================================
# Test 2: project-scope file overrides defaults
# =========================================================================
echo "[2] project-scope overrides defaults"
mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{
  "pretool_use": true,
  "liveness_ttl_seconds": 3600
}
EOF
OUT=$(bash "$SUT" resolve)
assert_eq "true" "$(json_field "$OUT" pretool_use)" "project pretool_use override"
assert_eq "3600" "$(json_field "$OUT" liveness_ttl_seconds)" "project liveness_ttl override"
assert_eq "false" "$(json_field "$OUT" require_signed_signals)" "unset field -> default"
rm "$TMP/.claude/habeebs-policy.json"

# =========================================================================
# Test 3: user-scope provides base, project overrides
# =========================================================================
echo "[3] user-scope base + project override"
mkdir -p "$FAKE_HOME/.claude"
cat > "$FAKE_HOME/.claude/habeebs-policy.json" <<'EOF'
{
  "pretool_use": true,
  "liveness_ttl_seconds": 7200,
  "require_signed_signals": true
}
EOF
mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{
  "liveness_ttl_seconds": 1800
}
EOF
OUT=$(bash "$SUT" resolve)
assert_eq "true" "$(json_field "$OUT" pretool_use)" "user pretool_use inherited"
assert_eq "1800" "$(json_field "$OUT" liveness_ttl_seconds)" "project overrides user ttl"
assert_eq "true" "$(json_field "$OUT" require_signed_signals)" "user require_signed inherited"
rm "$TMP/.claude/habeebs-policy.json"
rm "$FAKE_HOME/.claude/habeebs-policy.json"

# =========================================================================
# Test 4: local-scope overrides project
# =========================================================================
echo "[4] local-scope overrides project"
mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{
  "pretool_use": false,
  "liveness_ttl_seconds": 3600
}
EOF
cat > "$TMP/.claude/habeebs-policy.local.json" <<'EOF'
{
  "pretool_use": true
}
EOF
OUT=$(bash "$SUT" resolve)
assert_eq "true" "$(json_field "$OUT" pretool_use)" "local overrides project pretool_use"
assert_eq "3600" "$(json_field "$OUT" liveness_ttl_seconds)" "project ttl inherited through local"
rm "$TMP/.claude/habeebs-policy.json"
rm "$TMP/.claude/habeebs-policy.local.json"

# =========================================================================
# Test 5: managed-scope (env) overrides all
# =========================================================================
echo "[5] managed-scope overrides all"
mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{
  "pretool_use": true,
  "liveness_ttl_seconds": 3600,
  "require_signed_signals": true
}
EOF
MANAGED_FILE="$TMP/managed-policy.json"
cat > "$MANAGED_FILE" <<'EOF'
{
  "pretool_use": false,
  "require_signed_signals": false
}
EOF
OUT=$(HABEEBS_MANAGED_POLICY="$MANAGED_FILE" bash "$SUT" resolve)
assert_eq "false" "$(json_field "$OUT" pretool_use)" "managed overrides project pretool_use"
assert_eq "3600" "$(json_field "$OUT" liveness_ttl_seconds)" "project ttl not overridden by managed (managed didn't set it)"
assert_eq "false" "$(json_field "$OUT" require_signed_signals)" "managed overrides project require_signed"
rm "$TMP/.claude/habeebs-policy.json"
rm "$MANAGED_FILE"

# =========================================================================
# Test 6: full 4-scope precedence chain
# =========================================================================
echo "[6] full 4-scope precedence"
mkdir -p "$FAKE_HOME/.claude"
cat > "$FAKE_HOME/.claude/habeebs-policy.json" <<'EOF'
{
  "pretool_use": false,
  "liveness_ttl_seconds": 1000,
  "require_signed_signals": false
}
EOF
mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{
  "pretool_use": true,
  "liveness_ttl_seconds": 2000
}
EOF
cat > "$TMP/.claude/habeebs-policy.local.json" <<'EOF'
{
  "liveness_ttl_seconds": 3000
}
EOF
MANAGED_FILE="$TMP/managed-policy.json"
cat > "$MANAGED_FILE" <<'EOF'
{
  "require_signed_signals": true
}
EOF
OUT=$(HABEEBS_MANAGED_POLICY="$MANAGED_FILE" bash "$SUT" resolve)
assert_eq "true" "$(json_field "$OUT" pretool_use)" "project pretool_use (highest non-managed setter)"
assert_eq "3000" "$(json_field "$OUT" liveness_ttl_seconds)" "local ttl wins over project+user"
assert_eq "true" "$(json_field "$OUT" require_signed_signals)" "managed require_signed wins over all"
rm "$FAKE_HOME/.claude/habeebs-policy.json"
rm "$TMP/.claude/habeebs-policy.json"
rm "$TMP/.claude/habeebs-policy.local.json"
rm "$MANAGED_FILE"

# =========================================================================
# Test 7: unknown key rejected
# =========================================================================
echo "[7] unknown key rejected"
mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{
  "pretool_use": false,
  "some_unknown_key": 42
}
EOF
OUT=$(bash "$SUT" resolve 2>&1)
RC=$?
assert_exit_code "1" "$RC" "unknown key -> non-zero exit"
assert_contains "$OUT" "some_unknown_key" "error names the unknown key"
rm "$TMP/.claude/habeebs-policy.json"

# =========================================================================
# Test 8: prefer_worktree specifically rejected with deferral message
# =========================================================================
echo "[8] prefer_worktree rejected with v1.1 deferral"
mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{
  "pretool_use": false,
  "prefer_worktree": "always"
}
EOF
OUT=$(bash "$SUT" resolve 2>&1)
RC=$?
assert_exit_code "1" "$RC" "prefer_worktree -> non-zero exit"
assert_contains "$OUT" "prefer_worktree" "error names prefer_worktree"
assert_contains "$OUT" "v1.1" "error mentions v1.1 deferral"
rm "$TMP/.claude/habeebs-policy.json"

# =========================================================================
# Test 9: partial policy fills missing from defaults
# =========================================================================
echo "[9] partial policy fills defaults"
mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{
  "require_signed_signals": true
}
EOF
OUT=$(bash "$SUT" resolve)
assert_eq "false" "$(json_field "$OUT" pretool_use)" "missing pretool_use -> default false"
assert_eq "86400" "$(json_field "$OUT" liveness_ttl_seconds)" "missing ttl -> default 86400"
assert_eq "true" "$(json_field "$OUT" require_signed_signals)" "set require_signed -> true"
rm "$TMP/.claude/habeebs-policy.json"

# =========================================================================
# Test 10: invalid JSON -> error
# =========================================================================
echo "[10] invalid JSON -> error"
mkdir -p "$TMP/.claude"
echo "NOT VALID JSON {{{" > "$TMP/.claude/habeebs-policy.json"
OUT=$(bash "$SUT" resolve 2>&1)
RC=$?
assert_exit_code "1" "$RC" "invalid JSON -> non-zero exit"
assert_contains "$OUT" "habeebs-policy.json" "error names the file"
rm "$TMP/.claude/habeebs-policy.json"

# =========================================================================
# Test 11: HABEEBS_SKIP env recognized
# =========================================================================
echo "[11] HABEEBS_SKIP env recognized"
OUT=$(HABEEBS_SKIP="session-start,pre-push" bash "$SUT" resolve)
SKIP_VAL=$(json_field "$OUT" skip)
assert_contains "$SKIP_VAL" "session-start" "skip includes session-start"
assert_contains "$SKIP_VAL" "pre-push" "skip includes pre-push"

# Verify defaults still apply alongside skip
assert_eq "false" "$(json_field "$OUT" pretool_use)" "defaults with skip set"

# =========================================================================
# Test 12: liveness_ttl_seconds must be positive finite integer
# =========================================================================
echo "[12] liveness_ttl_seconds validation"
mkdir -p "$TMP/.claude"

# Negative value
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{ "liveness_ttl_seconds": -1 }
EOF
OUT=$(bash "$SUT" resolve 2>&1)
RC=$?
assert_exit_code "1" "$RC" "negative ttl -> non-zero exit"

# Zero value
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{ "liveness_ttl_seconds": 0 }
EOF
OUT=$(bash "$SUT" resolve 2>&1)
RC=$?
assert_exit_code "1" "$RC" "zero ttl -> non-zero exit"

# String value
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{ "liveness_ttl_seconds": "not a number" }
EOF
OUT=$(bash "$SUT" resolve 2>&1)
RC=$?
assert_exit_code "1" "$RC" "string ttl -> non-zero exit"

# Float value (should be accepted — rounded or truncated is fine)
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{ "liveness_ttl_seconds": 3600.5 }
EOF
OUT=$(bash "$SUT" resolve 2>&1)
RC=$?
assert_exit_code "0" "$RC" "float ttl -> accepted (finite positive)"

rm "$TMP/.claude/habeebs-policy.json"

# =========================================================================
# Test 13: $schema key is allowed (not treated as unknown)
# =========================================================================
echo "[13] \$schema key allowed"
mkdir -p "$TMP/.claude"
cat > "$TMP/.claude/habeebs-policy.json" <<'EOF'
{
  "$schema": "https://habeebs-skill.dev/schemas/habeebs-policy-v1.json",
  "pretool_use": true
}
EOF
OUT=$(bash "$SUT" resolve)
RC=$?
assert_exit_code "0" "$RC" "\$schema not rejected"
assert_eq "true" "$(json_field "$OUT" pretool_use)" "\$schema + valid field works"
rm "$TMP/.claude/habeebs-policy.json"

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
