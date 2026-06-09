#!/usr/bin/env bash
# Dogfood scenario 37 — slice-shape is the 8th ambiguity axis and the slice
# table is a standing Phase 1 inventory item class.
# Per spec slice #1 (grill-2.0-alignment) + the regrill-edge-and-grill-alignment-axes decision.
#
# Executable half of the scenario. The LLM-behavior half lives in the sibling
# fixtures (37a planted horizontal decomposition, 37b sound-slices control).
#
# Test cases:
#   (a) ambiguity-axes.md has an axis-8 heading naming slice shape
#   (b) axis 8 carries >= 4 probes, each phrased as a question
#   (c) axis-8 probes cover the four load-bearing concepts:
#       vertical-ness, deprioritization, HITL placement, ordering justification
#   (d) socratic-grill SKILL.md Phase 1 names the slice table as a standing
#       inventory item class
#   (e) socratic-grill SKILL.md Phase 2 axis list counts eight, not seven
#   (f) no checklist/rubric language inside axis 8 (the gate stays a
#       conversation: "pass/fail", "checklist", "must satisfy" are banned there)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
AXES="$REPO_ROOT/skills/socratic-grill/references/ambiguity-axes.md"
GRILL="$REPO_ROOT/skills/socratic-grill/SKILL.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f "$AXES" ] || fail "ambiguity-axes.md not found at $AXES"
[ -f "$GRILL" ] || fail "socratic-grill SKILL.md not found at $GRILL"

# Extract the axis-8 section (from the '## 8.' heading to the next '## ' or EOF)
AXIS8=$(awk '/^## 8\./{flag=1; print; next} /^## /{flag=0} flag' "$AXES")

# ---------------------------------------------------------------------------
# Case (a) — axis-8 heading exists and names slice shape
# ---------------------------------------------------------------------------
echo "$AXIS8" | head -1 | grep -qi 'slice shape' \
  || fail "(a) no '## 8.' axis heading naming slice shape in ambiguity-axes.md"
pass "(a) axis 8 'Slice shape' heading present"

# ---------------------------------------------------------------------------
# Case (b) — >= 4 probes, question-shaped
# ---------------------------------------------------------------------------
PROBE_COUNT=$(echo "$AXIS8" | grep -c '^- ' || true)
[ "$PROBE_COUNT" -ge 4 ] || fail "(b) axis 8 has $PROBE_COUNT probes; need >= 4"
QUESTION_COUNT=$(echo "$AXIS8" | grep '^- ' | grep -c '?' || true)
[ "$QUESTION_COUNT" -ge 4 ] || fail "(b) only $QUESTION_COUNT probes are question-shaped; need >= 4"
pass "(b) axis 8 has $PROBE_COUNT probes, $QUESTION_COUNT question-shaped"

# ---------------------------------------------------------------------------
# Case (c) — the four load-bearing concepts are covered
# ---------------------------------------------------------------------------
for concept in 'vertical' 'throw away\|deprioriti' 'HITL' 'order'; do
  echo "$AXIS8" | grep -qi "$concept" \
    || fail "(c) axis 8 missing load-bearing concept: $concept"
done
pass "(c) vertical-ness / deprioritization / HITL / ordering all covered"

# ---------------------------------------------------------------------------
# Case (d) — slice table is a standing Phase 1 inventory item class
# ---------------------------------------------------------------------------
PHASE1=$(awk '/^### Phase 1/{flag=1; print; next} /^### Phase 2/{flag=0} flag' "$GRILL")
echo "$PHASE1" | grep -qi 'slice table' \
  || fail "(d) grill Phase 1 does not name the slice table as an inventory item class"
pass "(d) slice table is a standing Phase 1 inventory item"

# ---------------------------------------------------------------------------
# Case (e) — Phase 2 axis list counts eight
# ---------------------------------------------------------------------------
grep -qi 'eight axes' "$GRILL" \
  || fail "(e) grill SKILL.md still says 'seven axes' (or lost the axis count)"
grep -qi 'seven axes' "$GRILL" \
  && fail "(e) grill SKILL.md still contains a 'seven axes' reference"
pass "(e) grill SKILL.md axis count is eight"

# ---------------------------------------------------------------------------
# Case (f) — no checklist/rubric language inside axis 8
# ---------------------------------------------------------------------------
echo "$AXIS8" | grep -qiE 'pass/fail|checklist|must satisfy' \
  && fail "(f) axis 8 contains checklist/rubric language — the gate must stay a conversation"
pass "(f) axis 8 is conversation-shaped (no rubric language)"

echo
echo "===SCENARIO 37 ALL 6 CASES PASS==="
