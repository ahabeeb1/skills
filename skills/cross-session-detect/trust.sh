#!/usr/bin/env bash
# Cross-session conflict detection — trust mode (slice-31, v1.16.0).
#
# Opt-in signature verification for peer sidecars. When
# require_signed_signals: true, validates the peer's HEAD commit via
# git verify-commit. Unsigned peers get a warning, never a halt.
#
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 14)
#
# Subcommands:
#   verify  --peer-commit <sha> --require-signed <bool>

set -u

cmd=${1:-}
shift || true

do_verify() {
  local peer_commit="" require_signed=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --peer-commit)    peer_commit="$2"; shift 2 ;;
      --require-signed) require_signed="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  [ -n "$peer_commit" ] || { echo "verify requires --peer-commit" >&2; exit 2; }

  if [ "$require_signed" != "true" ]; then
    echo '{"status":"skipped","reason":"require_signed_signals is false"}'
    return 0
  fi

  if git verify-commit "$peer_commit" >/dev/null 2>&1; then
    echo '{"status":"verified","commit":"'"$peer_commit"'"}'
  else
    echo '{"status":"unsigned","commit":"'"$peer_commit"'","message":"unsigned peer signal — advisory only"}'
  fi

  return 0
}

case "$cmd" in
  verify) do_verify "$@" ;;
  *) echo "usage: trust.sh {verify} --peer-commit <sha> --require-signed <bool>" >&2; exit 2 ;;
esac
