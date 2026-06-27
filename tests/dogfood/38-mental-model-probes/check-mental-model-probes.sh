#!/usr/bin/env bash
# Dogfood scenario 38 — three indirect mental-model probes in grill Phase 1,
# tier-scaled in count, with answers landing in a consumed record section.
# Per spec slice #2 (grill-2.0-alignment) + the regrill-edge-and-grill-alignment-axes decision.
#
# Executable half. The LLM-behavior half lives in 38a (Balanced run shows
# exactly 2 probes asked and answers echoed into the record).
#
# Test cases:
#   (a) grill SKILL.md names the three probes: premortem, door classification,
#       concrete example
#   (b) tier-count rule present: Quick 1 / Balanced 2 / Deep 3
#   (c) door probe carries the one-follow-up rule (concrete undo cost on every
#       "two-way" label)
#   (d) design-template.md has a "User mental model" section covering
#       success criteria, door classifications, and premortem risks
#   (e) write-plan SKILL.md reads the section's success criteria as
#       acceptance-gate candidates
#   (f) decision-record SKILL.md reads door labels into ADR consequences

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
# The grill now writes the mental-model answers into the Design's Decided section
# (there is no separate grill-record template). The Design template defines that
# section's shape.
GRILL="$REPO_ROOT/skills/socratic-grill/SKILL.md"
TEMPLATE="$REPO_ROOT/skills/draft-spec/references/design-template.md"
PLAN="$REPO_ROOT/skills/write-plan/SKILL.md"
RECORD="$REPO_ROOT/skills/decision-record/SKILL.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

for f in "$GRILL" "$TEMPLATE" "$PLAN" "$RECORD"; do
  [ -f "$f" ] || fail "missing file: $f"
done

# ---------------------------------------------------------------------------
# Case (a) — three named probes in grill SKILL.md
# ---------------------------------------------------------------------------
grep -qi 'premortem' "$GRILL" || fail "(a) premortem probe not named in grill SKILL.md"
grep -qiE 'one-way|two-way' "$GRILL" || fail "(a) door-classification probe not named"
grep -qi 'concrete example' "$GRILL" || fail "(a) concrete-example probe not named"
pass "(a) premortem / door-classification / concrete-example probes named"

# ---------------------------------------------------------------------------
# Case (b) — tier-count rule
# ---------------------------------------------------------------------------
grep -qiE 'Quick.*1.*Balanced.*2.*Deep.*3|Quick 1 / Balanced 2 / Deep 3' "$GRILL" \
  || fail "(b) tier-count rule (Quick 1 / Balanced 2 / Deep 3) not found"
pass "(b) tier-count rule present"

# ---------------------------------------------------------------------------
# Case (c) — door one-follow-up rule
# ---------------------------------------------------------------------------
grep -qi 'undo cost' "$GRILL" \
  || fail "(c) door probe lacks the one-follow-up rule (concrete undo cost)"
pass "(c) one-follow-up undo-cost rule present"

# ---------------------------------------------------------------------------
# Case (d) — template section
# ---------------------------------------------------------------------------
MM=$(awk '/^#+ User mental model/{flag=1; print; next} /^#{1,2} [A-Z]/{flag=0} flag' "$TEMPLATE")
[ -n "$MM" ] || fail "(d) design-template.md has no 'User mental model' section in Decided"
echo "$MM" | grep -qi 'success criteria' || fail "(d) section missing success criteria"
echo "$MM" | grep -qiE 'door|one-way|two-way' || fail "(d) section missing door classifications"
echo "$MM" | grep -qi 'premortem' || fail "(d) section missing premortem risks"
pass "(d) 'User mental model' template section covers all three answer kinds"

# ---------------------------------------------------------------------------
# Case (e) — write-plan consumes success criteria
# ---------------------------------------------------------------------------
grep -qi 'user mental model' "$PLAN" \
  || fail "(e) write-plan SKILL.md does not read the User mental model section"
pass "(e) write-plan reads success criteria as gate candidates"

# ---------------------------------------------------------------------------
# Case (f) — decision-record consumes door labels
# ---------------------------------------------------------------------------
grep -qi 'user mental model' "$RECORD" \
  || fail "(f) decision-record SKILL.md does not read the User mental model section"
pass "(f) decision-record reads door labels into consequences"

echo
echo "===SCENARIO 38 ALL 6 CASES PASS==="
