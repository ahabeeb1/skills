---
name: sync
description: Reconcile local default-branch with origin after a PR merge — auto-resolves squash-merge ghost-commit divergence and cleans up merged feature branches + worktrees. Delegates to using-worktrees Phase 6.5.
---

Invoke the `using-worktrees` skill from `skills/using-worktrees/SKILL.md`, jumping directly to **Phase 6.5 — Post-merge sync**.

What this does:

1. `git fetch origin --prune`
2. Resolve the default branch via `origin/HEAD`
3. Check local default-branch divergence (`ahead` / `behind` vs origin):
   - `ahead=0, behind=0` — already in sync, skip to cleanup.
   - `ahead=0, behind>0` — **simple fast-forward** (most common post-merge state). `git merge --ff-only origin/<default>`, then cleanup.
   - `ahead>0, behind=0` — real local-only work, **halt**.
   - `ahead>0, behind>0` — possible ghost commits; run detection (step 4).
4. **Ghost-commit detection** — for every local-only commit on the default branch, check tree-equivalence against recent origin commits. If every local commit has a tree-match in origin, it's a squash-merge ghost-commit case (safe to reset).
5. **Safe-reset** (only when step 4 confirms): `git reset --hard origin/<default>`, with a one-line announcement first.
6. **Cleanup merged feature branches** — for each local non-default branch reported as MERGED by `gh pr list` (or merged via fast-forward / rebase per `git branch --merged`), remove the worktree (if any), `git branch -d`, and `git push origin --delete` the remote.
7. `git worktree prune`.

Halt conditions (never auto-resolves; user must intervene):

- Local default-branch has `ahead>0, behind=0` — real local-only work.
- Any local-ahead commit has no tree-equivalent in origin — genuine divergence.
- A worktree contains uncommitted changes.
- A rebase / merge / cherry-pick is mid-operation.
- `git fetch` failed.
- Detached HEAD on the source checkout.

Optional flag: `/sync --squash-window=N` raises the origin-commit search window from the default 10 to `N`. Use when several PRs merged in quick succession.
