#!/usr/bin/env bash
# habeebs-skill pre-push hook — block on overlap with live peers (slice-29, v1.16.0).
#
# For each live peer sidecar, runs the overlap probe against the peer's
# stash SHA. If any peer shows conflict, blocks the push (exit 1) and
# surfaces all conflicting peers + files.
#
# Per ADR-0003: block-only (exit non-zero to prevent push; never auto-fix).
# Per ADR-0018: advisory sidecar reads under four-sub-clause guard.
#
# Emergency disable: HABEEBS_DISABLE_HOOKS=1
# Per-invocation skip: HABEEBS_SKIP=pre-push

set -u

# ---- emergency disable ----
if [ "${HABEEBS_DISABLE_HOOKS:-0}" = "1" ]; then
  exit 0
fi

# ---- per-invocation skip ----
skip="${HABEEBS_SKIP:-}"
if echo ",$skip," | grep -qF ",pre-push,"; then
  exit 0
fi

# ---- git check ----
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# ---- resolve script paths ----
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SIDECAR="$REPO_ROOT/skills/cross-session-detect/sidecar.sh"
OVERLAP="$REPO_ROOT/skills/cross-session-detect/overlap.sh"

if [ ! -f "$SIDECAR" ] || [ ! -f "$OVERLAP" ]; then
  exit 0
fi

# ---- session ID ----
session_id="${HABEEBS_SESSION_ID:-}"
if [ -z "$session_id" ]; then
  session_id="session-$(date +%s)-$$"
fi

# ---- scan for live peers ----
peers=$(bash "$SIDECAR" list --session-id "$session_id" 2>/dev/null) || true

if [ -z "$peers" ]; then
  exit 0
fi

# ---- path helpers ----
abs_native_pwd() {
  if pwd -W >/dev/null 2>&1; then
    pwd -W
  else
    pwd
  fi
}

common_dir() {
  local d; d=$(git rev-parse --git-common-dir)
  case "$d" in
    /*|?:*) printf '%s\n' "$d" ;;
    *)      (cd "$d" && abs_native_pwd) ;;
  esac
}

sidecar_dir="$(common_dir)/habeebs-sessions"

# ---- probe each peer for overlap ----
has_conflict=false
conflict_output=""

while IFS= read -r peer_id; do
  [ -n "$peer_id" ] || continue

  peer_file="$sidecar_dir/${peer_id}.json"
  [ -f "$peer_file" ] || continue

  # Read peer's stash SHA
  stash_sha=$(node -e "
    const fs = require('fs');
    try {
      const s = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
      process.stdout.write(s.stash_sha || '');
    } catch { process.stdout.write(''); }
  " "$peer_file" 2>/dev/null) || stash_sha=""

  if [ -z "$stash_sha" ]; then
    continue
  fi

  # Verify the SHA exists in our repo
  if ! git cat-file -t "$stash_sha" >/dev/null 2>&1; then
    continue
  fi

  # Run overlap probe
  probe_result=$(bash "$OVERLAP" probe --peer-sha "$stash_sha" 2>/dev/null) || continue

  conflicted=$(node -e "
    try {
      const r = JSON.parse(process.argv[1]);
      process.stdout.write(String(r.conflicted === true));
    } catch { process.stdout.write('false'); }
  " "$probe_result" 2>/dev/null) || conflicted="false"

  if [ "$conflicted" = "true" ]; then
    has_conflict=true
    files=$(node -e "
      try {
        const r = JSON.parse(process.argv[1]);
        process.stdout.write((r.files || []).join(', '));
      } catch { process.stdout.write('(unknown files)'); }
    " "$probe_result" 2>/dev/null) || files="(unknown files)"

    conflict_output="${conflict_output}  Peer ${peer_id}: conflicts on ${files}\n"
  fi
done <<< "$peers"

if [ "$has_conflict" = "true" ]; then
  echo ""
  echo "[habeebs-skill] Push blocked — overlap detected with live peer session(s):"
  echo ""
  printf '%b' "$conflict_output"
  echo ""
  echo "Resolve the overlap before pushing. Options:"
  echo "  - Coordinate with the peer session"
  echo "  - Use HABEEBS_SKIP=pre-push to bypass this check"
  echo ""
  exit 1
fi

exit 0
