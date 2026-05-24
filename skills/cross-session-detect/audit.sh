#!/usr/bin/env bash
# Cross-session conflict detection — audit writer (slice-27, v1.16.0).
#
# Single-writer, append-once JSON writer for conflict audit records.
# Idempotent: re-firing with the same conflict_id is a no-op.
#
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 6)
#
# Subcommands:
#   write  --context <json>   writes docs/agents/conflicts/<id>.json

set -u

cmd=${1:-}
shift || true

abs_native_pwd() {
  if pwd -W >/dev/null 2>&1; then
    pwd -W
  else
    pwd
  fi
}

worktree_path() {
  (cd "$(git rev-parse --show-toplevel)" && abs_native_pwd)
}

do_write() {
  local ctx=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --context) ctx="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  [ -n "$ctx" ] || { echo "write requires --context <json>" >&2; exit 2; }

  local wt conflicts_dir
  wt=$(worktree_path)
  conflicts_dir="$wt/docs/agents/conflicts"

  mkdir -p "$conflicts_dir"

  # Ensure .gitkeep exists
  if [ ! -f "$conflicts_dir/.gitkeep" ]; then
    touch "$conflicts_dir/.gitkeep"
  fi

  CTX="$ctx" \
  CONFLICTS_DIR="$conflicts_dir" \
  node -e '
    const fs = require("fs");
    const path = require("path");

    const ctx = JSON.parse(process.env.CTX);
    const dir = process.env.CONFLICTS_DIR;
    const id = ctx.conflict_id;

    if (!id) {
      process.stderr.write("error: context JSON must include conflict_id\n");
      process.exit(1);
    }

    const outPath = path.join(dir, id + ".json");

    // Idempotent: skip if file already exists
    if (fs.existsSync(outPath)) {
      process.exit(0);
    }

    // Force resolved_by to "user" per v1 spec
    const record = {
      conflict_id: id,
      detected_at_iso: ctx.detected_at_iso || new Date().toISOString(),
      trigger: ctx.trigger || "unknown",
      session_a: ctx.session_a || {},
      session_b: ctx.session_b || {},
      overlap: ctx.overlap || {},
      resolution: ctx.resolution || "unknown",
      resolved_at_iso: ctx.resolved_at_iso || new Date().toISOString(),
      resolved_by: "user",
      notes: ctx.notes || ""
    };

    fs.writeFileSync(outPath, JSON.stringify(record, null, 2) + "\n");
  '
}

case "$cmd" in
  write) do_write "$@" ;;
  *) echo "usage: audit.sh {write} --context <json>" >&2; exit 2 ;;
esac
