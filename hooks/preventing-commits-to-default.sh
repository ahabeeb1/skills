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
# Matches top-level, chained (`X && git push Y`), and git invocations carrying
# global flags between `git` and the verb (`git -C <path> commit`,
# `git -c key=val commit`). The literal-substring form missed those and let
# `git -C <default> commit` slip past the guard entirely.
# ────────────────────────────────────────────────────────────────────────────
if ! printf '%s' "$command_text" | grep -Eq 'git( +-[cC] +[^ ]+)* +(commit|push)\b'; then
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Tag-only push carve-out (ADR-0015)
#
# A release tag pushed on the default branch is NOT a branch-commit push.
# The following unambiguous tag-only forms are ALLOWED on the default branch:
#
#   git push --tags                        (all local tags)
#   git push <remote> --tags               (all local tags to named remote)
#   git push <remote> tag <name>           (explicit single tag)
#   git push <remote> refs/tags/<name>     (unambiguous refspec — preferred)
#
# STILL BLOCKED:
#   git push <remote> <name>               (ambiguous: could be branch or tag)
#   git push                               (bare push advances the branch)
#   git commit                             (unchanged)
#
# The carve-out is intentionally conservative: the preferred form is
# `git push origin refs/tags/<version>` (what the `release` skill uses).
# The `--tags` and `tag <name>` forms are also recognized as unambiguous
# enough that blocking them serves no policy purpose.
#
# Residual limitation: this is glob matching on a command string, not a
# shell parser. A command that pushes a branch AND tags in one invocation
# (`git push origin main --tags`) can evade the carve-out's intent. The
# first case arm below declines the carve-out for any command that also
# contains `git commit` (the likely accidental case). The branch+tags
# combination is an accepted residual — this hook is a guardrail against
# accidental default-branch commits, not an adversary boundary
# (HABEEBS_DISABLE_HOOKS=1 and the per-repo allowlist remain the escapes).
# ────────────────────────────────────────────────────────────────────────────
case "$command_text" in
  # A command that also runs `git commit` is never a pure tag-push —
  # decline the carve-out so the commit half is still blocked on default.
  *"git commit"*)
    ;;
  # `git push --tags` or `git push <remote> --tags`
  *"git push"*"--tags"*)
    exit 0
    ;;
  # `git push <remote> tag <name>` (explicit "tag" keyword)
  *"git push"*" tag "*)
    exit 0
    ;;
  # `git push <remote> refs/tags/<name>` (unambiguous refspec)
  *"git push"*"refs/tags/"*)
    exit 0
    ;;
esac

# ────────────────────────────────────────────────────────────────────────────
# Resolve the directory the commit/push will ACTUALLY run in.
#
# The hook process's own cwd is the harness launch dir (typically the main
# checkout). But the command frequently targets a sibling worktree on a feature
# branch via `cd <path> && git commit ...` or `git -C <path> commit ...`. We
# must resolve the branch from THAT directory, not the hook's cwd — otherwise a
# commit that correctly lands on a feature branch in a worktree is false-
# positive-blocked as "on the default branch" (the exact workflow using-worktrees
# mandates). Extraction precedence: a leading `cd <path>` wins (it changes the
# shell's cwd for the whole chain), else a `git -C <path>` on the git invocation.
# ────────────────────────────────────────────────────────────────────────────
target_dir="."
# Leading `cd <path>` (the first command in a `cd X && git ...` chain).
cd_path=$(printf '%s' "$command_text" \
  | sed -n "s/^[[:space:]]*cd[[:space:]]\+\(\"[^\"]*\"\|'[^']*'\|[^&;|][^&;|]*\)[[:space:]]*\(&&\|;\).*/\1/p" \
  | head -1)
if [ -n "$cd_path" ]; then
  cd_path="${cd_path%\"}"; cd_path="${cd_path#\"}"
  cd_path="${cd_path%\'}"; cd_path="${cd_path#\'}"
  cd_path="${cd_path%"${cd_path##*[![:space:]]}"}"   # rstrip trailing ws
  target_dir="$cd_path"
else
  # `git -C <path>` (path immediately follows the -C global flag).
  c_path=$(printf '%s' "$command_text" \
    | sed -n "s/.*git[[:space:]]\+-C[[:space:]]\+\(\"[^\"]*\"\|'[^']*'\|[^ ]\+\).*/\1/p" \
    | head -1)
  if [ -n "$c_path" ]; then
    c_path="${c_path%\"}"; c_path="${c_path#\"}"
    c_path="${c_path%\'}"; c_path="${c_path#\'}"
    target_dir="$c_path"
  fi
fi
# If the extracted dir doesn't resolve, fall back to the hook's own cwd.
[ -d "$target_dir" ] || target_dir="."

# ────────────────────────────────────────────────────────────────────────────
# Are we in a git working tree (at the resolved target dir)?
# ────────────────────────────────────────────────────────────────────────────
if ! git -C "$target_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Skip if mid-operation — rebase / merge / cherry-pick transient branch states
# would cause false positives.
# ────────────────────────────────────────────────────────────────────────────
git_dir=$(git -C "$target_dir" rev-parse --absolute-git-dir 2>/dev/null)
if [ -n "$git_dir" ]; then
  [ -f "$git_dir/REBASE_HEAD" ] && exit 0
  [ -f "$git_dir/MERGE_HEAD" ] && exit 0
  [ -f "$git_dir/CHERRY_PICK_HEAD" ] && exit 0
  [ -d "$git_dir/rebase-apply" ] && exit 0
  [ -d "$git_dir/rebase-merge" ] && exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Resolve default branch + current branch (both at the target dir)
# ────────────────────────────────────────────────────────────────────────────
default_branch=$(git -C "$target_dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
[ -z "$default_branch" ] && default_branch="main"

current_branch=$(git -C "$target_dir" branch --show-current 2>/dev/null)
# Detached HEAD or empty result — don't block
[ -z "$current_branch" ] && exit 0

# ────────────────────────────────────────────────────────────────────────────
# Per-repo opt-out: .claude/habeebs-allowed-branches (one branch per line)
# ────────────────────────────────────────────────────────────────────────────
repo_root=$(git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null)
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
