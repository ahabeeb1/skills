#!/usr/bin/env bash
# Dogfood scenario 42 — the run-file format: the loop harness's only new
# artifact class, defined as a reference doc at
# docs/agents/references/run-file-format.md.
# Per spec slice #4 (loop-harness) + the grill record's Item 5 user override
# (run files extend docs/agents/dispatches/ — no new writer path).
#
# Executable half: greps the reference doc for each contract point, then
# asserts a conforming fixture run file actually carries the format.
#
# Test cases:
#   (a) location + naming: docs/agents/dispatches/run-<run-id>.md, a second
#       record class beside dispatch-record JSON; cross-links the
#       dispatch-record template
#   (b) frontmatter fields all enumerated, incl. the EFFECTIVE-ceiling rule
#       (default 2x open slices or --max-iterations override, recorded
#       either way) and the status enum (running | done | blocked)
#   (c) session/worktree scoping: session-identity check before any resume
#       touches the file (the #15047 cross-session hijack guard)
#   (d) writer rule: skill-written only; hooks never write it (ADR-0003
#       Rule 3 untouched)
#   (e) advisory-only semantics + ADR-0019-shaped staleness contract: git is
#       the durability layer; stale run file detected by comparing recorded
#       SHAs/iteration against git
#   (f) halt-report format: 7 re-grill payload fields + cause /
#       evidence-summary / options; ONE format for all four halt classes
#   (g) RUN_SUMMARY format: per-slice status table, queued halts,
#       provisional actions awaiting ratification, /tdd --resume <run-id>
#   (h) format-freeze rule: no breaking field changes without a grill round
#   (i) fixture run file carries every enumerated frontmatter field
#   (j) fixture run file carries a RUN_SUMMARY section naming /tdd --resume

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
REF="$REPO_ROOT/docs/agents/references/run-file-format.md"
FIXTURE="$REPO_ROOT/tests/dogfood/42-run-file-format/fixture-run-file.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f "$REF" ] || fail "run-file-format.md reference doc not found"
[ -f "$FIXTURE" ] || fail "fixture-run-file.md not found"

# ---------------------------------------------------------------------------
# Case (a) — location, naming, second record class, template cross-link
# ---------------------------------------------------------------------------
grep -q 'docs/agents/dispatches/run-<run-id>\.md' "$REF" \
  || fail "(a) location/naming docs/agents/dispatches/run-<run-id>.md not stated"
grep -qiE 'second record class' "$REF" \
  || fail "(a) run file not framed as a second record class beside dispatch records"
grep -q 'dispatch-record-template\.md' "$REF" \
  || fail "(a) no cross-link to the dispatch-record template"
pass "(a) location + naming + second-record-class framing + template cross-link"

# ---------------------------------------------------------------------------
# Case (b) — frontmatter fields enumerated, ceiling semantics, status enum
# ---------------------------------------------------------------------------
for field in run_id plan_ref session_id worktree branch started_at updated_at \
             iteration_count iteration_ceiling last_error_hash status; do
  grep -q "$field" "$REF" || fail "(b) frontmatter field missing from reference: $field"
done
grep -qiE 'per-slice retry counter' "$REF" \
  || fail "(b) per-slice retry counters not enumerated"
grep -qiE 'effective ceiling' "$REF" \
  || fail "(b) iteration_ceiling not defined as the EFFECTIVE ceiling"
grep -qiE '2.?x|2×' "$REF" || fail "(b) 2x-open-slices default not stated"
grep -q '\-\-max-iterations' "$REF" \
  || fail "(b) --max-iterations override not named"
grep -qE 'running.*\|.*done.*\|.*blocked' "$REF" \
  || fail "(b) status enum (running | done | blocked) not stated"
pass "(b) all frontmatter fields + ceiling semantics + status enum enumerated"

# ---------------------------------------------------------------------------
# Case (c) — session/worktree scoping rule (the #15047 guard)
# ---------------------------------------------------------------------------
grep -qiE 'session.identity' "$REF" \
  || fail "(c) session-identity check not stated"
grep -qiE 'before (any |a )?resume|resume MUST check' "$REF" \
  || fail "(c) the check is not bound to happen BEFORE a resume touches the file"
grep -q '15047' "$REF" \
  || fail "(c) the #15047 cross-session hazard class is not cited"
pass "(c) session/worktree scoping rule with the #15047 guard"

# ---------------------------------------------------------------------------
# Case (d) — writer rule: skill-written only, hooks never write
# ---------------------------------------------------------------------------
grep -qiE 'skill-written only|skills? (write|own) it.*hooks never|written (only )?by skills' "$REF" \
  || fail "(d) skill-written-only rule not stated"
grep -qiE 'hooks never write' "$REF" \
  || fail "(d) hooks-never-write rule not stated"
