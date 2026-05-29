#!/usr/bin/env bash
# Dogfood scenario 32 — ADR index cutover note + hand-maintained index (v1.23.0)
# Per spec slice #5 (v1.23.0-dated-artifact-naming): OQ-4 (README section note),
# OQ-5 (index hand-maintained by decision-record, no script), OQ-2 (title+link
# cross-ref convention documented in the note).
#
# Cases:
#   (a) adrs/README.md carries an integer->dated cutover marker note.
#   (b) the note states the title+link cross-reference convention (OQ-2).
#   (c) the index table lists 0023 and 0024 as real rows (the stray `| 0023 | --- |`
#       placeholders the old rename script appended are gone).
#   (d) the Numbering convention acknowledges the frozen-integer + dated mixed scheme
#       (no longer claims a single monotonic-integer rule).
#   (e) decision-record/SKILL.md instructs hand-appending the index row at write
#       time, and creates NO index script (regression guard for OQ-5).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
README="$REPO_ROOT/docs/agents/adrs/README.md"
DR_SKILL="$REPO_ROOT/skills/decision-record/SKILL.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f "$README" ] || fail "adrs/README.md not found"
[ -f "$DR_SKILL" ] || fail "decision-record SKILL.md not found"

# ---------------------------------------------------------------------------
# (a) cutover marker note present
# ---------------------------------------------------------------------------
grep -Eiq 'frozen integer|0001-0024 are frozen|integer ADRs.*dated|dated thereafter|dated .* YYYY-MM-DD' "$README" \
  || fail "(a) README has no integer->dated cutover marker note"
grep -Eq 'YYYY-MM-DD-<slug>\.md' "$README" \
  || fail "(a) cutover note does not name the dated 'YYYY-MM-DD-<slug>.md' scheme"
pass "(a) integer->dated cutover marker note present"

# ---------------------------------------------------------------------------
# (b) note states the title+link cross-reference convention (OQ-2)
# ---------------------------------------------------------------------------
grep -Eiq 'title ?\+ ?(markdown )?link|title and (a )?(markdown )?link' "$README" \
  || fail "(b) README cutover note does not state the title+link cross-ref convention"
grep -Eq 'ADR-00NN|ADR-0[0-9]{3}' "$README" \
  || fail "(b) README does not state frozen integer ADRs are cited as ADR-00NN"
pass "(b) title+link cross-ref convention documented (frozen ADRs stay ADR-00NN)"

# ---------------------------------------------------------------------------
# (c) 0023 and 0024 are real index rows; no stray `--- ` placeholder rows
# ---------------------------------------------------------------------------
grep -Eq '\| 0023 \| \[' "$README" || fail "(c) ADR-0023 is not a real index row (with a linked title)"
grep -Eq '\| 0024 \| \[' "$README" || fail "(c) ADR-0024 is not a real index row (with a linked title)"
if grep -Eq '\| 002[34] \| --- \|' "$README"; then
  fail "(c) stray '| 0023/0024 | --- |' placeholder rows still present (the old rename-script artifact)"
fi
pass "(c) 0023 + 0024 are real index rows; stray placeholders removed"

# ---------------------------------------------------------------------------
# (d) Numbering convention acknowledges the mixed scheme
# ---------------------------------------------------------------------------
grep -Eiq 'frozen|0001-0024|dated|two schemes|mixed' "$README" \
  || fail "(d) Numbering/Conventions section does not acknowledge the frozen-integer + dated mixed scheme"
pass "(d) Numbering convention acknowledges frozen-integer + dated mixed scheme"

# ---------------------------------------------------------------------------
# (e) decision-record instructs hand-appending the index row; no index script
# ---------------------------------------------------------------------------
grep -Eiq 'append .* index row|index row .* (at )?(ADR-)?write|hand-append|maintained by this skill|append .* adrs/README' "$DR_SKILL" \
  || fail "(e) decision-record/SKILL.md does not instruct hand-appending the index row"
# No new index script should exist (OQ-5: hand-maintained, no script).
if [ -e "$REPO_ROOT/skills/decision-record/scripts/update-adr-index.sh" ] \
   || [ -e "$REPO_ROOT/skills/release/scripts/update-adr-index.sh" ]; then
  fail "(e) an index-maintenance script exists — OQ-5 ruled hand-maintained, no script"
fi
pass "(e) decision-record hand-appends the index row; no index script created"

echo
echo "===SCENARIO 32 ALL 5 CASES PASS==="
