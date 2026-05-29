#!/usr/bin/env bash
# Dogfood scenario 30 — dated ADR naming at creation (decouple identity from release)
# Per spec slice #1 (v1.23.0-dated-artifact-naming) + the superseding dated ADR
# (docs/agents/adrs/2026-05-29-decouple-decision-identity-from-releases.md, Slice 6).
#
# Verifies the v1.23.0 cutover in skills/decision-record/SKILL.md:
#   (a) decision-record instructs writing YYYY-MM-DD-<slug>.md at creation.
#   (b) decision-record NO LONGER instructs writing adr-<slug>.md or NNNN-<slug>.md
#       as the create-time target (the old late-binding write path is gone).
#   (c) the same-day collision rule is documented: HALT LOUD if the dated filename
#       already exists; demand a more specific slug (no overwrite, no suffix).
#   (d) the title+link cross-reference convention is documented (new ADRs cite each
#       other by title+markdown-link; frozen integer ADRs stay ADR-00NN).
#   (e) collision-contract simulation — a writer that follows the documented
#       halt-loud rule refuses to overwrite an existing YYYY-MM-DD-<slug>.md and
#       leaves it byte-for-byte unchanged.
#
# This scenario is the tracer for the whole v1.23.0 decision. It asserts the
# SKILL.md *instruction text* (the behavioral contract decision-record carries)
# plus a mechanical proof that the documented halt-loud rule is sound.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
DR_SKILL="$REPO_ROOT/skills/decision-record/SKILL.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# Body extractor — everything after the second `---` (frontmatter close),
# with HTML-commented and `## See also`/`## Origins` footer regions dropped.
# Matches the body-scan idiom used by scenarios 26/27/28 so an instruction in a
# footer or comment never satisfies a body-text assertion.
skill_body() {
  awk '
    BEGIN { in_fm=0; fm_seen=0; in_comment=0; in_footer=0 }
    /^---$/ {
      if (fm_seen == 0) { in_fm = 1; fm_seen = 1; next }
      else if (in_fm == 1) { in_fm = 0; next }
    }
    in_fm { next }
    {
      line = $0
      gsub(/<!--[^>]*-->/, "", line)
      if (in_comment == 0 && match(line, /<!--/)) {
        in_comment = 1
        line = substr(line, 1, RSTART - 1)
      }
      if (in_comment == 1) {
        if (match(line, /-->/)) { in_comment = 0; line = substr(line, RSTART + RLENGTH) }
        else { next }
      }
    }
    /^## (See also|Sources for this section|Origins)/ { in_footer = 1; next }
    /^## / && in_footer == 1 { in_footer = 0 }
    in_footer { next }
    { print line }
  ' "$1"
}

[ -f "$DR_SKILL" ] || fail "decision-record SKILL.md not found at $DR_SKILL"
BODY="$(skill_body "$DR_SKILL")"

# ---------------------------------------------------------------------------
# Case (a) — dated write target instructed at creation
# ---------------------------------------------------------------------------
echo "$BODY" | grep -Eq 'YYYY-MM-DD-<slug>\.md' \
  || fail "(a) decision-record body does not instruct the dated 'YYYY-MM-DD-<slug>.md' write target"
# It must tie the dated name to creation time, not a later rename step.
echo "$BODY" | grep -Eiq 'at creation|creation time|when (it )?writes|write[ -]?time' \
  || fail "(a) decision-record does not state the dated name is written AT CREATION"
pass "(a) dated 'YYYY-MM-DD-<slug>.md' write target instructed at creation"

# ---------------------------------------------------------------------------
# Case (b) — old late-binding write targets are gone
# A SKILL that still instructs writing 'adr-<slug>.md' or 'NNNN-<slug>.md' as
# the create-time target contradicts the new convention. We allow the literal
# string to survive ONLY inside an explicit "no longer / not / never" negation
# (e.g. "do NOT write adr-<slug>.md"), so the regression guard targets
# instruction-to-write, not mere mention.
OFFENDERS="$(echo "$BODY" | grep -En 'adr-<slug>\.md|NNNN-<slug>\.md|adr-<kebab' || true)"
if [ -n "$OFFENDERS" ]; then
  BAD=""
  while IFS= read -r ln; do
    [ -z "$ln" ] && continue
    # Negated mentions are fine (documenting what NOT to do); flag the rest.
    echo "$ln" | grep -Eiq '\bno longer\b|\bnot\b|\bnever\b|\bdo not\b|\bdon.t\b|\binstead of\b|\bno (integer|number)\b|\bwas\b|\bused to\b|\bpreviously\b|\bold\b|\bdeprecated\b|\bsuperseded\b' \
      || BAD="${BAD}${ln}"$'\n'
  done <<< "$OFFENDERS"
  if [ -n "$BAD" ]; then
    echo "FAIL: (b) decision-record still instructs an old late-binding write target:" >&2
    echo "$BAD" >&2
    exit 1
  fi
