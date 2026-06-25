#!/usr/bin/env bash
# habeebs-skill — harness-agnostic bundle-root resolver (sourced or executed).
#
# Resolves the path to the installed/vendored habeebs-skill bundle root so a
# single hook/command body runs identically under Claude Code, Cursor, and Codex
# CLI. Priority order (per the dual-native parity ADR, 2026-06-25, extending
# ADR-0003 Rule 2 "multi-harness aware"):
#
#   1. CLAUDE_PLUGIN_ROOT   — Claude Code plugin runtime
#   2. CURSOR_PLUGIN_ROOT   — Cursor
#   3. CODEX_PLUGIN_ROOT    — explicit Codex override (vendored-at-subpath installs)
#   4. git rev-parse --show-toplevel  — Codex default when the bundle IS the repo root
#   5. self-location two levels up from this script — ultimate fallback, never fails
#
# Always emits SOME path (never errors): the final fallback self-locates from
# this file's own path (<root>/hooks/lib/resolve-bundle-root.sh).
#
# Usage:
#   root="$(bash "${BASH_SOURCE%/*}/lib/resolve-bundle-root.sh")"   # capture
#   . "${BASH_SOURCE%/*}/lib/resolve-bundle-root.sh"                # export HABEEBS_BUNDLE_ROOT

habeebs_resolve_bundle_root() {
  local candidate=""
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    candidate="$CLAUDE_PLUGIN_ROOT"
  elif [ -n "${CURSOR_PLUGIN_ROOT:-}" ]; then
    candidate="$CURSOR_PLUGIN_ROOT"
  elif [ -n "${CODEX_PLUGIN_ROOT:-}" ]; then
    candidate="$CODEX_PLUGIN_ROOT"
  elif candidate="$(git rev-parse --show-toplevel 2>/dev/null)" && [ -n "$candidate" ]; then
    : # git toplevel
  else
    candidate="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
  fi
  printf '%s\n' "$candidate"
}

HABEEBS_BUNDLE_ROOT="$(habeebs_resolve_bundle_root)"
export HABEEBS_BUNDLE_ROOT

# When executed directly (not sourced), print the resolved root.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  printf '%s\n' "$HABEEBS_BUNDLE_ROOT"
fi
