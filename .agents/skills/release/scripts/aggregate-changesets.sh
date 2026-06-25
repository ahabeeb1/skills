#!/usr/bin/env bash
# Changeset aggregation — release skill's writer for plugin.json, marketplace.json,
# and CHANGELOG.md. Per ADR adr-late-binding-and-changesets § Decision. Implements
# Slice #3 of spec docs/agents/specs/v1.20.0-methodology-overhaul.md.
#
# Contract:
#   - Reads .changeset/*.md (excluding README.md, EXAMPLE.md, .gitkeep, hidden files).
#   - Picks the highest bump level across all changesets (major > minor > patch).
#   - Computes the new SemVer from .claude-plugin/plugin.json's current version.
#   - Writes plugin.json + marketplace.json + CHANGELOG.md in one atomic step
#     (temp-staging-dir approach: all writes go to a temp copy first, then mv into
#     place; failure at any point leaves the working tree exactly as it started).
#   - Deletes consumed changesets in the same atomic step.
#
# Usage:
#   aggregate-changesets.sh [--root <path>] [--dry-run] [--help]
#
# Exit codes:
#   0 — success (or no changesets to aggregate)
#   1 — aborted clean (write failure detected before any mutation; working tree
#       unchanged)
#   2 — aborted dirty (manual intervention required; should never happen given
#       temp-dir approach but documented for safety per ADR § Decision)

set -euo pipefail

ROOT=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: aggregate-changesets.sh [OPTIONS]

Aggregates pending .changeset/*.md files into a single version bump
(plugin.json + marketplace.json + CHANGELOG.md) and deletes the consumed
changesets. Atomic: all writes succeed or none do.

OPTIONS:
  --root <path>   Repo root (default: git rev-parse --show-toplevel)
  --dry-run       Print aggregation plan; make no filesystem changes
  --help          Print this usage and exit 0

EXIT CODES:
  0  success (or no changesets to aggregate)
  1  aborted clean (write failed; working tree unchanged)
  2  aborted dirty (manual intervention required)

Per ADR adr-late-binding-and-changesets § Decision.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root)     ROOT="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    --help|-h)  usage; exit 0 ;;
    *)          echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [ -z "$ROOT" ]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "Not in a git repo and no --root given" >&2; exit 1; }
fi
CHANGESET_DIR="$ROOT/.changeset"
PLUGIN_JSON="$ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$ROOT/.claude-plugin/marketplace.json"
CHANGELOG="$ROOT/CHANGELOG.md"

[ -d "$CHANGESET_DIR" ] || { echo "No .changeset/ directory at $ROOT" >&2; exit 1; }
[ -f "$PLUGIN_JSON" ] || { echo "Missing $PLUGIN_JSON" >&2; exit 1; }
[ -f "$MARKETPLACE_JSON" ] || { echo "Missing $MARKETPLACE_JSON" >&2; exit 1; }
[ -f "$CHANGELOG" ] || { echo "Missing $CHANGELOG" >&2; exit 1; }

# Collect real changesets (skip README.md, EXAMPLE.md, .gitkeep)
CHANGESETS=()
for f in "$CHANGESET_DIR"/*.md; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  case "$base" in
    README.md|EXAMPLE.md) continue ;;
  esac
  CHANGESETS+=("$f")
done

if [ ${#CHANGESETS[@]} -eq 0 ]; then
  echo "No changesets to aggregate."
  exit 0
fi

# Parse each changeset's bump + why
bump_rank() {
  case "$1" in
    major) echo 3 ;;
    minor) echo 2 ;;
    patch) echo 1 ;;
    *)     echo 0 ;;
  esac
}

MAX_RANK=0
WHY_LINES=()
for cs in "${CHANGESETS[@]}"; do
  bump=$(awk '/^bump:/{print $2; exit}' "$cs")
  why=$(awk '/^why:/{sub(/^why:[[:space:]]*/, ""); print; exit}' "$cs")
  rank=$(bump_rank "$bump")
  [ "$rank" -eq 0 ] && { echo "Invalid bump '$bump' in $cs" >&2; exit 1; }
  [ "$rank" -gt "$MAX_RANK" ] && MAX_RANK="$rank"
  WHY_LINES+=("$why")
done

case "$MAX_RANK" in
  3) BUMP=major ;;
  2) BUMP=minor ;;
  1) BUMP=patch ;;
esac

# Read current version
CURRENT=$(awk -F'"' '/"version":/{print $4; exit}' "$PLUGIN_JSON")
[ -n "$CURRENT" ] || { echo "Could not parse current version from $PLUGIN_JSON" >&2; exit 1; }
IFS=. read -r MAJ MIN PAT <<< "$CURRENT"

