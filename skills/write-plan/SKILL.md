---
name: write-plan
description: Turn a locked ADR + sliced spec into a phased delivery plan with acceptance gates. Use when decision-record emits "HANDOFF: implementation ready", user types "/plan", "give me a plan", "map this out", or before any parallel-dev dispatch of 3+ slices. Do not use for single-slice work or when no ADR exists.
disable-model-invocation: true
---

# Write Plan

Convert a locked architectural decision into a sequenced, gated delivery story. The plan is what every downstream skill reads: `tdd-loop` works one slice at a time per the plan's order; `parallel-dev` only dispatches groups the plan marks parallelizable; `systematic-debugging` consults the plan when a bug crosses phase boundaries.

The plan is NOT:
- A Gantt chart (timing is illustrative, not contractual)
- A re-statement of the ADR (link to it, don't re-litigate)
- A list of slices (that's `vertical-slice`'s output — the plan *sequences and gates* slices)
- An eternal document (it has revisit triggers and decays)

## When to use this skill

**Trigger on:**

- `decision-record` produced `HANDOFF: implementation ready`
- The user says "write the plan", "what's the rollout", "map this out", "phase this", "give me the plan"
- `vertical-slice` produced 3+ slices and ordering/parallelization isn't obvious
- Before `parallel-dev` dispatches a batch of 3+ AFK slices (the plan is the parallel-dispatch contract)
- A feature is "in flight" with no shared artifact tying its commits together

**Do NOT trigger on:**

- Single-slice work (plan overhead exceeds value)
- Spike / throwaway exploration (the design IS the deliverable)
- Documentation-only changes
- No ADR exists yet (run `decision-record` first — planning without a locked decision is premature)
- A plan already exists for this feature (update it; don't write a second)

## Inputs (required before Phase 1)

- **ADR** from `decision-record` — the locked architecture
- **Sliced spec** from `vertical-slice` / `draft-spec` — the decomposition
- **Grill record** from `socratic-grill` — accepted trade-offs and revisit triggers
- **SYSTEM_CONTEXT.md** from `prior-art-research` Phase 0 — scale envelope, observability, deployment shape
- **Tier** — the `**Tier:**` field from the ADR / spec header (Quick / Balanced / Deep — see [`docs/agents/references/tier-scale.md`](../../docs/agents/references/tier-scale.md)). Echo it into the plan header's `Tier` row.

If any upstream artifact is missing, halt and surface the gap. Don't fabricate a plan on top of unknowns.

**Where the tier puts this skill.** At the **Quick** tier `write-plan` is normally skipped — `tdd-loop` runs the spec's slice order directly. At **Balanced** it runs when there are 3+ slices or ordering isn't obvious. At **Deep** it always runs. If the user invokes `/plan` explicitly on a Quick chain, honor it — the tier sets the default, the user overrides it.

## Core workflow

### Pre-flight — Environment check

Before Phase 1, verify `docs/agents/SYSTEM_CONTEXT.md` exists. If missing, halt with:

> **SETUP REQUIRED:** `docs/agents/SYSTEM_CONTEXT.md` missing. Run `/groundwork` (preferred — one-shot bootstrap) or `/research` (writes the file via Phase 0 reconnaissance) first.

This skill cannot produce reliable output without the environment-binding cache. Do not proceed to Phase 1.

**Staleness check:** Before reading SYSTEM_CONTEXT.md, run the staleness-check protocol per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md). If stale, emit the banner and proceed with a clear `[stale]` annotation on any inferences drawn from the cache. This skill is a READER — only `prior-art-research` Phase 0 writes SYSTEM_CONTEXT.md.

**GLOSSARY lookup (on-demand):** If methodology terminology in this spec / grill / plan feels ambiguous (e.g., "slice", "phase", "dispatch group", "pgroup", "HITL", "AFK"), Read `docs/agents/GLOSSARY.md` immediately before proceeding. Don't guess at habeebs-skill vocabulary — the glossary is the canonical reference.

### Phase 1 — Locate inputs and choose plan home

ADRs live in `docs/agents/adrs/`. Plans live in `docs/agents/plans/<slug>.md`. The slug matches the ADR slug (e.g., ADR `0008-use-yjs-for-collaborative-editing` → plan `0008-use-yjs-for-collaborative-editing.md`).

If `docs/agents/plans/` doesn't exist, create it. If a plan with this slug already exists, switch mode: UPDATE the plan in place; do NOT write a second.

### Phase 2 — Group slices into phases

A phase is a set of slices that ship behind ONE acceptance gate. The gate is a binary, user-observable criterion — not a tasks-done count.

Good gates:
- "User can create and load a doc round-trip in production for 100% of canary cohort"
- "p95 read latency < 80ms on production traffic for 24h"
- "All foreign-key migrations applied; no reads against the old schema"

Bad gates (reject these):
- "All slice checkboxes ticked" (tautological)
- "Tests pass" (already required per slice)
- "Code reviewed" (process, not outcome)

Rules of thumb for grouping:
- **3–7 slices per phase**. More → the gate is too coarse; fewer → phases are too granular.
- **Each phase ships SOMETHING** end-to-end visible. A "scaffolding phase" with no user-visible result is a bad phase boundary — fold it into the next one.
- **Phase N+1 cannot start until phase N's gate passes.** If you can't enforce that, the gate is decorative.

### Phase 3 — Build the dependency DAG

For every slice, list its prerequisites (other slices, infra changes, external dependencies). Render as a text DAG. The plan supports any of:

- **Mermaid flowchart** (preferred when the repo renders Mermaid)
- **ASCII-art DAG** (fallback)
- **Adjacency list** (`Slice 3 ← {Slice 1, Slice 2}`)

The DAG must be acyclic. If you find a cycle, halt — the slicing is wrong, not the plan. Hand back to `vertical-slice`.

### Phase 4 — Mark parallelization groups

A parallelization group is a maximal set of slices in the same phase with no dependencies between them. Compute it from the DAG.

Express as `pgroup-N` labels. Example:
```
Phase 1: pgroup-1A = {Slice 1, Slice 2}, pgroup-1B = {Slice 3} (depends on 1, 2)
Phase 2: pgroup-2A = {Slice 4, Slice 5, Slice 6}, pgroup-2B = {Slice 7}
```

**Independence sanity-check (mandatory):** before labeling two slices as the same pgroup, apply `parallel-dev`'s Phase 2 independence checklist (file overlap, state dependency, resource contention, ordering, implicit shared state). If any check fails, they're sequential, not parallel.

**The 20% rule:** if more than 80% of slices are tagged parallelizable, something is wrong. Real features have ordering dependencies. Aggressive parallel-tagging usually masks missed dependencies that surface as merge conflicts.

### Phase 5 — Risk register + rollback hooks per phase

For each phase, write:

- **Top 3 risks** — short, concrete (not "things might go wrong"). Example: "Yjs CRDT may exceed payload budget at 5KB+ docs."
- **Rollback hook** — the specific operation that reverts the phase. Examples:
  - Feature flag toggle (`yjs_enabled` → off)
  - Migration revert script (`prisma migrate resolve --rolled-back`)
  - Route-level kill switch
  - "Not rollback-able after gate passes — explicit one-way door"

If a phase has no rollback path, **say so explicitly**. A phase with "no rollback" is fine — it's an honest one-way door — but it must be flagged so the gate can be set higher.

### Phase 6 — Revisit triggers

Conditions that should re-open the plan. Inherit relevant triggers from the ADR; add plan-specific ones:

- Scale milestones (e.g., "MAU > 50k")
- Latency regressions beyond stated SLO
- New capability requirement (e.g., "offline editing requested")
- External dependency change (e.g., "Yjs major version bumped")

If a trigger fires mid-execution, halt at the current phase gate and re-run `socratic-grill` on the affected sections. Don't push through a triggered plan.

### Phase 7 — Write the plan doc

Follow `references/plan-template.md` exactly. Required sections in order:

1. **Header** — slug, ADR link, tier (inherited), status (Proposed / Active / Done / Superseded), last updated, owner
2. **Goal & success measure** — one sentence each, copied from spec; success measure must be observable in production
3. **Phases** — each phase has: name, slices contained, acceptance gate, top-3 risks, rollback hook
4. **Slice table** — one row per slice: id, name, label (HITL:inline / HITL:approval-gate / AFK:full-auto), phase, pgroup, blocked-by, est duration, rollback hook
5. **Dependency DAG** — Mermaid or ASCII
6. **Parallelization map** — `pgroup-N` listing
7. **Risk register** — full enumeration; the per-phase top-3 lifts from this
8. **Revisit triggers** — bulleted list
9. **References** — ADR, spec, grill record, SYSTEM_CONTEXT.md

Status field semantics:
- **Proposed** — written but no slice has started
- **Active** — at least one slice is in `tdd-loop`
- **Done** — final phase gate passed; feature is shipped
- **Superseded by plans/<slug>.md** — replaced by a newer plan

### Phase 8 — Hand off

```
HANDOFF: implementation ready — plan locked at docs/agents/plans/<slug>.md.
  Next: tdd-loop on slice <first-id> (phase 1, pgroup-1A).
  Parallelizable now: <pgroup-1A members>.
  Gate to pass before phase 2: <phase 1 gate>.
```

**Always emit:** if the plan has any pgroup of size ≥ 2, also emit the pgroup-dispatch-ready handoff so the downstream `tdd-loop` Phase 0.5 knows to auto-dispatch (rather than fall through to single-slice sequential):

```
HANDOFF: pgroup-dispatch-ready — when tdd-loop is invoked on this plan, pgroups of size ≥2 will auto-dispatch via parallel-dev.
  Eligible pgroups: <comma-separated list of pgroup-N labels with size ≥ 2>.
  Each subagent runs its own red-green-refactor cycle in its own worktree per using-worktrees.
  Concurrency cap: 5 default, opt-in override via `concurrency: <N>` per pgroup.
```

If the plan has a particularly large pgroup (≥3 AFK slices), the marketing-level emit is still useful:

```
HANDOFF: parallel dispatch ready — pgroup-<N> contains <K> AFK slices with no inter-deps.
  parallel-dev can dispatch these concurrently. Each gets its own worktree per using-worktrees.
```

Both handoff lines are read by `tdd-loop` Phase 0.5. The `pgroup-dispatch-ready` line is the *machine-readable* dispatch trigger; the `parallel dispatch ready` line is the *human-readable* heads-up.

## Anti-patterns this skill guards against

- **Plan-as-Gantt-chart.** Dates without acceptance gates are wishes. Every phase must have a binary gate.
- **Re-litigating the ADR.** If you find yourself re-justifying the architecture in the plan, the ADR is incomplete — fix the ADR, link from the plan.
- **All slices parallelizable.** Real features have ordering deps. 80%+ parallel-tagged is a smell.
- **Phases with no user-visible outcome.** A "scaffolding phase" is a horizontal slice in disguise. Fold it forward.
- **No rollback path AND no explicit one-way-door flag.** Silent one-way doors blow up in production. Either define rollback or flag it.
- **Plan written for an audience of one.** The plan is read by `tdd-loop`, `parallel-dev`, and the team. Optimize for the slice-executor, not your own legibility.
- **Plan that never updates.** Plans decay. Update Status field every commit that lands a slice; update revisit-triggers when one fires.
- **Plan without revisit triggers.** Equivalent to "this is forever." Nothing is forever.

## Update protocol (when an existing plan needs revision)

When called on an existing plan:

1. Diff intent: the user is reacting to (a) a slice landing, (b) a trigger firing, or (c) a new constraint
2. Localize: which phase/slice does the change affect? Surgical edit, not rewrite
3. Bump `Last updated` and add a one-line entry to the plan's `Change log` section (added on first revision)
4. If the change crosses a phase gate that's already passed, halt — that needs `socratic-grill` first

## Integration with the chain

- **Upstream:** `decision-record` locks the ADR this plan implements; `vertical-slice` / `draft-spec` produces slices; `socratic-grill` provides accepted trade-offs; `prior-art-research` Phase 0 supplies the system context
- **Downstream:** `tdd-loop` reads the plan slice-by-slice; `parallel-dev` consumes pgroups; `systematic-debugging` consults phase boundaries when a bug crosses them
- **Standalone:** humans invoke `/plan` to write or update a plan manually

## Compatibility notes

- Mermaid renders natively on GitHub and most markdown viewers. If the repo's markdown viewer doesn't render Mermaid, fall back to ASCII DAG (`references/plan-template.md` shows both).
- The plan lives in the same repo as the code so it's review-able in the same PR that implements its first slice.

## See also

- `decision-record` — upstream; locks the ADR
- `vertical-slice` — upstream; produces slices
- `socratic-grill` — upstream; accepted trade-offs and revisit triggers
- `tdd-loop` — downstream; executes slice-by-slice per the plan
- `parallel-dev` — downstream; consumes pgroups
- `systematic-debugging` — consulted when a bug crosses phase boundaries
- `references/plan-template.md` — strict plan format
- `references/phase-gate-examples.md` — good vs. bad acceptance gates
- `docs/agents/references/tier-scale.md` — the tier that decides whether this skill runs
