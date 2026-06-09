#!/usr/bin/env bash
# Dogfood scenario 39 — the re-grill edge: tdd-loop can halt a slice on
# implementation-revealed spec ambiguity and route it through a scoped grill round.
# Per spec slice #3 (grill-2.0-alignment) + the regrill-edge-and-grill-alignment-axes decision.
#
# Executable half. The LLM-behavior half lives in 39a (simulated halt ->
# payload -> back-linked record -> spec patch).
#
# Test cases:
#   (a) tdd-loop lists "re-grill" as a BLOCKED suggested_action
#   (b) the 7 learning-payload fields are all named in tdd-loop
#   (c) the halt surfaces as a fixed-format block with exactly two exits
#       (inline spec patch | ADR escalation)
#   (d) tdd-loop Phase 6 retro question routes material ambiguity through the
#       re-grill edge (not a bare "re-run socratic-grill" suggestion)
#   (e) grill defines the scoped round: fresh context + named-decision scope
#   (f) the blast-radius boundary is stated with all three minor-conditions
#       (no other slice's acceptance criteria, no new slice,
#        Architecture/Concrete-picks untouched)
#   (g) the round writes a dated record with a -regrill suffix back-linked to
#       the original grill record
#   (h) the domain-touch rule governs conditional-extension re-fire

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TDD="$REPO_ROOT/skills/tdd-loop/SKILL.md"
GRILL="$REPO_ROOT/skills/socratic-grill/SKILL.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f "$TDD" ] || fail "tdd-loop SKILL.md not found"
[ -f "$GRILL" ] || fail "socratic-grill SKILL.md not found"

# ---------------------------------------------------------------------------
# Case (a) — re-grill is a BLOCKED suggested_action in tdd-loop
# ---------------------------------------------------------------------------
grep -qi 're-grill' "$TDD" || fail "(a) tdd-loop never mentions re-grill"
grep -qiE 'suggested_action[^a-z]*"?re-grill' "$TDD" \
  || fail "(a) re-grill is not wired as a suggested_action value"
pass "(a) re-grill rides BLOCKED's suggested_action"

# ---------------------------------------------------------------------------
# Case (b) — all 7 payload fields named
# ---------------------------------------------------------------------------
for field in blocked_slice blocked_decision expected_vs_observed evidence \
             attempted_resolutions scope_classification salvaged_sibling_results; do
  grep -q "$field" "$TDD" || fail "(b) payload field missing from tdd-loop: $field"
done
pass "(b) all 7 learning-payload fields named"

# ---------------------------------------------------------------------------
# Case (c) — fixed-format halt block with exactly two exits
# ---------------------------------------------------------------------------
grep -qiE 'inline (spec )?patch' "$TDD" || fail "(c) halt block missing the inline-patch exit"
grep -qiE 'ADR (amendment|escalation)' "$TDD" || fail "(c) halt block missing the ADR-escalation exit"
pass "(c) halt block carries both exits"

# ---------------------------------------------------------------------------
# Case (d) — Phase 6 retro routes through the edge
# ---------------------------------------------------------------------------
PHASE6=$(awk '/^### Phase 6/{flag=1; print; next} /^## /{flag=0} flag' "$TDD")
echo "$PHASE6" | grep -qi 're-grill' \
  || fail "(d) Phase 6 retro does not route material ambiguity through the re-grill edge"
pass "(d) Phase 6 retro references the re-grill edge"

# ---------------------------------------------------------------------------
# Case (e) — grill scoped round: fresh context + named-decision scope
# ---------------------------------------------------------------------------
grep -qi 'fresh context' "$GRILL" || fail "(e) scoped round lacks fresh-context framing"
grep -qiE 'scoped.*(round|re-grill)|re-grill round' "$GRILL" \
  || fail "(e) grill does not define a scoped re-grill round"
pass "(e) scoped round defined with fresh-context framing"

# ---------------------------------------------------------------------------
# Case (f) — blast-radius boundary: all three minor-conditions stated
# ---------------------------------------------------------------------------
grep -qiE "other slice'?s acceptance criteria|acceptance criteria of any other slice" "$GRILL" \
  || fail "(f) boundary missing: no other slice's acceptance criteria change"
grep -qiE 'adds? no (new )?slice' "$GRILL" || fail "(f) boundary missing: adds no slice"
grep -qiE 'architecture.*concrete picks|concrete picks.*architecture' "$GRILL" \
  || fail "(f) boundary missing: Architecture / Concrete picks untouched"
pass "(f) blast-radius boundary states all three minor-conditions"

# ---------------------------------------------------------------------------
# Case (g) — dated -regrill record back-linked to the original
# ---------------------------------------------------------------------------
grep -qE 'regrill\.md|-regrill' "$GRILL" || fail "(g) no -regrill record naming convention"
grep -qiE 'back-link|links? back to the original' "$GRILL" \
  || fail "(g) record is not back-linked to the original grill record"
pass "(g) dated back-linked -regrill record convention present"

# ---------------------------------------------------------------------------
# Case (h) — domain-touch rule for extension re-fire
# ---------------------------------------------------------------------------
grep -qiE 'domain.touch|extension whose domain' "$GRILL" \
  || fail "(h) domain-touch rule for conditional-extension re-fire missing"
pass "(h) domain-touch extension re-fire rule present"

echo
echo "===SCENARIO 39 ALL 8 CASES PASS==="
