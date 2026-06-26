#!/usr/bin/env bash
# Dogfood scenario 35 — test-fixture identifiers are confirm-at-implementation
# Per spec slice #2 (v1.24.0 chain-fidelity-hardening) + the chain-fidelity
# executable-assertions decision § SP3.
#
# Asserts the "fixture identifiers are confirm-at-implementation" rule is present
# in the three chain surfaces that author or create test fixtures:
#
#   1. skills/draft-spec/SKILL.md  — test-strategy guidance: scenario numbers,
#                                    ADR slugs, file indices are confirm-at-implementation,
#                                    never hard-coded literals in a spec.
#   2. skills/write-plan/SKILL.md  — same rule for the plan surface.
#   3. skills/tdd-loop/SKILL.md    — Phase 1 RED globs the live tree for the next
#                                    free identifier before creating a fixture.
#
# The canonical instruction phrase is "confirm against the live tree". The
# spec/plan surfaces additionally carry the "confirm-at-implementation" framing.
#
# Test cases:
#   (a) draft-spec SKILL.md carries "confirm against the live tree"
#   (b) write-plan SKILL.md carries "confirm against the live tree"
#   (c) tdd-loop SKILL.md carries "confirm against the live tree"
#   (d) draft-spec + write-plan carry the "confirm-at-implementation" framing
#   (e) tdd-loop Phase 1 instructs globbing the live tree for the next free identifier
#   (f) all three additions are present-tense behavioral (no banned archaeology phrasing)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# Fixture identifiers now live on the Machine-layer surfaces that author test
# fixtures: vertical-slice (slice list with test seams), write-plan (gates/rollback
# referencing fixtures), and tdd-loop (Phase 1 RED). draft-spec writes the
# plain-language Design, which carries no test paths.
VSLICE="$REPO_ROOT/skills/vertical-slice/SKILL.md"
WRITE_PLAN="$REPO_ROOT/skills/write-plan/SKILL.md"
TDD_LOOP="$REPO_ROOT/skills/tdd-loop/SKILL.md"

for f in "$VSLICE" "$WRITE_PLAN" "$TDD_LOOP"; do
  [ -f "$f" ] || fail "expected skill surface missing: $f"
done

# Canonical phrase, case-insensitive so the assertion is robust to sentence casing.
CANON='confirm against the live tree'

# ---------------------------------------------------------------------------
# Case (a) — vertical-slice carries the canonical phrase
# ---------------------------------------------------------------------------
grep -qi "$CANON" "$VSLICE" \
  || fail "(a) vertical-slice/SKILL.md missing canonical phrase '$CANON'"
pass "(a) vertical-slice/SKILL.md carries '$CANON'"

# ---------------------------------------------------------------------------
# Case (b) — write-plan carries the canonical phrase
# ---------------------------------------------------------------------------
grep -qi "$CANON" "$WRITE_PLAN" \
  || fail "(b) write-plan/SKILL.md missing canonical phrase '$CANON'"
pass "(b) write-plan/SKILL.md carries '$CANON'"

# ---------------------------------------------------------------------------
# Case (c) — tdd-loop carries the canonical phrase
# ---------------------------------------------------------------------------
grep -qi "$CANON" "$TDD_LOOP" \
  || fail "(c) tdd-loop/SKILL.md missing canonical phrase '$CANON'"
pass "(c) tdd-loop/SKILL.md carries '$CANON'"

# ---------------------------------------------------------------------------
# Case (d) — spec + plan carry the confirm-at-implementation framing
# ---------------------------------------------------------------------------
grep -qi 'confirm-at-implementation' "$VSLICE" \
  || fail "(d) vertical-slice/SKILL.md missing 'confirm-at-implementation' framing"
grep -qi 'confirm-at-implementation' "$WRITE_PLAN" \
  || fail "(d) write-plan/SKILL.md missing 'confirm-at-implementation' framing"
pass "(d) vertical-slice + write-plan carry the 'confirm-at-implementation' framing"

# ---------------------------------------------------------------------------
# Case (e) — tdd-loop Phase 1 instructs globbing the live tree for the next free id
# ---------------------------------------------------------------------------
grep -qi 'next free' "$TDD_LOOP" \
  || fail "(e) tdd-loop/SKILL.md missing 'next free' identifier instruction"
grep -qi 'glob' "$TDD_LOOP" \
  || fail "(e) tdd-loop/SKILL.md missing glob-the-live-tree instruction"
pass "(e) tdd-loop/SKILL.md Phase 1 globs the live tree for the next free identifier"

# ---------------------------------------------------------------------------
# Case (f) — the three surfaces stay present-tense behavioral (no banned archaeology)
#   This mirrors scenario 34's self-referential-archaeology guard so the SP3 text
#   itself cannot reintroduce the prose shape SP2 bans.
# ---------------------------------------------------------------------------
ARCH_PAT='(this skill used to|previously (this|we)|was renamed|replaces the old|formerly|no release step [a-z]+s it|are not renamed|(in|set in) v[0-9]+([.][0-9]+)* this changed)'
for f in "$VSLICE" "$WRITE_PLAN" "$TDD_LOOP"; do
  if grep -niE "$ARCH_PAT" "$f" >/dev/null 2>&1; then
    # Only fail if a hit sits on a line that ALSO carries the SP3 phrasing
    # (we own the SP3 lines; pre-existing prose elsewhere is scenario 34's job).
    hits=$(grep -niE "$ARCH_PAT" "$f" | grep -iE "live tree|confirm-at-implementation|fixture" || true)
    [ -z "$hits" ] || fail "(f) SP3 text in $f uses banned archaeology phrasing: $hits"
  fi
done
pass "(f) SP3 instruction text is present-tense behavioral on all three surfaces"

echo
echo "===SCENARIO 35 ALL 6 CASES PASS==="
