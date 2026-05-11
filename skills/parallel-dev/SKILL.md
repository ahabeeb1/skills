---
name: parallel-dev
description: Dispatches parallel subagents for independent work. Used internally by prior-art-research Deep mode (one subagent per sub-problem) and by vertical-slice (one subagent per AFK slice). Also user-invokable for parallel refactor passes, parallel codebase exploration, or any batch of work where the pieces don't share state or order dependencies. Make sure to use this skill whenever the work can be decomposed into independent units that benefit from concurrent execution — but only after verifying independence (no shared mutable state, no ordering requirements, no file conflicts). Inspired by Superpowers' subagent-driven-development and OMC's ralph/team/ultrawork. Do NOT use for sequential work, for tasks where order matters, for work touching the same files, or when the cost of coordination exceeds the parallelism gain.
next-skills: [using-worktrees, tdd-loop]
---

# Parallel Dev

Orchestration primitive for parallel subagent dispatch. The art is in proving independence BEFORE dispatch — failures of independence become hard-to-debug merge conflicts, race conditions, or duplicated work.

## When to use this skill

**Trigger on:**

- `prior-art-research` enters Deep mode (one subagent per sub-problem to research)
- `draft-spec` produces a "Parallelizable group" of AFK slices
- The user requests a batch operation across files / modules ("update all docstrings", "audit all API endpoints", "fix all TypeScript errors")
- Codebase exploration where multiple areas can be investigated independently
- The user invokes `/parallel` explicitly

**Do NOT trigger on:**

