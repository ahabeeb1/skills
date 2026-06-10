#!/usr/bin/env bash
# Dogfood scenario 44 — loop mode: tdd-loop Phase 0.5 promoted to the
# outer-loop driver with the tiered halt policy.
# Per spec slice #5 (loop-harness) + grill Items 3, 6, 12.
#
# Executable half. The LLM-behavior half lives in 44a (two-slice plan loops
# to DONE) and 44b (planted ambiguity parks slice-local, siblings continue).
#
# Test cases:
#   (a) /tdd --loop invocation; driver algorithm (inspect -> dispatch ->
#       verify -> update run file -> next); flag-less behavior unchanged
#   (b) every slice dispatched in fresh context
#   (c) ceiling: default 2x open slices, --max-iterations override,
#       effective ceiling recorded in run-file frontmatter
#   (d) terminal states exactly DONE / BLOCKED-with-halt-report — no third
#       exit; RUN_SUMMARY written at run end
#   (e) tiered halt policy: park vs provisional enumerated; the three
#       provisional gates named; version-bump confirm parks
#   (f) re-grill halts never self-resolve; scope_classification governs
#       continue-vs-terminate
#   (g) /tdd --resume <run-id>: session-identity checked before touching the
#       file; halt reports replayed as seed context; re-enters RED
#   (h) loop references the failure-triage rule, never restates its budgets
#   (i) Phase 0.5 NEEDS_CONTEXT row carries the 2-bound materially-changed
#       rule (no stale "ONCE" re-dispatch bound)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TDD="$REPO_ROOT/skills/tdd-loop/SKILL.md"
RUNFMT="$REPO_ROOT/docs/agents/references/run-file-format.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f "$TDD" ] || fail "tdd-loop SKILL.md not found"
[ -f "$RUNFMT" ] || fail "run-file-format.md not found (slice 4 dependency)"

LOOP=$(awk '/^## Loop mode/{flag=1; print; next} /^## /{flag=0} flag' "$TDD")
[ -n "$LOOP" ] || fail "no '## Loop mode' section in tdd-loop"

# ---------------------------------------------------------------------------
# Case (a) — /tdd --loop invocation + driver algorithm
# ---------------------------------------------------------------------------
grep -q -- '/tdd --loop' "$TDD" || fail "(a) /tdd --loop never named"
echo "$LOOP" | grep -qiE 'inspect.*dispatch.*verify' \
  || fail "(a) driver algorithm steps (inspect -> dispatch -> verify) missing"
echo "$LOOP" | grep -qiE 'without the flag.*(unchanged|single-pass|exactly as)' \
  || fail "(a) flag-less behavior not stated as unchanged single-pass"
pass "(a) /tdd --loop drives inspect -> dispatch -> verify; flag-less unchanged"

# ---------------------------------------------------------------------------
# Case (b) — fresh context per slice
# ---------------------------------------------------------------------------
echo "$LOOP" | grep -qiE '(per|each|every) slice.*fresh context|fresh context.*(per|each|every) slice' \
  || fail "(b) fresh-context-per-slice dispatch not stated"
pass "(b) every slice dispatched in fresh context"

# ---------------------------------------------------------------------------
# Case (c) — iteration ceiling: default, override, recorded
# ---------------------------------------------------------------------------
echo "$LOOP" | grep -qE '2(×|x) open slices' || fail "(c) default ceiling (2x open slices) missing"
echo "$LOOP" | grep -q -- '--max-iterations' || fail "(c) --max-iterations override missing"
echo "$LOOP" | grep -qiE '(effective ceiling|iteration_ceiling).*(record|frontmatter)|record.*effective ceiling' \
  || fail "(c) effective ceiling not recorded in run-file frontmatter"
pass "(c) ceiling: 2x open slices default, --max-iterations override, recorded"

# ---------------------------------------------------------------------------
# Case (d) — exactly two terminal states + RUN_SUMMARY at run end
# ---------------------------------------------------------------------------
echo "$LOOP" | grep -qiE 'no third exit|exactly two' || fail "(d) two-terminal-state rule missing"
echo "$LOOP" | grep -qE 'DONE' || fail "(d) DONE terminal state missing"
echo "$LOOP" | grep -qiE 'BLOCKED.*halt report' || fail "(d) BLOCKED-with-halt-report missing"
echo "$LOOP" | grep -qiE 'RUN_SUMMARY' || fail "(d) RUN_SUMMARY never mentioned"
echo "$LOOP" | grep -qiE '(run end|either terminal|either state).*RUN_SUMMARY|RUN_SUMMARY.*(run end|either terminal|either state)' \
  || fail "(d) RUN_SUMMARY not tied to run end in either terminal state"
