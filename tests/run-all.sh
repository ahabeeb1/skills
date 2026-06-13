#!/usr/bin/env bash
# habeebs-skill test runner — aggregates every automated assertion suite.
#
# Runs all dogfood check-*.sh + standalone *_test.sh suites, reports per-suite
# pass/fail, and exits nonzero if ANY suite fails. This is the gate the `release`
# skill should run before tagging.
#
# Markdown-only dogfood scenarios (illustrative, run by hand) have no *.sh and are
# skipped automatically. Library files (lib-scan.sh, scenarios.sh) and this runner
# are excluded so we don't execute helpers as if they were suites.
#
# Usage: bash tests/run-all.sh
# Portable to Windows git-bash (the plugin's primary dev environment).

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT" || { echo "cannot cd to repo root" >&2; exit 2; }

PASS=0
FAIL=0
FAILED_SUITES=()

# Collect runnable suites: every check-*.sh and *_test.sh under tests/, plus the
# two non-conforming names in 11-description-budget. Excludes helpers + this file.
mapfile -t SUITES < <(
  {
    find tests -type f -name 'check-*.sh'
    find tests -type f -name '*_test.sh'
    # Non-check-prefixed assertion scripts that are still standalone suites:
    [ -f tests/dogfood/11-description-budget/chain-integrity.sh ] && echo tests/dogfood/11-description-budget/chain-integrity.sh
    [ -f tests/dogfood/11-description-budget/no-next-skills.sh ] && echo tests/dogfood/11-description-budget/no-next-skills.sh
  } | sort -u | grep -vE '(lib-scan|/scenarios|/run-all)\.sh$'
)

if [ "${#SUITES[@]}" -eq 0 ]; then
  echo "No test suites found under tests/." >&2
  exit 2
fi

echo "Running ${#SUITES[@]} test suites..."
echo

for suite in "${SUITES[@]}"; do
  if out=$(bash "$suite" 2>&1); then
    PASS=$((PASS + 1))
    printf '  PASS  %s\n' "$suite"
  else
    FAIL=$((FAIL + 1))
    FAILED_SUITES+=("$suite")
    printf '  FAIL  %s\n' "$suite"
    # Echo the last few lines of the failing suite for triage.
    printf '%s\n' "$out" | tail -5 | sed 's/^/        | /'
  fi
done

echo
echo "================================"
echo "Suites passed: $PASS"
echo "Suites failed: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo
  echo "Failed suites:"
  for s in "${FAILED_SUITES[@]}"; do echo "  - $s"; done
  exit 1
fi
echo "All suites green."
exit 0
