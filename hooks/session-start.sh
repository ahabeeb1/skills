#!/usr/bin/env bash
# habeebs-skill SessionStart hook
#
# Purpose: warn (never auto-fix) when local default branch has diverged from origin
# in a way that suggests squash-merge ghost commits OR a missed pull.
#
# Per ADR-0003:
#   - Rule 1: warn-only, never auto-fix (no git reset, no merge, no destructive ops)
#   - Rule 2: multi-harness aware (CLAUDE_PLUGIN_ROOT / CURSOR_PLUGIN_ROOT detection)
#   - Rule 3: stateless (reads git state and SYSTEM_CONTEXT.md; writes nothing)
#
# Emergency disable: HABEEBS_DISABLE_HOOKS=1

set -u

# ────────────────────────────────────────────────────────────────────────────
# Disable env var check (per ADR-0003)
# ────────────────────────────────────────────────────────────────────────────
if [ "${HABEEBS_DISABLE_HOOKS:-0}" = "1" ]; then
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Are we in a git working tree?
# ────────────────────────────────────────────────────────────────────────────
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Best-effort fetch (silent; exit clean on any failure — never block session)
# ────────────────────────────────────────────────────────────────────────────
if ! git fetch origin --prune --quiet 2>/dev/null; then
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Resolve default branch via origin/HEAD; fall back to "main"
# ────────────────────────────────────────────────────────────────────────────
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$default_branch" ]; then
  default_branch="main"
fi

# Skip if the local default branch doesn't exist (e.g., fresh clone of a worktree-only branch)
if ! git rev-parse "$default_branch" >/dev/null 2>&1; then
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Compute ahead / behind without switching branches
# ────────────────────────────────────────────────────────────────────────────
ahead=$(git rev-list --count "origin/$default_branch..$default_branch" 2>/dev/null || echo "0")
behind=$(git rev-list --count "$default_branch..origin/$default_branch" 2>/dev/null || echo "0")

# ────────────────────────────────────────────────────────────────────────────
# Build a one-line warning (warn-only — never reset/merge/delete anything)
# ────────────────────────────────────────────────────────────────────────────
warning=""

if [ "$ahead" = "0" ] && [ "$behind" != "0" ]; then
  warning="Local ${default_branch} is ${behind} commit(s) behind origin. Run /sync to fast-forward."
elif [ "$ahead" != "0" ] && [ "$behind" = "0" ]; then
  warning="Local ${default_branch} has ${ahead} unpushed commit(s). Push or discard before continuing."
elif [ "$ahead" != "0" ] && [ "$behind" != "0" ]; then
  warning="Local ${default_branch} has diverged (ahead=${ahead}, behind=${behind}). Likely squash-merge ghost commits — run /sync."
fi

# Nothing to warn about? exit clean
if [ -z "$warning" ]; then
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Emit JSON to stdout in the documented SessionStart shape.
#
# Per the Claude Code hook contract, context is injected via
# hookSpecificOutput.additionalContext with hookEventName: "SessionStart".
# (A bare top-level {"additionalContext": ...} is also accepted for SessionStart,
# but the nested form is the documented standard and avoids ambiguity.)
# ────────────────────────────────────────────────────────────────────────────
# Escape any embedded double-quotes in the warning (paranoia — the message is
# constructed entirely from numeric counts + literals, so this is belt + braces).
warning_escaped=$(printf '%s' "$warning" | sed 's/"/\\"/g')

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"[habeebs-skill] %s"}}\n' "$warning_escaped"
exit 0
