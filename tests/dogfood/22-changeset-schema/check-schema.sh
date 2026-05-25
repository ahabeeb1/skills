#!/usr/bin/env bash
# Dogfood scenario 22 — changeset schema validation
# Per spec slice #2 (v1.20.0-methodology-overhaul) + ADR adr-late-binding-and-changesets § A.
#
# Validates every .changeset/*.md file (excluding EXAMPLE.md + README.md) has:
#   - bump: one of patch | minor | major
#   - why: non-empty single line
#
# Exit codes:
#   0 — all changesets valid (or no real changesets present, only EXAMPLE.md + README.md + .gitkeep)
#   1 — at least one malformed changeset
#
# Error message contracts (asserted by Slice 3 dogfood scenario 25; this scenario only
# tests the schema-validator side):
#   Missing bump: "Changeset .changeset/<file>.md missing required `bump` frontmatter field. Expected one of: patch, minor, major. See .changeset/EXAMPLE.md."
#   Invalid bump value: "Changeset .changeset/<file>.md has invalid `bump: <value>`. Must be one of: patch, minor, major."
#   Empty why: "Changeset .changeset/<file>.md missing `why:` line. Add a one-sentence explanation."

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CHANGESET_DIR="$REPO_ROOT/.changeset"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# Substrate check
[ -d "$CHANGESET_DIR" ] || fail ".changeset/ directory missing (slice #2 not implemented)"
[ -f "$CHANGESET_DIR/README.md" ] || fail ".changeset/README.md missing (slice #2 incomplete)"
[ -f "$CHANGESET_DIR/EXAMPLE.md" ] || fail ".changeset/EXAMPLE.md missing (slice #2 incomplete)"
[ -f "$CHANGESET_DIR/.gitkeep" ] || fail ".changeset/.gitkeep missing (directory tracking incomplete)"

# Validate EXAMPLE.md itself — must parse as a valid changeset (it IS the contract demo)
EXAMPLE_BUMP=$(awk '/^bump:/{print $2; exit}' "$CHANGESET_DIR/EXAMPLE.md")
EXAMPLE_WHY=$(awk '/^why:/{sub(/^why:[[:space:]]*/, ""); print; exit}' "$CHANGESET_DIR/EXAMPLE.md")
case "$EXAMPLE_BUMP" in
  patch|minor|major) ;;
  *) fail ".changeset/EXAMPLE.md has invalid bump: '$EXAMPLE_BUMP' (must be patch|minor|major)" ;;
esac
[ -n "$EXAMPLE_WHY" ] || fail ".changeset/EXAMPLE.md missing non-empty why: line"

# Validate every real changeset (excluding EXAMPLE.md, README.md, .gitkeep, hidden files)
INVALID=0
TOTAL=0
for f in "$CHANGESET_DIR"/*.md; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  case "$base" in
    EXAMPLE.md|README.md) continue ;;
  esac
  TOTAL=$((TOTAL+1))

  BUMP=$(awk '/^bump:/{print $2; exit}' "$f")
  WHY=$(awk '/^why:/{sub(/^why:[[:space:]]*/, ""); print; exit}' "$f")

  if [ -z "$BUMP" ]; then
    echo "FAIL: Changeset .changeset/$base missing required \`bump\` frontmatter field. Expected one of: patch, minor, major. See .changeset/EXAMPLE.md." >&2
    INVALID=$((INVALID+1)); continue
  fi
  case "$BUMP" in
    patch|minor|major) ;;
    *) echo "FAIL: Changeset .changeset/$base has invalid \`bump: $BUMP\`. Must be one of: patch, minor, major." >&2
       INVALID=$((INVALID+1)); continue ;;
  esac
  if [ -z "$WHY" ]; then
    echo "FAIL: Changeset .changeset/$base missing \`why:\` line. Add a one-sentence explanation." >&2
    INVALID=$((INVALID+1)); continue
  fi
done

if [ "$INVALID" -gt 0 ]; then
  fail "$INVALID of $TOTAL real changesets are malformed"
fi

pass "changeset schema valid ($TOTAL real changesets + EXAMPLE.md verified)"
