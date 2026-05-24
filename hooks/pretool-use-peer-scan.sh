#!/usr/bin/env bash
# habeebs-skill PreToolUse hook — annotate-only peer overlap scan (slice-37, v1.16.0).
#
# Gated by pretool_use: true in policy. Fires on Edit/Write/NotebookEdit.
# Three-filter check: file path overlap, liveness, merge-tree overlap.
# On all-pass, annotates and allows — never denies.
#
# Per ADR-0003: annotate-only (never blocks the tool call).
# Per ADR-0018: advisory sidecar reads under four-sub-clause guard.
#
# Emergency disable: HABEEBS_DISABLE_HOOKS=1
# Per-invocation skip: HABEEBS_SKIP=pretool-use

set -u

# ---- emergency disable ----
if [ "${HABEEBS_DISABLE_HOOKS:-0}" = "1" ]; then
  exit 0
fi

# ---- per-invocation skip ----
skip="${HABEEBS_SKIP:-}"
if echo ",$skip," | grep -qF ",pretool-use,"; then
  exit 0
fi

# ---- tool filter: only Edit, Write, NotebookEdit ----
tool_name="${HABEEBS_TOOL_NAME:-}"
case "$tool_name" in
  Edit|Write|NotebookEdit) ;;
  *) exit 0 ;;
esac

# ---- git check ----
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# ---- resolve paths ----
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SIDECAR="$REPO_ROOT/skills/cross-session-detect/sidecar.sh"
OVERLAP="$REPO_ROOT/skills/cross-session-detect/overlap.sh"
POLICY="$REPO_ROOT/skills/cross-session-detect/policy.sh"

if [ ! -f "$SIDECAR" ] || [ ! -f "$OVERLAP" ] || [ ! -f "$POLICY" ]; then
  exit 0
fi

# ---- check policy: pretool_use must be true ----
policy_out=$(bash "$POLICY" resolve 2>/dev/null) || exit 0
pretool=$(node -e "
  try { process.stdout.write(String(JSON.parse(process.argv[1]).pretool_use === true)); }
  catch { process.stdout.write('false'); }
" "$policy_out" 2>/dev/null) || pretool="false"

if [ "$pretool" != "true" ]; then
  exit 0
fi

# ---- session ID ----
session_id="${HABEEBS_SESSION_ID:-}"
if [ -z "$session_id" ]; then
  session_id="session-$(date +%s)-$$"
fi

# ---- file being edited ----
target_file="${HABEEBS_TOOL_INPUT_FILE:-}"
if [ -z "$target_file" ]; then
  exit 0
fi

# ---- scan for live peers ----
peers=$(bash "$SIDECAR" list --session-id "$session_id" 2>/dev/null) || true

if [ -z "$peers" ]; then
  exit 0
fi

# ---- path helpers ----
abs_native_pwd() {
  if pwd -W >/dev/null 2>&1; then pwd -W; else pwd; fi
}

common_dir() {
  local d; d=$(git rev-parse --git-common-dir)
  case "$d" in
    /*|?:*) printf '%s\n' "$d" ;;
    *)      (cd "$d" && abs_native_pwd) ;;
  esac
}

sidecar_dir="$(common_dir)/habeebs-sessions"

# ---- check each peer for overlap on the target file ----
annotations=""

while IFS= read -r peer_id; do
  [ -n "$peer_id" ] || continue

  peer_file="$sidecar_dir/${peer_id}.json"
  [ -f "$peer_file" ] || continue

  stash_sha=$(node -e "
    const fs = require('fs');
    try { const s = JSON.parse(fs.readFileSync(process.argv[1],'utf8')); process.stdout.write(s.stash_sha || ''); }
    catch { process.stdout.write(''); }
  " "$peer_file" 2>/dev/null) || stash_sha=""

  [ -n "$stash_sha" ] || continue
  git cat-file -t "$stash_sha" >/dev/null 2>&1 || continue

  # Run overlap probe
  probe_result=$(bash "$OVERLAP" probe --peer-sha "$stash_sha" 2>/dev/null) || continue

  conflicted=$(node -e "
    try { const r = JSON.parse(process.argv[1]); process.stdout.write(String(r.conflicted === true)); }
    catch { process.stdout.write('false'); }
  " "$probe_result" 2>/dev/null) || conflicted="false"

  if [ "$conflicted" = "true" ]; then
    files=$(node -e "
      try { const r = JSON.parse(process.argv[1]); process.stdout.write((r.files||[]).join(', ')); }
      catch { process.stdout.write(''); }
    " "$probe_result" 2>/dev/null) || files=""

    # Check if target file is in the conflicted files
    if echo "$files" | grep -qF "$target_file"; then
      annotations="${annotations}[habeebs-skill] Warning: peer session $peer_id has overlapping changes on $target_file (files: $files). Edit proceeding (annotate-only).\n"
    fi
  fi
done <<< "$peers"

if [ -n "$annotations" ]; then
  printf '%b' "$annotations"
fi

exit 0
