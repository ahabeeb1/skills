---
name: draft-spec
description: Turn a research recommendation into a sliced implementation spec. Use when prior-art-research emits "HANDOFF: spec ready", when user types "/spec", or when an ADR is locked and slice decomposition is the next step. Do not use to research alternatives or debug an existing spec.
disable-model-invocation: true
---

# Draft Spec

Turn a research recommendation into an implementation spec a competent engineer or coding agent can start building from immediately.

This skill is convergent: it commits to choices, decomposes into deliverable slices, and produces a single spec document. It is NOT for exploring alternatives — `prior-art-research` already did that.

## When to use this skill

**Trigger on:**

- A `prior-art-research` output ended with `HANDOFF: spec ready`
- The user invoked `/spec` explicitly
- The user pasted a research recommendation or ADR and asked "now what?"
- The conversation has converged on an approach and the user wants to start building

**Do NOT trigger on:**

- Vague intent without a chosen approach (run `prior-art-research` first)
- A request to debug an existing spec (use `socratic-grill`)
- A request to start coding immediately on a trivial task (skip the chain entirely)

## Core workflow

### Pre-flight — Environment check

Before Phase 1, verify `docs/agents/SYSTEM_CONTEXT.md` exists. If missing, halt with:

> **SETUP REQUIRED:** `docs/agents/SYSTEM_CONTEXT.md` missing. Run `/groundwork` (preferred — one-shot bootstrap) or `/research` (writes the file via Phase 0 reconnaissance) first.

This skill cannot produce reliable output without the environment-binding cache. Do not proceed to Phase 1.

**Staleness check:** Before reading SYSTEM_CONTEXT.md, run the staleness-check protocol per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md). If stale, emit the banner and proceed with a clear `[stale]` annotation on any inferences drawn from the cache. This skill is a READER — only `prior-art-research` Phase 0 writes SYSTEM_CONTEXT.md.

**GLOSSARY lookup (on-demand):** If methodology terminology in this spec / grill / plan feels ambiguous (e.g., "slice", "phase", "dispatch group", "pgroup", "HITL", "AFK"), Read `docs/agents/GLOSSARY.md` immediately before proceeding. Don't guess at habeebs-skill vocabulary — the glossary is the canonical reference.

### Phase 1 — Locate the recommendation

The spec is built from a research recommendation. Find it:

1. Most recent `prior-art-research` output in the conversation, OR
2. An ADR the user pointed to (`docs/agents/adrs/...`), OR
3. The user's prose description of the chosen approach

If none of these exist, halt and ask: "I need a chosen approach to spec. Either invoke `prior-art-research` first, or describe the approach you've settled on."

### Phase 2 — Extract spec inputs

From the recommendation, extract:

- **Tier** — the `**Tier:**` field in the research report header (Quick / Balanced / Deep). This skill inherits it; it does not re-decide it. Echo it into the spec header's `**Tier:**` field. See [`docs/agents/references/tier-scale.md`](../../docs/agents/references/tier-scale.md). If the research report predates the tier system and has no `Tier:` field, default to Balanced.
- **Architecture sketch** — components, data flow, network boundaries (from the research Recommendation section)
- **Concrete picks** — the table of decisions from the research output
- **Trade-offs accepted** — what you're explicitly giving up
- **Decisions still to make** — the "Decisions to make next" section
- **Open questions** — anything research didn't resolve

If "decisions still to make" or "open questions" are non-empty, flag them prominently in the spec — they're candidates for `socratic-grill` to resolve before implementation starts.

**Tier shapes the spec's depth, never its correctness.** A **Quick** spec is terse — slice list, acceptance criteria, and test seam per slice, no dependency DAG and no parallelization map. A **Balanced** spec follows the full template. A **Deep** spec follows the full template plus a DAG and parallelization map. The tier governs ceremony only: open questions and unresolved decisions are flagged prominently at *every* tier (per `tier-scale.md` invariant 1 — a real decision always reaches `socratic-grill`).

### Phase 3 — Decompose into vertical slices

Use the `vertical-slice` skill (or its principles if the skill isn't loaded yet): each slice cuts through ALL integration layers end-to-end, never a horizontal slice of one layer.

**A good slice:**

- Demonstrates end-to-end value (the user can see something work)
- Takes a single focused session to implement (2-5 hours for a human, 1-3 turns for an agent)
- Has acceptance criteria measurable in a test
- Has explicit dependencies on prior slices (or none)
- Is labeled **HITL** (human input required mid-slice — e.g., naming a domain concept, choosing between two architectural seams discovered during implementation) or **AFK** (autonomous-friendly — can be implemented and merged by an agent without human gating)

**Bad slices to avoid:**

- "Build the database layer" (horizontal — doesn't demonstrate user value)
- "Implement everything" (too big — no demonstration point)
- "Add types" (too vague — no acceptance criterion)
- Slices with hidden dependencies on each other

### Phase 4 — Test strategy per slice

For each slice, identify how it will be verified:

- **Unit test** — pure logic, deterministic
- **Integration test** — multi-component, real I/O or close to it
- **End-to-end test** — full stack against a running system
- **Manual smoke test** — UI/visual, hard to automate

The slice's first commit should be the failing test (RED phase from `tdd-loop`). Name the test file path in the spec.

### Phase 5 — Dependency ordering

Number slices in implementation order. A slice depending on another must come after it. Express dependencies as `Blocked by: #N` references.

DAG and parallelization scale with the tier: **Quick** — skip both (slices run in spec order). **Balanced** — produce a small DAG comment when the spec has 5+ slices. **Deep** — always produce the DAG. At Balanced and Deep, AFK slices that share no dependencies can be marked `Parallelizable` for `parallel-dev` dispatch.

### Phase 6 — Write the spec document

Follow `references/spec-template.md` exactly. Write to:

- `docs/specs/<feature-slug>.md` if the repo's setup convention is established (via `setup-habeebs-skill`)
- `.scratch/spec-<feature-slug>.md` if the repo has no convention
- Inline in the conversation if no filesystem is available

### Phase 7 — Hand off

End with:

```
HANDOFF: grill ready — invoke `socratic-grill` to resolve the open questions and challenge ambiguous decisions before implementation.
HANDOFF: record ready — invoke `decision-record` after grill to capture the architecture as an ADR.
HANDOFF: implementation ready — once spec is locked, invoke `tdd-loop` per slice in dependency order (AFK slices can run via `parallel-dev`).
```

## Anti-patterns this skill guards against

- **Horizontal slicing.** Breaking by layer (DB → API → UI) instead of feature. Each slice should be vertical.
- **Slices that are too big.** If a slice can't be completed in one focused session, it's not a slice.
- **Implicit assumptions hiding in prose.** Every "should" or "probably" in the spec is a future bug. Flag as an open question for `socratic-grill`.
- **Skipping test strategy.** A slice without a verification approach can't enter `tdd-loop`.
- **Spec drift from research.** The spec must trace back to the research recommendation. If you find yourself recommending something different mid-spec, halt and re-research.
- **Premature optimization in spec.** Don't pre-decide things the implementation will reveal. Capture trade-offs and revisit-triggers, not micro-optimizations.

## See also

- `prior-art-research` — upstream; produces the recommendation this skill specs out
- `vertical-slice` — the decomposition primitive used in Phase 3
- `socratic-grill` — downstream; drives ambiguity out of open questions before implementation
- `decision-record` — downstream; captures the locked spec as an ADR
- `tdd-loop` — implementation skill; runs against each slice
- `references/spec-template.md` — strict format for the spec document
- `docs/agents/references/tier-scale.md` — the tier this spec inherits and how it shapes spec depth
