---
name: write-plan
description: Sequence a signed-off Design into a phased delivery plan with acceptance gates. Use when the work is genuinely multi-phase or the user types "/plan". Do not use for single-phase work (the slice list is the plan) or before a Design is signed off.
disable-model-invocation: true
---

# Write Plan — sequence multi-phase work

**NO SEPARATE PLAN FOR SINGLE-PHASE WORK.**

A plan exists to sequence work across real phase gates — points where one batch must ship and be
verified before the next starts. If the work is a single phase, the machine slice list and its
ordering ARE the plan; writing a separate plan doc is pure duplication. Write a plan only when
there are genuine phase boundaries, a staged rollout, or parallel dispatch of 3+ independent
slices. This is a Machine-layer artifact: `tdd-loop` and `parallel-dev` read it.

Write in the house voice — see [`docs/agents/references/skill-voice.md`](../../docs/agents/references/skill-voice.md).

## When to use this skill

**Trigger on:**

- Implementation is multi-phase: a batch must ship and pass a gate before the next batch starts
- 3+ AFK slices with no inter-dependencies need parallel dispatch (the plan is the dispatch contract)
- A staged rollout with rollback points per phase
- The user types `/plan` explicitly

**Do NOT trigger on:**

- Single-phase work (the slice list and its order are the plan — go straight to `tdd-loop`)
- Spike / throwaway exploration
- A Design that isn't signed off yet (run `socratic-grill` to sign-off first)
- A plan already exists for this feature (update it; don't write a second)

## Inputs (required before Phase 1)

- **Signed-off Design** from `socratic-grill` — the Overview, Key decisions, and Decided section
  (including the **User mental model** success criteria, which are the strongest acceptance-gate
  candidates).
- **Slice list** from `vertical-slice` — the Machine-layer decomposition.
- **SYSTEM_CONTEXT.md** — scale envelope, observability, deployment shape.
- **Tier** — the `Tier:` field from the Design header; echo it into the plan header.

If the Design isn't signed off or the slice list is missing, halt and surface the gap.

## Core workflow

### Pre-flight — Environment check

Verify `docs/agents/SYSTEM_CONTEXT.md` exists. If missing, halt with the `SETUP REQUIRED` banner
(run `/groundwork` or `/research`). Run the staleness-check per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md). This skill only READS SYSTEM_CONTEXT.md.

### Phase 1 — Locate inputs and choose the plan home

Plans live at `docs/agents/plans/YYYY-MM-DD-<slug>.md`, slug matching the Design's slug. The
release version goes in the plan's `Version:` / `Release:` frontmatter field, not the filename.
Halt loud if the dated filename already exists. If a plan with this slug exists, UPDATE it in
place — don't write a second.

### Phase 2 — Group slices into phases

A phase is a set of slices that ship behind ONE acceptance gate — a binary, user-observable
criterion, not a tasks-done count. Read the Design's **User mental model** success criteria first;
they are the user's own definition of shipped-and-working and the strongest gate candidates.

Good gates: "User can create and load a doc round-trip in production for 100% of canary cohort";
"p95 read latency < 80ms for 24h." Bad gates (reject): "all slice checkboxes ticked"; "tests
pass" (already required per slice); "code reviewed" (process, not outcome).

Rules of thumb: 3–7 slices per phase; each phase ships something end-to-end visible; phase N+1
cannot start until phase N's gate passes. If you can't enforce that, the gate is decorative — and
if there's only one phase, you don't need a plan.

### Phase 3 — Build the dependency DAG

For each slice, list its prerequisites. Render as Mermaid (preferred), ASCII, or adjacency list.
The DAG must be acyclic — a cycle means the slicing is wrong; hand back to `vertical-slice`.

### Phase 4 — Mark parallelization groups

A parallelization group (`pgroup`) is a maximal set of slices in one phase with no dependencies
between them. **Independence sanity-check (mandatory):** before co-labeling two slices, apply
`parallel-dev`'s Phase 2 checklist (file overlap, state dependency, resource contention, ordering,
implicit shared state). If any check fails, they're sequential. **The 20% rule:** if more than 80%
of slices are tagged parallelizable, the slicing is hiding dependencies that will surface as merge
conflicts.

