#!/usr/bin/env bash
# Dogfood scenario 14 — asserts the SYSTEM_CONTEXT template at
# skills/prior-art-research/references/system-context-template.md
# exposes only the ADR-0010 retained sections as live schema.
set -euo pipefail

FILE="skills/prior-art-research/references/system-context-template.md"
FAILED=0

if [[ ! -f "$FILE" ]]; then
  echo "FAIL: $FILE missing"
  exit 1
fi

# Template MUST document each retained section in its example body (after the schema preamble)
# We grep for the literal section header without anchoring (the template has a "DO NOT persist"
# block that mentions Stack/Persistence/etc. by name as guidance — those mentions are fine).
RETAINED=(
  "## Scale envelope"
  "## Methodology / agent setup"
  "## Notable absences"
  "## Project mode"
  "## Active steering"
  "## Last reconciliation outcome"
)

for section in "${RETAINED[@]}"; do
  if ! grep -qF "$section" "$FILE"; then
    echo "FAIL: template missing retained section: $section"
    FAILED=1
  fi
done

# Template MUST reference ADR-0010 explicitly (signals the prune contract)
if ! grep -qE "ADR-0010" "$FILE"; then
  echo "FAIL: template does not reference ADR-0010"
  FAILED=1
fi

# Template MUST have a DO NOT persist guidance block listing dropped sections
if ! grep -qE "DO NOT persist" "$FILE"; then
  echo "FAIL: template missing 'DO NOT persist' guidance block"
  FAILED=1
fi

if [[ $FAILED -eq 0 ]]; then
  echo "PASS: $FILE template matches ADR-0010 schema"
  exit 0
else
  exit 1
fi
