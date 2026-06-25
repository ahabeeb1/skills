#!/usr/bin/env bash
# habeebs-skill test — harness-agnostic bundle-root resolver (Slice 2, dual-native parity).
#
# Asserts hooks/lib/resolve-bundle-root.sh resolves the bundle root across the
# documented priority order, and NEVER returns empty regardless of which
# harness env var is (un)set. This is the portability proof for Codex: a hook
# body must locate its bundle without any Claude-specific env var.
#
#   (a) CLAUDE_PLUGIN_ROOT wins when set
#   (b) CURSOR_PLUGIN_ROOT used when only it is set
#   (c) CODEX_PLUGIN_ROOT used when only it is set
#   (d) all three unset, inside a git tree -> git toplevel (non-empty)
#   (e) resolution is never empty (the portability invariant)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RESOLVER="$REPO_ROOT/hooks/lib/resolve-bundle-root.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f "$RESOLVER" ] || fail "resolver not found at $RESOLVER"

# Run the resolver as a clean subprocess with a controlled environment.
# `env -i` strips inherited vars; we re-add PATH + the var(s) under test, and
# run from inside the repo so the git-toplevel branch has a tree to resolve.
run_resolver() {
  ( cd "$REPO_ROOT" && env -i PATH="$PATH" HOME="${HOME:-/root}" "$@" bash "$RESOLVER" )
}

# (a) CLAUDE_PLUGIN_ROOT wins
got="$(run_resolver CLAUDE_PLUGIN_ROOT=/tmp/claude-root)"
[ "$got" = "/tmp/claude-root" ] || fail "(a) expected /tmp/claude-root, got '$got'"
pass "(a) CLAUDE_PLUGIN_ROOT takes precedence"

# (b) CURSOR_PLUGIN_ROOT used when only it is set
got="$(run_resolver CURSOR_PLUGIN_ROOT=/tmp/cursor-root)"
[ "$got" = "/tmp/cursor-root" ] || fail "(b) expected /tmp/cursor-root, got '$got'"
pass "(b) CURSOR_PLUGIN_ROOT used when no CLAUDE var"

# (c) CODEX_PLUGIN_ROOT used when only it is set
got="$(run_resolver CODEX_PLUGIN_ROOT=/tmp/codex-root)"
[ "$got" = "/tmp/codex-root" ] || fail "(c) expected /tmp/codex-root, got '$got'"
pass "(c) CODEX_PLUGIN_ROOT used when no Claude/Cursor var"

# (d) all harness vars unset, inside git tree -> non-empty git toplevel
got="$(run_resolver)"
[ -n "$got" ] || fail "(d) resolver returned empty with all env unset"
[ -d "$got" ] || fail "(d) resolver returned a non-directory: '$got'"
# In this repo the bundle IS the git root, so the resolved root must contain skills/
[ -d "$got/skills" ] || fail "(d) resolved root '$got' has no skills/ dir"
pass "(d) all harness vars unset -> git toplevel ('$got')"

# (e) precedence chain: CLAUDE beats CURSOR beats CODEX
got="$(run_resolver CLAUDE_PLUGIN_ROOT=/tmp/a CURSOR_PLUGIN_ROOT=/tmp/b CODEX_PLUGIN_ROOT=/tmp/c)"
[ "$got" = "/tmp/a" ] || fail "(e) precedence broken, got '$got'"
got="$(run_resolver CURSOR_PLUGIN_ROOT=/tmp/b CODEX_PLUGIN_ROOT=/tmp/c)"
[ "$got" = "/tmp/b" ] || fail "(e) CURSOR should beat CODEX, got '$got'"
pass "(e) precedence chain CLAUDE > CURSOR > CODEX holds"

echo
echo "===RESOLVE-BUNDLE-ROOT ALL 5 CASES PASS==="