pass "(d) terminal states DONE / BLOCKED-with-halt-report; RUN_SUMMARY at run end"

# ---------------------------------------------------------------------------
# Case (e) — tiered halt policy: park vs provisional, gates named
# ---------------------------------------------------------------------------
echo "$LOOP" | grep -qi 'park' || fail "(e) no park classification"
echo "$LOOP" | grep -qi 'provisional' || fail "(e) no provisional classification"
echo "$LOOP" | grep -qiE 'fixture-ID confirm' || fail "(e) fixture-ID confirm gate not named"
echo "$LOOP" | grep -qiE 'ANNOTATE' || fail "(e) verify-output ANNOTATE-mode gate not named"
echo "$LOOP" | grep -qiE 'spec-compliance review' || fail "(e) spec-compliance review gate not named"
echo "$LOOP" | grep -qiE 'version-bump.*park|park.*version-bump' \
  || fail "(e) version-bump confirm does not park"
echo "$LOOP" | grep -qiE 'green check' || fail "(e) provisional gates not gated on green checks"
echo "$LOOP" | grep -qiE 'ratif' || fail "(e) provisional gates not logged for ratification"
pass "(e) halt policy enumerates park vs provisional; 3 provisional gates; version-bump parks"

# ---------------------------------------------------------------------------
# Case (f) — re-grill halts never self-resolve; scope governs continuation
# ---------------------------------------------------------------------------
echo "$LOOP" | grep -qiE 'never self-resolve' || fail "(f) re-grill self-resolution not forbidden"
echo "$LOOP" | grep -q 'scope_classification' || fail "(f) scope_classification not governing halts"
echo "$LOOP" | grep -qiE 'unaffected slices' || fail "(f) continue-on-unaffected-slices missing"
echo "$LOOP" | grep -qiE 'spec-wide' || fail "(f) spec-wide termination case missing"
pass "(f) re-grill halts never self-resolve; scope_classification governs continuation"

# ---------------------------------------------------------------------------
# Case (g) — /tdd --resume <run-id> with the #15047 session-identity guard
# ---------------------------------------------------------------------------
grep -q -- '/tdd --resume' "$TDD" || fail "(g) /tdd --resume never named"
echo "$LOOP" | grep -qiE 'session.identity' || fail "(g) session-identity field not checked"
echo "$LOOP" | grep -qiE 'session.identity[^.]*(first|before)' \
  || fail "(g) session-identity not checked FIRST / before touching the file"
echo "$LOOP" | grep -qiE 'halt report.*seed|seed context' || fail "(g) halt reports not replayed as seed context"
echo "$LOOP" | grep -qiE 're-enter[s]? RED|RED on the parked' || fail "(g) resume does not re-enter RED"
echo "$LOOP" | grep -qiE 'run file \+ git|no state beyond' || fail "(g) resume-by-inspection rule missing"
pass "(g) /tdd --resume: session-identity first, halt-report seed, re-enters RED"

# ---------------------------------------------------------------------------
# Case (h) — loop references failure-triage, never restates its budgets
# ---------------------------------------------------------------------------
echo "$LOOP" | grep -qiE 'failure-triage' || fail "(h) loop never references the failure-triage rule"
if echo "$LOOP" | grep -qiE 'budget of exactly|retry budget of'; then
  fail "(h) loop restates the triage rule's retry budgets instead of referencing them"
fi
pass "(h) loop points at the failure-triage rule without restating budgets"

# ---------------------------------------------------------------------------
# Case (i) — Phase 0.5 NEEDS_CONTEXT row: 2-bound materially-changed rule
# ---------------------------------------------------------------------------
P05=$(awk '/^### Phase 0\.5/{flag=1; print; next} /^### /{flag=0} flag' "$TDD")
[ -n "$P05" ] || fail "(i) Phase 0.5 section not found"
echo "$P05" | grep -qiE 'materially changed' || fail "(i) materially-changed rule missing from NEEDS_CONTEXT row"
echo "$P05" | grep -qE 'up to 2|2 re-dispatch' || fail "(i) 2-re-dispatch bound missing"
echo "$P05" | grep -qiE 'dispatcher' || fail "(i) dispatcher-judges rule missing"
echo "$P05" | grep -qiE 'unchanged input[^|]*(escalat|BLOCKED)' \
  || fail "(i) unchanged-input immediate escalation missing"
if echo "$P05" | grep -qE '\bONCE\b'; then
  fail "(i) stale ONCE re-dispatch bound still in Phase 0.5"
fi
pass "(i) NEEDS_CONTEXT row carries the ADR-0004 2-bound materially-changed rule"

echo
echo "===SCENARIO 44 ALL 9 CASES PASS==="
