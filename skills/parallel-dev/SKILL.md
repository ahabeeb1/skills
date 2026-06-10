---
name: parallel-dev
description: Dispatch parallel subagents for verified-independent work. Use when user says "do these N in parallel", "fan these out", "run these batches concurrently", types "/parallel", or when prior-art-research / tdd-loop has a pgroup of size ≥2. Do not use for sequential work or tasks touching the same files.
disable-model-invocation: true
---

# Parallel Dev

Orchestration primitive for parallel subagent dispatch. The art is in proving independence BEFORE dispatch — failures of independence become hard-to-debug merge conflicts, race conditions, or duplicated work.

## When to use this skill

**Trigger on:**

- `prior-art-research` enters the Deep tier (one subagent per sub-problem to research)
- `draft-spec` produces a "Parallelizable group" of AFK slices
- The user requests a batch operation across files / modules ("update all docstrings", "audit all API endpoints", "fix all TypeScript errors")
- Codebase exploration where multiple areas can be investigated independently
- The user invokes `/parallel` explicitly

**Do NOT trigger on:**

- Sequential work (slice #2 depends on slice #1 — run them in order)
- Work touching the same files (merge conflicts, lost updates)
- `HITL:inline` or `HITL:approval-gate` slices (each needs a human checkpoint — parallelism doesn't compose with that). Only `AFK:full-auto` slices are eligible for parallel dispatch.
- Tasks where the cost of coordination + verification exceeds the time saved
- Single-task work (parallelism overhead is wasted)

## Task class — read vs write

Two production literatures disagree on multi-agent fan-out, and the split lines up with the two kinds of work this skill dispatches. Classify the batch before Phase 1; the answer changes which downstream phases are mandatory.

**Read-task dispatch.** Subagents fetch information, extract patterns, audit, or otherwise *read* shared substrate and return structured records the parent aggregates. No subagent writes to the repo. Research-shaped tasks see ~90% lift at ~15× the token cost of a single-agent equivalent — the cost is real, the gain is real, the merge-conflict surface is zero because nothing is written. Examples: `prior-art-research` Phase 4-5 source-fetchers, `pattern-extractor` runs, audit-style dispatches.

**Write-task dispatch.** Subagents commit artifacts (code, ADRs, slices, docs) to the repo. Parallel writers without isolation diverge irrecoverably: actions carry implicit decisions, and conflicting decisions carry bad results. This skill makes the failure mode survivable by enforcing three gates simultaneously — none of which are optional for write tasks:

1. **Per-worktree isolation** — every artifact-producing subagent runs in its own `git worktree` on its own branch, via `using-worktrees` invoked once per subagent before dispatch. Phase 4 already requires this.
2. **≤8 concurrent dispatches** — the existing 5-default concurrency cap (Phase 4) and the per-pgroup ceiling of 8 (the empirical maximum across Cursor's parallel-agent mode and the appxlab 5-7 ceiling). Overrides above 8 are forbidden, not just discouraged — past that point reviewer burden has been shown to exceed parallelism gain in every published case.
3. **Phase 2 independence verification, mandatory** — file overlap, state dependency, ordering semantics. For read tasks Phase 2 is hygiene; for write tasks it is the load-bearing failure-prevention step. Skipping Phase 2 on a write dispatch is the most common silent cause of `parallel-dev` failures.

If a write dispatch cannot honor all three, **fall back to sequential**. The cost of a wrong write dispatch is high and not always recoverable from the dispatch record alone.

**Hybrid dispatches are not a category.** A pgroup either writes to the repo or it doesn't. If some subagents write and some read, treat the entire pgroup as a write dispatch (the stricter rule wins).

## Sources for this section

- [Anthropic — Built a multi-agent research system](https://www.anthropic.com/research/built-a-multi-agent-research-system) — read-task efficacy + 15× token cost
- [Cognition — Don't build multi-agents](https://cognition.ai/blog/dont-build-multi-agents) — write-task anti-pattern

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

For each subagent, produce a complete spec. The canonical input shape (formal JSON schema in `references/dispatch-record-template.md`) is:

```
SUBAGENT N: <name>
  dispatch_id:      <ulid or short hash from Phase 4>
  subagent_name:    <name>
  task:             <what to do, in 1-3 sentences>
  input_files:      <[paths] the subagent reads>
  output_path:      <exact deliverable location, when applicable>
  constraints:      <[what NOT to touch]>
  verification:     <how the dispatcher will know the subagent succeeded>
  worktree_path:    <required for artifact-producing subagents; see Phase 4>
  branch:           <required for artifact-producing subagents; see Phase 4>
  context_preamble: <REQUIRED — full content of docs/agents/SYSTEM_CONTEXT.md
                    injected into the subagent's prompt so subagents inherit
                    the parent's environment binding rather than re-running
                    Phase 0 reconnaissance>
  commit:           <required for any subagent that produces persistent artifacts; see "Commit discipline" below>
```

The spec should be self-contained. The subagent should not need to ask clarifying questions — if it does, the spec was incomplete (which is a `STATUS: NEEDS_CONTEXT` return per the contract in `## Return contract` below).

**Context preamble is mandatory.** Without it, subagents drift from the parent's environment binding, re-run Phase 0 reconnaissance, and burn tokens for no reason. The dispatcher reads `docs/agents/SYSTEM_CONTEXT.md` once and injects the content into every subagent's input.

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

#### Pre-dispatch goal-clarity gate

Before Phase 4, re-read each subagent spec and answer two yes/no questions:

1. **Is success unambiguous?** Name the deliverable concretely — an exact file path, a named return field, or a one-sentence claim. If you can only restate the task ("the auth code is improved"), the spec failed Q1. Put the concrete name into the spec, then re-answer.
2. **Is verification one-turn resolvable?** Name the single inspection step that confirms success — `git diff <path>`, the value at `result.commit_sha`, the existence of a file at the output path. If verification needs three reads against an unwritten rubric, rewrite `verification` until it names one.

Both questions must produce a concrete name, not a yes/no. A `NEEDS_CONTEXT` return is a missed gate here, not a subagent failure — don't dispatch until both names exist in the spec.

### Phase 4 — Dispatch

For **artifact-producing subagents** (those that will commit to the repo), invoke the `using-worktrees` skill ONCE per subagent BEFORE dispatch. Each subagent gets its own worktree path + branch and is invoked with `cwd=<worktree-path>`. Concurrent subagents must never share a working tree — that is the most common silent failure of parallel dispatch.

For **research subagents** (those returning structured records without writing files), worktrees are not needed; dispatch them in the source checkout.

Launch all subagents in the same turn. (In Claude Code, this is one tool-call message with N spawn requests. In OMC, this is `omc team N:claude "..."` or equivalent. In Cowork, this is the parallel subagent API.)

Why same turn: dispatching one at a time defeats the purpose. Some agent runtimes treat sequential dispatch as cheating — verify your runtime supports concurrent spawn.

**Concurrency cap:** default 5; per-pgroup override via opt-in `concurrency: <N>` field in the pgroup labeling (see `write-plan` Phase 4). The 5-default comes from appxlab's empirical 5-7 ceiling for concurrent coding agents — past that, review burden offsets parallelism gain. Override sparingly; pgroups that need >5 concurrent subagents often have a Phase 2 independence problem in disguise.

**Hard ceiling for write-task dispatches: 8.** Per the "Task class" section above, write dispatches (artifact-producing subagents) must not exceed 8 concurrent — overrides above 8 are forbidden. Read-task dispatches (research / pattern-extraction / audit) may go higher if independence is provable, but the practical ceiling is the runtime's spawn cap and your tolerance for the ~15× token multiplier Anthropic measured.

### Single-writer invariant for SYSTEM_CONTEXT.md

`docs/agents/SYSTEM_CONTEXT.md` is **read-only for subagents**. The parent agent's `prior-art-research` Phase 0 is the single writer. Dispatch subagents only AFTER Phase 0 has settled (i.e., the parent has completed research-phase recon). This prevents read-during-write races and keeps the environment-binding cache consistent across the parallel batch.

Before reading SYSTEM_CONTEXT.md (in the parent agent prior to building each subagent's context preamble), run the staleness-check protocol per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md). The parent dispatcher emits the banner if stale, then proceeds with whatever the consuming chain skill's policy is (most halt with `Refresh? (Y/n)`).

### Phase 5 — Wait and collect

While subagents run, the dispatcher is idle (or can do bookkeeping). When notifications arrive:

- Capture timing per subagent (`duration_ms`, `total_tokens`) — this is the only chance
- **Capture commit SHA(s) returned by each artifact-producing subagent** — these populate the dispatch record's audit trail
- Verify each subagent's output against its spec's verification step
- For write-task dispatches, route each `DONE` through the reviewer (see `## Reviewer dispatch` below) before treating the work as verified
- Note any subagent that failed, returned partial results, or deviated from spec

**Don't lose partial successes.** If 4 of 5 subagents succeeded, keep their work (the commits are already in the tree). Re-dispatch only the failed one with a clearer spec (or fall back to sequential).

### Phase 6 — Aggregate and synthesize

Combine outputs. For research-style dispatches, this is a synthesis step (one pattern-extractor subagent can also handle this — see `../../agents/synthesizer.md`). For implementation-style dispatches, this is a merge step (run tests after merging; resolve conflicts if any).

### Phase 7 — Verify the whole

After aggregation, run the full verification:

- Tests still pass? (For implementation dispatches)
- Synthesis is coherent? (For research dispatches)
- No subagent's output contradicts another's?

If verification fails, the parallel dispatch saved nothing — and may have cost extra in tokens and complexity. Phase 7.5 captures that outcome in the dispatch record for future calibration.

### Phase 7.5 — Write the dispatch record

After Phase 7 verifies, write **one JSON file** at:

```
docs/agents/dispatches/<dispatch-id>.json
```

The `<dispatch-id>` is the same ulid or short hash generated in Phase 4 (carried in every subagent's commit-message `Dispatch-id:` trailer). Match the schema in [`references/dispatch-record-template.md`](./references/dispatch-record-template.md) § Section 4 exactly:

- Top-level fields — `dispatch_id`, `invoker`, `started_at` / `completed_at` (ISO-8601), `parent_task`, `plan_ref` (if any), `concurrency_used`.
- `independence_verification` block — copy the 5 checks from Phase 2.
- `subagents` array — one entry per subagent with `status`, `commit_shas`, `duration_ms`, `total_tokens`, `notes` / `blocker` / `context_request`, `worktree_path`, `branch`.
- `aggregate` block — `total_wall_ms = max(durations)`, `sequential_equivalent_ms = sum(durations)`, `parallelism_gain = sequential / wall`, `outcome ∈ {SUCCESS, PARTIAL, FAILED}` from Phase 7's verdict.
- `re_dispatches` array — empty if no re-dispatch fired.

**Always-on.** No tier conditionality. Every dispatch produces a record. (Tier governs whether a chain *uses* parallel-dev at all, but once a dispatch happens, recording is unconditional.)

**Failure mode.** If the write fails (filesystem full, permission denied, path missing), emit one line and proceed:

```
⚠ Could not write dispatch record at <path>: <error>. Audit trail incomplete.
```

The parallel work already succeeded; losing the audit log MUST NOT poison successful results. This matches the graceful-degradation pattern in [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md) § Case A.

**Single-writer invariant.** The dispatcher is the sole writer of dispatch records. No downstream skill reads dispatch records during chain execution; the directory is an audit-only log. Forensic readers (`socratic-grill` re-grilling a past failed slice, future calibration scripts) grep across the directory after the fact.

## Return contract

Every subagent dispatched via `parallel-dev` returns exactly one of four statuses. The full input + return JSON schemas live in `references/dispatch-record-template.md`; semantics below.

### `DONE`

The subagent completed its task fully and the output satisfies the spec's `verification` step. Commit SHAs (if any) are returned. The dispatcher advances the slice / sub-problem and moves on.

### `DONE_WITH_CONCERNS`

The subagent completed its task but noticed something the dispatcher should see — a smell, an inconsistency it couldn't fix in scope, a side effect that wasn't in the spec. The `notes` field is required and contains the concern. The dispatcher advances (this is NOT a halt) but emits a warning in its output and appends `notes` to the dispatch record.

### `BLOCKED`

The subagent could not complete the task. Required: `blocker` field with a one-line description and `suggested_action ∈ {"edit-spec-and-redispatch", "investigate-manually", "escalate-to-maintainer", "re-grill"}`. The dispatcher halts the pgroup, surfaces the structured BLOCKED message to the user, and does NOT re-dispatch automatically — the user decides next steps.

**Halt scope for `re-grill`.** When the suggested action is `re-grill` (implementation revealed an ambiguous or contradicted spec decision — see `tdd-loop`'s re-grill edge), the dispatcher classifies the blocker's cause before touching siblings:

- **`spec-wide`** (the blocked decision feeds other slices in flight) — in-flight siblings pause at their next checkpoint. Pause, never terminate: worktree isolation makes the pause lossless, and partial work survives for the resume.
- **`slice-local`** (the blocker is confined to the halted slice) — siblings run to completion; only the halted slice waits on the round.
- **Ambiguous cause defaults to spec-wide** (pause-all). The lead may explicitly classify `slice-local` to let siblings run, and owns that call.
- **Salvage rule:** siblings that already finished land their results in the re-grill payload's `salvaged_sibling_results` — finished work is evidence for the round, never discarded wholesale.

### `NEEDS_CONTEXT`

The subagent's input was incomplete or ambiguous and it cannot proceed without more information. Required: `context_request` field naming the missing input. The dispatcher re-dispatches up to 2 times (the dispatch contract's Part 1 bound, amended 2026-06-10 — see `references/dispatch-record-template.md`), each re-dispatch requiring materially changed input — the dispatcher judges "materially changed", because it composed the original input and can diff it against the corrected one. A re-dispatch attempt with unchanged input escalates immediately as `BLOCKED` instead of dispatching; the same escalation fires when the bound is exhausted (the 2nd re-dispatch also returns `NEEDS_CONTEXT`). The bound is a termination guarantee documented as convention, not a tuned optimum.

### Status handling matrix

| Status | Dispatcher action | User-facing emission |
|---|---|---|
| `DONE` | Advance | Silent (or quiet success line) |
| `DONE_WITH_CONCERNS` | Advance | Warning with `notes` |
| `BLOCKED` | Halt pgroup | Structured BLOCKED message |
| `NEEDS_CONTEXT` | Re-dispatch up to 2× with materially changed input (dispatcher judges); unchanged input or exhausted bound → escalate as `BLOCKED` | Silent on re-dispatches; BLOCKED-shape on escalation |

Sub-skills that consume `parallel-dev` outputs (today: `tdd-loop` Phase 0.5, `prior-art-research` Deep-tier synthesis) MUST honor this matrix. Free-form text returns are non-compliant; the contract is machine-readable.

## Reviewer dispatch (context-starved)

After a write-task subagent returns `DONE`, the dispatcher sends the work to a reviewer running in fresh context. The reviewer is a **read-task-class dispatch**: it writes nothing, so there is no merge surface and read-task rules apply (no worktree, no commit discipline).

**Input triple — nothing else.** The reviewer receives exactly three things: the diff, the slice spec, and the bounding commit SHAs. The context-starvation rule is explicit: the reviewer NEVER sees the writer's conversation or reasoning. A reviewer that inherits the writer's context inherits the writer's blind spots; starvation is what makes the review independent.

**Finding constraints — gaps, not style.** Findings are limited to correctness gaps and stated-requirements gaps (the slice spec's acceptance criteria). Style preference, naming taste, and unprompted refactor suggestions are out of scope. Severity tiers:

| Severity | Effect |
|---|---|
| Critical | Blocks progression |
| Important | Blocks progression |
| Minor | Recorded in the dispatch record; never blocks |

**One fix round.** Each Critical/Important finding gets exactly one writer fix round. A finding surviving its fix round escalates to `BLOCKED` — this composes with `tdd-loop`'s same-finding-twice rule: the same finding is never attempted twice.

**PASS is evidence, not an oracle.** A reviewer PASS is recorded as evidence in the dispatch record. In narrative weight it sits above the writer's self-review — fresh eyes outrank the author's — but it NEVER replaces deterministic assertions; the executable checks remain the verification floor.

**Ownership.** `parallel-dev` DEFINES this reviewer contract; both `parallel-dev` and `tdd-loop`'s loop mode CONSUME it (the loop dispatches a reviewer per slice via this same contract). In AFK mode a Critical finding hard-blocks — no overnight override; the slice parks with a halt report.

## Sub-patterns

These are dispatch shapes that recur often enough to warrant naming. Each is a specialization of the general Phase 1-7 workflow.

### Hypothesis probe (generate-N-filter-to-K)

**When it fits:** Debugging or design exploration with ≥3 plausible hypotheses, where each hypothesis can be probed independently with a falsifiable test, and the probes are read-only / non-destructive.

**Pattern:** Dispatch one subagent per hypothesis, each with a single-purpose probe spec (e.g., "run this query against the prod replica; report the count" or "rebuild with the suspected flag toggled; report whether the test now passes"). Collect all results; the disconfirming probes eliminate hypotheses; the confirming probes (often just one) localize the root cause.

**Origin:** DeepMind's AlphaCode (competitive programming, 2022) — generate up to 1M candidate programs, filter by execution against test cases, cluster by behavior, submit 10. The generalization for debugging is the same shape with N=3-10 and "candidates = hypotheses, tests = probes".

**Independence sanity:** probes are usually read-only and operate against shared infrastructure (prod replica, staging DB). File-overlap independence is automatic; resource contention (rate limits, connection pool) may need a soft cap < 5.

**Consumer:** `systematic-debugging` Phase 3.5 — when ≥3 hypotheses are on the table, fan out probes via this pattern instead of probing sequentially.

**Citation:** ["competitive programming with AlphaCode" — DeepMind blog](https://deepmind.google/blog/competitive-programming-with-alphacode/). Pattern adapted from generate-N-filter-to-K to N-hypothesis-fan-out via probe execution.

## Independence checklist (Phase 2 expanded)

Quick decision matrix for the most common cases:

| Work shape | Likely independent? | Notes |
|---|---|---|
| Research: each subagent fetches a different source | Yes | No shared state; output is per-subagent |
| Refactor: each subagent works on a separate module's tests | Usually | Check for shared test fixtures |
| Refactor: each subagent works on a separate module's code | Maybe | Check for shared types/exports |
| Bug fix: each subagent fixes a different bug in the same file | NO | File overlap |
| Implementation: each subagent implements a different `AFK:full-auto` slice | Yes if slices are truly vertical | Re-check the slice independence. HITL:* slices are NEVER eligible. |
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

- **Used by `prior-art-research`** in the Deep tier — one subagent per sub-problem, plus a synthesizer subagent that aggregates findings
- **Used by `vertical-slice` / `draft-spec`** — AFK slices marked "Parallelizable" run concurrently here
- **Standalone** for batch refactors, audits, doc generation

## See also

- `prior-art-research` — primary consumer in the Deep tier
- `draft-spec` — produces parallelizable slice groups
- `tdd-loop` — what each subagent runs internally when implementing a slice
- `../../agents/source-fetcher.md` — subagent prompt for research fetching
- `../../agents/pattern-extractor.md` — subagent prompt for research extraction
- `../../agents/synthesizer.md` — subagent prompt for aggregating parallel results
- `references/dispatch-record-template.md` — template for capturing a parallel dispatch
