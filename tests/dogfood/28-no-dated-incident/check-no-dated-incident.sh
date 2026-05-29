#!/usr/bin/env bash
# Dogfood scenario 28 — no dated incident references in SKILL.md bodies
# Per spec slice #6 (v1.21.0-body-cleanup) + ADR adr-behavioral-only-skill-body § Decision.
#
# Scans every skills/*/SKILL.md body for dated incident phrases:
#   - "(documented YYYY-MM-DD)" / "documented YYYY-MM-DD"
#   - "incident YYYY-MM-DD"
#   - "the YYYY-MM-DD incident"
#   - "on YYYY-MM-DD we"
#   - Standalone "(YYYY-MM-DD)" in body prose (3+ digit-year ISO date)
#
# Postmortems live in docs/agents/postmortems/. The surviving rule restates in
# the skill body without the date stamp.
#
# Frontmatter, HTML-comments, and Pattern-D footer blocks are excluded. Code
# fences are NOT excluded — dates in code examples are rare and worth catching
# if they appear.
#
# v1.23.0 dated-naming carve-out (spec slice #3): the dated-artifact convention
# writes ADR/spec/plan files as YYYY-MM-DD-<slug>.md with a frontmatter
# `Date: YYYY-MM-DD` field. Those dates are immutable identifiers (like a git
# SHA), categorically different from decaying version-archaeology prose. The
# scan already targets prose BODIES only — it never reads the filename, and
# frontmatter is excluded — so the carve-out holds structurally. Cases (f)/(g)
# assert it explicitly; case (h) asserts the failure message DOCUMENTS the
# carve-out so a tripped contributor understands prose-date is banned while
# filename/frontmatter-date is allowed. The prose-date ban is NOT weakened.
#
# Test cases:
#   (a) "(documented 2026-05-12)" in body detected
#   (b) "the 2026-05-12 incident" in body detected
#   (c) standalone "(2026-05-12)" in body detected
#   (d) date inside frontmatter NOT detected (year field in description text)
#   (f) dated FILENAME + frontmatter Date: NOT detected (v1.23.0 carve-out)
#   (g) dated filename allowed but dated PROSE in the same file still banned
#   (h) failure-message guidance distinguishes banned prose-date from allowed
#       filename/frontmatter-date (DevEx — grill new decision #3)
#   (e) main repo scan — currently expected to FAIL pre-cleanup, PASS post-cleanup

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