### Phase 5 — Risk register + rollback hooks per phase

For each phase: top 3 concrete risks, and the specific rollback operation (feature-flag toggle,
migration revert, route kill-switch, or an explicit "ONE-WAY DOOR — no rollback after gate
passes"). A phase with no rollback path MUST say so explicitly so the gate is set higher.

### Phase 6 — Revisit triggers

Conditions that reopen the plan (scale milestones, latency regressions, new capability
requirements, external dependency changes). If a trigger fires mid-execution, halt at the current
phase gate and re-grill the affected section. Don't push through a triggered plan.

### Phase 7 — Write the plan doc

Follow `references/plan-template.md` exactly. It enforces the plain-English plan format: TL;DR at
top before any table; per-phase narrative intro before gates/risks; tables limited to the status
block and the slice list; acceptance gates as numbered prose; risks as prose with embedded
`Mitigation:` lines; jargon discipline (GLOSSARY-linked terms used freely, plan-specific
identifiers defined inline). Required sections: frontmatter, TL;DR, status block, goal & success
measure, phases, slice table, dependency DAG, parallelization map, revisit triggers, change log,
references.

**Fixture identifiers are confirm-at-implementation, never plan literals.** Where a phase gate,
rollback hook, or test path references a test-fixture identifier (a dogfood scenario number, a
file index), write a placeholder; the implementer must confirm against the live tree before
creating the fixture.

### Phase 8 — Hand off

Recap in one plain sentence what ships in phase 1 and the gate to pass, then:

```
HANDOFF: implementation ready — plan locked at docs/agents/plans/YYYY-MM-DD-<slug>.md. Next: tdd-loop on slice <first-id> (phase 1). Gate before phase 2: <phase 1 gate>.
```

If any pgroup has size ≥ 2, also emit so `tdd-loop` Phase 0.5 auto-dispatches:

```
HANDOFF: pgroup-dispatch-ready — pgroups of size ≥2 auto-dispatch via parallel-dev. Eligible: <pgroup labels>. Each subagent runs its own red-green-refactor in its own worktree.
```

## Anti-patterns this skill guards against

| Thought | Reality |
|---|---|
| "I'll write a plan for this single-phase feature." | The slice list is the plan for single-phase work. A separate doc is duplication — skip it. |
| "Dates make it look like a real plan." | Dates without acceptance gates are wishes. Every phase needs a binary gate. |
| "I'll re-justify the architecture in the plan." | That's the Design's job. If the plan re-litigates it, the Design is incomplete — fix the Design. |
| "Tag everything parallelizable — it's faster." | Real features have ordering deps. 80%+ parallel is a smell that hides merge conflicts. |
| "A scaffolding phase with no user-visible result is fine." | That's a horizontal slice in disguise. Fold it into the next phase. |
| "The plan is forever." | Plans decay. Update Status as slices land; add revisit triggers. |

## Update protocol (when an existing plan needs revision)

1. Diff intent: reacting to a slice landing, a trigger firing, or a new constraint.
2. Localize: which phase/slice — surgical edit, not rewrite.
3. Add a dated entry to the Change log.
4. If the change crosses a phase gate that already passed, halt — that needs `socratic-grill` first.

## See also

- `socratic-grill` — upstream; the signed-off Design and its success criteria
- `vertical-slice` — upstream; the slice list this plan sequences
- `decision-record` — upstream; locks any one-way-door ADR before planning
- `tdd-loop` — downstream; executes slice-by-slice per the plan
- `parallel-dev` — downstream; consumes pgroups
- `systematic-debugging` — consulted when a bug crosses phase boundaries mid-plan
- `references/plan-template.md` — strict plan format
- `docs/agents/references/skill-voice.md` — the house voice
- `docs/agents/references/tier-scale.md` — the tier that decides whether this skill runs
