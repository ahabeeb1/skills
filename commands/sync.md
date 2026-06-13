---
description: Reconcile local default-branch with origin after a PR merge — auto-resolves squash-merge ghost-commit divergence and cleans up merged feature branches + worktrees. Delegates to using-worktrees Phase 6.5.
---

You are running the `using-worktrees` skill from habeebs-skill, jumping directly to **Phase 6.5 — Post-merge sync**.

Read `${CLAUDE_PLUGIN_ROOT}/skills/using-worktrees/SKILL.md` § "Phase 6.5" and follow it exactly — it is the single source for the sync steps, the tree-equivalence ghost-commit detection, and the halt conditions (do not re-derive them here; this command is a thin entry point).

In short: fetch + prune, resolve the default branch, fast-forward or safe-reset only when every local-ahead commit has a tree-match in origin (the squash-merge ghost-commit case), then clean up merged feature branches + worktrees. It **halts** rather than auto-resolving on genuine local-only work, a non-matching local commit, a dirty worktree, a mid-operation rebase/merge, a failed fetch, or detached HEAD.

Arguments: $ARGUMENTS

Optional flag: `/sync --squash-window=N` (parsed from `$ARGUMENTS`) raises the origin-commit search window from the default 10 to `N`. Use when several PRs merged in quick succession.
