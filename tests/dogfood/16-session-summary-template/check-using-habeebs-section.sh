#!/usr/bin/env bash
# Dogfood scenario 16 — asserts skills/using-habeebs-skill/SKILL.md contains
# the Compress-at-overflow (summary-and-flush) section and points at the template.
# Run from repo root.
#
# NOTE: this check used to require an inline "ADR-0012" cite and a "v1.11.0
# promotion criterion" in the section. Both were removed when ADR-0022 made skill
# bodies behavioral-only (scenario 26 forbids inline ADR cites; scenarios 27/28
# forbid version/dated archaeology in bodies). The check now asserts the
# behavioral content that policy DOES permit.
set -euo pipefail

FILE="skills/using-habeebs-skill/SKILL.md"
FAILED=0

if [[ ! -f "$FILE" ]]; then
  echo "FAIL: $FILE missing"
  exit 1
fi

# Section heading
if ! grep -qE "## When sessions grow long" "$FILE"; then
  echo "FAIL: missing '## When sessions grow long' section"
  FAILED=1
fi

# Describes the summary-and-flush protocol (the behavioral content)
if ! grep -qiE "summary-and-flush|Compress-at-overflow" "$FILE"; then
  echo "FAIL: section does not describe the summary-and-flush / Compress-at-overflow protocol"
  FAILED=1
fi

# Template path reference
if ! grep -qF "references/session-summary-template.md" "$FILE"; then
  echo "FAIL: section does not reference the template path"
  FAILED=1
fi

if [[ $FAILED -eq 0 ]]; then
  echo "PASS: $FILE has the Compress-at-overflow section (summary-and-flush + template ref)"
  exit 0
else
  exit 1
fi
