---
name: using-worktrees
description: Isolate each feature, AFK slice, or experimental refactor in its own git worktree on its own branch, with a verified-clean test baseline before work starts and a clean teardown when work ends. Used by parallel-dev to dispatch AFK slices into separate worktrees (so concurrent subagents never fight over the same working tree), and used directly when starting any non-trivial multi-commit task. Inspired by Superpowers' using-git-worktrees + finishing-a-development-branch. Make sure to use this skill whenever the user says "let's work on a new feature", "start a branch", "let's experiment", before parallel-dev dispatches AFK slices, or whenever tdd-loop is about to begin a multi-commit slice. Do NOT use for trivial one-commit changes, for read-only investigation, when the user has explicitly opted out of worktrees, or when the host runtime cannot create worktrees (e.g., some sandboxed environments).
next-skills: [tdd-loop, parallel-dev]
---

# Using Worktrees

Every non-trivial piece of work gets its own git worktree on its own branch. The point isn't bookkeeping — it's that concurrent subagents in `parallel-dev` would otherwise race on the working tree, and a TDD session in progress shouldn't be polluted by a mid-stream merge from `main`.

This skill is the isolation primitive. It is consumed by `parallel-dev` and `tdd-loop`; it can also be invoked directly when a human (or agent) is starting a multi-commit feature.

## When to use this skill

**Trigger on:**

- `parallel-dev` is about to dispatch 2+ AFK slices (each goes into its own worktree)
- `tdd-loop` is about to start a slice that will take 2+ commits
- The user says "start a new branch / feature / experiment"
- The user wants to compare two approaches side-by-side (one worktree per approach)

**Do NOT trigger on:**

- Trivial single-commit changes (overhead exceeds the benefit)
- Read-only investigation / debugging without code changes
- Environments that don't support `git worktree` (some sandboxes)
- When the user has explicitly opted out (e.g., they prefer the single-tree workflow)

## Branching strategy

Worktrees are mechanical isolation; branching strategy is the policy on top. Both have to be right or the worktree is doing useless work.

### Hard rules (never violated by this skill)

