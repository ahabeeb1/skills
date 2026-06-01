#!/usr/bin/env bash
# Dogfood scenario 36 — supersession-link integrity (v1.24.0 chain-fidelity, SP4)
# Per spec slice #3 (2026-06-01-v1.24.0-chain-fidelity-hardening) + grill OQ-4.
#
# The release doc-sync audit gates a release on this invariant; this dogfood is
# the MECHANISM (runs every PR), the doc-sync procedure is the GATE (references
# scenario 36 at release time). OQ-4 resolved BOTH, non-redundant.
#
# Invariant — for any ADR whose Status line names a Superseded state:
#   (a) the SAME record carries a forward markdown link to the superseding record
#       (a `](./...md)` or `](...md)` target), and
#   (b) if the supersession is PARTIAL (the Status text says "half" / "partial" /
#       "part"), the record also names which half SURVIVES (in force / in-force /
#       retained / survives / remain / continues / unchanged / stands).
#
# Discriminator: only the ADR's real Status HEADER line is inspected — the first
# `**Status:**` / `Status:` line outside any code fence. A YAML-template
# enumeration line such as `Status: <Proposed | ... | Superseded by ADR-N>`
# living inside a ``` code fence is NOT a real status and is excluded (the same
# code-fence discipline as scenario 28/34).
#
# Test cases:
#   (a) a Superseded ADR WITH a forward link passes
#   (b) a Superseded ADR WITHOUT a forward link FAILS
#   (c) a PARTIAL supersession naming the surviving half passes
#   (d) a PARTIAL supersession missing the surviving-half statement FAILS
#   (e) main repo scan over docs/agents/adrs/*.md MUST PASS — the live ADR-0020
#       (partial, ADR-ID half) and ADR-0001 (partial, multi-superseder) pairs
#       both satisfy the invariant.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ADRS="$REPO_ROOT/docs/agents/adrs"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

GUIDANCE='Supersession-link integrity (release doc-sync gate, dogfood 36): when an ADR Status becomes Superseded, the SAME record MUST carry a forward markdown link to the superseding record (`](./<file>.md)`). For a PARTIAL supersession (Status text says "half"/"partial"/"part"), the record MUST also name which half SURVIVES (e.g. "remains in force", "retained", "unchanged"). Fix: add the forward link to the Status line or the supersession note, and for partial supersession state explicitly which half stays in force.'

# ---------------------------------------------------------------------------
# extract_status FILE — print the ADR's real Status HEADER line (lower-cased),
# i.e. the first line whose text (after stripping `**` bold markers and leading
# `> ` blockquote) begins with "status:", scanned OUTSIDE code fences. Returns
# empty if the record has no status header.
# ---------------------------------------------------------------------------
extract_status() {
  awk '
    BEGIN { in_code = 0 }
    /^```/ { in_code = !in_code; next }
    in_code { next }
    {
      line = $0
      gsub(/\*\*/, "", line)          # strip bold markers
      sub(/^[[:space:]]*> ?/, "", line)  # strip blockquote prefix
      probe = tolower(line)
      if (probe ~ /^status:/) { print probe; exit }
    }
  ' "$1"
}

# ---------------------------------------------------------------------------
# has_forward_link FILE — exit 0 if the record carries a markdown link to a
# .md target, i.e. `](./something.md)` or `](something.md)`. We look across the
# whole record (the forward pointer may sit on the Status line OR in the
# supersession note paragraph). Code fences are excluded.
# ---------------------------------------------------------------------------
has_forward_link() {
  awk '
    BEGIN { in_code = 0; found = 0 }
    /^```/ { in_code = !in_code; next }
    in_code { next }
    /\]\(\.?\/?[^)]*\.md[^)]*\)/ { found = 1 }
    END { exit (found ? 0 : 1) }
  ' "$1"
}

