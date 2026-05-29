#!/usr/bin/env bash
# Dogfood scenario 21b — late-binding ADR-ID rename machinery removed
# Per spec slice #2 (v1.23.0-dated-artifact-naming).
#
# v1.23.0 makes ADRs dated-at-creation (decision-record writes
# YYYY-MM-DD-<slug>.md directly — landed in slice #1). The release-time
# late-binding rename step (mechanism #1 of the old two-mechanism design) is
# therefore dead. This scenario asserts the teardown is complete AND that the
# INDEPENDENT Changesets machinery (mechanism #2 — shares only the release
# skill as coordinator, no code/state) is untouched.
#
# Test cases:
#   (a) skills/release/scripts/assign-adr-ids.sh does NOT exist
#   (b) skills/release/SKILL.md carries no `Phase 3.5` / `assign-adr-ids` /
#       `late-binding` reference (case-insensitive)
#   (c) tests/dogfood/21-late-binding-adr/ does NOT exist
#   (d) Changesets machinery still present (aggregate-changesets.sh,
#       check-changeset-required.sh, dogfood 22/23/25)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
RELEASE_SKILL="$REPO_ROOT/skills/release/SKILL.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# ---------------------------------------------------------------------------
# Case (a) — assign-adr-ids.sh deleted
# ---------------------------------------------------------------------------
ASSIGN="$REPO_ROOT/skills/release/scripts/assign-adr-ids.sh"
[ ! -e "$ASSIGN" ] || fail "(a) assign-adr-ids.sh still exists at $ASSIGN"
pass "(a) skills/release/scripts/assign-adr-ids.sh — removed"

# ---------------------------------------------------------------------------
# Case (b) — release SKILL.md carries no dead-machinery reference
# ---------------------------------------------------------------------------
[ -f "$RELEASE_SKILL" ] || fail "(b) release SKILL.md missing at $RELEASE_SKILL"
HITS=$(grep -niE 'phase 3\.5|assign-adr-ids|late-binding|late binding' "$RELEASE_SKILL" || true)
if [ -n "$HITS" ]; then
  echo "FAIL: (b) release SKILL.md still references dead late-binding machinery:" >&2
  echo "$HITS" >&2
  exit 1
fi
pass "(b) release SKILL.md — no Phase 3.5 / assign-adr-ids / late-binding reference"

# ---------------------------------------------------------------------------
# Case (c) — scenario 21 directory removed
# ---------------------------------------------------------------------------
OLD_SCENARIO="$REPO_ROOT/tests/dogfood/21-late-binding-adr"
[ ! -e "$OLD_SCENARIO" ] || fail "(c) tests/dogfood/21-late-binding-adr/ still exists"
pass "(c) tests/dogfood/21-late-binding-adr/ — removed"

# ---------------------------------------------------------------------------
# Case (d) — independent Changesets machinery intact
# ---------------------------------------------------------------------------
declare -a KEEP=(
  "skills/release/scripts/aggregate-changesets.sh"
  "skills/release/scripts/check-changeset-required.sh"
  "tests/dogfood/22-changeset-schema/check-schema.sh"
  "tests/dogfood/23-changeset-aggregation/check-aggregation.sh"
  "tests/dogfood/25-changeset-required-check/check-path-audit.sh"
)
for rel in "${KEEP[@]}"; do
  [ -f "$REPO_ROOT/$rel" ] || fail "(d) Changesets machinery file missing: $rel"
done
pass "(d) Changesets machinery — all 5 files present and untouched"

echo
echo "===SCENARIO 21b ALL 4 CASES PASS==="
