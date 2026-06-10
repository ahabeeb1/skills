---
Status: Proposed
Date-Created: 2026-06-10
Last-Reviewed: 2026-06-10
Superseded-By: null
Tier: Deep
Deciders: [Modie (owner), Claude (chain run)]
---

# Adopt a fresh-context-per-slice loop harness with classify-then-route triage and tiered fail-closed halts

**Status:** Proposed
**Date:** 2026-06-10
**Deciders:** Modie (owner), Claude (chain run)
**Tier:** Deep

## Context

habeebs-skill's chain ends each slice with human-paced invocation: the user runs `/tdd` per slice, reads failures, and decides what happens next. The Boris Cherny loop pattern ("I don't prompt anymore, I run loops") demands the inverse — an overnight-capable harness where the loop itself dispatches slices, corrects failures, and parks what it cannot decide. The Deep-tier research ([2026-06-09 loop-harness research](../research/2026-06-09-loop-harness-research.md)) found five gaps between Tier-0 machinery and that goal: no failure-triage rule, no bounded retry, no independent reviewer, no outer-loop driver, and a 1-shot NEEDS_CONTEXT bound too tight for autonomous runs.

Hard constraints: ADR-0002 (markdown-only, no runtime substrate), ADR-0003 Rule 3 (hooks never own state — which a Stop-hook loop's state file would violate), ADR-0004's 4-status contract and Phase 0.5 idempotent resume, and the Grill 2.0 decision ([re-grill edge ADR](./2026-06-09-add-regrill-edge-and-grill-alignment-axes.md)) that spec-implicated halts are human-resolved. Three independent observers put context collapse at ~100–150k tokens, ruling out any single-session loop; Claude Code issue #15047 documents cross-session resume hijack, making session identity a mandatory guard on any persisted loop state.

## Decision

We will build the loop harness as contract changes across existing skill surfaces plus one new artifact class — no hooks, no new substrate, no new skill. Specifically:

- **Outer loop:** `tdd-loop` Phase 0.5 is promoted from resume mechanism to iteration driver, invoked as `/tdd --loop`. Each iteration dispatches the next pending slice in **fresh context**; ceiling defaults to 2× open slices (`--max-iterations` override, recorded in run-file frontmatter); terminal states are `DONE` or `BLOCKED`-with-halt-report — no third exit.
- **Inner correction:** a classify-then-route triage rule in `tdd-loop` — transient-shaped failures get one re-run (budget 2); structural failures (assertion-shaped, or same-error-twice by string comparison) auto-invoke `systematic-debugging` in fresh context; spec-implicated failures take the existing re-grill edge unchanged.
- **Independent review:** `parallel-dev` defines a context-starved reviewer dispatch (diff + slice spec + bounding SHAs only — never the writer's conversation); both `parallel-dev` and the loop consume it. Findings are gaps-not-style, severity-gated; Critical findings hard-block in AFK mode. Reviewer PASS is evidence, never a substitute for deterministic assertions.
- **Halt policy, tiered fail-closed:** decision gates and structured halts **park** scope (per `scope_classification`) into a structured halt report and the loop continues on unaffected slices; three confirmation gates (fixture-ID confirm, verify-output ANNOTATE concerns, spec-compliance review) proceed **provisionally**, gated on green checks and logged for ratification; version-bump confirm parks. Halt *handling* changes; halt *authority* does not — the human-mediated re-grill rejection from Grill 2.0 is re-affirmed.
- **Loop state:** a per-run tracked markdown run file (iteration count, per-slice retry counters, last-error hash, session/worktree identity per the #15047 guard) living in `docs/agents/dispatches/` as a widened record class — skill-written only, advisory, ADR-0019-shaped staleness contract. The run ends by writing a RUN_SUMMARY morning-read whose halt sections name the resume command, `/tdd --resume <run-id>` (resume-by-inspection: run file + git, nothing else).
- **Bound widening:** ADR-0004 Part 1 is amended in place — NEEDS_CONTEXT re-dispatches go 1→2, each requiring materially changed input as judged by the dispatcher; unchanged input escalates immediately as `BLOCKED`. (Lands with slice 3.)
- **Explicitly deferred:** the ADR-0003 Stop-hook carve-out. No v1 surface needs hook-enforced continuation; taking that one-way door is reserved until a real need emerges.

The shape follows from the constraints: fresh-context-per-slice is the only loop topology that survives both the context-collapse ceiling and ADR-0003 Rule 3, and every mechanism above extends a contract Tier 0 already has (Phase 0.5, 4-status, re-grill payload, dispatch records) rather than adding substrate ADR-0002 forbids.

## Consequences

### Positive

- Overnight runs make real progress: independent slices continue past a parked halt instead of the whole run dying (the user's own concrete-example expectation from the grill).
- Bounded everything — retry budget 2, iteration ceiling 2× open slices, NEEDS_CONTEXT cap 2 — gives a termination guarantee; runaway token waste (premortem risk #1) is structurally impossible.
- The reviewer + provisional-execution logging gives merged work a second pair of eyes without blocking AFK throughput (premortem risks #2 and #3).
- Zero new substrate: ADR-0002 untouched, ADR-0003 untouched, one in-place ADR-0004 amendment.

### Negative / Accepted trade-offs

- No true hands-off continuation past human-judgment surfaces — parked work waits for morning.
- Fresh context discards session memory; repo artifacts carry everything, costing re-read tokens per iteration.
- Fixed retry budgets will occasionally truncate an almost-converged fix loop (aider #3450 class); accepted until field evidence demands configurability.
- Reviewer PASS is evidence, not proof — deterministic assertions remain the verification floor.

### Door classification (from the grill's User mental model)

Two-way door with **costly undo**: removing the harness costs one minor release plus a CHANGELOG migration note, and the run-file format is frozen (no breaking field changes) until removal. The ADR-0003 Stop-hook carve-out — the adjacent one-way door — was deliberately not taken.

### Operational impact

- One new artifact class in `docs/agents/dispatches/` (runtime writer path; ADR-0021 classification already covers the directory).
- The morning-after workflow is: read RUN_SUMMARY → ratify provisional actions → `/tdd --resume <run-id>` per parked slice.
- Severability under scope pressure (grill decision): slice 3 (NEEDS_CONTEXT widening) defers first, then 2, then 4; slices 1+5 are the spine.

## Alternatives considered

### Stop-hook continuation loop (ralph lineage)

A Stop hook re-injects "continue" until the plan is done — the most cited public pattern. Rejected: the hook needs a state file to know when to stop, which is exactly ADR-0003 Rule 3's forbidden artifact, and the loop inherits the session's context collapse at ~100–150k tokens.

### Single persistent long-context session

One session loops over all slices, keeping full memory. Rejected: three independent observers place quality collapse at ~100–150k tokens; an overnight multi-slice run blows through that ceiling with certainty.

### New wrapper skill / external orchestrator

A dedicated loop-runner skill or out-of-repo daemon owning dispatch and state. Rejected: duplicates the driver `tdd-loop` Phase 0.5 already is, and an external orchestrator is the runtime substrate ADR-0002 exists to forbid.

### Autonomous halt self-resolution (re-plan without the human)

On a spec-implicated halt, the loop re-grills itself and continues. Rejected: four-vendor convergence on fail-closed for judgment surfaces, and it would reverse Grill 2.0's explicit rejection of autonomous re-planning — the grill re-affirmed that halt authority stays human.

## Revisit triggers

This ADR should be reopened if any of:

- Retry budgets repeatedly hit on legitimately converging fixes → make budgets configurable.
- Re-grill rounds fire >2× per release cycle (existing Grill 2.0 trigger, now doubly load-bearing).
- Credible non-Claude loop-harness evidence contradicts fresh-per-slice → re-open the F1 fork.
- A real need for hook-enforced in-slice determinism emerges → take the deferred ADR-0003 carve-out (ADR-0019-shaped sub-clauses + `stop_hook_active` + session-ID guard are mandatory minimums).
- Field evidence of a legitimate long-wait failure misclassified as structural (OpenHands #5355 class) → add the wait-exemption deferred at grill.
- The 2026-06-15 headless credit-pool change materially alters fresh-session economics.

## References

- Research: [2026-06-09 loop-harness research](../research/2026-06-09-loop-harness-research.md)
- Spec: [2026-06-09 loop-harness spec](../specs/2026-06-09-loop-harness.md)
- Grill: [2026-06-09 loop-harness grill record](../specs/2026-06-09-loop-harness-grill.md)
- Related ADRs: ADR-0002 (standalone), ADR-0003 (hooks scope), ADR-0004 (dispatch contract — Part 1 amended by slice 3 of this release), ADR-0019 (advisory in-flight reads), ADR-0021 (dispatches/ as runtime writer path), [re-grill edge ADR](./2026-06-09-add-regrill-edge-and-grill-alignment-axes.md) (line-76 revisit trigger discharged by this decision; changelog entry lands with slice 6)

---

## Changelog

- 2026-06-10 — Initial ADR, status Proposed
