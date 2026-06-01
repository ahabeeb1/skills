#!/usr/bin/env bash
# Dogfood scenario 34 — no self-referential migration archaeology in SKILL.md bodies
# Per spec slice #1 (v1.24.0 chain-fidelity-hardening) + the chain-fidelity
# executable-assertions decision § SP2.
#
# Scans every skills/*/SKILL.md body for SELF-REFERENTIAL archaeology — prose that
# narrates the methodology's OWN past evolution, e.g.:
#   - "this skill used to <verb>"        (the skill narrating its own past behavior)
#   - "previously this/we <verb>"
#   - "was renamed"
#   - "replaces the old <X>"
#   - "(in|set in) vN this changed"      (version-pegged self-history)
#   - "formerly"
#   - "no release step <verb>s it"       (narrating removed release machinery)
#   - "<X> are NOT renamed"              (freeze-old migration narration)
#
# The discriminator is the SENTENCE SUBJECT, not the verb phrase. A grill-time
# corpus measurement proved the naive phrase set (bare "no longer" / "used to")
# scored 4 hits across the live bodies, ALL false positives — legitimate
# present-tense prose like "a test that used to pass now fails". Real archaeology
# narrates the skill's own evolution; a false positive describes a domain scenario
# in present tense. So the regex requires a self/skill subject and does NOT match
# bare "no longer" / "used to".
#
# A behavioral skill body describes the PRESENT, never the diff from the past.
# Version history lives in CHANGELOG.md; introduction history in git blame + tags;
# incidents in docs/agents/postmortems/.
#
# Frontmatter, HTML-comments, footer sections (## See also / ## Sources / ## Origins),
# and code fences are excluded — same scope discipline as scenario 28.
#
# Test cases:
#   (a) "this skill used to write adr-<slug>.md" detected (session's actual offender)
#   (b) "Existing X are NOT renamed (freeze-old)" detected (session's actual offender)
#   (c) "no release step renames it" detected (session's actual offender)
#   (d) "was renamed" / "formerly" / "replaces the old" / "set in vN this changed" detected
#   (e) FALSE-POSITIVE GUARD: the 4 measured present-tense shapes NOT detected
#         ("Deprecated — no longer current", "a test that used to pass now fails",
#          "no longer maps to reality", "a path that no longer exists")
#   (f) frontmatter / HTML-comment / footer / code-fence regions NOT scanned
#   (g) failure-message guidance distinguishes self-archaeology (banned) from
#       present-tense domain prose (allowed)
#   (z) main repo scan — corpus is clean post-v1.23.0, MUST PASS

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
      if (match(tolower(line), pat)) {
        print FILENAME ":" NR ":" line
      }
    }
  ' "$file"
}

# ---------------------------------------------------------------------------
# Self-referential archaeology pattern (matched against tolower(line); subject-aware).
# Each alternative requires a self/skill/artifact subject so it cannot match the
# present-tense domain prose the grill measured as false positives. Notably it
# does NOT contain bare "no longer" or bare "used to" — only "used to" bound to a
# self subject ("this skill used to", "previously (this|we) ... used to").
# ---------------------------------------------------------------------------
ARCH_PAT='(this skill used to|previously (this|we)|was renamed|replaces the old|formerly|no release step [a-z]+s it|are not renamed|(in|set in) v[0-9]+([.][0-9]+)* this changed)'

ARCH_GUIDANCE='Self-referential migration archaeology is banned in SKILL.md PROSE BODIES — sentences narrating the methodology'\''s OWN past ("this skill used to X", "X are NOT renamed", "no release step renames it", "was renamed", "formerly", "replaces the old Y"). A behavioral body describes the PRESENT. This is NOT a ban on present-tense domain prose that happens to contain "no longer"/"used to" (e.g. "a test that used to pass now fails" is allowed — it describes a current scenario, not the skill'\''s history). Fix: restate the rule in present tense; version history belongs in CHANGELOG.md, introduction history in git blame + tags, incidents in docs/agents/postmortems/.'

make_skill_fixture() {
  local dir; dir=$(mktemp -d)
  local body="$1"
  cat > "$dir/SKILL.md" <<EOF
---
name: test-skill
description: Test skill for scenario 34.
---

# Test Skill

$body
EOF
  echo "$dir/SKILL.md"
}

# ---------------------------------------------------------------------------
# Case (a) — "this skill used to write adr-<slug>.md" detected (real offender)
# ---------------------------------------------------------------------------
F=$(make_skill_fixture "Phase 2 writes the dated filename. This skill used to write adr-<slug>.md placeholders.")
RESULT=$(scan_for_pattern "$F" "$ARCH_PAT")
[ -n "$RESULT" ] || fail "(a) 'this skill used to write adr-<slug>.md' not detected"
rm -rf "$(dirname "$F")"
pass "(a) 'this skill used to <verb>' — detected"

