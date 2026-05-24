#!/usr/bin/env bash
# Cross-session conflict detection — halt UX renderer (slice-30, v1.16.0).
#
# Renders the 5-option action menu when a conflict is detected, reads user
# input, and returns structured JSON with the chosen action.
#
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 7)
# ADR-0018: Decision 2 — action menu vocabulary lock-in.
#
# Subcommands:
#   dispatch  --peer-session-id <id> --conflict-files <csv>
#             Renders menu, reads choice, returns JSON to stdout.

set -u

cmd=${1:-}
shift || true

do_dispatch() {
  local peer_session_id="" conflict_files=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --peer-session-id) peer_session_id="$2"; shift 2 ;;
      --conflict-files)  conflict_files="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  [ -n "$peer_session_id" ] || { echo "dispatch requires --peer-session-id" >&2; exit 2; }

  # Default action on signal (Ctrl+C, SIGHUP) is abort
  trap 'emit_result "abort" "$peer_session_id"; exit 0' INT HUP TERM

  # Display conflict summary (to stderr so JSON result goes to stdout cleanly)
  echo "" >&2
  echo "[habeebs-skill] Conflict detected with peer session: $peer_session_id" >&2
  if [ -n "$conflict_files" ]; then
    echo "Conflicting files: $(echo "$conflict_files" | tr ',' ', ')" >&2
  fi
  echo "" >&2

  # Show diff if not suppressed
  if [ "${HABEEBS_HALT_NO_DIFF:-}" != "1" ]; then
    # Best-effort diff display; skip if no peer SHA available
    if [ -n "${HABEEBS_HALT_PEER_SHA:-}" ]; then
      echo "--- diff --stat ---" >&2
      git diff --stat HEAD "$HABEEBS_HALT_PEER_SHA" 2>/dev/null >&2 || true
      echo "" >&2

      # Full diff through pager
      local pager="${PAGER:-less}"
      git diff HEAD "$HABEEBS_HALT_PEER_SHA" 2>/dev/null | $pager >&2 || true
      echo "" >&2
    fi
  fi

  # Render menu and read choice
  local action=""
  while [ -z "$action" ]; do
    echo "Choose an action:" >&2
    echo "  [1/m] Merge       — drop into git conflict markers" >&2
    echo "  [2/s] Sequence    — wait for peer to finish" >&2
    echo "  [3/t] Transfer    — write a note for the peer; abandon your change" >&2
    echo "  [4/a] Abort       — drop your branch + worktree state" >&2
    echo "  [5/w] Worktree-out — branch into a new worktree" >&2
    echo "" >&2
    printf "Your choice: " >&2

    local choice
    if ! read -r choice; then
      # EOF (pipe closed, terminal gone) — default to abort
      action="abort"
      break
    fi

    case "$choice" in
      1|m|M) action="merge" ;;
      2|s|S) action="sequence" ;;
      3|t|T) action="transfer" ;;
      4|a|A) action="abort" ;;
      5|w|W) action="worktree-out" ;;
      *)
        echo "Invalid choice '$choice'. Try again." >&2
        echo "" >&2
        ;;
    esac
  done

  emit_result "$action" "$peer_session_id"
}

emit_result() {
  local action="$1" peer_id="$2"
  printf '{"action":"%s","peer_session_id":"%s"}\n' "$action" "$peer_id"
}

case "$cmd" in
  dispatch) do_dispatch "$@" ;;
  *) echo "usage: halt-ux.sh {dispatch} --peer-session-id <id> --conflict-files <csv>" >&2; exit 2 ;;
esac