# ---------------------------------------------------------------------------
# names_surviving_half FILE — exit 0 if the record names a surviving half
# (the prose that keeps one half in force). Code fences excluded.
# ---------------------------------------------------------------------------
SURVIVE_PAT='in force|in-force|retained|retain|survives|surviving|remains?|continues?|unchanged|stands|untouched|still in force'
names_surviving_half() {
  awk -v pat="$SURVIVE_PAT" '
    BEGIN { in_code = 0; found = 0 }
    /^```/ { in_code = !in_code; next }
    in_code { next }
    { if (tolower($0) ~ pat) found = 1 }
    END { exit (found ? 0 : 1) }
  ' "$1"
}

# ---------------------------------------------------------------------------
# check_record FILE — apply the full invariant to one ADR file. Echoes a
# failure reason to stdout and returns 1 on violation; returns 0 (silent) if
# the record is not Superseded OR satisfies the invariant.
# ---------------------------------------------------------------------------
check_record() {
  local file="$1" status
  status="$(extract_status "$file")"
  case "$status" in
    *superseded*) ;;   # a real Superseded status — apply the invariant
    *) return 0 ;;      # not superseded (or no status header) — nothing to check
  esac

  # (a) forward link must exist in the same record
  if ! has_forward_link "$file"; then
    echo "$file: Superseded status carries no forward markdown link to the superseding record"
    return 1
  fi

  # (b) partial supersession must name the surviving half
  case "$status" in
    *half*|*partial*|*part\ *|*"part)"*|*"part;"*|*"part,"*)
      if ! names_surviving_half "$file"; then
        echo "$file: partial supersession does not name which half survives (in force / retained / unchanged)"
        return 1
      fi
      ;;
  esac
  return 0
}

# ---------------------------------------------------------------------------
# Fixture maker: write a minimal ADR with a given Status line + body.
# ---------------------------------------------------------------------------
make_adr() {
  local dir status body
  dir=$(mktemp -d)
  status="$1"
  body="${2:-}"
  cat > "$dir/adr.md" <<EOF
# ADR-XXXX: fixture decision

**Status:** $status
**Date:** 2026-06-01
**Deciders:** Modie

## Context

$body
EOF
  echo "$dir/adr.md"
}

# ---------------------------------------------------------------------------
# Case (a) — Superseded ADR WITH a forward link passes
# ---------------------------------------------------------------------------
F=$(make_adr 'Superseded by the [new decision](./2026-06-01-new-decision.md)' \
  'Fully superseded; see the new decision.')
if check_record "$F" >/dev/null; then
  pass "(a) Superseded ADR with a forward link — passes"
else
  fail "(a) Superseded ADR WITH a forward link was wrongly flagged"
fi
rm -rf "$(dirname "$F")"

# ---------------------------------------------------------------------------
# Case (b) — Superseded ADR WITHOUT a forward link FAILS
# ---------------------------------------------------------------------------
F=$(make_adr 'Superseded by a later decision' \
  'This ADR is superseded but names no link to its replacement.')
if check_record "$F" >/dev/null; then
  fail "(b) Superseded ADR with NO forward link was NOT flagged (false negative)"
else
  pass "(b) Superseded ADR with no forward link — correctly FAILS"
fi
rm -rf "$(dirname "$F")"

# ---------------------------------------------------------------------------
# Case (c) — PARTIAL supersession naming the surviving half passes
# ---------------------------------------------------------------------------
F=$(make_adr 'Superseded (ADR-ID half) by [dated naming](./2026-05-28-decouple.md); Changesets half in force' \
  'The late-binding half is superseded; the Changesets half remains in force, unchanged.')
if check_record "$F" >/dev/null; then
  pass "(c) PARTIAL supersession naming the surviving half — passes"
else
  fail "(c) PARTIAL supersession that names the surviving half was wrongly flagged"
fi
rm -rf "$(dirname "$F")"

# ---------------------------------------------------------------------------
# Case (d) — PARTIAL supersession MISSING the surviving-half statement FAILS
# ---------------------------------------------------------------------------
F=$(make_adr 'Superseded (ADR-ID half only) by [dated naming](./2026-05-28-decouple.md)' \
  'The late-binding half is superseded by the dated-naming decision.')
if check_record "$F" >/dev/null; then
  fail "(d) PARTIAL supersession MISSING the surviving-half statement was NOT flagged (false negative)"
else
  pass "(d) PARTIAL supersession missing the surviving-half statement — correctly FAILS"
fi
rm -rf "$(dirname "$F")"

# ---------------------------------------------------------------------------
# Case extra — a non-Superseded ADR (Accepted) is ignored even if it lacks a link
# ---------------------------------------------------------------------------
F=$(make_adr 'Accepted' 'A normal in-force decision with no links.')
if check_record "$F" >/dev/null; then
  pass "(extra) non-Superseded ADR — correctly ignored"
else
  fail "(extra) non-Superseded ADR was wrongly flagged"
fi
rm -rf "$(dirname "$F")"

# ---------------------------------------------------------------------------
# Case (e) — main repo scan: every Superseded ADR in the live corpus satisfies
# the invariant. The live ADR-0020 (partial, ADR-ID half) + ADR-0001 (partial,
# multi-superseder) pairs MUST PASS. The ADR-0023 YAML-template enumeration line
# inside a code fence MUST NOT be treated as a real Superseded status.
# ---------------------------------------------------------------------------
[ -d "$ADRS" ] || fail "(e) ADR directory not found: $ADRS"

HITS=""
SUPERSEDED_COUNT=0
for adr in "$ADRS"/*.md; do
  [ -f "$adr" ] || continue
  status="$(extract_status "$adr")"
  case "$status" in *superseded*) SUPERSEDED_COUNT=$((SUPERSEDED_COUNT + 1)) ;; esac
  if ! reason="$(check_record "$adr")"; then
    HITS="${HITS}${reason}"$'\n'
  fi
done

if [ -n "$HITS" ]; then
  echo "FAIL: (e) live ADR corpus has supersession-link integrity violations:" >&2
  printf '%s' "$HITS" | sed '/^$/d' >&2
  echo >&2
  echo "$GUIDANCE" >&2
  exit 1
fi

[ "$SUPERSEDED_COUNT" -ge 1 ] \
  || fail "(e) scan found ZERO Superseded ADRs in the live corpus — expected at least the ADR-0020 pair; the scan or the corpus regressed"
pass "(e) main repo ADR corpus — all $SUPERSEDED_COUNT Superseded record(s) carry a forward link + name any surviving half"

echo
echo "===SCENARIO 36 ALL 6 CASES PASS==="
