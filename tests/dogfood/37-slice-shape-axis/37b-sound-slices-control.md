# Dogfood 37b — Slice-shape axis: sound slices (control)

**Type:** Negative control (no planted defect)

---

## Input to `socratic-grill`

A spec with `Tier: Balanced`, no explicit open questions, and this slice table:

> ### Slice 1 — Submit one rating end-to-end (AFK)
> A user submits a 1-5 rating and sees it persisted and re-rendered. Cuts through UI, API, and storage.
> **Blocked by:** None
>
> ### Slice 2 — Aggregate display (AFK)
> The item page shows the average across ratings, computed at read time.
> **Blocked by:** #1 (reads rows Slice 1 writes)
>
> ### Slice 3 — Owner moderation (HITL: naming the moderation states is a product call)
> An item owner hides an abusive rating; hidden ratings drop from the aggregate.
> **Blocked by:** #1 (acts on rows Slice 1 writes; independent of #2)

## Expected grill behavior

The slice table still enters the Phase 1 inventory (standing item class). The slice-shape review finds: slices vertical, ordering justified by real data dependencies, the HITL gate names its concrete human input. The item resolves quickly — e.g., "slice table reviewed, no defects" — with **zero manufactured objections**.

A run that invents slice-shape problems here (demands re-slicing, challenges the justified HITL gate, insists on parallelizing #2/#3 against the stated reason) FAILS the scenario.

## Failure mode this guards against

The axis turning into performative questioning — manufacturing ambiguity where the decomposition is sound, which is the calcification path the conversation-not-checklist design exists to prevent.
