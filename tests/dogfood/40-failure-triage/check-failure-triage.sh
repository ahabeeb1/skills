#!/usr/bin/env bash
# Dogfood scenario 40 — the failure-triage rule: tdd-loop classifies every
# verification failure on cheap signals and routes it three ways (transient /
# structural / spec-implicated) under a bounded retry budget.
# Per spec slice #1 (loop-harness) — closes gaps 1 and 2.
#
# Executable half. The LLM-behavior half lives in 40a (transient re-run),
# 40b (structural auto-invoke), 40c (budget-exhaustion halt).
#
# Test cases:
#   (a) a triage rule exists and covers both failure surfaces
#       (unexpected RED in Phases 2-4, verify-output BLOCKED in Pass 4c)
#   (b) the three routes are named with their actions: transient -> one
#       fresh-context re-run; structural -> systematic-debugging; spec-implicated
#       -> the re-grill edge
#   (c) same-error-twice rule: string comparison against the recorded last
#       failure; a repeat is structural
#   (d) history-less first-failure defaults: assertion-shaped -> structural;
#       error-shaped -> one retry
#   (e) per-slice retry budget of exactly 2, documented as a convention (not a
#       tuned optimum); exhaustion emits BLOCKED with a halt payload
#   (f) verify-output BLOCKED gets exactly 1 fresh-context fix attempt; the
#       same finding surviving the fix -> halt, never a second identical attempt
#   (g) systematic-debugging auto-invocation: fresh context + evidence payload
#       (test output, diff, attempted fix)
#   (h) spec-implicated routing points at the EXISTING re-grill edge unchanged
#       (7-field payload + fixed-format halt block not redefined)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TDD="$REPO_ROOT/skills/tdd-loop/SKILL.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f "$TDD" ] || fail "tdd-loop SKILL.md not found"

# ---------------------------------------------------------------------------
# Case (a) — triage rule exists, covering both failure surfaces
# ---------------------------------------------------------------------------
grep -qiE 'failure-triage|triage rule' "$TDD" || fail "(a) no failure-triage rule in tdd-loop"
grep -qiE 'unexpected RED.*phases? 2.{1,4}4|phases? 2.{1,4}4.*unexpected RED' "$TDD" \
  || fail "(a) triage does not cover unexpected RED in Phases 2-4"
grep -qiE 'verify-output.*BLOCKED.*(pass |phase )?4c|(pass |phase )4c.*verify-output.*BLOCKED' "$TDD" \
  || fail "(a) triage does not cover verify-output BLOCKED in Pass 4c"
pass "(a) triage rule covers both failure surfaces"

# ---------------------------------------------------------------------------
# Case (b) — three routes named with their actions
# ---------------------------------------------------------------------------
grep -qiE 'transient.*(one|exactly one|1) fresh-context re-run' "$TDD" \
  || fail "(b) transient route missing its one-fresh-context-re-run action"
grep -qiE 'structural.*systematic-debugging' "$TDD" \
  || fail "(b) structural route does not name systematic-debugging"
grep -qiE 'spec-implicated' "$TDD" || fail "(b) spec-implicated route missing"
pass "(b) all three routes named with actions"

# ---------------------------------------------------------------------------
# Case (c) — same-error-twice rule: string comparison, repeat is structural
# ---------------------------------------------------------------------------
grep -qi 'same-error-twice' "$TDD" || fail "(c) same-error-twice rule missing"
grep -qiE 'string.compar.*(recorded )?last failure|last failure.*string.compar' "$TDD" \
  || fail "(c) rule is not a string comparison against the recorded last failure"
grep -qiE 'repeat is structural|a repeat.*structural' "$TDD" \
  || fail "(c) a repeated error is not classified structural"
pass "(c) same-error-twice rule: string comparison, repeat -> structural"

# ---------------------------------------------------------------------------
# Case (d) — history-less first-failure defaults
# ---------------------------------------------------------------------------
grep -qiE 'assertion-shaped.*structural' "$TDD" \
  || fail "(d) history-less default missing: assertion-shaped -> structural"
grep -qiE 'error-shaped.*(one|1) retry' "$TDD" \
  || fail "(d) history-less default missing: error-shaped -> one retry"
pass "(d) history-less first-failure defaults stated"

# ---------------------------------------------------------------------------
# Case (e) — retry budget of exactly 2, convention, BLOCKED on exhaustion
# ---------------------------------------------------------------------------
grep -qiE 'retry budget of exactly 2' "$TDD" || fail "(e) per-slice retry budget of exactly 2 missing"
grep -qiE 'convention, not a tuned optimum' "$TDD" \
  || fail "(e) budget not documented as a convention (not a tuned optimum)"
grep -qiE 'exhaust.*BLOCKED.*halt payload|BLOCKED.*halt payload.*exhaust' "$TDD" \
  || fail "(e) budget exhaustion does not emit BLOCKED with a halt payload"
pass "(e) retry budget = 2 as convention; exhaustion -> BLOCKED + halt payload"

# ---------------------------------------------------------------------------
# Case (f) — verify-output BLOCKED: 1 fix attempt, never a second identical one
# ---------------------------------------------------------------------------
grep -qiE 'exactly (1|one) fresh-context fix attempt' "$TDD" \
  || fail "(f) verify-output BLOCKED fix attempt not bounded at exactly 1"
grep -qiE 'same finding surviv' "$TDD" \
  || fail "(f) same-finding-survives clause missing"
grep -qiE 'never a second identical (fix )?attempt' "$TDD" \
  || fail "(f) the never-a-second-identical-attempt rule missing"
pass "(f) verify-output BLOCKED: 1 fix attempt; surviving finding -> halt"

# ---------------------------------------------------------------------------
# Case (g) — systematic-debugging auto-invocation with evidence payload
# ---------------------------------------------------------------------------
grep -qiE 'auto-invoke.*systematic-debugging|systematic-debugging.*auto-invo' "$TDD" \
  || fail "(g) systematic-debugging is not auto-invoked"
grep -qiE 'systematic-debugging.*fresh context|fresh context.*systematic-debugging' "$TDD" \
  || fail "(g) systematic-debugging invocation is not fresh-context"
grep -qiE 'test output.*diff.*attempted fix' "$TDD" \
  || fail "(g) evidence payload (test output, diff, attempted fix) missing"
pass "(g) structural route auto-invokes systematic-debugging with evidence"

# ---------------------------------------------------------------------------
# Case (h) — spec-implicated routes to the EXISTING re-grill edge, unchanged
# ---------------------------------------------------------------------------
grep -qiE 'spec-implicated.*re-grill edge' "$TDD" \
  || fail "(h) spec-implicated does not route to the re-grill edge"
grep -qiE 'spec-implicated.*re-grill edge[^.]*unchanged|re-grill edge.*unchanged' "$TDD" \
  || fail "(h) re-grill edge routing not marked unchanged"
# Guard: the edge's 7-field payload must still be defined exactly once (the
# triage section points at it, never redefines it).
COUNT=$(grep -c 'blocked_decision' "$TDD")
[ "$COUNT" -eq 1 ] || fail "(h) re-grill payload fields redefined ($COUNT definitions of blocked_decision; expected 1)"
pass "(h) spec-implicated -> existing re-grill edge, payload untouched"

echo
echo "===SCENARIO 40 ALL 8 CASES PASS==="
