---
name: using-worktrees
description: Isolate features and AFK slices in their own git worktrees on their own branches. Use when user says "let's work on a new feature", "start a branch", "let's experiment", before parallel-dev AFK dispatch, or when tdd-loop starts a multi-commit slice. Do not use for trivial one-commit changes or read-only investigation.
---

# Using Worktrees

**ONE WORKTREE, ONE BRANCH. NEVER NEST.**

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
- no usernames unless the team explicitly wants `<user>/<slug>` for solo work

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
        ↓
[Phase 6.5 — post-merge sync]   ← reconciles local default-branch with origin's squash,
                                   detects ghost commits, cleans up other merged branches
```

Never abandon a worktree. Phase 6 enforces full teardown; Phase 6.5 reconciles the local repo with origin after the merge actually lands.

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

### Phase 6.5 — Post-merge sync (squash-merge ghost-commit cleanup)

After a PR is **squash-merged** on origin, the local default branch carries the original feature commits whose *content* is now duplicated by origin's squash commit. `git pull origin <default>` then conflicts on every release. This sub-phase auto-resolves the divergence — but only when it's unambiguously a squash-ghost case. Genuine local-ahead work always halts.

**Triggers:**

- Immediately after step 5 of Phase 6, once the PR has been merged on origin
- Start of any subsequent chain run when `git fetch origin` reveals default-branch divergence
- Direct invocation via `/sync`

**Workflow:**

1. **Fetch + prune**
   ```bash
   git fetch origin --prune
   ```

2. **Resolve the default branch**
   ```bash
   default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
   ```
   If `origin/HEAD` is unset, fall back to `main` and emit a one-line note.

3. **Check default-branch divergence**
   ```bash
   git checkout "$default_branch"
   ahead=$(git rev-list --count origin/"$default_branch"..HEAD)
   behind=$(git rev-list --count HEAD..origin/"$default_branch")
   ```
   - `ahead=0, behind=0`: already in sync. Skip to step 6.
   - `ahead=0, behind>0`: **simple fast-forward** — local is behind, no local-only commits. Run `git merge --ff-only origin/"$default_branch"` and proceed to step 6. This is the most common state after a PR is merged on origin and no other local work has happened on the default branch.
   - `ahead>0, behind=0`: local has work origin doesn't. **Halt** — this is real local-only work the user must push or discard; never auto-reset it.
   - `ahead>0, behind>0`: divergence with ghost-commit possibility. Run step 4 (ghost-commit detection).

4. **Ghost-commit detection (the heart of the sub-phase)**

   For each local-ahead commit (from `git log origin/"$default_branch"..HEAD --format=%H`), compare its tree to recent origin commits:
   ```bash
   for c in $(git log origin/"$default_branch"..HEAD --format=%H); do
     local_tree=$(git rev-parse "$c^{tree}")
     matched=
     for o in $(git log origin/"$default_branch" -n 10 --format=%H); do
       if [ "$(git rev-parse "$o^{tree}")" = "$local_tree" ]; then
         matched="$o"; break
       fi
     done
     if [ -z "$matched" ]; then
       echo "UNMATCHED: $c (no tree-equivalent in origin)"; UNMATCHED=1
     else
       echo "GHOST: $c ↔ $matched"
     fi
   done
   ```
   - **Every local-ahead commit has a tree-match** → safe ghost-commit case. Proceed to step 5.
   - **Any local-ahead commit has no tree-match** → genuine local divergence. **Halt**, list the unmatched commits, instruct the user.

   The `-n 10` window covers typical squash-merge cases; raise via `/sync --squash-window=N` if needed.

5. **Safe-reset (only when step 4 confirms ghost-commit case)**

   Print a one-liner before resetting so the user sees what's about to happen:
   ```
   Detected N ghost commits from squash-merge. Origin contains the same content.
   Resetting local <default_branch> → origin/<default_branch>.
   ```
   Then:
   ```bash
   git reset --hard origin/"$default_branch"
   ```
   The reset is destructive in principle but safe here because every local-only commit's content is preserved in origin's squash.

6. **Cleanup merged feature branches**

   For each local branch other than `$default_branch`:
   ```bash
   for b in $(git branch --format='%(refname:short)' | grep -v "^$default_branch\$"); do
     # Prefer gh; fall back to ancestry check.
     merged=
     if command -v gh >/dev/null 2>&1; then
       state=$(gh pr list --state merged --head "$b" --json number,state -q '.[0].state' 2>/dev/null)
       [ "$state" = "MERGED" ] && merged=1
     fi
     if [ -z "$merged" ] && git branch --merged origin/"$default_branch" | grep -q "^[ *]*$b\$"; then
       merged=1   # fast-forward / rebase merge; misses squash but harmless when ghost-reset already ran in step 5
     fi
     [ -z "$merged" ] && continue

     # Worktree first (must precede branch delete).
     wt=$(git worktree list --porcelain | awk -v b="$b" '$1=="worktree"{p=$2} $1=="branch" && $2=="refs/heads/" b {print p}')
     [ -n "$wt" ] && git worktree remove "$wt"

     git branch -d "$b"                     # safe-delete; -D never
     git push origin --delete "$b" 2>/dev/null || true   # no-op if already deleted
   done
   ```

7. **Prune stale worktree records**
   ```bash
   git worktree prune
   ```

8. **One-line summary**
   ```
   Synced <default_branch> ← origin (reset N ghost commits). Cleaned M merged branch(es).
   ```

**Halt conditions (never auto-resolve):**

- Step 3 found `ahead>0, behind=0` (local-only work without remote advancement)
- Step 4 found a commit with no tree-match in origin (genuine local divergence)
- A worktree contains uncommitted changes (would lose work) — refuse `git worktree remove`
- Mid-operation state present: `.git/MERGE_HEAD`, `.git/REBASE_HEAD`, `.git/CHERRY_PICK_HEAD`, or `.git/rebase-apply/`
- `git fetch` failed (no network / auth issue) — Phase 6.5 must wait
- Detached HEAD on the source checkout — halt and ask user to switch

On any halt, print the diagnosis + the local-only commit list + instructions on next steps. Never destroy work.

## Anti-patterns this skill guards against

- **Working in the main checkout while subagents run in parallel.** Race condition guaranteed.
- **Creating a worktree on a dirty source.** Pollutes the new worktree with carried-over edits.
- **Skipping Phase 4 (baseline test run).** Any later failure becomes ambiguous.
- **Removing a worktree before the branch is pushed.** Loses commits.
- **`git branch -D` on an unmerged branch.** Loses commits silently.
- **Nesting worktrees inside the source checkout.** Confuses path-relative tooling.
- **Skipping the rebase before push.** Merge conflicts surface in PR review instead of in your local worktree.
- **Manually fighting squash-merge ghost commits.** If `git pull origin <default>` conflicts after a PR merge, run Phase 6.5 (or `/sync`) rather than resolving the conflict by hand. The ghost commits' content is already on origin; manual resolution risks introducing real drift.
- **Auto-resetting on `ahead>0, behind=0`.** That signals genuine local-only work; resetting would lose it. Phase 6.5 halts in that case by design.

## Hazards from git itself (not this skill's fault, but this skill is where you find out)

Three git-worktree behaviors surprise multi-worktree users and have caused real conflicts in habeebs-skill's parallel-dev workflows. None are bugs in this skill, but this skill is where users go to figure out why their worktrees collided — so the warnings live here.

### Shared config across worktrees (the `extensions.worktreeConfig` footgun)

By default, git stores config in one place per repository — every worktree reads and writes the same `config` file. If one worktree (or one subagent) runs `git config core.sparseCheckout true`, every other worktree on the same repo inherits that setting on its next git operation. The official git docs name this directly: `core.worktree`, `core.bare`, and `core.sparseCheckout` "should never be shared" without enabling per-worktree config.

The fix is a one-time per-repo opt-in:

```bash
git config extensions.worktreeConfig true
```

After that, each worktree has its own `config.worktree` file under its `.git` directory, and the three config keys above are read from there in priority order. **Run this on first repo setup, not per-worktree** — it changes how git resolves config repo-wide.

Two pragmatic rules while this is opt-in:

- **Never run `git config core.*` from inside a parallel-dev subagent's worktree.** The mutation leaks to every peer. If a subagent needs a config change, the dispatcher sets it before Phase 4 and re-evaluates afterward.
- **Treat `git config --local` as repo-wide, not worktree-local,** unless you've confirmed `extensions.worktreeConfig` is on. The `--local` flag is named misleadingly relative to worktrees.

### Manual `rm -rf` of a worktree dir leaves stale refs

`git worktree remove <path>` is not equivalent to `rm -rf <path>`. The former cleans up the worktree's entry in `.git/worktrees/<name>` and the gitdir pointer; the latter leaves both behind. Orphaned entries surface later as:

```
fatal: '<branch>' is already checked out at '<deleted-path>'
```

…even though the path no longer exists. Recovery is `git worktree prune` (drops stale entries) followed by deleting the branch by name. Easy to misdiagnose because the error message names a path that no longer exists, so grepping for it finds nothing.

Phase 6 of this skill always uses `git worktree remove`. If you (or another agent) reached for `rm -rf` between sessions, run `git worktree prune` before any new `git worktree add`.

### One branch, one worktree, period

Git refuses to check out the same branch in two worktrees simultaneously:

```
fatal: '<branch>' is already checked out at '<other-worktree-path>'
```

There is no force flag — the constraint is structural (two worktrees on one branch would race the index). If you want two worktrees with the same starting point, give them different branches off the same base (`git worktree add ../wt-a -b feature/a origin/main` + `git worktree add ../wt-b -b feature/b origin/main`).

For cross-session parallel work, this constraint is doing useful work: it forces session-per-branch isolation. Don't try to work around it.

**Source:** [`git-worktree(1)`](https://git-scm.com/docs/git-worktree) — the BUGS and CONFIGURATION FILES sections cover all three.

## Integration with the chain

- **Consumed by `parallel-dev`** — each AFK slice subagent gets its own worktree (concurrent subagents never share a working tree)
- **Consumed by `tdd-loop`** — non-trivial multi-commit slices run in a worktree so the source checkout stays available for other work
- **Standalone** — humans can invoke `/worktree start <slug>` to begin a feature manually
- **Standalone sync** — humans can invoke `/sync` after any PR merge to reconcile local default-branch with origin and clean up merged feature branches; jumps directly to Phase 6.5

## Compatibility notes

- Codex CLI honors `cwd` per command; worktrees work natively.
- Some sandboxed Claude Code modes restrict directory creation outside the project root. In those, fall back to single-branch sequential work and emit a one-line note.
- GitHub Actions runners and CI environments don't need this skill — they get a fresh checkout per job.

## See also

- `parallel-dev` — primary consumer; dispatches AFK slices into worktrees
- `tdd-loop` — consumer; runs RED/GREEN/REFACTOR inside a worktree
- `decision-record` — produces ADRs that may live on `main` regardless of the feature worktree (write directly to source checkout, not the worktree)
- [`using-habeebs-skill` § Aborting the chain](../using-habeebs-skill/SKILL.md) — when a chain abort triggers worktree teardown, follow Phase 6 from this skill (no destructive ops beyond user-confirmed `git worktree remove`)
