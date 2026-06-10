#!/usr/bin/env bash
# Dogfood scenario 41 — context-starved reviewer dispatch: after a write-task
# subagent returns DONE, a reviewer in fresh context receives only the
# diff + slice spec + bounding SHAs, finds gaps-not-style, and its PASS is
# evidence — never a replacement for deterministic assertions.
# Per spec slice #2 (loop-harness) + grill items 4 (placement/authority) and
# 10 (both-sided falsifiability).
#
# Executable half. The LLM-behavior halves live in 41a (planted violation
# must be caught) and 41b (clean control must pass without hallucinated
# Critical findings).
#
# Test cases:
#   (a) reviewer fires after a write-task subagent returns DONE, in fresh context
#   (b) reviewer is a read-task-class dispatch with no merge surface
#   (c) input is exactly the triple: diff + slice spec + bounding commit SHAs
#   (d) context starvation explicit: reviewer never sees the writer's
#       conversation or reasoning
#   (e) finding constraints: correctness / stated-requirements gaps only —
#       gaps-not-style
#   (f) severity tiers: Critical and Important block; Minor is recorded,
#       never blocks
#   (g) one writer fix round per Critical/Important finding; a surviving
#       finding -> BLOCKED (composes with tdd-loop's same-finding-twice rule)
#   (h) reviewer PASS recorded as evidence in the dispatch record, above the
#       writer's self-review in narrative weight, never replacing
#       deterministic assertions
#   (i) ownership: parallel-dev defines the contract; parallel-dev AND
#       tdd-loop's loop mode consume it
#   (j) AFK authority: a Critical finding hard-blocks — no overnight
#       override; the slice parks

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PD="$REPO_ROOT/skills/parallel-dev/SKILL.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f "$PD" ] || fail "parallel-dev SKILL.md not found"

# ---------------------------------------------------------------------------
# Case (a) — fires after a write-task DONE, in fresh context
# ---------------------------------------------------------------------------
grep -qiE 'after a write-task subagent returns .?DONE.?.*reviewer|reviewer.*after a write-task subagent returns .?DONE' "$PD" \
  || fail "(a) reviewer is not wired to fire after a write-task subagent returns DONE"
grep -qi 'fresh context' "$PD" || fail "(a) reviewer does not run in fresh context"
pass "(a) reviewer fires after write-task DONE, in fresh context"

# ---------------------------------------------------------------------------
# Case (b) — read-task-class dispatch, no merge surface
# ---------------------------------------------------------------------------
grep -qiE 'read-task[- ]class' "$PD" || fail "(b) reviewer is not classified as a read-task-class dispatch"
grep -qiE 'no merge surface' "$PD" || fail "(b) the no-merge-surface property is not stated"
grep -qiE 'read-task rules apply' "$PD" || fail "(b) read-task rules are not declared applicable to the reviewer"
pass "(b) reviewer is a read-task-class dispatch with no merge surface"

# ---------------------------------------------------------------------------
# Case (c) — input is exactly the triple
# ---------------------------------------------------------------------------
grep -qiE 'input triple|exactly three (things|inputs)' "$PD" || fail "(c) the input triple is not named"
grep -qi 'the diff' "$PD" || fail "(c) triple missing: the diff"
grep -qi 'slice spec' "$PD" || fail "(c) triple missing: the slice spec"
grep -qiE 'bounding (commit )?SHAs' "$PD" || fail "(c) triple missing: the bounding commit SHAs"
pass "(c) input is exactly the triple: diff + slice spec + bounding SHAs"

# ---------------------------------------------------------------------------
# Case (d) — context starvation explicit
# ---------------------------------------------------------------------------
grep -qiE 'context[- ]starv' "$PD" || fail "(d) context starvation is never named"
grep -qiE "never sees the writer'?s (conversation|reasoning)" "$PD" \
  || fail "(d) the rule that the reviewer never sees the writer's conversation/reasoning is missing"