case "$BUMP" in
  major) NEW="$((MAJ + 1)).0.0" ;;
  minor) NEW="${MAJ}.$((MIN + 1)).0" ;;
  patch) NEW="${MAJ}.${MIN}.$((PAT + 1))" ;;
esac

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Would aggregate ${#CHANGESETS[@]} changeset(s); bump $CURRENT → $NEW ($BUMP):"
  for cs in "${CHANGESETS[@]}"; do
    echo "  - $(basename "$cs")"
  done
  echo "Would bump plugin.json + marketplace.json to $NEW."
  echo "Would prepend ## v$NEW section to CHANGELOG.md with ${#WHY_LINES[@]} bullet(s)."
  echo "Would delete consumed changesets."
  echo "(dry-run — no filesystem changes)"
  exit 0
fi

# Atomic mutation: build everything in a temp directory, then mv into place.
# If any single step fails, exit before mutating the working tree.
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

# Stage new plugin.json
sed "s/\"version\": *\"$CURRENT\"/\"version\": \"$NEW\"/" "$PLUGIN_JSON" > "$STAGING/plugin.json"
grep -q "\"version\": \"$NEW\"" "$STAGING/plugin.json" || \
  { echo "Failed to stage plugin.json bump" >&2; exit 1; }

# Stage new marketplace.json
sed "s/\"version\": *\"$CURRENT\"/\"version\": \"$NEW\"/" "$MARKETPLACE_JSON" > "$STAGING/marketplace.json"
grep -q "\"version\": \"$NEW\"" "$STAGING/marketplace.json" || \
  { echo "Failed to stage marketplace.json bump" >&2; exit 1; }

# Write WHY_LINES to a temp file the awk reads
printf '%s\n' "${WHY_LINES[@]}" > "$STAGING/whys.txt"

# Stage new CHANGELOG: prepend a new "## [NEW] — YYYY-MM-DD" section before
# the first existing release heading. Matches BOTH legacy formats — "## v..."
# and "## [...]" — so it works against pre-v1.20.0 CHANGELOGs and the format
# this script itself writes going forward.
TODAY=$(date +%Y-%m-%d)
awk -v new="$NEW" -v today="$TODAY" -v whys_file="$STAGING/whys.txt" '
  BEGIN { inserted=0 }
  /^## (\[|v[0-9])/ && !inserted {
    print "## [" new "] — " today "\n"
    while ((getline line < whys_file) > 0) print "- " line
    print ""
    inserted=1
  }
  { print }
  END {
    if (!inserted) {
      print "\n## [" new "] — " today "\n"
      while ((getline line < whys_file) > 0) print "- " line
    }
  }
' "$CHANGELOG" > "$STAGING/CHANGELOG.md" || \
  { echo "Failed to stage CHANGELOG" >&2; exit 1; }

grep -q "^## \[$NEW\]" "$STAGING/CHANGELOG.md" || \
  { echo "CHANGELOG staging missing new section" >&2; exit 1; }

# All three staging files built. Now commit atomically by moving each into place.
# If any mv fails after the first succeeds, we restore from backup.
BACKUP=$(mktemp -d)
trap 'rm -rf "$STAGING" "$BACKUP"' EXIT
cp "$PLUGIN_JSON" "$BACKUP/plugin.json"
cp "$MARKETPLACE_JSON" "$BACKUP/marketplace.json"
cp "$CHANGELOG" "$BACKUP/CHANGELOG.md"

# Attempt the writes. If any fails, restore from backup and exit 1 (clean abort).
if ! mv "$STAGING/plugin.json" "$PLUGIN_JSON" 2>/dev/null; then
  echo "Aborted: plugin.json write failed; working tree unchanged" >&2
  exit 1
fi
if ! mv "$STAGING/marketplace.json" "$MARKETPLACE_JSON" 2>/dev/null; then
  cp "$BACKUP/plugin.json" "$PLUGIN_JSON"
  echo "Aborted: marketplace.json write failed; rolled back plugin.json" >&2
  exit 1
fi
if ! mv "$STAGING/CHANGELOG.md" "$CHANGELOG" 2>/dev/null; then
  cp "$BACKUP/plugin.json" "$PLUGIN_JSON"
  cp "$BACKUP/marketplace.json" "$MARKETPLACE_JSON"
  echo "Aborted: CHANGELOG write failed; rolled back plugin.json + marketplace.json" >&2
  exit 1
fi

# All three writes succeeded; delete consumed changesets
for cs in "${CHANGESETS[@]}"; do
  rm -f "$cs"
done

echo "Aggregated ${#CHANGESETS[@]} changeset(s); bumped $CURRENT → $NEW; CHANGELOG updated."