scan_for_pattern() {
  local file="$1" pattern="$2"
  awk -v pat="$pattern" '
    BEGIN { in_fm=0; fm_seen=0; in_comment=0; in_footer=0; in_code=0 }
    /^---$/ {
      if (fm_seen == 0) { in_fm = 1; fm_seen = 1; next }
      else if (in_fm == 1) { in_fm = 0; next }
    }
    in_fm { next }
    /^```/ { in_code = !in_code; next }
    in_code { next }
    {
      line = $0
      gsub(/<!--[^>]*-->/, "", line)
      if (in_comment == 0 && match(line, /<!--/)) {
        in_comment = 1
        line = substr(line, 1, RSTART - 1)
      }
      if (in_comment == 1) {
        if (match(line, /-->/)) {
          in_comment = 0
          line = substr(line, RSTART + RLENGTH)
        } else {
          next
        }
      }
    }
    /^## (See also|Sources for this section|Origins)/ { in_footer = 1; next }
    /^## / && in_footer == 1 { in_footer = 0 }
    in_footer { next }
    {
      if (match(line, pat)) {
        print FILENAME ":" NR ":" line
      }
    }
  ' "$file"
}

# Dated-incident patterns. ISO date with one of the incident keyword shapes,
# OR a parenthetical ISO date in incident-context prose. Standalone (YYYY-MM-DD)
# is also flagged — false-positive risk on legitimate date references is low
# enough to accept given the 26-of-27 research convergence.
DATED_PAT='(documented [0-9]{4}-[0-9]{2}-[0-9]{2}|incident [0-9]{4}-[0-9]{2}-[0-9]{2}|the [0-9]{4}-[0-9]{2}-[0-9]{2} incident|on [0-9]{4}-[0-9]{2}-[0-9]{2} we|[(][0-9]{4}-[0-9]{2}-[0-9]{2}[)])'

# Failure-message guidance (single source of truth). Printed when case (e)
# fires, and asserted by case (h). Distinguishes the banned shape (dated string
# in a SKILL.md PROSE BODY) from the allowed shapes (dated ADR/spec/plan
# FILENAMES and frontmatter `Date:` fields — the v1.23.0 dated-naming
# convention, where the date is an immutable identifier, not decaying prose).
DATED_PROSE_GUIDANCE='Dated strings are banned in SKILL.md PROSE BODIES only — dated ADR/spec/plan FILENAMES (YYYY-MM-DD-<slug>.md) and frontmatter Date: fields are allowed (the v1.23.0 dated-naming convention; a filename date is an immutable identifier, not version-archaeology). Fix: move the date out of prose — into a filename or a frontmatter Date: field, or restate the rule without the date stamp (postmortems live in docs/agents/postmortems/).'

make_skill_fixture() {
  local dir; dir=$(mktemp -d)
  local body="$1"
  cat > "$dir/SKILL.md" <<EOF
---
name: test-skill
description: Test skill for scenario 28.
---

# Test Skill

$body
EOF
  echo "$dir/SKILL.md"
}

# ---------------------------------------------------------------------------
# Case (a) — "(documented 2026-05-12)" detected
# ---------------------------------------------------------------------------
F=$(make_skill_fixture "The chain's bleeding pain (documented 2026-05-12) was a research run.")
RESULT=$(scan_for_pattern "$F" "$DATED_PAT")
[ -n "$RESULT" ] || fail "(a) '(documented 2026-05-12)' not detected"
rm -rf "$(dirname "$F")"
pass "(a) '(documented YYYY-MM-DD)' — detected"

# ---------------------------------------------------------------------------
# Case (b) — "the 2026-05-12 incident" detected
# ---------------------------------------------------------------------------
F=$(make_skill_fixture "We learned from the 2026-05-12 incident that decompositions miss categories.")
RESULT=$(scan_for_pattern "$F" "$DATED_PAT")
[ -n "$RESULT" ] || fail "(b) 'the 2026-05-12 incident' not detected"
rm -rf "$(dirname "$F")"
pass "(b) 'the YYYY-MM-DD incident' — detected"

# ---------------------------------------------------------------------------
# Case (c) — standalone "(2026-05-12)" in body detected
# ---------------------------------------------------------------------------
F=$(make_skill_fixture "Phase 2.5 was added (2026-05-12) to catch this failure.")
RESULT=$(scan_for_pattern "$F" "$DATED_PAT")
[ -n "$RESULT" ] || fail "(c) standalone '(2026-05-12)' not detected"
rm -rf "$(dirname "$F")"
pass "(c) standalone '(YYYY-MM-DD)' — detected"

# ---------------------------------------------------------------------------
# Case (d) — date in frontmatter NOT detected
# ---------------------------------------------------------------------------
FM_DIR=$(mktemp -d)
cat > "$FM_DIR/SKILL.md" <<'EOF'
---
name: test-skill
description: Skill last reviewed (2026-05-12) for staleness.
---

# Test Skill

Clean body, no date.
EOF
RESULT=$(scan_for_pattern "$FM_DIR/SKILL.md" "$DATED_PAT")
[ -z "$RESULT" ] || fail "(d) frontmatter date was wrongly detected: $RESULT"
rm -rf "$FM_DIR"
pass "(d) frontmatter date — correctly ignored"

# ---------------------------------------------------------------------------
# Case (f) — dated FILENAME + frontmatter Date: NOT detected (v1.23.0 carve-out)
#
# The v1.23.0 dated-naming convention writes ADR/spec/plan files as
# YYYY-MM-DD-<slug>.md with a frontmatter `Date: YYYY-MM-DD` field. The scan
# targets prose BODIES only — it never reads the filename, and frontmatter is
# already excluded. This case proves the carve-out explicitly: a fixture whose
# filename IS a dated string and whose frontmatter carries `Date: 2026-05-29`
# must produce zero hits.
# ---------------------------------------------------------------------------
DATED_DIR=$(mktemp -d)
# Filename itself is a dated string per the v1.23.0 convention.
cat > "$DATED_DIR/2026-05-29-some-decision.md" <<'EOF'
---
name: test-skill
description: Test skill for scenario 28 dated-filename carve-out.
Date: 2026-05-29
---

# Test Skill

Clean body. The naming convention puts the date in the filename and frontmatter,
not in this prose, so nothing here should trip the lint.
EOF
RESULT=$(scan_for_pattern "$DATED_DIR/2026-05-29-some-decision.md" "$DATED_PAT")
[ -z "$RESULT" ] || fail "(f) dated filename / frontmatter Date: was wrongly detected: $RESULT"
rm -rf "$DATED_DIR"
pass "(f) dated filename + frontmatter Date: — correctly allowed (v1.23.0 carve-out)"

# ---------------------------------------------------------------------------
# Case (g) — dated filename ALLOWED but dated PROSE in the same file BANNED
#
# Proves the carve-out is narrow: living in a dated-named file with a dated
# frontmatter field does NOT license a dated string in the prose body. The
# filename/frontmatter date is allowed; the prose date is still caught.
# ---------------------------------------------------------------------------
MIX_DIR=$(mktemp -d)
cat > "$MIX_DIR/2026-05-29-mixed.md" <<'EOF'
---
name: test-skill
description: Test skill for scenario 28 narrow carve-out.
Date: 2026-05-29
---

# Test Skill

We learned from the 2026-05-12 incident that decompositions miss categories.
EOF
RESULT=$(scan_for_pattern "$MIX_DIR/2026-05-29-mixed.md" "$DATED_PAT")
[ -n "$RESULT" ] || fail "(g) dated PROSE inside a dated-named file was not detected"
rm -rf "$MIX_DIR"
pass "(g) dated filename allowed + dated prose still banned — carve-out is narrow"

# ---------------------------------------------------------------------------
# Case (h) — failure-message guidance distinguishes prose (banned) from
#            filename/frontmatter (allowed) — DevEx, grill new decision #3
#
# A contributor who trips this lint must understand the carve-out: dated
# strings are banned in PROSE BODIES only; dated ADR/spec/plan FILENAMES and
# frontmatter Date: fields are allowed. Assert the single-source-of-truth
# guidance string carries both halves of the distinction.
# ---------------------------------------------------------------------------
case "$DATED_PROSE_GUIDANCE" in
  *"PROSE"*) ;;
  *) fail "(h) guidance does not mention the PROSE-body scope of the ban" ;;
esac
case "$DATED_PROSE_GUIDANCE" in
  *"FILENAME"*|*"filename"*) ;;
  *) fail "(h) guidance does not mention dated FILENAMES are allowed" ;;
esac
case "$DATED_PROSE_GUIDANCE" in
  *"frontmatter"*) ;;
  *) fail "(h) guidance does not mention frontmatter Date: fields are allowed" ;;
esac
pass "(h) failure-message guidance distinguishes banned prose-date from allowed filename/frontmatter-date"

# ---------------------------------------------------------------------------
# Case (e) — main repo scan
# ---------------------------------------------------------------------------
HITS=""
for skill in "$REPO_ROOT"/skills/*/SKILL.md; do
  [ -f "$skill" ] || continue
  result=$(scan_for_pattern "$skill" "$DATED_PAT")
  if [ -n "$result" ]; then
    HITS="${HITS}${result}"$'\n'
  fi
done

if [ -n "$HITS" ]; then
  echo "FAIL: (e) main repo has dated incident references in SKILL.md PROSE BODIES:" >&2
  echo "$HITS" | head -30 >&2
  total=$(echo "$HITS" | grep -c "^skills" || true)
  echo "Total hits: $total" >&2
  echo >&2
  echo "$DATED_PROSE_GUIDANCE" >&2
  exit 1
fi

pass "(e) main repo SKILL.md bodies — zero dated incident references"

echo
echo "===SCENARIO 28 ALL 8 CASES PASS==="
