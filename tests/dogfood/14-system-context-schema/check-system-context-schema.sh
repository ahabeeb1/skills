#!/usr/bin/env bash
# Dogfood scenario 14 — asserts docs/agents/SYSTEM_CONTEXT.md matches the
# ADR-0010 contents-prune schema. Run from repo root.
set -euo pipefail

FILE="docs/agents/SYSTEM_CONTEXT.md"
FAILED=0

if [[ ! -f "$FILE" ]]; then
  echo "FAIL: $FILE missing"
  exit 1
fi

# Retained sections (per ADR-0010 § Decision) — MUST be present as top-level headers
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
    echo "FAIL: required section missing: $section"
    FAILED=1
  fi
done

# Dropped sections (per ADR-0010 § Decision) — MUST NOT be present as top-level headers
# Anchored to "^## " to avoid matching mentions in prose
DROPPED=(
  "^## Stack$"
  "^## Persistence$"
  "^## Deployment shape$"
  "^## External services$"
  "^## Recent hot files$"
  "^## Open / unknown$"
)

for section in "${DROPPED[@]}"; do
  if grep -qE "$section" "$FILE"; then
    echo "FAIL: dropped section still present: $section"
    FAILED=1
  fi
done

# Schema marker — header area should reference ADR-0010
if ! head -20 "$FILE" | grep -qE "ADR-0010|per ADR-0010"; then
  echo "WARN: header does not reference ADR-0010 schema (advisory; not failing)"
fi

# Tracked manifests block should be removed (was scaffolding for the prior contract)
if grep -qE "^\*\*Tracked manifests:" "$FILE"; then
  echo "FAIL: Tracked manifests block still present (dropped per ADR-0010)"
  FAILED=1
fi

if [[ $FAILED -eq 0 ]]; then
  echo "PASS: $FILE matches ADR-0010 contents-prune schema"
  exit 0
else
  exit 1
fi
