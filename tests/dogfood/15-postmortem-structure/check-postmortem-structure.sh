#!/usr/bin/env bash
# Dogfood scenario 15 — asserts every postmortem under docs/agents/postmortems/
# contains the 8 required sections per ADR-0011. Run from repo root.
set -euo pipefail

DIR="docs/agents/postmortems"
FAILED=0

if [[ ! -d "$DIR" ]]; then
  echo "FAIL: $DIR missing"
  exit 1
fi

# Required section headers (regex-anchored)
REQUIRED_SECTIONS=(
  "## 1\. Summary"
  "## 2\. User prompt"
  "## 3\. Expected outcome"
  "## 4\. Actual outcome"
  "## 5\. Transition-failure matrix"
  "## 6\. Failure category"
  "## 7\. Fix applied"
  "## 8\. v1\."
)

shopt -s nullglob
POSTMORTEMS=("$DIR"/*.md)

if [[ ${#POSTMORTEMS[@]} -eq 0 ]]; then
  echo "FAIL: no files under $DIR"
  exit 1
fi

for file in "${POSTMORTEMS[@]}"; do
  basename="$(basename "$file")"
  # Skip README — it's the template doc, not a postmortem entry
  if [[ "$basename" == "README.md" ]]; then
    continue
  fi

  for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -qE "$section" "$file"; then
      echo "FAIL: $basename missing section: $section"
      FAILED=1
    fi
  done
done

if [[ $FAILED -eq 0 ]]; then
  echo "PASS: all postmortems in $DIR have the 8 required sections"
  exit 0
else
  exit 1
fi
