#!/usr/bin/env bash
# Dogfood scenario 45 — the house voice (iron law + plain English + jargon glossed)
# Per the adopt-superpowers-house-voice decision.
#
# Structural guard only. A regex cannot verify that prose READS plainly — that is
# judgment-based, surfaced in chain-postmortems if a run ships a jargon-cliff. What
# this scenario CAN verify mechanically:
#
#   (a) docs/agents/references/skill-voice.md exists, non-empty, and names the four devices
#   (b) every skills/*/SKILL.md opens with one iron law — an all-caps bold imperative
#       line within the first lines of the body
#   (c) the Design template carries the plain-language sections + a GLOSSARY footer
#   (d) every skills/*/SKILL.md carries a Thought->Reality anti-pattern table (device 3)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
VOICE="$REPO_ROOT/docs/agents/references/skill-voice.md"
DESIGN_TMPL="$REPO_ROOT/skills/draft-spec/references/design-template.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# ---------------------------------------------------------------------------
# (a) skill-voice.md exists, non-empty, names the four devices
# ---------------------------------------------------------------------------
[ -s "$VOICE" ] || fail "(a) docs/agents/references/skill-voice.md missing or empty"
grep -qi 'iron law' "$VOICE"            || fail "(a) skill-voice.md does not define the iron-law device"
grep -qiE 'thought.*reality|reality table' "$VOICE" || fail "(a) skill-voice.md does not define the Thought->Reality table device"
grep -qi 'imperative' "$VOICE"          || fail "(a) skill-voice.md does not define the plain-imperative device"
grep -qiE 'gloss|jargon'  "$VOICE"      || fail "(a) skill-voice.md does not define the jargon-gloss device"
pass "(a) skill-voice.md present and names the four devices"

# ---------------------------------------------------------------------------
# (b) every SKILL.md opens with one iron law (all-caps bold imperative line)
#     The body starts after the second '---'. An iron law is a line that is
#     bold-wrapped (**...**) with no lowercase letters between the markers.
# ---------------------------------------------------------------------------
missing=""
for skill_file in "$REPO_ROOT"/skills/*/SKILL.md; do
  name=$(basename "$(dirname "$skill_file")")
  # Body = everything after the closing frontmatter '---'; take the first 15 body lines.
  head_body=$(awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2{print}' "$skill_file" | head -15 || true)
  if ! echo "$head_body" | grep -qE '^\*\*[^a-z]*\*\*$'; then
    missing="${missing} ${name}"
  fi
done
[ -z "$missing" ] || fail "(b) SKILL.md files missing an iron law near the top:${missing}"
pass "(b) every SKILL.md opens with an iron law"

# ---------------------------------------------------------------------------
# (c) Design template carries the plain-language sections + GLOSSARY footer
# ---------------------------------------------------------------------------
[ -f "$DESIGN_TMPL" ] || fail "(c) design-template.md missing"
grep -qi '^## Overview' "$DESIGN_TMPL"            || fail "(c) Design template missing Overview section"
grep -qi '^## Why this approach' "$DESIGN_TMPL"   || fail "(c) Design template missing Why-this-approach section"
grep -qi '^## Decided' "$DESIGN_TMPL"             || fail "(c) Design template missing Decided section"
grep -qiE 'Terms:.*GLOSSARY|GLOSSARY\.md' "$DESIGN_TMPL" || fail "(c) Design template missing GLOSSARY footer"
pass "(c) Design template carries plain-language sections + GLOSSARY footer"

# ---------------------------------------------------------------------------
# (d) every SKILL.md carries a Thought->Reality anti-pattern table (device 3)
#     The standard mandates the anti-pattern list be a 2-column table whose
#     header row is `| Thought | Reality |`. A bulleted anti-pattern list fails.
# ---------------------------------------------------------------------------
no_table=""
for skill_file in "$REPO_ROOT"/skills/*/SKILL.md; do
  name=$(basename "$(dirname "$skill_file")")
  if ! grep -qiE '^\|[[:space:]]*Thought[[:space:]]*\|[[:space:]]*Reality[[:space:]]*\|' "$skill_file"; then
    no_table="${no_table} ${name}"
  fi
done
[ -z "$no_table" ] || fail "(d) SKILL.md files missing a Thought->Reality table:${no_table}"
pass "(d) every SKILL.md carries a Thought->Reality table"

echo
echo "===SCENARIO 45 (skill voice) ALL 4 CASES PASS==="
