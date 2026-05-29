#!/usr/bin/env bash
# Integration test for the commit-block hook's worktree-awareness fix (v1.23.0).
#
# Root-cause bug this guards: hooks/preventing-commits-to-default.sh resolved the
# current branch from the hook PROCESS cwd (the harness launch dir, on the default
# branch), so a `cd <worktree> && git commit` whose commit actually lands on a
# FEATURE branch in a sibling worktree was false-positive-blocked as "on main".
#
# The fix: resolve the branch from the directory where the commit will actually
# run — parse a leading `cd <path>` or a `git -C <path>` out of the command and
# resolve the branch there; fall back to the hook's own cwd otherwise.
#
# Cases:
#   1. plain `git commit` from a default-branch checkout -> BLOCK (exit 2)  [unchanged guarantee]
#   2. `cd <feature-worktree> && git commit`            -> ALLOW (exit 0)  [the fix]
#   3. `git -C <feature-worktree> commit`               -> ALLOW (exit 0)  [the fix, -C form]
#   4. `cd <default-checkout> && git commit`            -> BLOCK (exit 2)  [no false-negative]
#   5. tag-only push on default                         -> ALLOW (exit 0)  [ADR-0015 carve-out preserved]
#   6. plain `git push` (branch advance) on default     -> BLOCK (exit 2)  [unchanged guarantee]
#   7. `git -C <default-checkout> commit`               -> BLOCK (exit 2)  [false-negative guard]
#   8. `git -c <cfg> commit` on default                 -> BLOCK (exit 2)  [false-negative guard]

set -u

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$TEST_DIR/../.." && pwd)
SUT="$REPO_ROOT/hooks/preventing-commits-to-default.sh"

PASS=0
FAIL=0
FAIL_MSGS=()
pass() { PASS=$((PASS + 1)); printf '  PASS  %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); FAIL_MSGS+=("$1"); printf '  FAIL  %s\n' "$1"; }

[ -f "$SUT" ] || { echo "FATAL: SUT not found at $SUT" >&2; exit 1; }

# Feed a tool_input.command payload to the hook and capture exit code.
# Run the hook FROM the default-branch checkout to mimic the harness launch cwd.
run_hook() {
  local cmd="$1"
  printf '{"tool_input":{"command":%s}}' "$(json_str "$cmd")" \
    | ( cd "$DEFAULT_CHECKOUT" && bash "$SUT" >/dev/null 2>&1 ); echo $?
}
# Minimal JSON string encoder (escape backslash + double-quote).
json_str() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '"%s"' "$s"
}

TMP=$(mktemp -d -t cblock-XXXXXX)
trap 'rm -rf "$TMP"' EXIT

# --- Build a default-branch checkout + a sibling feature worktree -------------
DEFAULT_CHECKOUT="$TMP/main-checkout"
mkdir -p "$DEFAULT_CHECKOUT"
cd "$DEFAULT_CHECKOUT"
git init -q
git config user.email t@t.t
git config user.name t
git symbolic-ref HEAD refs/heads/main
echo seed > seed.txt
git add seed.txt
git -c commit.gpgsign=false commit -q -m "seed"
# origin/HEAD is unset in this throwaway repo; the hook falls back to default_branch="main".

FEATURE_WT="$TMP/feature-wt"
git worktree add -q "$FEATURE_WT" -b feature/x main

# Resolve to native paths if under msys (so `cd` inside the command works).
if pwd -W >/dev/null 2>&1; then
  FEATURE_WT_NATIVE=$(cd "$FEATURE_WT" && pwd -W)
  DEFAULT_NATIVE=$(cd "$DEFAULT_CHECKOUT" && pwd -W)
else
  FEATURE_WT_NATIVE="$FEATURE_WT"
  DEFAULT_NATIVE="$DEFAULT_CHECKOUT"
fi

# --- Case 1: plain commit on default -> BLOCK ---------------------------------
RC=$(run_hook "git commit -m x")
[ "$RC" = "2" ] && pass "1. plain 'git commit' on default branch -> BLOCK (exit 2)" \
                || fail "1. plain commit on default should BLOCK (got exit $RC)"

# --- Case 2: cd into feature worktree then commit -> ALLOW (the fix) -----------
RC=$(run_hook "cd $FEATURE_WT_NATIVE && git commit -m x")
[ "$RC" = "0" ] && pass "2. 'cd <feature-worktree> && git commit' -> ALLOW (exit 0)" \
                || fail "2. cd-into-feature-worktree commit should ALLOW (got exit $RC)"

# --- Case 3: git -C feature worktree commit -> ALLOW (the fix, -C form) --------
RC=$(run_hook "git -C $FEATURE_WT_NATIVE commit -m x")
[ "$RC" = "0" ] && pass "3. 'git -C <feature-worktree> commit' -> ALLOW (exit 0)" \
                || fail "3. git -C feature-worktree commit should ALLOW (got exit $RC)"

# --- Case 4: cd into the default checkout then commit -> BLOCK (no false-neg) --
RC=$(run_hook "cd $DEFAULT_NATIVE && git commit -m x")
[ "$RC" = "2" ] && pass "4. 'cd <default-checkout> && git commit' -> BLOCK (exit 2)" \
                || fail "4. cd-into-default commit should still BLOCK (got exit $RC)"

# --- Case 5: tag-only push on default -> ALLOW (ADR-0015 carve-out) ------------
RC=$(run_hook "git push origin refs/tags/v1.23.0")
[ "$RC" = "0" ] && pass "5. tag-only push on default -> ALLOW (exit 0)" \
                || fail "5. tag-only push should ALLOW (got exit $RC)"

# --- Case 6: plain branch-advancing push on default -> BLOCK ------------------
RC=$(run_hook "git push")
[ "$RC" = "2" ] && pass "6. plain 'git push' on default -> BLOCK (exit 2)" \
                || fail "6. plain push on default should BLOCK (got exit $RC)"

# --- Case 7: `git -C <default-checkout> commit` -> BLOCK -----------------------
# Guards the false-negative: the command-detection must recognize `git -C <path>
# commit` and `git -c key=val commit` as commits (the literal-substring "git
# commit" match misses them), then resolve the branch at <path> and block.
RC=$(run_hook "git -C $DEFAULT_NATIVE commit -m x")
[ "$RC" = "2" ] && pass "7. 'git -C <default-checkout> commit' -> BLOCK (exit 2)" \
                || fail "7. git -C default-checkout commit should BLOCK (got exit $RC)"

# --- Case 8: `git -c commit.gpgsign=false commit` on default -> BLOCK ----------
RC=$(run_hook "git -c commit.gpgsign=false commit -m x")
[ "$RC" = "2" ] && pass "8. 'git -c <cfg> commit' on default -> BLOCK (exit 2)" \
                || fail "8. git -c <cfg> commit on default should BLOCK (got exit $RC)"

echo
echo "==========================="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo
  echo "Failed assertions:"
  for m in "${FAIL_MSGS[@]}"; do echo "  - $m"; done
  exit 1
fi
echo "===COMMIT-BLOCK WORKTREE TEST ALL $PASS CASES PASS==="
exit 0
