#!/usr/bin/env bash
# Dogfood scenario 43 — bounded NEEDS_CONTEXT multi-retry: ADR-0004 Part 1 is
# amended in place to widen the re-dispatch bound from 1 to 2, each re-dispatch
# requiring materially changed input (the dispatcher judges), with unchanged
# input escalating immediately as BLOCKED — and parallel-dev's return-contract
# wording matches.
# Per spec slice #3 (loop-harness) + grill item 1 (amendment vehicle +
# changed-input rule).
#
# Executable half. The LLM-behavior half lives in 43a (simulated NEEDS_CONTEXT
# return where the input cannot be materially changed -> immediate BLOCKED
# escalation, no second dispatch).
#
# Test cases:
#   (a) ADR-0004 states the re-dispatch bound of 2
#   (b) ADR-0004 states the materially-changed-input requirement with the
#       dispatcher as the judge
#   (c) ADR-0004 states immediate escalation as BLOCKED on unchanged input
#   (d) ADR-0004 carries a dated 2026-06-10 amendment line in its changelog
#   (e) parallel-dev's NEEDS_CONTEXT section reflects the new bound of 2
#   (f) parallel-dev states immediate escalation for unchanged input
#   (g) no stale "re-dispatches once" / "re-dispatch ONCE"-style 1-bound
#       wording survives in parallel-dev's return contract

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ADR="$REPO_ROOT/docs/agents/adrs/0004-parallel-subagent-dispatch-contract.md"
PD="$REPO_ROOT/skills/parallel-dev/SKILL.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f "$ADR" ] || fail "ADR-0004 not found"
[ -f "$PD" ] || fail "parallel-dev SKILL.md not found"

# ---------------------------------------------------------------------------
# Case (a) — ADR-0004 states the bound of 2
# ---------------------------------------------------------------------------
grep -qiE 'up to 2 re-dispatch' "$ADR" \
  || fail "(a) ADR-0004 does not state the up-to-2 re-dispatch bound"
pass "(a) ADR-0004 states the re-dispatch bound of 2"

# ---------------------------------------------------------------------------
# Case (b) — materially-changed-input requirement, dispatcher as judge
# ---------------------------------------------------------------------------
grep -qiE 'materially changed input' "$ADR" \
  || fail "(b) ADR-0004 does not require materially changed input per re-dispatch"
grep -qiE 'dispatcher judges' "$ADR" \
  || fail "(b) ADR-0004 does not name the dispatcher as the judge of \"materially changed\""
grep -qiE 'composed the original input' "$ADR" \
  || fail "(b) ADR-0004 does not carry the dispatcher's judging rationale (it composed the original input)"
pass "(b) materially-changed-input requirement with the dispatcher as judge"

# ---------------------------------------------------------------------------
# Case (c) — immediate escalation as BLOCKED on unchanged input
# ---------------------------------------------------------------------------
grep -qiE 'unchanged input.*escalates immediately|escalates immediately.*unchanged input' "$ADR" \
  || fail "(c) ADR-0004 does not state immediate escalation on unchanged input"
grep -qiE 'unchanged input.*BLOCKED|BLOCKED.*unchanged input' "$ADR" \
  || fail "(c) ADR-0004's unchanged-input escalation does not name BLOCKED"
grep -qiE 'instead of dispatching' "$ADR" \
  || fail "(c) ADR-0004 does not state that escalation happens instead of dispatching"
pass "(c) unchanged input escalates immediately as BLOCKED, never dispatches"

# ---------------------------------------------------------------------------
# Case (d) — dated 2026-06-10 amendment line in the changelog
# ---------------------------------------------------------------------------
grep -qE '^- 2026-06-10' "$ADR" \
  || fail "(d) ADR-0004 changelog has no dated 2026-06-10 amendment line"
grep -qiE '2026-06-10.*(NEEDS_CONTEXT|re-dispatch)' "$ADR" \
  || fail "(d) the 2026-06-10 amendment line does not reference the NEEDS_CONTEXT re-dispatch bound"
grep -qE '2026-06-10-loop-harness-fresh-context-outer-loop\.md' "$ADR" \
  || fail "(d) the amendment does not cite the loop-harness decision"
pass "(d) dated 2026-06-10 amendment line present, citing the loop-harness decision"

# ---------------------------------------------------------------------------
# Case (e) — parallel-dev NEEDS_CONTEXT section reflects the new bound
# ---------------------------------------------------------------------------
RC=$(awk '/^## Return contract/{flag=1; print; next} /^## /{flag=0} flag' "$PD")
echo "$RC" | grep -qiE 'up to 2' \
  || fail "(e) parallel-dev return contract does not state the up-to-2 bound"
echo "$RC" | grep -qiE 'materially changed' \
  || fail "(e) parallel-dev return contract does not require materially changed input"
echo "$RC" | grep -qiE 'dispatcher judges' \
  || fail "(e) parallel-dev return contract does not name the dispatcher as the judge"
pass "(e) parallel-dev NEEDS_CONTEXT section reflects the new bound"

# ---------------------------------------------------------------------------
# Case (f) — parallel-dev: unchanged input escalates immediately
# ---------------------------------------------------------------------------
echo "$RC" | grep -qiE 'unchanged input.*(escalates immediately|immediately.*BLOCKED)|escalates immediately.*unchanged input' \
  || fail "(f) parallel-dev does not state immediate escalation for unchanged input"
echo "$RC" | grep -qiE 'instead of dispatching' \
  || fail "(f) parallel-dev does not state that unchanged-input escalation skips the dispatch"
pass "(f) parallel-dev: unchanged input escalates immediately as BLOCKED"

# ---------------------------------------------------------------------------
# Case (g) — no stale 1-bound wording in the return contract
# ---------------------------------------------------------------------------
if echo "$RC" | grep -qiE 're-dispatch(es)? once|re-dispatch ONCE|once with the corrected input'; then
  fail "(g) stale 1-bound re-dispatch wording survives in parallel-dev's return contract"
fi
pass "(g) no stale re-dispatch-once wording in the return contract"

echo
echo "===SCENARIO 43 ALL 7 CASES PASS==="
