---
Status: Accepted
Date-Created: 2026-06-09
Last-Reviewed: 2026-06-09
Superseded-By: null
Tier: Balanced
Deciders: [Modie (project lead)]
---

# Add a re-grill edge, slice-shape axis, and mental-model probes to the grill

**Status:** Accepted
**Date:** 2026-06-09
**Deciders:** Modie (project lead)
**Tier:** Balanced

## Context

socratic-grill is the chain's alignment gate, but on v1.24.0 it has three confirmed blind spots: it never validates the slice decomposition (its 7 axes are feature-decision-only — 9 of 12 historical grill records grilled slice shape only ad-hoc, and the v1.20.0 record's PT-4 caught a factually wrong slice-ordering justification by luck of agenda); it has no sanctioned path back from implementation when a slice reveals spec ambiguity (only a soft Phase 6 retro suggestion in tdd-loop — the same undefined-backward-edge gap that makes Kubernetes SIGs improvise inconsistent KEP status resets); and it probes the spec's clarity, never the user's expectations (all 3 documented mental-model misses — v1.13.0 D4, v1.19.0 OQ-6, v1.22.0 OQ-5/6 — were caught late by user pushback). Constraints: markdown-only per ADR-0002, behavioral-only skill bodies per ADR-0022, dated artifacts per the [dated-naming decision](./2026-05-28-decouple-decision-identity-from-releases.md). Priorities: correctness, scale headroom.

## Decision

We will extend the grill on three surfaces, all conversation-shaped, none adding a new status or phase:

- **Slice-shape becomes the 8th ambiguity axis**, and the spec's slice table becomes a standing Phase 1 inventory item class. Probes: vertical-ness, deprioritization test, size balance, HITL-gate necessity, ordering justification, parallelizability. No pass/fail rubric.
- **Re-grill becomes a first-class edge:** tdd-loop's BLOCKED payload gains `suggested_action: "re-grill"` with a 7-field learning payload (blocked_slice, blocked_decision quoted from spec, expected_vs_observed, evidence, attempted_resolutions, scope_classification, salvaged_sibling_results) surfaced as a fixed-format halt block with exactly two exits. The scoped re-grill round runs in fresh context on the named decision only and resolves by the **blast-radius rule**: a patch is minor iff it changes no other slice's acceptance criteria, adds no slice, and touches neither Architecture nor Concrete picks — otherwise it escalates to ADR amendment/supersession. Every round writes a new dated grill record back-linked to the original. Conditional extensions re-fire only under the **domain-touch rule** (the one extension whose domain the blocked decision touches, on that item only). In-flight siblings follow the **pause-all default** (pause at next checkpoint when cause is ambiguous; lead may classify slice-local to let them run; finished sibling results enter the payload as evidence).
- **Three indirect mental-model probes in grill Phase 1**, count tier-scaled (Quick 1 / Balanced 2 / Deep 3): premortem, concrete-example demand on the riskiest decision, and a door-classification challenge with the one-follow-up rule (every "two-way" label gets "what's the undo cost, concretely?"). Answers land in a "User mental model" record section with two mandatory consumers: write-plan (success criteria → acceptance-gate candidates) and decision-record (door labels → ADR consequences).

The shape follows convergent external evidence: no mature process loops backward in-place (Rust RFCs force a new back-linked artifact; Anthropic's guidance restarts in fresh context; obra/superpowers prohibits autonomous re-planning), working pre-implementation gates are conversations with judgment rather than checklists (Scrum.org's Definition-of-Ready anti-pattern), and effective mental-model probes are indirect (Example Mapping, Klein's premortem, Amazon's door framework).

## Consequences

### Positive

- Slice defects (horizontal slicing, wrong ordering justifications, unnecessary HITL gates) get caught pre-implementation by a standing agenda item instead of by luck.
- Mid-implementation spec ambiguity has a sanctioned, structured resolution path — no more improvised resets or silently drifting specs.
- User expectations (success criteria, reversibility beliefs) become recorded, consumed artifacts instead of late-stage pushback.
- The 4-status dispatch vocabulary survives intact; zero migration for existing consumers.

### Negative / Accepted trade-offs

- More grill ceremony per run — contained by tier-scaled probe counts, but Balanced runs get measurably longer.
- Re-grill is human-mediated: every spec-invalidating ambiguity costs a human round-trip (deliberate — autonomous re-planning rejected on convergent peer evidence).
- Slice-shape grilling stays judgment-based; quality depends on the conversation, not a mechanical check.

