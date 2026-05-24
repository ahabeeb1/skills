#!/usr/bin/env bash
# Integration test for slice-31 trust mode (v1.16.0).
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 14)
#
# Tests covered:
#   1. require_signed_signals: false -> no verification
#   2. require_signed_signals: true, unsigned peer -> warn (not halt)
#   3. verification result surfaced in output

set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$TEST_DIR/../.." && pwd)
SUT="$REPO_ROOT/skills/cross-session-detect/trust.sh"

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

TMP=$(mktemp -d -t slice31-XXXXXX)
trap 'rm -rf "$TMP"' EXIT

if [ ! -f "$SUT" ]; then
  echo "FATAL: SUT not found at $SUT (RED phase — implement skills/cross-session-detect/trust.sh)" >&2
  exit 1
fi

cd "$TMP"
git init -q
git config user.email t@t.t
git config user.name t
echo seed > seed.txt
git add seed.txt
git -c commit.gpgsign=false commit -q -m seed
UNSIGNED_COMMIT=$(git rev-parse HEAD)

FAKE_HOME="$TMP/fakehome"
mkdir -p "$FAKE_HOME"
export HOME="$FAKE_HOME"
export USERPROFILE="$FAKE_HOME"

# =========================================================================
# Test 1: require_signed_signals: false -> skip
# =========================================================================
echo "[1] require_signed_signals: false -> no verification"
OUT=$(bash "$SUT" verify --peer-commit "$UNSIGNED_COMMIT" --require-signed "false" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 when not required"
assert_contains "$OUT" "skipped" "output says skipped"

# =========================================================================
# Test 2: require_signed_signals: true, unsigned -> warn
# =========================================================================
echo "[2] unsigned peer -> warn"
OUT=$(bash "$SUT" verify --peer-commit "$UNSIGNED_COMMIT" --require-signed "true" 2>&1)
RC=$?
assert_eq "0" "$RC" "exit 0 (warn, not halt)"
assert_contains "$OUT" "unsigned" "output warns about unsigned"

# =========================================================================
# Test 3: verification result surfaced
# =========================================================================
echo "[3] verification result in output"
assert_contains "$OUT" "advisory" "output mentions advisory"

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
