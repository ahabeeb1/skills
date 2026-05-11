---
name: worktree
description: Start a new feature in an isolated git worktree on a new branch with a verified test baseline. Delegates to the using-worktrees skill.
---

Invoke the `using-worktrees` skill from `skills/using-worktrees/SKILL.md`.

If the user provided a slug after `/worktree`, use it as the branch suffix. Otherwise, ask for one before creating the worktree.

After the worktree is ready, hand off to whatever skill the user invoked the worktree for (typically `tdd-loop`).
