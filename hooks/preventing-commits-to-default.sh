#!/usr/bin/env bash
# habeebs-skill PreToolUse hook (matcher: Bash)
#
# Purpose: block `git commit` / `git push` on the default branch (main / master /
# whatever origin/HEAD resolves to). Enforces ADR-0001's never-commit-to-default
# rule mechanically rather than by skill text alone.
#
# Per ADR-0003:
#   - Rule 1: block-only, never auto-fix (no git checkout, no branch creation)
#   - Rule 2: multi-harness aware (detection via env vars + git universality)
#   - Rule 3: stateless (reads tool input + git state; writes nothing)
#
# Per-repo opt-out: add a branch name (one per line) to .claude/habeebs-allowed-branches
# Emergency disable: HABEEBS_DISABLE_HOOKS=1

set -u

# ────────────────────────────────────────────────────────────────────────────
# Disable env var check (per ADR-0003)
# ────────────────────────────────────────────────────────────────────────────
if [ "${HABEEBS_DISABLE_HOOKS:-0}" = "1" ]; then
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Read the JSON payload from stdin and extract tool_input.command
# Prefer jq when available; fall back to sed regex
# ────────────────────────────────────────────────────────────────────────────
input=$(cat 2>/dev/null) || exit 0
[ -z "$input" ] && exit 0

if command -v jq >/dev/null 2>&1; then
  command_text=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  # Fallback: extract the first "command": "..." value via sed.
  # Fragile on nested quotes, but tool_input.command in Bash tool calls is
  # typically a single-line shell string — good enough for the block-check.
  command_text=$(printf '%s' "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

if [ -z "$command_text" ]; then
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Only fire on `git commit` or `git push` — ignore log/status/diff/fetch/etc.
# Matches both top-level and chained (`X && git push Y`) usage.
# ────────────────────────────────────────────────────────────────────────────
case "$command_text" in
  *"git commit"*|*"git push"*) ;;
  *) exit 0 ;;
esac

# ────────────────────────────────────────────────────────────────────────────
# Are we in a git working tree?
# ────────────────────────────────────────────────────────────────────────────
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Skip if mid-operation — rebase / merge / cherry-pick transient branch states
# would cause false positives.
# ────────────────────────────────────────────────────────────────────────────
git_dir=$(git rev-parse --git-dir 2>/dev/null)
if [ -n "$git_dir" ]; then
  [ -f "$git_dir/REBASE_HEAD" ] && exit 0
  [ -f "$git_dir/MERGE_HEAD" ] && exit 0
  [ -f "$git_dir/CHERRY_PICK_HEAD" ] && exit 0
  [ -d "$git_dir/rebase-apply" ] && exit 0
  [ -d "$git_dir/rebase-merge" ] && exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Resolve default branch + current branch
# ────────────────────────────────────────────────────────────────────────────
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
[ -z "$default_branch" ] && default_branch="main"

current_branch=$(git branch --show-current 2>/dev/null)
# Detached HEAD or empty result — don't block
[ -z "$current_branch" ] && exit 0

# ────────────────────────────────────────────────────────────────────────────
# Per-repo opt-out: .claude/habeebs-allowed-branches (one branch per line)
# ────────────────────────────────────────────────────────────────────────────
repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$repo_root" ] && [ -f "$repo_root/.claude/habeebs-allowed-branches" ]; then
  if grep -Fxq "$current_branch" "$repo_root/.claude/habeebs-allowed-branches" 2>/dev/null; then
    exit 0
  fi
fi

# ────────────────────────────────────────────────────────────────────────────
# Only block when current branch IS the default branch
# ────────────────────────────────────────────────────────────────────────────
if [ "$current_branch" != "$default_branch" ]; then
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Block: stderr is shown to Claude; exit 2 denies the tool call
# ────────────────────────────────────────────────────────────────────────────
cat >&2 <<EOF
BLOCKED by habeebs-skill: \`${command_text}\` on \`${default_branch}\` violates ADR-0001's never-commit-to-default rule.

Create a feature branch first:
  git checkout -b <prefix>/<slug>
  (prefixes: feature/ fix/ chore/ docs/ spike/ slice-<N>/)

Per-repo opt-out:
  echo "${current_branch}" >> .claude/habeebs-allowed-branches

Emergency disable:
  HABEEBS_DISABLE_HOOKS=1
EOF

exit 2