- Sequential work (slice #2 depends on slice #1 — run them in order)
- Work touching the same files (merge conflicts, lost updates)
- HITL slices (each needs a human checkpoint — parallelism doesn't compose with that)
- Tasks where the cost of coordination + verification exceeds the time saved
- Single-task work (parallelism overhead is wasted)

## Core workflow

### Phase 1 — Decompose

Identify the units of work. Each unit should:

- Have a clearly bounded input
- Produce a bounded, named output
- Be implementable in a single subagent turn (or 1-3 turns with constrained scope)

If a unit doesn't fit, decompose it further OR remove it from the parallel batch.

### Phase 2 — Verify independence

This is the make-or-break phase. For each pair of units (A, B), check:

1. **File overlap.** Do A and B write to any shared file? If yes, NOT independent — they'll conflict.
2. **State dependency.** Does A's output feed B's input? If yes, sequence them, don't parallelize.
3. **Resource contention.** Do A and B compete for a constrained resource (a DB connection pool, a rate-limited API)? Maybe parallel still works, but cap concurrency.
4. **Ordering semantics.** Does the order in which A and B complete affect correctness? If yes, NOT independent.
5. **Implicit shared state.** Environment variables, global config, mutated singletons. Often the source of subtle bugs.

If ANY pair fails independence, either:
- Split the failing pair into a sequential phase, OR
- Restructure the work so the dependency is removed, OR
- Don't parallelize this batch

Document the independence check in the dispatch record. If you're uncertain, prefer sequential — the cost of a wrong dispatch is high.

### Phase 3 — Compose the dispatch

For each subagent, produce a complete spec:

```
SUBAGENT N: <name>
  Task:        <what to do, in 1-3 sentences>
  Input:       <files / data / context the subagent needs>
  Output:      <exact deliverable location/format>
  Constraints: <what NOT to touch>
  Verification: <how the dispatcher will know the subagent succeeded>
  Commit:      <required for any subagent that produces persistent artifacts; see "Commit discipline" below>
```

The spec should be self-contained. The subagent should not need to ask clarifying questions — if it does, the spec was incomplete.

#### Commit discipline (required for any subagent that writes to the repo)

Every subagent that produces a persistent artifact (code, migration, ADR, spec, slice file, doc) **MUST commit its own work** before returning. Returning a text blob that the parent has to interpret-and-write is forbidden — too lossy, too easy to silently drop, breaks `git blame`.

Each subagent commit message follows this shape:

```
<dispatch-id>/<subagent-name>: <one-line description>

Dispatched-by: parallel-dev
Dispatch-id:   <ulid or short hash from Phase 4>
Subagent:      <name>
Slice:         #N from <spec-path>   (if applicable)
Parent-task:   <one line of why this work exists>

What this commit does:
- <change 1>
- <change 2>

What this commit does NOT do:
- <intentionally deferred>
```

The subagent returns its commit SHA(s) to the dispatcher. The dispatch record (Phase 6) captures all SHAs so the run is fully replayable via `git log --grep="Dispatch-id: <id>"`.

**Research subagents** (those producing structured records to be aggregated into the parent's synthesis, not files in the repo) are exempt — the parent commits the final synthesized output once aggregation completes.

### Phase 4 — Dispatch

For **artifact-producing subagents** (those that will commit to the repo), invoke the `using-worktrees` skill ONCE per subagent BEFORE dispatch. Each subagent gets its own worktree path + branch and is invoked with `cwd=<worktree-path>`. Concurrent subagents must never share a working tree — that is the most common silent failure of parallel dispatch.

For **research subagents** (those returning structured records without writing files), worktrees are not needed; dispatch them in the source checkout.

Launch all subagents in the same turn. (In Claude Code, this is one tool-call message with N spawn requests. In OMC, this is `omc team N:claude "..."` or equivalent. In Cowork, this is the parallel subagent API.)

Why same turn: dispatching one at a time defeats the purpose. Some agent runtimes treat sequential dispatch as cheating — verify your runtime supports concurrent spawn.

### Phase 5 — Wait and collect

While subagents run, the dispatcher is idle (or can do bookkeeping). When notifications arrive:

- Capture timing per subagent (`duration_ms`, `total_tokens`) — this is the only chance
- **Capture commit SHA(s) returned by each artifact-producing subagent** — these populate the dispatch record's audit trail
- Verify each subagent's output against its spec's verification step
- Note any subagent that failed, returned partial results, or deviated from spec

**Don't lose partial successes.** If 4 of 5 subagents succeeded, keep their work (the commits are already in the tree). Re-dispatch only the failed one with a clearer spec (or fall back to sequential).

### Phase 6 — Aggregate and synthesize

Combine outputs. For research-style dispatches, this is a synthesis step (one pattern-extractor subagent can also handle this — see `agents/synthesizer.md`). For implementation-style dispatches, this is a merge step (run tests after merging; resolve conflicts if any).

### Phase 7 — Verify the whole

After aggregation, run the full verification:

- Tests still pass? (For implementation dispatches)
- Synthesis is coherent? (For research dispatches)
- No subagent's output contradicts another's?

If verification fails, the parallel dispatch saved nothing — and may have cost extra in tokens and complexity. Note this in the dispatch record for future calibration.

## Independence checklist (Phase 2 expanded)

Quick decision matrix for the most common cases:

| Work shape | Likely independent? | Notes |
|---|---|---|
| Research: each subagent fetches a different source | Yes | No shared state; output is per-subagent |
| Refactor: each subagent works on a separate module's tests | Usually | Check for shared test fixtures |
| Refactor: each subagent works on a separate module's code | Maybe | Check for shared types/exports |
| Bug fix: each subagent fixes a different bug in the same file | NO | File overlap |
| Implementation: each subagent implements a different AFK slice | Yes if slices are truly vertical | Re-check the slice independence |
| Doc generation: each subagent generates docs for a different module | Usually | Check that they're not all writing to the same index |
| Migration: each subagent migrates a different table | Usually | Check that they don't share foreign-key dependencies in the migration step |

## Anti-patterns this skill guards against

- **Parallelizing because we can.** Parallelism has overhead — coordination, verification, merge. If the units are small or the coordination is large, parallel is slower than sequential.
- **Skipping independence verification.** Most failures of `parallel-dev` are failures of Phase 2. Take the time.
- **Losing partial successes.** If 4 of 5 subagents succeed and 1 fails, don't throw away the 4. Re-dispatch only the failed one.
- **Letting subagents share mutable state through the filesystem.** Two subagents writing to the same .md file = one of them loses. Two subagents both running `npm install` = race on `package-lock.json`.
- **Specifying tasks loosely.** "Improve the auth code" is not a subagent spec. "Add a unit test at path/X covering case Y; do not modify anything else" is.
- **Forgetting to capture timing/tokens.** This is your only signal about whether the parallel dispatch was worth it. Future calibration depends on it.

## When to fall back to sequential

These signs say "parallel isn't right here, run sequentially":

- More than half the pairs in Phase 2 show some form of dependency
- The work is small (< 30 sec per unit) — overhead dominates
- The verification step would be more expensive than the work itself
- The work generates large outputs that aggregation can't easily merge
- The user wants visibility into intermediate steps (parallel hides progress)

## Integration with the chain

- **Used by `prior-art-research`** in Deep mode — one subagent per sub-problem, plus a synthesizer subagent that aggregates findings
- **Used by `vertical-slice` / `draft-spec`** — AFK slices marked "Parallelizable" run concurrently here
- **Standalone** for batch refactors, audits, doc generation

## See also

- `prior-art-research` — primary consumer in Deep mode
- `draft-spec` — produces parallelizable slice groups
- `tdd-loop` — what each subagent runs internally when implementing a slice
- `agents/source-fetcher.md` — subagent prompt for research fetching
- `agents/pattern-extractor.md` — subagent prompt for research extraction
- `agents/synthesizer.md` — subagent prompt for aggregating parallel results
- `references/dispatch-record-template.md` — template for capturing a parallel dispatch
