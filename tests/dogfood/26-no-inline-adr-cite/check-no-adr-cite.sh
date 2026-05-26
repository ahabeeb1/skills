#!/usr/bin/env bash
# Dogfood scenario 26 — no inline ADR-NNNN citations in SKILL.md bodies
# Per spec slice #6 (v1.21.0-body-cleanup) + ADR adr-behavioral-only-skill-body § Decision.
#
# Scans every skills/*/SKILL.md body for inline `ADR-NNNN` references. The body
# is everything after the second `---` (frontmatter close). HTML-commented
# regions (`<!-- ... -->`) and Pattern-D footer blocks (`## See also`,
# `## Sources for this section:`) are excluded — those are the carve-outs the
# ADR explicitly permits.
#
# Fails loud (exit 1) with a file:line list if any hit is found.
# Passes (exit 0) only on a clean repo state.
#
# Test cases:
#   (a) scenario detects a planted ADR-NNNN cite in a fixture skill body
#   (b) scenario ignores an ADR-NNNN cite inside `<!-- ... -->`
#   (c) scenario ignores an ADR-NNNN cite inside frontmatter
#   (d) scenario ignores an ADR-NNNN cite inside a `## See also` footer block
#   (e) main repo scan — currently expected to FAIL pre-cleanup, PASS post-cleanup

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCAN_LIB="$REPO_ROOT/tests/dogfood/26-no-inline-adr-cite/lib-scan.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# Inline the scan logic. Other scenarios source it from lib-scan.sh; for
# self-contained-test reasons we duplicate the small awk filter rather than
# carrying a shared lib (markdown-only substrate per ADR-0002).
#
# Body extraction: skip lines until the second `---` (frontmatter close).
# HTML-comment exclusion: when inside `<!-- ... -->`, drop the content.
# Footer-block exclusion: when inside a `## See also` or `## Sources for this
# section:` section (until the next `## ` heading or EOF), drop the content.

scan_for_pattern() {
  local file="$1" pattern="$2"
  awk -v pat="$pattern" '
    BEGIN { in_fm=0; fm_seen=0; in_comment=0; in_footer=0 }
    # Frontmatter tracking
    /^---$/ {
      if (fm_seen == 0) { in_fm = 1; fm_seen = 1; next }
      else if (in_fm == 1) { in_fm = 0; next }
    }
    in_fm { next }
    # HTML comment tracking — single-line and multi-line
    {
      line = $0
      # Strip single-line comments first
      gsub(/<!--[^>]*-->/, "", line)
      # Multi-line comment open
      if (in_comment == 0 && match(line, /<!--/)) {
        in_comment = 1
        line = substr(line, 1, RSTART - 1)
      }
      # Multi-line comment close (in same iter as open is single-line, handled above)
      if (in_comment == 1) {
        if (match(line, /-->/)) {
          in_comment = 0
          line = substr(line, RSTART + RLENGTH)
        } else {
          next
        }
      }
    }
    # Footer-block tracking — enter on heading, exit on next ## heading
    /^## (See also|Sources for this section|Origins)/ { in_footer = 1; next }
    /^## / && in_footer == 1 { in_footer = 0 }
    in_footer { next }
    # Pattern match against the cleaned line
    {
      if (match(line, pat)) {
        print FILENAME ":" NR ":" line
      }
    }
  ' "$file"
}

# Fixture helpers
make_skill_fixture() {
  # Creates a temp dir with a fake SKILL.md whose body is the second argument
  local dir; dir=$(mktemp -d)
  local body="$1"
  cat > "$dir/SKILL.md" <<EOF
---
name: test-skill
description: A test skill for dogfood scenario 26.
---

# Test Skill

$body
EOF
  echo "$dir/SKILL.md"
}

# ---------------------------------------------------------------------------
# Case (a) — planted ADR cite in body detected
# ---------------------------------------------------------------------------
PLANTED=$(make_skill_fixture "This rule lives per ADR-0004 Part 2 and must hold.")
RESULT=$(scan_for_pattern "$PLANTED" "ADR-[0-9]{4}")
[ -n "$RESULT" ] || fail "(a) planted ADR-0004 cite not detected in fixture body"
rm -rf "$(dirname "$PLANTED")"
pass "(a) planted ADR-NNNN cite in body — detected"

# ---------------------------------------------------------------------------
# Case (b) — ADR cite inside HTML comment ignored
# ---------------------------------------------------------------------------
COMMENTED=$(make_skill_fixture $'<!-- TODO: revisit per ADR-0004 -->\nClean body content here.')
RESULT=$(scan_for_pattern "$COMMENTED" "ADR-[0-9]{4}")
[ -z "$RESULT" ] || fail "(b) HTML-commented ADR cite was wrongly detected: $RESULT"
rm -rf "$(dirname "$COMMENTED")"
pass "(b) HTML-commented ADR cite — correctly ignored"

# ---------------------------------------------------------------------------
# Case (c) — ADR cite in frontmatter ignored
# ---------------------------------------------------------------------------
FM_DIR=$(mktemp -d)
cat > "$FM_DIR/SKILL.md" <<'EOF'
---
name: test-skill
description: References ADR-0004 in frontmatter only.
---

# Test Skill

Clean body content.
EOF
RESULT=$(scan_for_pattern "$FM_DIR/SKILL.md" "ADR-[0-9]{4}")
[ -z "$RESULT" ] || fail "(c) frontmatter ADR cite was wrongly detected: $RESULT"
rm -rf "$FM_DIR"
pass "(c) frontmatter ADR cite — correctly ignored"

# ---------------------------------------------------------------------------
# Case (d) — ADR cite inside footer block ignored
# ---------------------------------------------------------------------------
FOOTER_DIR=$(mktemp -d)
cat > "$FOOTER_DIR/SKILL.md" <<'EOF'
---
name: test-skill
description: Clean body.
---

# Test Skill

Clean rule statement here.

## See also

- [ADR-0004](../adrs/0004-x.md) — the dispatch contract
EOF
RESULT=$(scan_for_pattern "$FOOTER_DIR/SKILL.md" "ADR-[0-9]{4}")
[ -z "$RESULT" ] || fail "(d) footer-block ADR cite was wrongly detected: $RESULT"
rm -rf "$FOOTER_DIR"
pass "(d) footer-block ADR cite — correctly ignored"

# ---------------------------------------------------------------------------
# Case (e) — main repo scan
# Pre-cleanup: expected to fail loud with ≥1 hit (proves detection works).
# Post-cleanup: expected to pass.
# ---------------------------------------------------------------------------
HITS=""
for skill in "$REPO_ROOT"/skills/*/SKILL.md; do
  [ -f "$skill" ] || continue
  result=$(scan_for_pattern "$skill" "ADR-[0-9]{4}")
  if [ -n "$result" ]; then
    HITS="${HITS}${result}"$'\n'
  fi
done

if [ -n "$HITS" ]; then
  echo "FAIL: (e) main repo has inline ADR-NNNN cites in SKILL.md bodies:" >&2
  echo "$HITS" | head -30 >&2
  total=$(echo "$HITS" | grep -c "^skills" || true)
  echo "Total hits: $total" >&2
  exit 1
fi

pass "(e) main repo SKILL.md bodies — zero inline ADR-NNNN cites"

echo
echo "===SCENARIO 26 ALL 5 CASES PASS==="
