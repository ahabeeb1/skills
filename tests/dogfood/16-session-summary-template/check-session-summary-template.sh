#!/usr/bin/env bash
# Dogfood scenario 16 — asserts the session-summary template at
# docs/agents/templates/session-summary-template.md exists and contains
# the 7 required sections per ADR-0012. Run from repo root.
set -euo pipefail

FILE="docs/agents/templates/session-summary-template.md"
FAILED=0

if [[ ! -f "$FILE" ]]; then
  echo "FAIL: $FILE missing"
  exit 1
fi

# 7 required section headers per ADR-0012 § Decision
REQUIRED_SECTIONS=(
  "## 1\. Active artifacts"
  "## 2\. Current slice"
  "## 3\. Last successful action"
  "## 4\. What's blocking"
  "## 5\. Open grill Qs"
  "## 6\. Recent test state"
  "## 7\. Branch / worktree pointer"
)

for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -qE "$section" "$FILE"; then
    echo "FAIL: template missing section: $section"
    FAILED=1
  fi
done

# Tail section must include resume protocol
if ! grep -qE "Fresh sub-session resume protocol" "$FILE"; then
  echo "FAIL: template missing 'Fresh sub-session resume protocol' tail section"
  FAILED=1
fi

# Template must reference ADR-0012
if ! grep -qE "ADR-0012" "$FILE"; then
  echo "FAIL: template does not reference ADR-0012"
  FAILED=1
fi

if [[ $FAILED -eq 0 ]]; then
  echo "PASS: $FILE has all 7 required sections + resume protocol + ADR-0012 reference"
  exit 0
else
  exit 1
fi
