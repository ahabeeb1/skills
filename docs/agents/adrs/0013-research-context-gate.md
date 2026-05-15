# ADR-0013: The `prior-art-research` Phase 1 context gate is adaptive, not a hard block

**Status:** Accepted
**Date:** 2026-05-15
**Deciders:** Modie (Habeeb)

## Context

A review of the `/research` command asked whether `prior-art-research` should
ask clarifying questions before researching, or run on the prompt as-is.

Questions-first is already the design: `prior-art-research/SKILL.md` runs Phase
0 (repo recon) then Phase 1, which asks up to 5 staged questions (2, then 3)
plus optional steering slots. `CLAUDE.md` lists "skipping the context-capture
questions" as an anti-pattern. The review was not a proposal to add a gate — it
was a question about whether the *existing* gate is shaped right.

Two problems surfaced:

1. **The command and the skill contradicted each other.** `commands/research.md`
   said "Ask the user the 5 context questions. Wait for answers. Do not proceed
   without them." — an absolute hard block. `SKILL.md` Phase 1 said the
   opposite: accept partial / "I don't know" answers, proceed, and flag
   unknowns with `[assumed]`/`[unknown]` tags. The command is read last, so the
   effective behavior was stricter than the skill intends.

2. **The gate was binary** — full staged 5 questions regardless of scope. For
   an obviously-Quick scope (single sub-problem, shipping-speed signalled in the
   prompt) the two question round-trips can cost more than the research itself.

## Decision

The Phase 1 context gate stays, but is **adaptive**:

- **Keep questions-first.** Research here is convergent and expensive (Deep mode
  is ~15-20 min, 10-20 sources, parallel subagents). Context — scale, stack,
  priorities — weights Phase 4 source tiering and is the only thing that
  prevents the skill's own "FAANG-scale solutions for non-FAANG-scale problems"
  anti-pattern. The whole downstream chain inherits Phase 1's Context section.
  The cost asymmetry decisively favors asking.

- **Scale the asking to the anticipated mode.** Phase 1 precedes the formal
  mode choice (Phase 3), but scope is usually legible from the prompt. Obvious
  Quick scope → collapse to the 2 foundational questions, or to a single
  confirmation line when Phase 0 + the prompt already cover them, and proceed on
  assumptions tagged `[assumed]`. Reserve the full staged 2-then-3 for Deep
  scopes, where the run justifies two round-trips.

- **Never hard-block.** Partial or "I don't know" answers are accepted; the run
  proceeds with unknowns flagged. `commands/research.md` is corrected to match
  `SKILL.md` Phase 1 — search must not start until Phase 1 context is captured
  *or explicitly waived*.

## Consequences

### Positive

- The command and skill no longer contradict; the skill is the single source of
  truth for gate behavior.
- Quick-scope research stops paying a fixed two-round-trip tax.
- Questions-first is preserved as the canonical gate, with its rationale
  recorded so future audits don't re-litigate it.

### Negative / Accepted trade-offs

- "Obvious Quick scope" is a judgment call made before Phase 3; an agent may
  collapse the gate on a scope that turns out to need Deep mode. Accepted — the
  `[assumed]` tags in the Context section make the thin inputs visible, and the
  user can correct mid-run.
- Adaptive asking is harder to dogfood-test deterministically than a fixed
  5-question script. Accepted — the gate's intent is legibility, not a fixed
  question count.

## Alternatives considered

- **Hard block, always ask 5.** Rejected — over-rigid; punishes well-specified
  prompts and contradicts the skill's own accept-partial rule.
- **Remove the gate, infer everything from Phase 0 + prompt.** Rejected — Phase
  0 cannot infer scale, priorities, or greenfield/retrofit; those drive the
  recommendation and cannot be re-derived from the repo.

## Revisit triggers

- Research runs repeatedly proceed on `[assumed]` scale and produce
  mis-tiered recommendations → tighten the Quick-mode collapse rule.
- A deterministic dogfood scenario for adaptive asking becomes necessary →
  formalize the "obvious Quick scope" heuristic into a testable predicate.

## References

- Skill: [`prior-art-research/SKILL.md`](../../../skills/prior-art-research/SKILL.md) § Phase 1
- Command: [`commands/research.md`](../../../commands/research.md)
- Sister ADRs:
  - [`adrs/0005-lifecycle-split-glossary-and-system-context.md`](./0005-lifecycle-split-glossary-and-system-context.md) — chains `setup-habeebs-skill` into Phase 0, which feeds Phase 1

---

## Changelog

- 2026-05-15 — Initial ADR, Accepted same day.