pass "(d) context-starvation rule is explicit"

# ---------------------------------------------------------------------------
# Case (e) — gaps-not-style finding constraints
# ---------------------------------------------------------------------------
grep -qiE 'gaps?[-, ]+not[- ]style' "$PD" || fail "(e) gaps-not-style constraint missing"
grep -qi 'correctness' "$PD" || fail "(e) correctness gaps not named as in-scope"
grep -qiE 'stated[- ]requirements' "$PD" || fail "(e) stated-requirements gaps not named as in-scope"
pass "(e) findings constrained to correctness/stated-requirements gaps, not style"

# ---------------------------------------------------------------------------
# Case (f) — severity tiers and their effects
# ---------------------------------------------------------------------------
grep -qiE 'critical.*(block|important)' "$PD" || fail "(f) Critical tier missing or not blocking"
grep -qiE 'important.*block' "$PD" || fail "(f) Important tier missing or not blocking"
grep -qiE 'minor.*(recorded|never blocks)' "$PD" || fail "(f) Minor tier missing its recorded-never-blocks semantics"
pass "(f) severity tiers: Critical/Important block, Minor recorded never blocks"

# ---------------------------------------------------------------------------
# Case (g) — one fix round, survivor -> BLOCKED, composes with same-finding-twice
# ---------------------------------------------------------------------------
grep -qiE '(one|exactly one) (writer )?fix round' "$PD" || fail "(g) one-fix-round bound missing"
grep -qiE 'surviv.*BLOCKED|BLOCKED.*surviv' "$PD" \
  || fail "(g) a finding surviving its fix round does not escalate to BLOCKED"
grep -qiE 'same-finding-twice' "$PD" || fail "(g) composition with tdd-loop's same-finding-twice rule missing"
pass "(g) one fix round per finding; survivor escalates BLOCKED via same-finding-twice"

# ---------------------------------------------------------------------------
# Case (h) — PASS is evidence: above self-review, below assertions
# ---------------------------------------------------------------------------
grep -qiE 'PASS.*(recorded|evidence).*dispatch record|dispatch record.*PASS.*evidence' "$PD" \
  || fail "(h) reviewer PASS not recorded as evidence in the dispatch record"
grep -qiE "above the writer'?s self-review" "$PD" \
  || fail "(h) narrative positioning above the writer's self-review missing"
grep -qiE 'never replac.* deterministic assertions' "$PD" \
  || fail "(h) the never-replaces-deterministic-assertions rule missing"
pass "(h) PASS is evidence — above self-review, never replacing assertions"

# ---------------------------------------------------------------------------
# Case (i) — ownership: parallel-dev defines, both skills consume
# ---------------------------------------------------------------------------
grep -qiE 'parallel-dev.*DEFINES.*reviewer contract|DEFINES this reviewer contract' "$PD" \
  || fail "(i) parallel-dev is not named as the contract definer"
grep -qiE "tdd-loop.{0,30}loop mode.*CONSUME|CONSUME.*tdd-loop.{0,30}loop mode" "$PD" \
  || fail "(i) tdd-loop's loop mode is not named as a consumer"
pass "(i) parallel-dev defines; parallel-dev + tdd-loop loop mode consume"

# ---------------------------------------------------------------------------
# Case (j) — AFK Critical hard-block, no overnight override, slice parks
# ---------------------------------------------------------------------------
grep -qiE 'AFK.*critical.*hard-block|critical.*hard-block.*AFK' "$PD" \
  || fail "(j) AFK Critical hard-block missing"
grep -qiE 'no overnight override' "$PD" || fail "(j) no-overnight-override rule missing"
grep -qiE 'slice parks' "$PD" || fail "(j) the slice-parks consequence missing"
pass "(j) AFK Critical hard-blocks: no overnight override, slice parks"

echo
echo "===SCENARIO 41 ALL 10 CASES PASS==="
