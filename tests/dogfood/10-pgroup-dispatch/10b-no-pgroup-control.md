# Dogfood 10b — No-pgroup control (regression — single-slice flow must still work)

**Type:** Negative (false-positive regression — wiring must NOT dispatch when no pgroup ≥2)
**Expected verdict:** Zero `parallel-dev` dispatches; `tdd-loop` falls through to Phase 1 sequentially; no dispatch record written

This scenario is the **load-bearing regression test** for slice #6. Every habeebs-skill release prior to v1.7.0 used single-slice TDD without any pgroup detection. The new Phase 0.5 must pass through cleanly when the active plan has no pgroup of size ≥2 — otherwise, every existing user's chain breaks the moment they install v1.7.0.

---

## Synthetic plan (input to `tdd-loop`)

A toy plan at `docs/agents/plans/dogfood-10b-toy.md` (single-slice):

```
| ID | Name                  | Label         | Phase | pgroup    | Blocked by | Est  |
|----|-----------------------|---------------|-------|-----------|------------|------|
| #1 | Write a single file   | AFK:full-auto | 1     | pgroup-1A | —          | 0.1d |
```

`pgroup-1A` has exactly one member. No other pgroups exist.

## Expected `tdd-loop` Phase 0.5 behavior

**Turn 1:**
- Phase 0.5 Step 1: reads plan, identifies next unfinished pgroup as `pgroup-1A` with size 1
- Phase 0.5 Step 2 (idempotent check): no completed slices; classifies #1 as Pending
- Phase 0.5 Step 3: pgroup size < 2 → **no dispatch**; fall through to Phase 1
- Phase 0.5 Step 6 (single-slice fallthrough invariant): `tdd-loop` proceeds to Phase 1 against slice #1 sequentially
- Standard Phase 1-6 (RED-GREEN-REFACTOR-REVIEW-COMMIT) on slice #1

**Side effect — dispatch record:**
- **`docs/agents/dispatches/` is empty** (or unchanged from prior runs). Phase 0.5 did not invoke `parallel-dev`, so no record is written.

## Pass criteria

- [ ] Slice #1 proceeds through standard Phase 1-6 sequentially
- [ ] Zero `parallel-dev` invocations during the entire `tdd-loop` run (verifiable: no `parallel-dev` log entries, no new file in `docs/agents/dispatches/`)
- [ ] Phase 0.5 takes one decision-turn (read plan + classify + fall through) and produces no parallel dispatch
- [ ] No new branches matching `slice-*` created (other than the slice's own commit-branch, if any)
- [ ] Equivalent behavior to pre-v1.7.0 `tdd-loop` on a 1-slice plan: same output, same commit shape, same duration ±10%

## Fail conditions

- **Fail (false positive):** Phase 0.5 dispatches a single-member "pgroup" through `parallel-dev` — wasted overhead, broken contract (parallel-dev's Phase 2 size-check should also reject this, but defense-in-depth matters)
- **Fail (regression on single-slice flow):** Phase 0.5 hangs, errors, or otherwise blocks the single-slice TDD path — every existing habeebs-skill user's chain breaks
- **Fail (record written without dispatch):** a stray file in `docs/agents/dispatches/` appears even though no parallel work happened — substrate hygiene violated

## Why this scenario

If 10a (positive) is the "did the new wiring ship?" test, 10b is the "did we break the old path?" test. Both must pass for slice #6 to ship. In any production system, the regression test for "feature X must NOT activate when its preconditions aren't met" is at least as important as the test that X activates when they ARE met — and historically more often missed.

Per the plan's R5 (pgroup detection breaks single-slice flows), this scenario is the explicit acceptance criterion guarding that risk.
