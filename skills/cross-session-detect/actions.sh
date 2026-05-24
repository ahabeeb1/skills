#!/usr/bin/env bash
# Cross-session conflict detection — action handlers (slices 32-36, v1.16.0).
#
# Each subcommand implements one action from the 5-option halt menu.
# All handlers write an audit record via audit.sh.
#
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slices 8-12)
#
# Subcommands:
#   abort       --session-id <self> --peer-session-id <peer> --context <json>
#   worktree-out --session-id <self> --peer-session-id <peer> --context <json>
#   transfer    --session-id <self> --peer-session-id <peer> --context <json> [--message <text>]
#   sequence    --session-id <self> --peer-session-id <peer> --context <json>
#   merge       --session-id <self> --peer-session-id <peer> --context <json>

set -u

cmd=${1:-}
shift || true

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SIDECAR="$SCRIPT_DIR/sidecar.sh"
AUDIT="$SCRIPT_DIR/audit.sh"

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

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

parse_common_args() {
  SESSION_ID=""
  PEER_SESSION_ID=""
  CTX_JSON=""
  TRANSFER_MSG=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --session-id)      SESSION_ID="$2"; shift 2 ;;
      --peer-session-id) PEER_SESSION_ID="$2"; shift 2 ;;
      --context)         CTX_JSON="$2"; shift 2 ;;
      --message)         TRANSFER_MSG="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
}

