#!/usr/bin/env bash
# Path audit — applies the REQUIRED / OPTIONAL / NEVER matrix from
# ADR adr-late-binding-and-changesets § Decision to a list of changed files.
# Per Slice #3 of spec docs/agents/specs/v1.20.0-methodology-overhaul.md.
#
# Path classes:
#   REQUIRED (exit 1 if no changeset present): skills/, hooks/, .claude-plugin/,
#       plugin.json, marketplace.json
#   OPTIONAL (exit 0 + INFO note if no changeset): docs/, CLAUDE.md, AGENTS.md,
#       README.md, CHANGELOG.md
#   NEVER required (exit 0 silent): tests/, .gitignore, .github/, .gitattributes
#
# Usage:
#   check-changeset-required.sh [--changed-files <file>] [--changeset-dir <dir>] [--dry-run] [--help]
#   check-changeset-required.sh --print-messages

set -euo pipefail

CHANGED_FILES=""
CHANGESET_DIR=""
DRY_RUN=0
PRINT_MESSAGES=0

usage() {
  cat <<'EOF'
Usage: check-changeset-required.sh [OPTIONS]

Audits a list of changed files against the REQUIRED/OPTIONAL/NEVER matrix
and verifies a .changeset/*.md is present for REQUIRED-class paths.

OPTIONS:
  --changed-files <file>   File listing changed paths (one per line). Default:
                           output of `git diff --name-only main...HEAD`.
  --changeset-dir <dir>    .changeset/ directory (default: <root>/.changeset)
  --dry-run                Print the audit verdict without exiting non-zero
  --print-messages         Print all 5 named error message templates and exit 0
  --help                   Print this usage and exit 0

EXIT CODES:
  0  audit pass (or only OPTIONAL/NEVER paths touched)
  1  REQUIRED path modified without an accompanying changeset (halts release)

Per ADR adr-late-binding-and-changesets § Decision.
EOF
}

# The 5 named error messages, in one place so case (e) of dogfood scenario 25
# can grep them via --print-messages. Templates use literal <file>, <value>,
# <slug>, <file1>, <file2>, <path> placeholders that callers substitute.
print_messages() {
  cat <<'EOF'
Named error messages (per ADR adr-late-binding-and-changesets § Decision):

1. Missing bump frontmatter:
   "Changeset .changeset/<file>.md missing required `bump` frontmatter field. Expected one of: patch, minor, major. See .changeset/EXAMPLE.md."

2. Invalid bump value:
   "Changeset .changeset/<file>.md has invalid `bump: <value>`. Must be one of: patch, minor, major."

3. Empty why:
   "Changeset .changeset/<file>.md missing `why:` line. Add a one-sentence explanation."

4. Two identical-slug ADRs:
   "Cannot rename — two ADRs share slug `<slug>`: `<file1>`, `<file2>`. Pick distinct slugs."

5. Required path without changeset:
   "PR modifies skill files but contains no .changeset/*.md. Required path (`<path>`) needs a changeset. See `.changeset/README.md` for instructions."
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --changed-files)   CHANGED_FILES="$2"; shift 2 ;;
    --changeset-dir)   CHANGESET_DIR="$2"; shift 2 ;;
    --dry-run)         DRY_RUN=1; shift ;;
    --print-messages)  PRINT_MESSAGES=1; shift ;;
    --help|-h)         usage; exit 0 ;;
    *)                 echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [ "$PRINT_MESSAGES" -eq 1 ]; then
  print_messages
  exit 0
fi

# Default --changed-files to git diff against main
if [ -z "$CHANGED_FILES" ]; then
  CHANGED_FILES=$(mktemp)
  trap 'rm -f "$CHANGED_FILES"' EXIT
  git diff --name-only main...HEAD > "$CHANGED_FILES" 2>/dev/null || \
    { echo "Could not compute changed files; pass --changed-files explicitly" >&2; exit 1; }
fi
[ -f "$CHANGED_FILES" ] || { echo "Changed-files list not found: $CHANGED_FILES" >&2; exit 1; }

# Default --changeset-dir
if [ -z "$CHANGESET_DIR" ]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || ROOT="."
  CHANGESET_DIR="$ROOT/.changeset"
fi

# Classify each changed path
classify() {
  local p="$1"
  case "$p" in
    skills/*|hooks/*|.claude-plugin/*|plugin.json|marketplace.json) echo REQUIRED ;;
    docs/*|CLAUDE.md|AGENTS.md|README.md|CHANGELOG.md) echo OPTIONAL ;;
    tests/*|.gitignore|.github/*|.gitattributes) echo NEVER ;;
    *) echo OPTIONAL ;;  # default to OPTIONAL for unknown paths
  esac
}

REQUIRED_HITS=()
OPTIONAL_HITS=()
while IFS= read -r path; do
  [ -z "$path" ] && continue
  class=$(classify "$path")
  case "$class" in
    REQUIRED) REQUIRED_HITS+=("$path") ;;
    OPTIONAL) OPTIONAL_HITS+=("$path") ;;
  esac
done < "$CHANGED_FILES"

# Count real changesets (excluding README.md, EXAMPLE.md, .gitkeep)
CHANGESET_COUNT=0
if [ -d "$CHANGESET_DIR" ]; then
  for f in "$CHANGESET_DIR"/*.md; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    case "$base" in
      README.md|EXAMPLE.md) continue ;;
    esac
    CHANGESET_COUNT=$((CHANGESET_COUNT + 1))
  done
fi

# Verdict
if [ ${#REQUIRED_HITS[@]} -gt 0 ] && [ "$CHANGESET_COUNT" -eq 0 ]; then
  first="${REQUIRED_HITS[0]}"
  echo "PR modifies skill files but contains no .changeset/*.md. Required path (\`$first\`) needs a changeset. See \`.changeset/README.md\` for instructions." >&2
  if [ ${#REQUIRED_HITS[@]} -gt 1 ]; then
    echo "Additional REQUIRED paths modified:" >&2
    for p in "${REQUIRED_HITS[@]:1}"; do echo "  - $p" >&2; done
  fi
  [ "$DRY_RUN" -eq 1 ] || exit 1
fi

if [ ${#OPTIONAL_HITS[@]} -gt 0 ] && [ "$CHANGESET_COUNT" -eq 0 ]; then
  echo "INFO: PR modifies OPTIONAL paths without a changeset:"
  for p in "${OPTIONAL_HITS[@]}"; do echo "  - $p"; done
  echo "(optional — changeset not required for these paths)"
fi

exit 0
