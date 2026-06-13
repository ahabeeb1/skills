---
description: Start a new feature in an isolated git worktree on a new branch with a verified test baseline. Delegates to the using-worktrees skill.
---

You are running the `using-worktrees` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/using-worktrees/SKILL.md` and follow it exactly.

Branch slug: $ARGUMENTS

If a slug was provided after `/worktree`, use it as the branch suffix. Otherwise, ask for one before creating the worktree.

After the worktree is ready, hand off to whatever skill the user invoked the worktree for (typically `tdd-loop`).
