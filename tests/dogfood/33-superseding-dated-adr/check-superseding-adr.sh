#!/usr/bin/env bash
# Dogfood scenario 33 — the superseding dated ADR (v1.23.0 Slice 6, self-dogfood)
# Per spec slice #6 (v1.23.0-dated-artifact-naming) + grill OQ-6.
#
# The decision is recorded as the FIRST dated ADR, proving the convention end-to-
# end on a real decision. It fully supersedes ADR-0020 while explicitly re-stating
# ADR-0020's Changesets-shape version-bump half as still-in-force.
#
# Cases:
#   (a) a dated ADR YYYY-MM-DD-decouple-decision-identity-from-releases.md exists.
#   (b) the new ADR documents the required elements: halt-loud (OQ-1), title+link
#       cross-refs (OQ-2), full-sweep scope (OQ-3), dogfood-28 carve-out, freeze-
#       old/date-new migration, and the in-flight-branch rename step.
#   (c) the new ADR re-states the ADR-0020 Changesets-shape version-bump half as
#       retained / still-in-force.
#   (d) ADR-0020's status is "Superseded by [the dated ADR]" with a forward link,
#       plus a one-line note that its Changesets mechanism continues.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ADRS="$REPO_ROOT/docs/agents/adrs"
NEW_ADR=$(ls "$ADRS"/2026-*-decouple-decision-identity-from-releases.md 2>/dev/null | head -1)
OLD_ADR="$ADRS/0020-late-binding-and-changesets.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# ---------------------------------------------------------------------------
# (a) the dated superseding ADR exists with a dated filename
# ---------------------------------------------------------------------------
[ -n "$NEW_ADR" ] && [ -f "$NEW_ADR" ] \
  || fail "(a) no dated ADR matching 2026-*-decouple-decision-identity-from-releases.md found in $ADRS"
base=$(basename "$NEW_ADR")
echo "$base" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}-decouple-decision-identity-from-releases\.md$' \
  || fail "(a) the ADR filename is not a well-formed YYYY-MM-DD-<slug>.md: $base"
pass "(a) dated superseding ADR exists: $base"

NEW_BODY="$(cat "$NEW_ADR")"

# ---------------------------------------------------------------------------
# (b) required decision elements documented
# ---------------------------------------------------------------------------
echo "$NEW_BODY" | grep -Eiq 'halt[ -]?loud|halts? loud|refuse to write' \
  || fail "(b) new ADR does not document the halt-loud rule (OQ-1)"
echo "$NEW_BODY" | grep -Eiq 'title ?\+ ?(markdown )?link|title and (a )?(markdown )?link' \
  || fail "(b) new ADR does not document the title+link cross-ref convention (OQ-2)"
echo "$NEW_BODY" | grep -Eiq 'full sweep|specs?, plans?|grill-record' \
  || fail "(b) new ADR does not document the full-sweep scope (OQ-3)"
echo "$NEW_BODY" | grep -Eiq 'dogfood.?28|scenario 28|dated-string|carve-out|carveout' \
  || fail "(b) new ADR does not document the dogfood-28 carve-out rationale"
echo "$NEW_BODY" | grep -Eiq 'freeze|frozen|0001-0024' \
  || fail "(b) new ADR does not document the freeze-old/date-new migration"
echo "$NEW_BODY" | grep -Eiq 'in-flight|before merge|rename .* before' \
  || fail "(b) new ADR does not document the in-flight-branch migration step"
pass "(b) new ADR documents halt-loud, title+link, full-sweep, dogfood-28 carve-out, freeze, in-flight migration"

# ---------------------------------------------------------------------------
# (c) Changesets half re-stated as retained / in-force
# ---------------------------------------------------------------------------
echo "$NEW_BODY" | grep -Eiq 'changeset' \
  || fail "(c) new ADR does not mention the Changesets mechanism at all"
echo "$NEW_BODY" | grep -Eiq 'retain|still[ -]?in[ -]?force|continues?|remains?|unchanged|stands|untouched' \
  || fail "(c) new ADR does not re-state the Changesets-shape version-bump half as retained/in-force"
pass "(c) new ADR re-states the Changesets-shape version-bump half as retained/in-force"

# ---------------------------------------------------------------------------
# (d) ADR-0020 status flipped to Superseded with forward link + changesets note
# ---------------------------------------------------------------------------
[ -f "$OLD_ADR" ] || fail "(d) ADR-0020 not found"
OLD_BODY="$(cat "$OLD_ADR")"
echo "$OLD_BODY" | grep -Eiq 'Superseded' \
  || fail "(d) ADR-0020 status is not marked Superseded"
echo "$OLD_BODY" | grep -Eq 'decouple-decision-identity-from-releases\.md' \
  || fail "(d) ADR-0020 has no forward link to the dated superseding ADR"
echo "$OLD_BODY" | grep -Eiq 'changeset.*(continue|retain|in-force|still|unchanged|stands)' \
  || fail "(d) ADR-0020 has no one-line note that its Changesets mechanism continues under the new ADR"
pass "(d) ADR-0020 status = Superseded, forward link present, Changesets-continues note present"

echo
echo "===SCENARIO 33 ALL 4 CASES PASS==="