grep -qE 'ADR-0003' "$REF" \
  || fail "(d) ADR-0003 Rule 3 not referenced"
pass "(d) writer rule: skill-written only; hooks never write (ADR-0003)"

# ---------------------------------------------------------------------------
# Case (e) — advisory-only + ADR-0019-shaped staleness contract
# ---------------------------------------------------------------------------
grep -qiE 'advisory' "$REF" || fail "(e) advisory-only semantics not stated"
grep -qiE 'never .*(sole|single) source of truth|sole source of truth' "$REF" \
  || fail "(e) never-the-sole-source-of-truth rule not stated"
grep -qiE 'durability layer' "$REF" \
  || fail "(e) git refs + dispatch records not named as the durability layer"
grep -qiE 'stale' "$REF" || fail "(e) staleness contract not stated"
grep -qE 'ADR-0019' "$REF" \
  || fail "(e) staleness contract not anchored to the ADR-0019 shape"
grep -qiE 'compar(e|ing|ison).*(SHA|iteration).*(git)|against git' "$REF" \
  || fail "(e) stale-detection rule (recorded SHAs/iteration vs git) not stated"
pass "(e) advisory-only semantics + ADR-0019-shaped staleness contract"

# ---------------------------------------------------------------------------
# Case (f) — halt-report format: 7 payload fields + 3 extensions, one format
# ---------------------------------------------------------------------------
for field in blocked_slice blocked_decision expected_vs_observed evidence \
             attempted_resolutions scope_classification salvaged_sibling_results; do
  grep -q "$field" "$REF" || fail "(f) re-grill payload field missing: $field"
done
for field in cause evidence-summary options; do
  grep -q "$field" "$REF" || fail "(f) halt-report extension field missing: $field"
done
grep -qiE 'one format for every halt class|every halt class.*one format|all four halt classes' "$REF" \
  || fail "(f) one-format-for-every-halt-class rule not stated"
for class in re-grill 'budget exhaustion' 'reviewer block' 'parked gate'; do
  grep -qi "$class" "$REF" || fail "(f) halt class not named: $class"
done
pass "(f) halt-report format: 7+3 fields, one format across all four halt classes"

# ---------------------------------------------------------------------------
# Case (g) — RUN_SUMMARY format
# ---------------------------------------------------------------------------
grep -q 'RUN_SUMMARY' "$REF" || fail "(g) RUN_SUMMARY section not defined"
grep -qiE 'per-slice status table' "$REF" \
  || fail "(g) per-slice status table not specified"
grep -qiE 'halts? queued|queued halts?' "$REF" \
  || fail "(g) queued-halts requirement not specified"
grep -qiE 'provisional actions.*ratification|awaiting ratification' "$REF" \
  || fail "(g) provisional-actions-awaiting-ratification not specified"
grep -qE '/tdd --resume <run-id>' "$REF" \
  || fail "(g) halt section does not name /tdd --resume <run-id>"
pass "(g) RUN_SUMMARY format: status table + queued halts + provisional actions + resume command"

# ---------------------------------------------------------------------------
# Case (h) — format-freeze rule
# ---------------------------------------------------------------------------
grep -qiE 'no breaking field changes? without a grill round|breaking field changes? (need|require)s? a (new )?grill round' "$REF" \
  || fail "(h) format-freeze rule (breaking field changes need a grill round) not stated"
pass "(h) format-freeze rule present"

# ---------------------------------------------------------------------------
# Case (i) — fixture carries every enumerated frontmatter field
# ---------------------------------------------------------------------------
# Frontmatter = everything between the first two `---` lines.
FM=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$FIXTURE")
[ -n "$FM" ] || fail "(i) fixture has no frontmatter block"
for field in run_id plan_ref session_id worktree branch started_at updated_at \
             iteration_count iteration_ceiling last_error_hash status; do
  echo "$FM" | grep -q "^$field:" || fail "(i) fixture frontmatter missing field: $field"
done
echo "$FM" | grep -qE 'retr(y|ies)' \
  || fail "(i) fixture frontmatter missing per-slice retry counters"
echo "$FM" | grep -qE '^status: *(running|done|blocked)$' \
  || fail "(i) fixture status not one of running | done | blocked"
pass "(i) fixture run file carries every enumerated frontmatter field"

# ---------------------------------------------------------------------------
# Case (j) — fixture carries a RUN_SUMMARY naming the resume command
# ---------------------------------------------------------------------------
grep -q 'RUN_SUMMARY' "$FIXTURE" || fail "(j) fixture missing RUN_SUMMARY section"
grep -qE '/tdd --resume [a-z0-9-]+' "$FIXTURE" \
  || fail "(j) fixture RUN_SUMMARY does not name the /tdd --resume command"
pass "(j) fixture RUN_SUMMARY names /tdd --resume"

echo
echo "===SCENARIO 42 ALL 10 CASES PASS==="
