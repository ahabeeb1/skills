# Dogfood 37a — Slice-shape axis: planted horizontal decomposition

**Type:** Positive (planted defect)
**Planted defect:** horizontal layer-slicing + a speculative ordering justification

---

## Input to `socratic-grill`

A spec with `Tier: Balanced`, no explicit open questions, and this slice table:

> ### Slice 1 — Database layer (AFK)
> Build the schema and migrations for ratings storage.
> **Blocked by:** None
>
> ### Slice 2 — API layer (AFK)
> Build the REST endpoints over the ratings tables.
> **Blocked by:** #1
>
> ### Slice 3 — UI layer (HITL)
> Build the ratings widget and wire it to the API. HITL because the design might need input.
> **Blocked by:** #2

## Expected grill behavior

The Phase 1 inventory MUST include the slice table as an item even though the spec's open-questions section is empty. Grilling that item on the slice-shape axis MUST surface at least:

1. **Horizontal slicing** — none of the three slices demonstrates end-to-end value alone; they are layers, not tracer bullets. The grill proposes re-slicing (e.g., "Slice 1: one rating submitted and visible end-to-end").
2. **Unjustified HITL gate** — "the design might need input" names no concrete mid-slice human input; the grill asks what input, exactly, or relabels AFK.

A run that grills only feature decisions and lets this slice table through unchallenged FAILS the scenario.

## Failure mode this guards against

Grill treating the slice decomposition as correct-by-construction — the gap where a layered breakdown derails tdd-loop because no slice ever reaches a demonstrable end-to-end state.