1. **Never commit to the default branch** (`main` / `master` / `trunk` / `develop` — whatever the repo's `origin/HEAD` resolves to). Every change rides on a feature branch. If you're already on the default branch when this skill is invoked, that itself is a reason to create a worktree (see `tdd-loop` Phase 0).
2. **One worktree, one branch** (1:1). Never create two worktrees that share a branch — git refuses anyway, and the work patterns don't fit. Never reuse a branch for a second unrelated feature.
3. **Never nest worktrees.** If the current `cwd` is already inside a linked worktree (`git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`), do NOT create another. Reuse the existing worktree and skip to Phase 3 (Project Setup).
4. **`git branch -d`, never `-D`** unless the user has typed an explicit "yes, force-delete" confirmation. Force-delete on an unmerged branch silently loses commits.
5. **Push the branch before removing the worktree.** Always. Even if no PR yet — remote = backup.

### Branch naming

Default to **prefix + slug**:

| Kind of work | Prefix | Example |
|---|---|---|
| Feature / new behavior | `feature/` | `feature/rate-limiter-pg-bucket` |
| Bug fix | `fix/` | `fix/order-status-race` |
| Chore / refactor / infra | `chore/` | `chore/upgrade-prisma-5` |
| Docs only | `docs/` | `docs/clarify-adr-format` |
| Experimental spike | `spike/` | `spike/postgres-vs-redis-bench` |
| AFK slice from `parallel-dev` | `slice-<N>/` | `slice-2/rate-limit-middleware` |

Slug rules:
- lowercase, hyphen-separated, ≤6 words
- no issue numbers in the slug (they belong in the PR description)
- no usernames unless the team explicitly wants `<user>/<slug>` (Superpowers does this for solo work)

The skill checks the repo's existing branch names and adapts: if 80%+ of existing branches use a different convention (e.g., `<initials>/<slug>`), match the local convention rather than imposing the default.

### Linear history (rebase, not merge)

When syncing with the default branch DURING the feature (before PR):

```bash
git fetch origin
git rebase origin/<default-branch>
```

Never `git merge origin/main` into the feature branch. Merges create the "spaghetti history" pattern where reviewing the feature requires excluding merge commits. Rebases keep the feature linear and make `git log <branch> ^<default>` produce a clean list of just the feature's own commits.

If the rebase has conflicts:
- Resolve in the worktree (you have the test baseline from Phase 4 to verify nothing's drifted)
- Run the test suite after every conflict-resolution commit
- If conflicts are extensive (5+ files), halt and tell the user — the divergence may indicate the feature is now stale enough to warrant rethinking, not just rebasing

When merging the PR (at GitHub / GitLab / etc.): prefer **squash-and-merge** for slices/fixes and **rebase-and-merge** for features whose individual commits are meaningful (`tdd-loop`'s RED / GREEN / REFACTOR commits often are). Never use a merge commit on the default branch.

### One branch, one PR, one purpose

Each branch corresponds to exactly one PR. If a worktree's work grows mid-flight ("while I was here, I also fixed X"):
- Small detour, same problem area: include it, mention in the PR
- Different problem entirely: stop, create a SECOND worktree for the detour, return to the first

Stacked PRs (PR B depends on PR A) are OK if the runtime supports them, but each is still one branch.

### Lifecycle

```
[create worktree + branch]
        ↓
[work happens — possibly many commits]
        ↓
[rebase onto origin/<default>]
        ↓
[push branch]
        ↓
[open PR]
        ↓
[reviews + adjustments — more commits, periodic rebases]
        ↓
[merge via squash/rebase, never merge commit]
        ↓
[remove worktree (git worktree remove)]
        ↓
[delete branch (git branch -d <name>)]  ← safe delete; -D requires user confirmation
        ↓
[delete remote branch if it lingers (gh / git push origin --delete)]
```

Never abandon a worktree. Phase 6 of this skill enforces full teardown.

## Core workflow

### Phase 1 — Verify the source baseline is clean

Before creating a worktree, check the source branch is in a sane state:

```bash
git status --porcelain        # must be empty
git rev-parse HEAD            # capture current SHA for reference
<run project's test command>  # must pass
```

If `git status` shows uncommitted changes, halt: ask the user to commit, stash, or explicitly discard. **Never create a worktree on top of an unclean state** — bugs that surface in the new worktree are then ambiguous between "my new work" and "carried-over dirt."

If tests don't pass on the source, halt: ask the user whether to proceed (sometimes intentional — fixing the failing test IS the work) or fix first.

### Phase 2 — Create the worktree on a new branch

```bash
git worktree add <path> -b <branch-name>
```

Conventions (full details in the **Branching strategy** section above):

- **Path:** `../<repo-name>-<short-slug>` (e.g., `../skills-rate-limit-slice-1`) — sibling to the main checkout, not nested inside it
- **Branch:** prefix + slug per the strategy table (`feature/`, `fix/`, `chore/`, `docs/`, `spike/`, or `slice-<N>/` for parallel-dev). Match the repo's existing convention if it deviates from the default.
- **Base:** `origin/<default-branch>` (the resolved default — usually `main`). Never branch off another in-flight feature branch unless explicitly stacking.

**Nesting check (mandatory):** Before running `git worktree add`, verify you're not already inside a linked worktree:

```bash
[ "$(git rev-parse --git-dir)" = "$(git rev-parse --git-common-dir)" ] || \
  echo "Already in a linked worktree — skip to Phase 3"
```

If already nested, do NOT create another worktree. Proceed to Phase 3 in the current one.

Avoid path patterns inside `.git/` (worktrees stored there are fragile). Avoid nesting worktrees inside the source checkout (confuses tooling).

### Phase 3 — Run project setup in the worktree

Each worktree is a fresh checkout. Run whatever the project needs:

```bash
cd <path>
<package-manager install command>   # npm ci / pnpm i / pip install -r / bundle install / go mod download
<copy .env.example to .env>          # if applicable; never copy real .env
<run migrations / generate code>     # if the project requires it before tests
```

If setup fails, surface the error and halt — don't try to continue in a half-initialized worktree.

### Phase 4 — Verify clean test baseline in the worktree

Run the test suite in the worktree before any work starts:

```bash
<run project's test command>
```

If tests fail in the freshly-created worktree but passed in the source (Phase 1), something is wrong with the setup — usually a missing env var, an uncommitted migration, or a global resource (DB, port) that the source had primed. Halt and resolve.

If tests pass: the worktree is the trusted baseline. **Any failure from this point forward is attributable to the new work, not to the environment.**

### Phase 5 — Hand control to the consuming skill

Return the worktree path and branch name to whatever invoked this skill:

```
WORKTREE READY
  path:    ../skills-rate-limit-slice-1
  branch:  slice-1-rate-limit-pg-function
  base:    a3355f1
  clean:   tests passing as of <ISO timestamp>
```

`parallel-dev` consumes this to dispatch its subagent with `cwd=<path>`. `tdd-loop` consumes this to know where to run RED/GREEN/REFACTOR.

### Phase 6 — Finishing a development branch (when work is complete)

When the consuming skill reports its slice complete, this skill takes over teardown:

1. **Verify all commits land on the branch**
   ```bash
   cd <path>
   git status --porcelain     # must be empty (everything committed)
   git log <branch> ^<base>   # list of new commits — must be non-empty
   <run project's test command>  # must pass
   ```

2. **Rebase onto current `<base>` (usually `main`)**
   ```bash
   git fetch origin
   git rebase origin/<base>
   ```
   Resolve conflicts here, not after the merge. Re-run tests post-rebase.

3. **Push the branch**
   ```bash
   git push -u origin <branch>
   ```

4. **Open a PR** (if `gh` is available and the user agreed)
   ```bash
   gh pr create --base <base> --head <branch> --fill
   ```
   The PR description is auto-populated from the structured commit messages produced by `tdd-loop` and `parallel-dev`.

5. **Remove the worktree** (only after PR is open OR explicit user OK)
   ```bash
   cd <source-checkout>
   git worktree remove <path>
   git branch -D <branch>   # ONLY if PR is merged, never on local-only branches
   ```
   Default is to leave the worktree until the PR merges. The `git worktree remove` step needs explicit user confirmation if the branch hasn't been pushed.

## Anti-patterns this skill guards against

- **Working in the main checkout while subagents run in parallel.** Race condition guaranteed.
- **Creating a worktree on a dirty source.** Pollutes the new worktree with carried-over edits.
- **Skipping Phase 4 (baseline test run).** Any later failure becomes ambiguous.
- **Removing a worktree before the branch is pushed.** Loses commits.
- **`git branch -D` on an unmerged branch.** Loses commits silently.
- **Nesting worktrees inside the source checkout.** Confuses path-relative tooling.
- **Skipping the rebase before push.** Merge conflicts surface in PR review instead of in your local worktree.

## Integration with the chain

- **Consumed by `parallel-dev`** — each AFK slice subagent gets its own worktree (concurrent subagents never share a working tree)
- **Consumed by `tdd-loop`** — non-trivial multi-commit slices run in a worktree so the source checkout stays available for other work
- **Standalone** — humans can invoke `/worktree start <slug>` to begin a feature manually

## Compatibility notes

- Codex CLI honors `cwd` per command; worktrees work natively.
- Some sandboxed Claude Code modes restrict directory creation outside the project root. In those, fall back to single-branch sequential work and emit a one-line note.
- GitHub Actions runners and CI environments don't need this skill — they get a fresh checkout per job.

## See also

- `parallel-dev` — primary consumer; dispatches AFK slices into worktrees
- `tdd-loop` — consumer; runs RED/GREEN/REFACTOR inside a worktree
- `decision-record` — produces ADRs that may live on `main` regardless of the feature worktree (write directly to source checkout, not the worktree)
- Superpowers' `using-git-worktrees` + `finishing-a-development-branch` — the proven pattern this skill adapts
