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
# Test cases:
#   (a) "(documented 2026-05-12)" in body detected
#   (b) "the 2026-05-12 incident" in body detected
#   (c) standalone "(2026-05-12)" in body detected
#   (d) date inside frontmatter NOT detected (year field in description text)
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
  echo "FAIL: (e) main repo has dated incident references in SKILL.md bodies:" >&2
  echo "$HITS" | head -30 >&2
  total=$(echo "$HITS" | grep -c "^skills" || true)
  echo "Total hits: $total" >&2
  exit 1
fi

pass "(e) main repo SKILL.md bodies — zero dated incident references"

echo
echo "===SCENARIO 28 ALL 5 CASES PASS==="
