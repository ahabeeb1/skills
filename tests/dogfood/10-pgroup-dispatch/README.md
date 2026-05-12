# Dogfood 10 — Pgroup auto-dispatch + idempotent re-invocation

**Date:** 2026-05-12
**Skills under test:** `skills/tdd-loop/SKILL.md` Phase 0.5 + `skills/write-plan/SKILL.md` Phase 8 + `skills/parallel-dev/SKILL.md` § Return contract
**Slice:** v1.7.0 #6
**Plan:** [`docs/agents/plans/0004-parallel-subagent-v1.7.0.md`](../../../docs/agents/plans/0004-parallel-subagent-v1.7.0.md) Phase 2 gate

## Why two scenarios

The pgroup auto-dispatch wiring (slice #6) has two failure modes and one scenario tests each:

- **False positive (10a-pgroup-positive):** the wiring must dispatch correctly when a pgroup of size ≥2 is ready
- **False negative (10b-no-pgroup-control):** the wiring must NOT dispatch when no pgroup ≥2 is ready — single-slice plans must no-op cleanly

10b is the load-bearing regression test. Pre-v1.7.0, `tdd-loop` had no Phase 0.5 — adding Phase 0.5 must not break the sequential single-slice path that every prior release used.

## Scenarios

| File | Type | Synthetic plan | Expected behavior |
|---|---|---|---|
| [10a-pgroup-positive.md](./10a-pgroup-positive.md) | Positive | 3 slices: `#1` and `#2` in `pgroup-1A`, `#3` sequential after | `#1` and `#2` dispatch in same turn; `#3` starts only after both complete; dispatch record written |
| [10b-no-pgroup-control.md](./10b-no-pgroup-control.md) | Negative (regression) | 1 slice (no pgroup ≥2 anywhere) | Zero `parallel-dev` dispatches; `tdd-loop` falls through to Phase 1 sequentially; no dispatch record written |

## Acceptance bar

Phase 2 gate of plan 0004 does NOT pass unless both scenarios produce the expected behavior on the PR branch.

## Note on numbering

Spec/plan referred to these as `tests/dogfood/08-pgroup-dispatch.md` and `08-no-pgroup-control.md` but slot 08 is taken (`08-hitl-labels.md`). Renumbered to `10/` (directory parallel to `09-category-critic/`).
