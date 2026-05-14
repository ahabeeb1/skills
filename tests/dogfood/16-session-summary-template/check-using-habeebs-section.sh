#!/usr/bin/env bash
# Dogfood scenario 16 — asserts skills/using-habeebs-skill/SKILL.md contains
# the Compress-at-overflow section per ADR-0012. Run from repo root.
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

# ADR reference
if ! grep -qE "ADR-0012" "$FILE"; then
  echo "FAIL: section does not reference ADR-0012"
  FAILED=1
fi

# Template path reference
if ! grep -qF "docs/agents/templates/session-summary-template.md" "$FILE"; then
  echo "FAIL: section does not reference the template path"
  FAILED=1
fi

# v1.11.0 promotion criterion mentioned
if ! grep -qE "v1\.11\.0 promotion criterion" "$FILE"; then
  echo "FAIL: section missing v1.11.0 promotion criterion"
  FAILED=1
fi

if [[ $FAILED -eq 0 ]]; then
  echo "PASS: $FILE has Compress-at-overflow section + ADR-0012 + template ref + promotion criterion"
  exit 0
else
  exit 1
fi
