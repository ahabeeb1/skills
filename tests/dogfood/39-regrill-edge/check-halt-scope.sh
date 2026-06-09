#!/usr/bin/env bash
# Dogfood scenario 39 (concurrent-sibling half) — parallel-dev's halt-scope
# rule for re-grill: what happens to in-flight siblings when one slice halts.
# Per spec slice #4 (grill-2.0-alignment) + the regrill-edge-and-grill-alignment-axes decision.
#
# Test cases:
#   (i) parallel-dev's BLOCKED suggested_action set includes "re-grill"
#   (j) pause-all default: ambiguous cause -> siblings pause at their next
#       checkpoint; the lead may explicitly classify slice-local to let them run
#   (k) salvage rule: finished sibling results enter the re-grill payload as
#       evidence — never discarded wholesale

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PD="$REPO_ROOT/skills/parallel-dev/SKILL.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f "$PD" ] || fail "parallel-dev SKILL.md not found"

# ---------------------------------------------------------------------------
# Case (i) — re-grill in the suggested_action vocabulary
# ---------------------------------------------------------------------------
grep -qE 'suggested_action[^}]*"re-grill"' "$PD" \
  || fail "(i) parallel-dev suggested_action set does not include \"re-grill\""
pass "(i) re-grill is in parallel-dev's suggested_action vocabulary"

# ---------------------------------------------------------------------------
# Case (j) — pause-all default with slice-local override
# ---------------------------------------------------------------------------
grep -qiE 'pause.*next checkpoint' "$PD" \
  || fail "(j) pause-at-next-checkpoint default missing"
grep -qiE 'spec-wide' "$PD" || fail "(j) spec-wide classification missing"
grep -qiE 'slice-local' "$PD" || fail "(j) slice-local classification missing"
pass "(j) pause-all default + spec-wide/slice-local classification present"

# ---------------------------------------------------------------------------
# Case (k) — salvage rule
# ---------------------------------------------------------------------------
grep -qiE 'salvage|salvaged_sibling_results' "$PD" \
  || fail "(k) salvage rule missing — finished sibling work must enter the payload as evidence"
pass "(k) salvage rule present"

echo
echo "===SCENARIO 39 HALT-SCOPE ALL 3 CASES PASS==="
