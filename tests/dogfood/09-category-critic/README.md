# Dogfood 09 — Category-completeness critic (4-scenario adversarial suite)

**Date:** 2026-05-12
**Skill under test:** `skills/prior-art-research/SKILL.md` Phase 2.5 + `skills/parallel-dev/agents/category-completeness-critic.md`
**Slice:** v1.7.0 #5
**Plan:** [`docs/agents/plans/0004-parallel-subagent-v1.7.0.md`](../../../docs/agents/plans/0004-parallel-subagent-v1.7.0.md) Phase 2 gate

## Why a directory, not a single file

The category-completeness critic exists to fix a specific failure mode: a single-agent Phase 2 planner that misses entire categories of architectural concern (per the v1.6.0 hooks miss — `prior-art-research` decomposed habeebs-skill into core skills + integration but missed `hooks / event handlers` and `subagent-driven patterns`). A single-scenario dogfood risks the critic memorizing one planted-gap pattern rather than catching real gaps. **Four scenarios — three positive (missing-category) and one negative (no-gap control) — make the test adversarial**: the critic must catch real gaps AND must NOT hallucinate categories that aren't actually missing.

## The scenarios

| File | Type | Planted gap | Expected verdict |
|---|---|---|---|
| [09a-missing-observability.md](./09a-missing-observability.md) | Positive | Planner sees "build a job queue", misses `Observability / metrics / alerting` | ADDITIONS PROPOSED, surfaces observability |
| [09b-missing-hooks.md](./09b-missing-hooks.md) | Positive | Planner sees "plugin methodology", misses `Hooks / event handlers` (literal v1.6.0 reproducer) | ADDITIONS PROPOSED, surfaces hooks |
| [09c-missing-security.md](./09c-missing-security.md) | Positive | Planner sees "user-uploaded files", misses `Security / auth / permissions` | ADDITIONS PROPOSED, surfaces security |
| [09d-no-gap-control.md](./09d-no-gap-control.md) | **Negative** (false-positive gate) | None — decomposition is complete | APPROVED, zero hallucinated additions |

## Acceptance bar

Phase 2 gate of plan 0004 does NOT pass unless all four scenarios produce the expected verdict on the PR branch. 09d is the load-bearing scenario — it catches rubber-stamping-by-padding, which is the failure mode where a sycophantic critic invents categories to "look productive". 09b is the literal reproducer of the v1.6.0 miss (the bleeding pain that drove this work).

## How to run

These are illustrative scenarios, not automated tests. Run each manually against the chain:

1. Invoke `prior-art-research` on the scenario's `feature` field
2. Provide the scenario's `phase1_context` when the chain asks the Phase 1 gap-filling questions
3. When the chain reaches Phase 2 and produces the `proposed_decomposition` shown in the scenario, manually invoke Phase 2.5 (the chain will do this automatically post-v1.7.0; pre-merge dogfood does it manually)
4. Inspect the critic's output against the scenario's "Expected verdict" section
5. Pass / fail per the acceptance bar above

If pre-v1.7.0 (chain doesn't yet invoke Phase 2.5 automatically), invoke `skills/parallel-dev/agents/category-completeness-critic.md` directly as a subagent prompt with the scenario's inputs.

## Revisit triggers

- All four scenarios pass too easily across 3+ unrelated feature types (>30 days post-merge) — critic may be pattern-matching scenario structure rather than catching real gaps; add new adversarial scenarios
- 09d false-positive control fails (critic invents categories) — tune critic prompt; the no-pad-rule is load-bearing
- Real-world miss surfaces post-merge — add the missed category type as a new scenario (e.g., 09e, 09f)
