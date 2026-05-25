#!/usr/bin/env bash
# Late-binding ADR ID assignment — release skill's writer for NNNN-<slug>.md files.
# Per ADR adr-late-binding-and-changesets § Decision. Implements Slice #1 of
# spec docs/agents/specs/v1.20.0-methodology-overhaul.md.
#
# Contract:
#   - Scans docs/agents/adrs/ for `adr-<slug>.md` files (unnumbered, written
#     by decision-record skill).
#   - Reads the maximum existing `NNNN-*.md` integer; assigns ints sequentially
#     starting at max+1.
#   - Tiebreak: alphabetic slug order (deterministic, no random component).
#   - Slug collision (two adr-<identical-slug>.md anywhere in the scanned set)
#     halts loud with exit 2 and the exact message:
#       "Cannot rename — two ADRs share slug `<slug>`: `<file1>`, `<file2>`. Pick distinct slugs."
#   - Regenerates the ADR README index with the new entries appended.
#   - Existing NNNN-*.md files are NEVER renamed (Pattern B / immutable path).
#
# Usage:
#   assign-adr-ids.sh [--adrs-dir <path>] [--extra-scan <path>] [--dry-run] [--help]
#
# Exit codes:
#   0 — success (or no adr-*.md files found; nothing to do)
#   1 — usage error
#   2 — slug collision (halts before any FS change)

set -euo pipefail

ADRS_DIR=""
EXTRA_SCAN=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: assign-adr-ids.sh [OPTIONS]

Assigns sequential ADR integer prefixes to any adr-<slug>.md files under the
ADR directory, renames them to NNNN-<slug>.md, and updates the README index.

OPTIONS:
  --adrs-dir <path>    ADR directory (default: docs/agents/adrs relative to git root)
  --extra-scan <path>  Additional directory to scan for adr-*.md files (for tests
                       that simulate cross-branch collisions). Files found here
                       are NOT renamed; they only participate in slug-collision
                       detection.
  --dry-run            Print the rename plan; make no filesystem changes
  --help               Print this usage and exit 0

EXIT CODES:
  0  success (or no adr-*.md files found)
  1  usage error
  2  slug collision (two adr-<identical-slug>.md files; halts before any change)

Per ADR adr-late-binding-and-changesets § Decision.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --adrs-dir)   ADRS_DIR="$2"; shift 2 ;;
    --extra-scan) EXTRA_SCAN="$2"; shift 2 ;;
    --dry-run)    DRY_RUN=1; shift ;;
    --help|-h)    usage; exit 0 ;;
    *)            echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# Default ADRS_DIR to docs/agents/adrs under git root
if [ -z "$ADRS_DIR" ]; then
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "Not in a git repo and no --adrs-dir given" >&2; exit 1; }
  ADRS_DIR="$GIT_ROOT/docs/agents/adrs"
fi
[ -d "$ADRS_DIR" ] || { echo "ADR dir not found: $ADRS_DIR" >&2; exit 1; }

# Collect adr-<slug>.md files (primary set — these get renamed)
PRIMARY=()
while IFS= read -r -d '' f; do PRIMARY+=("$f"); done \
  < <(find "$ADRS_DIR" -maxdepth 1 -name 'adr-*.md' -print0 | sort -z)

# Collect extra-scan set (collision detection only, never renamed)
EXTRA=()
if [ -n "$EXTRA_SCAN" ] && [ -d "$EXTRA_SCAN" ]; then
  while IFS= read -r -d '' f; do EXTRA+=("$f"); done \
    < <(find "$EXTRA_SCAN" -maxdepth 1 -name 'adr-*.md' -print0 | sort -z)
fi

# Nothing to do
if [ ${#PRIMARY[@]} -eq 0 ] && [ ${#EXTRA[@]} -eq 0 ]; then
  echo "No adr-*.md files found in $ADRS_DIR — nothing to assign."
  exit 0
fi

# Extract slugs from filenames (strip 'adr-' prefix and '.md' suffix)
slug_of() {
  local base; base=$(basename "$1")
  base="${base#adr-}"
  base="${base%.md}"
  # Normalize: lowercase + collapse for case-equivalent collision detection.
  printf '%s' "$base" | tr '[:upper:]' '[:lower:]'
}

# Slug collision detection — across PRIMARY + EXTRA union.
declare -A SLUG_TO_PATH
ALL=("${PRIMARY[@]}")
[ ${#EXTRA[@]} -gt 0 ] && ALL+=("${EXTRA[@]}")
for f in "${ALL[@]}"; do
  s=$(slug_of "$f")
  if [ -n "${SLUG_TO_PATH[$s]:-}" ]; then
    first="${SLUG_TO_PATH[$s]}"
    echo "Cannot rename — two ADRs share slug \`$s\`: \`$first\`, \`$f\`. Pick distinct slugs." >&2
    exit 2
  fi
  SLUG_TO_PATH[$s]="$f"
done

# Find the max existing NNNN- prefix
MAX=0
while IFS= read -r -d '' f; do
  base=$(basename "$f")
  n="${base%%-*}"
  case "$n" in
    [0-9][0-9][0-9][0-9])
      n10=$((10#$n))
      [ "$n10" -gt "$MAX" ] && MAX="$n10"
      ;;
  esac
done < <(find "$ADRS_DIR" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' -print0)

# Compute rename plan (only PRIMARY files get renamed; sorted alphabetically by slug)
PLAN=()
NEXT=$((MAX + 1))
# Sort PRIMARY by slug (already sorted by find|sort -z above, but sort by slug explicitly)
SORTED=()
while IFS= read -r f; do SORTED+=("$f"); done < <(
  for f in "${PRIMARY[@]}"; do printf '%s\t%s\n' "$(slug_of "$f")" "$f"; done \
    | sort | cut -f2-
)
for src in "${SORTED[@]}"; do
  slug=$(slug_of "$src")
  pad=$(printf '%04d' "$NEXT")
  dst="$ADRS_DIR/${pad}-${slug}.md"
  PLAN+=("$src	$dst")
  NEXT=$((NEXT + 1))
done

# --dry-run: print plan and exit
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Would rename ${#PLAN[@]} ADR(s) starting at $(printf '%04d' "$((MAX + 1))"):"
  for entry in "${PLAN[@]}"; do
    src="${entry%%	*}"; dst="${entry#*	}"
    echo "  $(basename "$src")  →  $(basename "$dst")"
  done
  echo "(dry-run — no filesystem changes)"
  exit 0
fi

# Apply rename
for entry in "${PLAN[@]}"; do
  src="${entry%%	*}"; dst="${entry#*	}"
  mv "$src" "$dst"
done

# Regenerate README index — append new entries to the existing table.
# The README is expected to have a table; we append rows after the existing rows.
README="$ADRS_DIR/README.md"
if [ -f "$README" ] && [ ${#PLAN[@]} -gt 0 ]; then
  {
    cat "$README"
    for entry in "${PLAN[@]}"; do
      dst="${entry#*	}"
      base=$(basename "$dst" .md)
      n="${base%%-*}"
      slug="${base#*-}"
      # Try to pull title from the file's first heading
      title=$(awk 'NR==1{sub(/^# ADR-[A-Za-z0-9]+: */, ""); print; exit}' "$dst")
      [ -z "$title" ] && title="$slug"
      printf '| %s | %s | Accepted |\n' "$n" "$title"
    done
  } > "${README}.tmp"
  mv "${README}.tmp" "$README"
fi

echo "Renamed ${#PLAN[@]} ADR(s); README updated."
