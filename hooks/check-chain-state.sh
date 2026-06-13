#!/usr/bin/env bash
# habeebs-skill PostToolUse chain-state validator hook
#
# Purpose: warn (never block) when the user's edits indicate the habeebs-skill
# chain is in an inconsistent state. Surfaces drift at edit time so the user
# can correct course before commit.
#
# Per ADR-0003:
#   - Rule 1: warn-only, never block. Exit 0 always. Warnings to stderr.
#   - Rule 2: multi-harness aware (CLAUDE_PLUGIN_ROOT / CURSOR_PLUGIN_ROOT detection)
#   - Rule 3: stateless — file-existence-as-state per silent-contradiction-3
#             resolution. Reads frontmatter + git state; writes nothing.
#
# Scope (locked by v1.22.0 grill OQ-1):
#   (b) MISSING-GRILL — warn when a spec marked `Status: Grilled` has no
#       corresponding <slug>-grill.md file. Catches: spec advanced through the
#       chain without the grill record being committed.
#   (c) EDIT-ON-DEFAULT — warn when editing skills/, hooks/, or .claude-plugin/
#       on the default branch with uncommitted changes. Catches: starting a
#       new feature without creating a worktree.
#
# Rejected scopes (grill OQ-1 — for revisit triggers, see ADR):
#   (a) Missing spec when editing skills/ — false-positive prone, absent
#       branch-naming convention
#   (d) Stale plan Status fields — covered by Piece 5 release editorial scan
#
# Emergency disable: HABEEBS_DISABLE_HOOKS=1

set -u

# ─────────────────────────────────────────────────────────────────────────────
# Disable env var (per ADR-0003)
# ─────────────────────────────────────────────────────────────────────────────
if [ "${HABEEBS_DISABLE_HOOKS:-0}" = "1" ]; then
  exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# Are we in a git working tree?
# ─────────────────────────────────────────────────────────────────────────────
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -d "$REPO_ROOT/docs/agents" ] || exit 0   # not a habeebs-skill-configured repo

# ─────────────────────────────────────────────────────────────────────────────
# Resolve the default branch (multi-harness aware)
# ─────────────────────────────────────────────────────────────────────────────
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
default_branch="${default_branch:-main}"

current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

# ─────────────────────────────────────────────────────────────────────────────
# Scope (b): MISSING-GRILL drift detection
#
# Scan docs/agents/specs/*.md for files with `Status: Grilled` frontmatter and
# verify the corresponding <slug>-grill.md file exists.
# ─────────────────────────────────────────────────────────────────────────────
warned=0
details=""

specs_dir="$REPO_ROOT/docs/agents/specs"
if [ -d "$specs_dir" ]; then
  for spec in "$specs_dir"/*.md; do
    [ -f "$spec" ] || continue
    base=$(basename "$spec" .md)
    # Skip grill records themselves
    case "$base" in
      *-grill) continue ;;
    esac

    # Look for `Status: Grilled` (PascalCase, YAML or markdown-emphasis form)
    # Only check the first 30 lines (frontmatter region)
    if head -30 "$spec" 2>/dev/null | grep -qE '^(Status|[*][*]Status[*][*]):.*Grilled'; then
      grill_file="$specs_dir/${base}-grill.md"
      if [ ! -f "$grill_file" ]; then
        warned=1
        details="${details}  - spec ${spec#$REPO_ROOT/} is Status: Grilled but ${grill_file#$REPO_ROOT/} is missing\\n"
      fi
    fi
  done
fi

# ─────────────────────────────────────────────────────────────────────────────
# Scope (c): EDIT-ON-DEFAULT detection
#
# Three stateless signals:
#   1. Current branch IS the default branch
#   2. Working tree has uncommitted changes touching skills/, hooks/, or
#      .claude-plugin/
#   3. (implicit) The hook fires after an edit — so by the time we're here,
#      the edit landed
# ─────────────────────────────────────────────────────────────────────────────
if [ -n "$current_branch" ] && [ "$current_branch" = "$default_branch" ]; then
  # Check for uncommitted changes in load-bearing paths. The pattern matches
  # both modified-tracked (`^.M? `) and brand-new untracked (`^?? `) files, so a
  # freshly-Written file in skills/ on the default branch is also caught.
  if git status --porcelain 2>/dev/null | grep -qE '^(.M?|\?\?) (skills/|hooks/|\.claude-plugin/)'; then
    warned=1
    details="${details}  - editing skills/, hooks/, or .claude-plugin/ on default branch ($default_branch) with uncommitted changes\\n    consider: git stash + worktree on a feature branch (see using-worktrees)\\n"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Emit collected warnings as hookSpecificOutput.additionalContext.
#
# Per the hook contract, PostToolUse stderr/stdout on exit 0 is debug-log-only;
# warnings the model should see must travel via hookSpecificOutput. Exit stays 0
# (warn-only per ADR-0003 — this hook never blocks).
# ─────────────────────────────────────────────────────────────────────────────
if [ "$warned" -eq 1 ]; then
  msg="habeebs-skill chain-state warning:\\n${details}  (HABEEBS_DISABLE_HOOKS=1 disables this check.)"
  msg_escaped=$(printf '%s' "$msg" | sed 's/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"[habeebs-skill] %s"}}\n' "$msg_escaped"
fi

# Exit 0 always — warn-only per ADR-0003
exit 0
