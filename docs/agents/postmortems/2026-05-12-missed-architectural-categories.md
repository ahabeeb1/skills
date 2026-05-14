# Postmortem: missed architectural categories in single-lead decomposition

**Date discovered:** 2026-05-12
**Date of incident:** 2026-05-11 (approximate)
**Trace fidelity:** `[trace-from-memory]`

**Retrospective — recorded 2026-05-13; incident occurred 2026-05-11/12.** Backfilled per ADR-0011 § Decision: "at least one example postmortem entry committed (retrospective ... e.g., the 2026-05-12 missed-categories incident that drove Phase 2.5 critic)." Captures the original failure that motivated the Phase 2.5 category-completeness critic in v1.6.0.

## 1. Summary

A `prior-art-research` run on "how should parallel subagent processing work in habeebs-skill" produced a 3-sub-problem decomposition that missed two entire architectural categories: hook / event-handler surfaces, and subagent-driven-development patterns (Superpowers' implementer/reviewer triad). The chain proceeded against the incomplete decomposition; the resulting spec under-specified the dispatch contract and would have shipped without the 4-status return semantics if the user hadn't caught the gap in review. The failure motivated the Phase 2.5 category-completeness critic introduced in v1.6.0.

## 2. User prompt that triggered the chain

(Paraphrased — original trace not preserved.) "Research where parallel subagent processing should live in the habeebs-skill chain. What patterns do other teams use? How do we integrate?"

## 3. Expected outcome

A decomposition covering all the architectural surfaces a parallel-subagent system actually touches:

- Dispatch primitive (orchestration loop)
- Return contract (how subagents signal status to the parent)
- State persistence / audit log
- Pre-fetch context / preamble injection
- **Hook / event-handler surfaces** (where do `tdd-loop`, `write-plan` hand off to dispatch?)
- **Subagent-driven-development triad** (controller / implementer / reviewer — Superpowers pattern)
- Pause / resume / interruption semantics

7 sub-problems would have been appropriate.

## 4. Actual outcome

The Phase 2 decomposition produced 3 sub-problems: dispatch primitive, return contract, state persistence. The other 4 categories were missed entirely. Phase 4-5 deep-fetch ran against the incomplete decomposition; Phase 6 synthesis recommended a contract that addressed only what the decomposition surfaced. The dispatch / `tdd-loop` integration points and the implementer/reviewer composition pattern would have been invented from scratch in implementation rather than grounded in research evidence.

## 5. Transition-failure matrix

| Last successful phase | First failure phase | What failure phase missed |
|---|---|---|
| Phase 1 (Context capture) — accurate, scoped, complete | **Phase 2 (Decomposition)** | 4 architectural categories: hook/event-handler surfaces; subagent-driven-development triad; pause/resume semantics; preamble injection |

Phase 4-5 (deep-fetch) and Phase 6 (synthesis) ran correctly *against the incomplete input* — they produced the right recommendations for the 3 sub-problems they were given. The synthesizer cannot recover categories the decomposer never surfaced; "LLM synthesizer fills gaps with plausible text" was the silent failure mode (per LangGraph's documented multi-agent failure taxonomy).

## 6. Failure category

**`missed-architectural-categories`** — single-lead Phase 2 planner reliably misses entire categories of architectural concern on ambitious-scope features. The synthesizer downstream cannot recover what the decomposer never surfaced; coverage is the load-bearing axis of decomposition quality.

## 7. Fix applied

**Phase 2.5 category-completeness critic** added to `prior-art-research` in v1.6.0 (subsequently consolidated in v1.7.0 + v1.9.0 dispatches). The critic runs as ONE `parallel-dev` Phase 4 single-subagent dispatch (per ADR-0004) after Phase 2 produces a candidate decomposition; receives the decomposition + Phase 1 context + SYSTEM_CONTEXT preamble; returns either APPROVED or ADDITIONS PROPOSED with rationales. Lead either accepts (adds the surfaced category) or rejects with written reason. The bounded iteration cap (exactly ONE critic pass) keeps Phase 2.5 from becoming a coverage-debate hole.

Validated against the four-scenario adversarial dogfood suite at `tests/dogfood/09-category-critic/` (09a missing-observability, 09b missing-hooks, 09c missing-security, 09d no-gap control). Critic must surface the planted gap on 09a/b/c and return APPROVED with zero hallucinated additions on 09d.

## 8. v1.X.Y+ candidate rule

Already shipped — Phase 2.5 critic landed in v1.6.0 and has been load-bearing through every subsequent chain run. No new rule needed.

**Adjacent v1.11.0+ candidate rule** (related but different surface): when Phase 2.5 critic returns ADDITIONS PROPOSED but the lead rejects ALL proposed additions without surfacing them in the final report's "Phase 2.5 outcome" section, that's a silent-rejection violation per `prior-art-research` SKILL.md. Add a `verify-output` rule to detect this pattern by greping the final report for "Phase 2.5 outcome" or equivalent. Target v1.11.0.

## 9. Notes / trace fidelity

This postmortem is retrospective and uses `[trace-from-memory]` fidelity. The original 2026-05-11/12 trace is not preserved; the analysis is reconstructed from the v1.6.0 commit messages, ADR-0004's Context section, and the Phase 2.5 critic dogfood scenarios at `tests/dogfood/09-category-critic/`. Treat the failure-category naming as authoritative; treat the exact 4-sub-problems-missed list as best-recollection.

This entry exists primarily to anchor the postmortem convention and template structure for future entries — when a similar coverage incident occurs, the on-the-fly postmortem will have richer trace fidelity than this retrospective.
