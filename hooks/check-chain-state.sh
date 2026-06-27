#!/usr/bin/env bash
# habeebs-skill PostToolUse chain-state validator hook
#
# Purpose: warn (never block) when the user's edits indicate the habeebs-skill
# chain is in an inconsistent state. Surfaces drift at edit time so the user
# can correct course before commit.
#
# Per ADR-0003:
#   - Rule 1: warn-only, never block. Exit 0 always. Warnings to stderr.
#   - Rule 2: multi-harness aware (Claude Code / Cursor / Codex CLI — bundle root
#             via hooks/lib/resolve-bundle-root.sh; this script self-locates and
#             needs no harness-specific env var)
#   - Rule 3: stateless — file-existence-as-state per silent-contradiction-3
#             resolution. Reads frontmatter + git state; writes nothing.
#
# Scope:
#   (b) UNGRILLED-SIGNOFF — warn when a Design (`*-design.md`) marked
#       `Status: Signed-off` still has an empty Decided section (the
#       `_(none yet` placeholder). Catches: a Design signed off without the
#       grill writing the resolved decisions back into it.
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
# Scope (b): UNGRILLED-SIGNOFF drift detection
#
# Scan docs/agents/specs/*-design.md for Designs marked `Status: Signed-off`
# whose Decided section is still the empty placeholder (`_(none yet`). A signed-off
# Design with no recorded decisions means the grill never wrote its resolutions
# back into the Design — the chain advanced past the sign-off gate empty.
# ─────────────────────────────────────────────────────────────────────────────
warned=0
details=""

specs_dir="$REPO_ROOT/docs/agents/specs"
if [ -d "$specs_dir" ]; then
  for design in "$specs_dir"/*-design.md; do
    [ -f "$design" ] || continue

    # Look for `Status: Signed-off` (PascalCase, YAML or markdown-emphasis form)
    # in the frontmatter region (first 30 lines).
    if head -30 "$design" 2>/dev/null | grep -qE '^(Status|[*][*]Status[*][*]):.*Signed-off'; then
      # Decided section still carries the empty placeholder?
      if grep -qE '_\(none yet' "$design" 2>/dev/null; then
        warned=1
        details="${details}  - Design ${design#$REPO_ROOT/} is Status: Signed-off but its Decided section is still empty (grill resolutions not written back)\\n"
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
