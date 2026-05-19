# ADR-0016: The chain runs at a depth tier — Quick, Balanced, or Deep — carried in artifact headers

**Status:** Accepted
**Date:** 2026-05-18
**Deciders:** Modie (Habeeb)

## Context

`prior-art-research` had a **binary** depth system, chosen in its Phase 3:
Quick mode (single agent, ~5 sources) or Deep mode (one subagent per
sub-problem, 10-20 sources). That binary lived inside one skill. The rest of
the chain (`prior-art-research → draft-spec → socratic-grill →
decision-record → write-plan → tdd-loop`) had no shared notion of how much
effort a feature warranted — a trivial feature still got the same full spec /
grill / ADR / plan ceremony as a greenfield architecture.

ADR-0013 already made the Phase 1 context gate *adaptive* to the anticipated
mode, on the same cost-asymmetry reasoning. This ADR extends that adaptivity
from one gate to the whole chain, and from a binary to a graded scale.

Two requirements shaped the design:

1. The scale must reflect both **task complexity** (constraints, sub-problem
   count) and **residual ambiguity** — how unclear the task still is *after*
   Phase 1 follow-up questions.
2. A lighter tier must never produce a worse *decision*. It may only remove
   ceremony; correctness gates stay.

## Decision

**The chain runs at one of three tiers — Quick, Balanced, Deep.** Quick and
Deep keep their existing meaning (no existing `/research` invocation breaks);
Balanced is the new middle tier. The full tier table, auto-detect rule, and
invariants live in [`references/tier-scale.md`](../references/tier-scale.md);
this ADR records the load-bearing decisions.

**1. The tier governs the whole chain.** Every chain step scales with the
tier — research depth, whether the Phase 2.5 critic runs, spec verbosity,
whether the grill runs, whether an ADR is written, whether `write-plan` runs.
`tdd-loop` always runs in full; the tier scales *design*, not implementation.

**2. The tier travels in artifact headers, not runtime state.** The chain has
no runtime substrate by design (ADR-0002), and `SYSTEM_CONTEXT.md` has a
single writer (ADR-0005). So the tier is written by `prior-art-research`
Phase 3 into the research report header as `**Tier:**`, and every downstream
skill reads it from the upstream artifact it already reads in full, then
echoes `**Tier:**` into its own output header — exactly how `Slug` / `Status`
already propagate. The tier is decided once; downstream skills inherit it.

**3. Selection is auto-detect plus override.** Phase 3 scores three signals
(residual ambiguity, sub-problem count, constraint complexity) and sums to a
tier. `/research` accepts `--quick | --balanced | --deep` to override.

**4. Two non-negotiable invariants** (see `tier-scale.md`):

- *Tiers scale effort, never decision quality.* A real decision always pulls
  in the skill that handles it regardless of tier — non-empty open questions
  always trigger `socratic-grill`; a one-way-door decision always triggers an
  ADR — and an override never disables a triggered quality gate. The
  auto-detect carries an **ambiguity floor**: a high-ambiguity task can never
  resolve to Quick.
- *User-facing output stays focused.* Tier announcements and HANDOFF lines
  cite task-based reasons only; they never expose token, cost, or time-budget
  rationale.

## Consequences

### Positive

- A trivial feature reaches a plan fast; an ambitious one still gets the full
  treatment. The chain stops applying uniform ceremony to non-uniform work.
- Quick/Deep semantics are unchanged, so no existing invocation breaks; the
  output-template rename `Mode:` → `Tier:` is the only format change.
- The tier mechanism reuses the existing header-propagation contract — no new
  state layer, consistent with ADR-0002 and ADR-0005.

### Negative / Accepted trade-offs

- The auto-detect is a heuristic scored before the chain commits; it can
  mis-tier a borderline task. Accepted — it is not a hard gate (ADR-0013), the
  user can override, and the ambiguity floor protects the high-risk direction.
- Three tiers are harder to dogfood-test than a binary. Accepted — mitigated
  by a tier-detection eval over a labelled calibration set
  (`tests/dogfood/20-depth-tier/`).

## Alternatives considered

- **Encode the tier in the HANDOFF string.** Rejected — HANDOFF lines are
  navigation pointers, not state payloads (the full-doc-read contract in
  `using-habeebs-skill`). A header field in the document is the existing,
  contract-compliant carrier.
- **Write the tier to `SYSTEM_CONTEXT.md`.** Rejected — that file is per-repo
  and single-writer (ADR-0005/0010); the tier is per-feature state and would
  violate both invariants.
- **Keep the binary, scope it to research only.** Rejected — does not address
  the actual pain: uniform spec/grill/ADR/plan ceremony on trivial features.

## Revisit triggers

- The tier-detection eval drops below ~90% on the calibration set → re-weight
  the three signals or adjust the score thresholds.
- Users routinely override the auto-detected tier in one direction → the
  default rule is mis-calibrated; re-tune.
- A fourth tier is repeatedly requested → reconsider the three-tier split.

## References

- Reference: [`references/tier-scale.md`](../references/tier-scale.md) — tier
  table, auto-detect rule, invariants
- Skill: [`prior-art-research/SKILL.md`](../../../skills/prior-art-research/SKILL.md) § Phase 3
- Extends: [`adrs/0013-research-context-gate.md`](./0013-research-context-gate.md) —
  adaptive Phase 1 gate; ADR-0016 generalizes the same adaptivity chain-wide
- Sister ADRs: [`adrs/0002-habeebs-skill-standalone.md`](./0002-habeebs-skill-standalone.md)
  (no runtime substrate), [`adrs/0005-lifecycle-split-glossary-and-system-context.md`](./0005-lifecycle-split-glossary-and-system-context.md)
  (single-writer SYSTEM_CONTEXT)

---

## Changelog

- 2026-05-18 — Initial ADR, Accepted same day.