### Operational impact

- No runtime, hooks, or scripts change — five skill/reference/template markdown surfaces (`socratic-grill`, `tdd-loop`, `parallel-dev`, `write-plan`, `decision-record`) plus GLOSSARY and dogfood fixtures.
- Pause-all sibling default makes parallel-dev dispatches conservatively halt on ambiguous causes; worktree isolation makes the pause lossless.

## Alternatives considered

### Status quo — soft retro question only

tdd-loop Phase 6 already suggests "re-run socratic-grill if material." Rejected: the KEP evidence shows undefined backward edges produce improvised, inconsistent practice; the suggestion has no payload, no scope, no record convention.

### 5th dispatch status (RE_GRILL)

Top-level visibility for the re-grill signal. Rejected: breaks the locked 4-status vocabulary across tdd-loop, parallel-dev, verify-output, and all dispatch records for zero migration benefit; no consumer needs status-level visibility.

### Autonomous re-plan loop

Agent self-corrects the spec and continues without a human. Rejected on convergent peer evidence: superpowers prohibits it outright; Anthropic's two-corrections rule says accumulated failed context pollutes further attempts; the grill's purpose is human-agent alignment, which an autonomous loop bypasses.

### Separate Phase 1.5 slice-review gate

A dedicated mandatory phase for slice validation. Rejected: the Definition-of-Ready calcification path — a standing checklist phase decays into a stage-gate contract; the axis + item-class shape keeps the same guarantee (slice table always enters the agenda) while staying conversational.

## Revisit triggers

This ADR should be reopened if any of:

- Re-grill rounds fire more than twice in one release cycle — the blast-radius boundary is mis-tuned (too strict forces ceremony; too loose lets specs drift).
- A slice-shape item produces user-overridden false positives in 3+ consecutive runs — re-tune the axis probes.
- Mental-model probes draw one-word answers (probe fatigue) — reduce Balanced count to 1 and re-evaluate phrasing.
- A future release adds unattended/headless chain execution — the human-mediated re-grill assumption no longer holds and the autonomous-re-plan rejection needs re-research.

## References

- Research: [2026-06-09-grill-2.0-alignment-research.md](../research/2026-06-09-grill-2.0-alignment-research.md)
- Spec: [2026-06-09-grill-2.0-alignment.md](../specs/2026-06-09-grill-2.0-alignment.md)
- Grill: [2026-06-09-grill-2.0-alignment-grill.md](../specs/2026-06-09-grill-2.0-alignment-grill.md)
- External sources:
  - https://github.com/kubernetes/enhancements/issues/2960 — undefined backward edge → improvised practice
  - https://github.com/rust-lang/rfcs/blob/master/README.md — amendment cap; new back-linked artifact for substantial change
  - https://github.com/obra/superpowers/blob/main/skills/executing-plans/SKILL.md — halt-to-human prohibition on autonomous re-plan
  - https://code.claude.com/docs/en/best-practices — fresh-context restart after repeated corrections
  - https://www.scrum.org/resources/blog/scrum-anti-patterns-taxonomy — Definition-of-Ready checklist decay
  - https://cucumber.io/blog/bdd/example-mapping-introduction/ — indirect mental-model probing
  - https://hbr.org/2007/09/performing-a-project-premortem — prospective hindsight
  - https://aws.amazon.com/executive-insights/content/how-amazon-defines-and-operationalizes-a-day-1-culture/ — door classification and its misclassification hazard

---

## Changelog

- 2026-06-09 — Initial ADR, status Proposed
- 2026-06-09 — Status moved to Accepted, implementation started in slice #1
- 2026-06-10 — Revisit trigger "a future release adds unattended/headless chain execution" FIRED (the [loop-harness decision](./2026-06-10-loop-harness-fresh-context-outer-loop.md) adds exactly that) and is hereby DISCHARGED: the Deep-tier re-research re-affirmed the autonomous-re-plan rejection on four-vendor fail-closed convergence. AFK loops change halt *handling* — re-grill halts now park scope into a structured halt report queued in the RUN_SUMMARY instead of stopping the whole run — but halt *authority* is unchanged: re-grill rounds remain human-mediated and never self-resolve.
