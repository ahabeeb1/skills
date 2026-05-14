#!/usr/bin/env bash
# Dogfood scenario 15 — asserts docs/agents/postmortems/README.md documents
# all 8 required sections + references ADR-0011. Run from repo root.
set -euo pipefail

FILE="docs/agents/postmortems/README.md"
FAILED=0

if [[ ! -f "$FILE" ]]; then
  echo "FAIL: $FILE missing"
  exit 1
fi

# README must document each of the 8 section headers as part of its template guidance
REQUIRED_GUIDANCE=(
  "### 1\. Summary"
  "### 2\. User prompt"
  "### 3\. Expected outcome"
  "### 4\. Actual outcome"
  "### 5\. Transition-failure matrix"
  "### 6\. Failure category"
  "### 7\. Fix applied"
  "### 8\. v1\."
)

for section in "${REQUIRED_GUIDANCE[@]}"; do
  if ! grep -qE "$section" "$FILE"; then
    echo "FAIL: README missing template guidance for section: $section"
    FAILED=1
  fi
done

# README must reference ADR-0011
if ! grep -qE "ADR-0011" "$FILE"; then
  echo "FAIL: README does not reference ADR-0011"
  FAILED=1
fi

if [[ $FAILED -eq 0 ]]; then
  echo "PASS: $FILE documents all 8 required sections and references ADR-0011"
  exit 0
else
  exit 1
fi
