#!/usr/bin/env bash
# Dogfood scenario 24a — grill-records/ folded into specs/<name>-grill.md
# Per spec slice #6 (v1.20.0-methodology-overhaul) + ADR adr-methodology-folder-cuts § Decision.
#
# Verifies:
#   (a) docs/agents/grill-records/ directory is absent
#   (b) the single pre-existing grill record was moved (not copied) to
#       docs/agents/specs/v1.16.0-cross-session-conflict-detection-grill.md
#       — git log --follow resolves to the original commit
#   (c) the structural-fold ADR exists at the expected path
#       (adr-methodology-folder-cuts.md pre-rename, OR a renamed NNNN-methodology-folder-cuts.md
#       post-rename; both forms accepted)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# (a) directory absent
if [ -d "$REPO_ROOT/docs/agents/grill-records" ]; then
  fail "(a) docs/agents/grill-records/ still exists — slice #6 incomplete"
fi
pass "(a) docs/agents/grill-records/ deleted"

# (b) target file present and history preserved
TARGET="$REPO_ROOT/docs/agents/specs/v1.16.0-cross-session-conflict-detection-grill.md"
[ -f "$TARGET" ] || fail "(b) target file missing: $TARGET"

# Verify history preservation through git mv (not cp + delete).
# Two acceptance modes:
#   1) Post-commit: git log --follow resolves to ≥2 commits (move + original)
#   2) Mid-slice (staged but not committed): git status -sb shows the rename with capital R
# Mode 2 lets the dogfood pass during the slice itself; Mode 1 enforces the same invariant
# permanently once the commit lands. Both modes mean the same thing: the file was moved.
COMMIT_COUNT=$(git -C "$REPO_ROOT" log --follow --oneline -- "$TARGET" 2>/dev/null | wc -l)
if [ "$COMMIT_COUNT" -ge 2 ]; then
  pass "(b) target file present; git log --follow resolves to $COMMIT_COUNT commits (history preserved through git mv, committed)"
else
  # Mode 2 fallback: check staged rename
  STAGED_RENAME=$(git -C "$REPO_ROOT" status --porcelain | grep -E '^R[[:space:]]+docs/agents/grill-records/.+->.+v1\.16\.0-cross-session-conflict-detection-grill\.md$' || true)
  if [ -n "$STAGED_RENAME" ]; then
    pass "(b) target file present; staged as git rename (mid-slice, pre-commit)"
  else
    fail "(b) target file present but neither committed-rename nor staged-rename detected. File was likely copied instead of moved. git log --follow returned $COMMIT_COUNT commits."
  fi
fi

# (c) structural-fold ADR present (either late-binding or already-renamed form)
ADR_LATE="$REPO_ROOT/docs/agents/adrs/adr-methodology-folder-cuts.md"
ADR_RENAMED=$(find "$REPO_ROOT/docs/agents/adrs" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-methodology-folder-cuts.md' | head -1)
if [ ! -f "$ADR_LATE" ] && [ -z "$ADR_RENAMED" ]; then
  fail "(c) structural-fold ADR missing; expected either adrs/adr-methodology-folder-cuts.md or NNNN-methodology-folder-cuts.md"
fi
pass "(c) structural-fold ADR present at $([ -f "$ADR_LATE" ] && echo "$ADR_LATE" || echo "$ADR_RENAMED")"

echo
echo "===SCENARIO 24a (grill-records folded) ALL 3 CASES PASS==="