write_audit() {
  local resolution="$1" notes="${2:-}"
  local resolved_at; resolved_at=$(now_iso)

  # Build audit context by injecting resolution fields into the existing context
  local audit_ctx
  audit_ctx=$(node -e "
    const ctx = JSON.parse(process.argv[1]);
    ctx.resolution = process.argv[2];
    ctx.resolved_at_iso = process.argv[3];
    ctx.notes = process.argv[4] || '';
    process.stdout.write(JSON.stringify(ctx));
  " "$CTX_JSON" "$resolution" "$resolved_at" "$notes" 2>/dev/null) || return 0

  bash "$AUDIT" write --context "$audit_ctx" 2>/dev/null || true
}

# ---- Abort (Slice 8) ----
do_abort() {
  parse_common_args "$@"
  [ -n "$SESSION_ID" ] || { echo "abort requires --session-id" >&2; exit 2; }

  write_audit "abort" "Session aborted by user"

  # Remove own sidecar
  bash "$SIDECAR" end --session-id "$SESSION_ID" 2>/dev/null || true

  echo '{"action":"abort","status":"complete"}'
}

# ---- Worktree-out (Slice 9) ----
do_worktree_out() {
  parse_common_args "$@"
  [ -n "$SESSION_ID" ] || { echo "worktree-out requires --session-id" >&2; exit 2; }

  # Generate short UUID for branch name
  local short_uuid
  short_uuid=$(node -e "process.stdout.write(require('crypto').randomUUID().slice(0,8))" 2>/dev/null) || \
    short_uuid=$(date +%s | tail -c 9)

  local branch_name="worktree-out/$short_uuid"
  local repo_name; repo_name=$(basename "$(git rev-parse --show-toplevel)")
  local worktree_path; worktree_path="$(dirname "$(git rev-parse --show-toplevel)")/${repo_name}-${short_uuid}"

  # Check for dirty state
  local stash_sha=""
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    stash_sha=$(git stash create 2>/dev/null) || stash_sha=""
  fi

  # Create worktree (redirect stdout to stderr so JSON output stays clean)
  if ! git worktree add "$worktree_path" -b "$branch_name" >/dev/null 2>&1; then
    echo '{"action":"worktree-out","status":"failed","error":"git worktree add failed"}' >&2
    exit 1
  fi

  # Apply stash in new worktree if there was dirty state
  if [ -n "$stash_sha" ]; then
    if ! (cd "$worktree_path" && git stash apply "$stash_sha" 2>/dev/null); then
      echo "Warning: stash apply failed in new worktree. Your stash ($stash_sha) is preserved — recover with 'git stash apply $stash_sha'." >&2
    fi
  fi

  write_audit "worktree-out" "Branched to $worktree_path on $branch_name"

  printf '{"action":"worktree-out","status":"complete","worktree_path":"%s","branch":"%s"}\n' "$worktree_path" "$branch_name"
}

# ---- Transfer (Slice 12) ----
do_transfer() {
  parse_common_args "$@"
  [ -n "$SESSION_ID" ] || { echo "transfer requires --session-id" >&2; exit 2; }
  [ -n "$PEER_SESSION_ID" ] || { echo "transfer requires --peer-session-id" >&2; exit 2; }

  local message="${TRANSFER_MSG:-}"
  if [ -z "$message" ] && [ -t 0 ]; then
    printf "Enter a message for the peer session: " >&2
    read -r message
  fi
  message="${message:-[no message provided]}"

  # Write transfer note for the peer
  local sidecar_dir; sidecar_dir="$(common_dir)/habeebs-sessions"
  local transfer_file="$sidecar_dir/${PEER_SESSION_ID}.transfer.md"
  local ts; ts=$(now_iso)

  TRANSFER_FILE="$transfer_file" \
  TS="$ts" \
  SID="$SESSION_ID" \
  MSG="$message" \
  node -e '
    const fs = require("fs");
    const content = "# Transfer Note\n\n" +
      "**From:** " + process.env.SID + "\n" +
      "**At:** " + process.env.TS + "\n" +
      "**Message:** " + process.env.MSG + "\n";
    fs.writeFileSync(process.env.TRANSFER_FILE, content);
  ' 2>/dev/null

  write_audit "transfer" "Transferred to $PEER_SESSION_ID: $message"

  # Remove own sidecar (like abort)
  bash "$SIDECAR" end --session-id "$SESSION_ID" 2>/dev/null || true

  echo '{"action":"transfer","status":"complete"}'
}

# ---- Sequence (Slice 11) ----
do_sequence() {
  parse_common_args "$@"
  [ -n "$SESSION_ID" ] || { echo "sequence requires --session-id" >&2; exit 2; }
  [ -n "$PEER_SESSION_ID" ] || { echo "sequence requires --peer-session-id" >&2; exit 2; }

  local sidecar_dir; sidecar_dir="$(common_dir)/habeebs-sessions"
  local peer_file="$sidecar_dir/${PEER_SESSION_ID}.json"

  # Read max wait from policy (default to liveness_ttl, which defaults to 86400)
  local max_wait=86400
  local policy_out
  policy_out=$(bash "$SCRIPT_DIR/policy.sh" resolve 2>/dev/null) || true
  if [ -n "$policy_out" ]; then
    max_wait=$(node -e "
      try { process.stdout.write(String(JSON.parse(process.argv[1]).liveness_ttl_seconds || 86400)); }
      catch { process.stdout.write('86400'); }
    " "$policy_out" 2>/dev/null) || max_wait=86400
  fi

  local waited=0
  local delay=1
  local outcome="resolved"

  echo "Waiting for peer session $PEER_SESSION_ID to finish..." >&2

  while [ -f "$peer_file" ]; do
    if [ "$waited" -ge "$max_wait" ]; then
      outcome="timed_out"
      echo "Max wait ($max_wait s) exceeded. Peer session still active." >&2
      break
    fi
    sleep "$delay"
    waited=$((waited + delay))
    # Exponential backoff capped at 30s
    delay=$((delay * 2))
    if [ "$delay" -gt 30 ]; then delay=30; fi
  done

  if [ "$outcome" = "resolved" ]; then
    echo "Peer session $PEER_SESSION_ID has ended." >&2
  fi

  write_audit "sequence" "Waited for $PEER_SESSION_ID: $outcome (${waited}s)"

  printf '{"action":"sequence","status":"%s","waited_seconds":%d}\n' "$outcome" "$waited"
}

# ---- Merge (Slice 10) ----
do_merge() {
  parse_common_args "$@"
  [ -n "$SESSION_ID" ] || { echo "merge requires --session-id" >&2; exit 2; }

  # Extract conflicted files from context
  local files
  files=$(node -e "
    try {
      const ctx = JSON.parse(process.argv[1]);
      const f = ctx.overlap?.conflicted_paths || ctx.overlap?.files || [];
      process.stdout.write(f.join('\\n'));
    } catch { process.stdout.write(''); }
  " "$CTX_JSON" 2>/dev/null) || files=""

  if [ -z "$files" ]; then
    echo "No conflicted files found in context." >&2
    write_audit "merge" "No files to merge"
    echo '{"action":"merge","status":"no_files"}'
    return 0
  fi

  # Get the peer's stash/commit SHA from context for merge-tree conflict markers
  local peer_sha
  peer_sha=$(node -e "
    try {
      const ctx = JSON.parse(process.argv[1]);
      process.stdout.write(ctx.session_a?.last_commit || ctx.overlap?.peer_sha || '');
    } catch { process.stdout.write(''); }
  " "$CTX_JSON" 2>/dev/null) || peer_sha=""

  if [ -n "$peer_sha" ] && git cat-file -t "$peer_sha" >/dev/null 2>&1; then
    # Use git merge to create conflict markers in the working tree
    # --no-commit leaves the tree in a conflicted state for manual resolution
    git merge --no-commit --no-ff "$peer_sha" 2>/dev/null || true
  fi

  # Open editor on first conflicted file if interactive
  local first_file
  first_file=$(echo "$files" | head -1)
  if [ -t 0 ] && [ -n "$first_file" ] && [ -f "$first_file" ]; then
    local editor="${EDITOR:-${VISUAL:-}}"
    if [ -n "$editor" ]; then
      $editor "$first_file" >&2 || true
    else
      echo "Set \$EDITOR to edit conflicted files. Files with markers:" >&2
      echo "$files" >&2
    fi
  fi

  write_audit "merge" "Merge markers inserted in: $(echo "$files" | tr '\n' ', ')"

  printf '{"action":"merge","status":"markers_inserted","files":%s}\n' \
    "$(node -e "process.stdout.write(JSON.stringify(process.argv[1].split('\\n').filter(Boolean)))" "$files" 2>/dev/null)"
}

case "$cmd" in
  abort)       do_abort "$@" ;;
  worktree-out) do_worktree_out "$@" ;;
  transfer)    do_transfer "$@" ;;
  sequence)    do_sequence "$@" ;;
  merge)       do_merge "$@" ;;
  *) echo "usage: actions.sh {abort|worktree-out|transfer|sequence|merge} [args...]" >&2; exit 2 ;;
esac
