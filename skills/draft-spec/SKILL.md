---
name: draft-spec
description: Turns a prior-art-research recommendation into a concrete implementation spec. Decomposes the chosen approach into vertical slices (tracer bullets) labeled HITL (human-in-the-loop) or AFK (autonomous), with acceptance criteria, test strategy, and dependency ordering per slice. Make sure to use this skill whenever you have a research recommendation and need to convert it into something an engineer (or coding agent) can actually start building from. Triggers automatically when prior-art-research produces a "HANDOFF: spec ready" line, or explicitly via /spec. Do NOT use to research alternatives (that's prior-art-research) or to debug an existing spec (that's socratic-grill).
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

### Phase 1 — Locate the recommendation

The spec is built from a research recommendation. Find it:

1. Most recent `prior-art-research` output in the conversation, OR
2. An ADR the user pointed to (`docs/agents/adrs/...`), OR
3. The user's prose description of the chosen approach

If none of these exist, halt and ask: "I need a chosen approach to spec. Either invoke `prior-art-research` first, or describe the approach you've settled on."

### Phase 2 — Extract spec inputs

From the recommendation, extract:

- **Architecture sketch** — components, data flow, network boundaries (from the research Recommendation section)
- **Concrete picks** — the table of decisions from the research output
- **Trade-offs accepted** — what you're explicitly giving up
- **Decisions still to make** — the "Decisions to make next" section
- **Open questions** — anything research didn't resolve

If "decisions still to make" or "open questions" are non-empty, flag them prominently in the spec — they're candidates for `socratic-grill` to resolve before implementation starts.

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

For Deep specs (5+ slices), produce a small DAG comment showing the structure. AFK slices that share no dependencies can be marked `Parallelizable` for `parallel-dev` dispatch.

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