fi
pass "(b) no live 'adr-<slug>.md' / 'NNNN-<slug>.md' create-time write target remains"

# ---------------------------------------------------------------------------
# Case (c) — halt-loud same-day collision rule documented
# ---------------------------------------------------------------------------
echo "$BODY" | grep -Eiq 'halt|refuse|stop|do not (over)?write|abort' \
  || fail "(c) decision-record does not document a halt/refuse on filename collision"
echo "$BODY" | grep -Eiq 'already exist' \
  || fail "(c) decision-record does not describe the 'filename already exists' collision trigger"
echo "$BODY" | grep -Eiq 'more specific slug|specific(er)? slug|better slug|distinct slug|rename .* slug' \
  || fail "(c) decision-record does not instruct demanding a more specific slug on collision"
# No silent disambiguation by counter/suffix.
echo "$BODY" | grep -Eiq 'no suffix|without a suffix|no counter|not a counter|no -2|no .-N. suffix' \
  || fail "(c) decision-record does not rule out a silent numeric suffix on collision"
pass "(c) halt-loud-on-duplicate-slug rule documented (no overwrite, no suffix)"

# ---------------------------------------------------------------------------
# Case (d) — title+link cross-reference convention documented
# ---------------------------------------------------------------------------
echo "$BODY" | grep -Eiq 'title ?\+ ?(markdown )?link|title and (a )?(markdown )?link|markdown link' \
  || fail "(d) decision-record does not document the title+link cross-ref convention for new ADRs"
echo "$BODY" | grep -Eq 'ADR-00NN|ADR-0[0-9]{3}|frozen integer' \
  || fail "(d) decision-record does not state frozen integer ADRs are still cited as ADR-00NN"
pass "(d) title+link cross-ref convention documented (frozen ADRs stay ADR-00NN)"

# ---------------------------------------------------------------------------
# Case (e) — collision-contract simulation: halt-loud writer never overwrites
# A reference implementation of the documented rule. Proves the contract is
# mechanically sound: writing YYYY-MM-DD-<slug>.md when it already exists must
# refuse (non-zero) and leave the existing file untouched.
# ---------------------------------------------------------------------------
dated_write() {
  # $1 = adrs dir, $2 = dated filename, $3 = content
  local dir="$1" name="$2" content="$3" target="$1/$2"
  if [ -e "$target" ]; then
    echo "HALT — \`$name\` already exists. The slug is too vague; choose a more specific slug. No overwrite, no suffix." >&2
    return 3
  fi
  printf '%s' "$content" > "$target"
}

SIM_DIR=$(mktemp -d)
mkdir "$SIM_DIR/adrs"
DATED="2026-05-29-decouple-decision-identity-from-releases.md"
# First write succeeds.
dated_write "$SIM_DIR/adrs" "$DATED" "ORIGINAL" || fail "(e) first dated write should succeed"
[ -f "$SIM_DIR/adrs/$DATED" ] || fail "(e) first dated write did not create the file"
ORIG_SUM=$(cksum "$SIM_DIR/adrs/$DATED")
# Second write with the SAME date+slug must halt loud and NOT overwrite.
set +e
OUT=$(dated_write "$SIM_DIR/adrs" "$DATED" "CLOBBER" 2>&1)
EC=$?
set -e
[ "$EC" -ne 0 ] || fail "(e) same-day-same-slug second write should halt non-zero, got exit 0"
echo "$OUT" | grep -Eiq 'already exists' || fail "(e) collision message missing 'already exists'. Got: $OUT"
echo "$OUT" | grep -Eiq 'more specific slug' || fail "(e) collision message missing 'more specific slug'. Got: $OUT"
NEW_SUM=$(cksum "$SIM_DIR/adrs/$DATED")
[ "$ORIG_SUM" = "$NEW_SUM" ] || fail "(e) existing dated file was modified despite halt (overwrite occurred)"
[ "$(cat "$SIM_DIR/adrs/$DATED")" = "ORIGINAL" ] || fail "(e) existing dated file content changed despite halt"
rm -rf "$SIM_DIR"
pass "(e) halt-loud writer refuses to overwrite an existing dated ADR; file untouched"

echo
echo "===SCENARIO 30 ALL 5 CASES PASS==="
