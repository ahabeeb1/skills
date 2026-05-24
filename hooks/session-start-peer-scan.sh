#!/usr/bin/env bash
# habeebs-skill SessionStart hook — cross-session peer scan (slice-28, v1.16.0).
#
# Writes own sidecar, scans for live peers, emits warn-only output if any found.
# Per ADR-0003: warn-only (never blocks), stateless beyond the sidecar write,
# multi-harness aware. Per ADR-0019: advisory sidecar under four-sub-clause guard.
#
# Emergency disable: HABEEBS_DISABLE_HOOKS=1
# Per-invocation skip: HABEEBS_SKIP=session-start

set -u

# ---- emergency disable ----
if [ "${HABEEBS_DISABLE_HOOKS:-0}" = "1" ]; then
  exit 0
fi

# ---- per-invocation skip ----
skip="${HABEEBS_SKIP:-}"
if echo ",$skip," | grep -qF ",session-start,"; then
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

if [ ! -f "$SIDECAR" ]; then
  exit 0
fi

# ---- session ID ----
session_id="${HABEEBS_SESSION_ID:-}"
if [ -z "$session_id" ]; then
  session_id="session-$(date +%s)-$$"
fi

# ---- write own sidecar ----
bash "$SIDECAR" write --session-id "$session_id" 2>/dev/null || true

# ---- scan for live peers ----
peers=$(bash "$SIDECAR" list --session-id "$session_id" 2>/dev/null) || true

if [ -z "$peers" ]; then
  exit 0
fi

# ---- build peer info lines ----
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
peer_lines=""
peer_count=0

while IFS= read -r peer_id; do
  [ -n "$peer_id" ] || continue
  peer_count=$((peer_count + 1))
  peer_file="$sidecar_dir/${peer_id}.json"
  if [ -f "$peer_file" ]; then
    info=$(node -e "
      const fs = require('fs');
      try {
        const s = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
        const wt = s.worktree_path || 'unknown';
        const st = s.start_time_iso || 'unknown';
        process.stdout.write(wt + ' (started ' + st + ')');
      } catch { process.stdout.write('(could not read sidecar)'); }
    " "$peer_file" 2>/dev/null) || info="(could not read sidecar)"
    peer_lines="${peer_lines}  - ${peer_id}: ${info}\\n"
  else
    peer_lines="${peer_lines}  - ${peer_id}: (sidecar file missing)\\n"
  fi
done <<< "$peers"

# ---- emit warn-only JSON ----
warning="Active peer session(s) detected on this repo:\\n${peer_lines}Enable pretool_use: true in .claude/habeebs-policy.json to catch in-session collisions."
warning_escaped=$(printf '%s' "$warning" | sed 's/"/\\"/g')

printf '{"additionalContext": "[habeebs-skill] %s"}\n' "$warning_escaped"
exit 0