# ---------------------------------------------------------------------------
# Case (b) — "Existing X are NOT renamed (freeze-old)" detected (real offender)
# ---------------------------------------------------------------------------
F=$(make_skill_fixture "Existing integer ADRs are NOT renamed (freeze-old); only new ones are dated.")
RESULT=$(scan_for_pattern "$F" "$ARCH_PAT")
[ -n "$RESULT" ] || fail "(b) 'X are NOT renamed' not detected"
rm -rf "$(dirname "$F")"
pass "(b) '<X> are NOT renamed' — detected"

# ---------------------------------------------------------------------------
# Case (c) — "no release step renames it" detected (real offender)
# ---------------------------------------------------------------------------
F=$(make_skill_fixture "The slug is the uniqueness key; no release step renames it later.")
RESULT=$(scan_for_pattern "$F" "$ARCH_PAT")
[ -n "$RESULT" ] || fail "(c) 'no release step renames it' not detected"
rm -rf "$(dirname "$F")"
pass "(c) 'no release step <verb>s it' — detected"

# ---------------------------------------------------------------------------
# Case (d) — other self-archaeology shapes detected
# ---------------------------------------------------------------------------
for probe in \
  "The directory was renamed during the cleanup pass." \
  "Formerly this lived in docs/agents/templates/." \
  "This skill replaces the old assign-adr-ids machinery." \
  "Set in v1.20.0 this changed to late-binding identifiers."; do
  F=$(make_skill_fixture "$probe")
  RESULT=$(scan_for_pattern "$F" "$ARCH_PAT")
  [ -n "$RESULT" ] || fail "(d) self-archaeology shape not detected: '$probe'"
  rm -rf "$(dirname "$F")"
done
pass "(d) was-renamed / formerly / replaces-the-old / set-in-vN — detected"

# ---------------------------------------------------------------------------
# Case (e) — FALSE-POSITIVE GUARD: the 4 measured present-tense shapes NOT detected
# ---------------------------------------------------------------------------
for clean in \
  "Deprecated — no longer current but kept for historical context." \
  "A test that used to pass now fails (regression)." \
  "The current draft-spec or grill record no longer maps to reality." \
  "The error message names a path that no longer exists, so grepping finds nothing."; do
  F=$(make_skill_fixture "$clean")
  RESULT=$(scan_for_pattern "$F" "$ARCH_PAT")
  [ -z "$RESULT" ] || fail "(e) present-tense prose wrongly flagged: '$clean' → $RESULT"
  rm -rf "$(dirname "$F")"
done
pass "(e) 4 measured present-tense shapes — correctly NOT flagged"

# ---------------------------------------------------------------------------
# Case (f) — frontmatter / HTML-comment / footer / code-fence NOT scanned
# ---------------------------------------------------------------------------
SCOPE_DIR=$(mktemp -d)
cat > "$SCOPE_DIR/SKILL.md" <<'EOF'
---
name: test-skill
description: This skill used to be called something else — frontmatter is exempt.
---

# Test Skill

Present-tense body, clean.

<!-- This skill used to write adr-<slug>.md — HTML comment is exempt. -->

```
# code fence: this skill used to do X — exempt
```

## See also

- previously this pointed elsewhere — footer is exempt
EOF
RESULT=$(scan_for_pattern "$SCOPE_DIR/SKILL.md" "$ARCH_PAT")
[ -z "$RESULT" ] || fail "(f) excluded region wrongly scanned: $RESULT"
rm -rf "$SCOPE_DIR"
pass "(f) frontmatter / HTML-comment / footer / code-fence — correctly excluded"

# ---------------------------------------------------------------------------
# Case (g) — failure-message guidance carries both halves of the distinction
# ---------------------------------------------------------------------------
case "$ARCH_GUIDANCE" in
  *"narrating the methodology"*) ;;
  *) fail "(g) guidance does not name the self-referential (banned) shape" ;;
esac
case "$ARCH_GUIDANCE" in
  *"present-tense domain prose"*|*"present-tense"*) ;;
  *) fail "(g) guidance does not name the present-tense (allowed) shape" ;;
esac
pass "(g) failure-message guidance distinguishes banned self-archaeology from allowed present-tense prose"

# ---------------------------------------------------------------------------
# Case (z) — main repo scan: corpus is clean post-v1.23.0, MUST PASS
# ---------------------------------------------------------------------------
HITS=""
for skill in "$REPO_ROOT"/skills/*/SKILL.md; do
  [ -f "$skill" ] || continue
  result=$(scan_for_pattern "$skill" "$ARCH_PAT")
  if [ -n "$result" ]; then
    HITS="${HITS}${result}"$'\n'
  fi
done

if [ -n "$HITS" ]; then
  echo "FAIL: (z) main repo has self-referential archaeology in SKILL.md PROSE BODIES:" >&2
  echo "$HITS" | head -30 >&2
  total=$(echo "$HITS" | grep -c "^" || true)
  echo "Total hits: $total" >&2
  echo >&2
  echo "$ARCH_GUIDANCE" >&2
  exit 1
fi

pass "(z) main repo SKILL.md bodies — zero self-referential archaeology"

echo
echo "===SCENARIO 34 ALL 7 CASES PASS==="
