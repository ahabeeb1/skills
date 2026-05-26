#!/usr/bin/env bash
# Dogfood scenario 27 — no inline version-archaeology tags in SKILL.md bodies
# Per spec slice #6 (v1.21.0-body-cleanup) + ADR adr-behavioral-only-skill-body § Decision.
#
# Scans every skills/*/SKILL.md body for version-archaeology phrases:
#   - "Added in vN.M" / "Added in vN.M.Z"
#   - "Introduced in vN.M"
#   - "(added vN.M)" / "(added in vN.M)"
#   - "vN.M+" / "vN.M.Z+" candidate/promotion/planning markers
#   - "Phase X.Y (added vN.M)"
#   - "Phase X.Y (added in vN.M)"
#   - Section headings carrying "(vN.M+)" or "(vN.M.Z+)" parentheticals
#   - "Post-vN.M:" prose
#
# CHANGELOG.md is the canonical version log; git history reconstructs introduction
# date for any rule. Bodies don't carry version archaeology.
#
# Frontmatter, HTML-comments, and Pattern-D footer blocks (## See also,
# ## Sources for this section, ## Origins) are excluded.
#
# Test cases:
#   (a) scenario detects "Added in v1.7.0" in fixture
#   (b) scenario detects "Phase 0.5 (added v1.7.0)" in fixture
#   (c) scenario detects "v1.8.0+ candidate" in fixture
#   (d) scenario detects "(v1.20.0+)" parenthetical in a section heading
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

# The version-archaeology pattern union. Matches any of:
#   "Added in v"  /  "Introduced in v"  /  "Phase N.M (added"  /
#   "vN.M+"  /  "(vN.M.Z+)"  /  "Post-vN.M"
#   "pre-vN.M"  /  "pre-vN.M.Z" (v1.22.0 — same shape as Post- and Added in)
#   "Dropped from the pre-vN.M template" / "Dropped in vN.M"  (v1.22.0 —
#       version-transition prose framing migrated cruft from one shape to
#       another; catch the prose form too)
#
# POSIX awk strips backslash-escapes when a regex arrives via -v (string
# context). To match literal `.`, `(`, `+`, `)`, use bracket-character-class
# forms ([.] [(] [+] [)]) which survive both string and regex contexts.
VERSION_PAT='(Added in v[0-9]|Introduced in v[0-9]|Phase [0-9]+[.][0-9]+ [(]added|v[0-9]+[.][0-9]+([.][0-9]+)?[+]|[(]v[0-9]+[.][0-9]+([.][0-9]+)?[+][)]|Post-v[0-9]+[.][0-9]+|pre-v[0-9]+[.][0-9]+|Dropped from|Dropped in v[0-9])'

make_skill_fixture() {
  local dir; dir=$(mktemp -d)
  local body="$1"
  cat > "$dir/SKILL.md" <<EOF
---
name: test-skill
description: Test skill for scenario 27.
---

# Test Skill

$body
EOF
  echo "$dir/SKILL.md"
}

# ---------------------------------------------------------------------------
# Case (a) — "Added in v1.7.0" detected
# ---------------------------------------------------------------------------
F=$(make_skill_fixture "This phase was Added in v1.7.0 and works as follows.")
RESULT=$(scan_for_pattern "$F" "$VERSION_PAT")
[ -n "$RESULT" ] || fail "(a) 'Added in v1.7.0' not detected"
rm -rf "$(dirname "$F")"
pass "(a) 'Added in vN.M.Z' — detected"

# ---------------------------------------------------------------------------
# Case (b) — "Phase 0.5 (added v1.7.0)" detected
# ---------------------------------------------------------------------------
F=$(make_skill_fixture "Phase 0.5 (added v1.7.0) reads the active plan.")
RESULT=$(scan_for_pattern "$F" "$VERSION_PAT")
[ -n "$RESULT" ] || fail "(b) 'Phase 0.5 (added v1.7.0)' not detected"
rm -rf "$(dirname "$F")"
pass "(b) 'Phase X.Y (added vN.M)' — detected"

# ---------------------------------------------------------------------------
# Case (c) — "v1.8.0+ candidate" detected
# ---------------------------------------------------------------------------
F=$(make_skill_fixture "This is a v1.8.0+ candidate; planning is preliminary.")
RESULT=$(scan_for_pattern "$F" "$VERSION_PAT")
[ -n "$RESULT" ] || fail "(c) 'v1.8.0+ candidate' not detected"
rm -rf "$(dirname "$F")"
pass "(c) 'vN.M.Z+' planning marker — detected"

# ---------------------------------------------------------------------------
# Case (d) — section heading with "(v1.20.0+)" parenthetical detected
# ---------------------------------------------------------------------------
F=$(make_skill_fixture $'## Phase 3.25 — Changeset aggregation (v1.20.0+)\n\nDoes the thing.')
RESULT=$(scan_for_pattern "$F" "$VERSION_PAT")
[ -n "$RESULT" ] || fail "(d) '(v1.20.0+)' in section heading not detected"
rm -rf "$(dirname "$F")"
pass "(d) section-heading '(vN.M.Z+)' parenthetical — detected"

# ---------------------------------------------------------------------------
# Case (d2) — "pre-vN.M template" + "Dropped from" version-transition prose
# ---------------------------------------------------------------------------
F=$(make_skill_fixture "Dropped from the pre-v1.22.0 template (do not include): old columns.")
RESULT=$(scan_for_pattern "$F" "$VERSION_PAT")
[ -n "$RESULT" ] || fail "(d2) 'Dropped from the pre-v1.22.0 template' not detected"
rm -rf "$(dirname "$F")"
pass "(d2) 'pre-vN.M' + 'Dropped from' version-transition prose — detected"

# ---------------------------------------------------------------------------
# Case (e) — main repo scan
# ---------------------------------------------------------------------------
HITS=""
for skill in "$REPO_ROOT"/skills/*/SKILL.md; do
  [ -f "$skill" ] || continue
  result=$(scan_for_pattern "$skill" "$VERSION_PAT")
  if [ -n "$result" ]; then
    HITS="${HITS}${result}"$'\n'
  fi
done

if [ -n "$HITS" ]; then
  echo "FAIL: (e) main repo has version-archaeology tags in SKILL.md bodies:" >&2
  echo "$HITS" | head -30 >&2
  total=$(echo "$HITS" | grep -c "^skills" || true)
  echo "Total hits: $total" >&2
  exit 1
fi

pass "(e) main repo SKILL.md bodies — zero version-archaeology tags"

echo
echo "===SCENARIO 27 ALL 5 CASES PASS==="
