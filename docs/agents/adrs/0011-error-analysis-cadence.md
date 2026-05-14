# ADR-0011: Adopt error-analysis-first evals cadence — chain-postmortem section + verify-output classified as complementary

**Status:** Accepted
**Date:** 2026-05-13 (Proposed and Accepted same day — v1.10.0 release slice)
**Deciders:** Modie (Habeeb)

## Context

ADR-0008 (2026-05-13) added `verify-output` to the chain as a post-tdd anti-slop pass with ANNOTATE default and GATE opt-in. v1.9.0 shipped that skill plus three dogfood scenarios (`tests/dogfood/12-verify-output/`). As shipped, the chain's quality feedback loops are: synthetic dogfood scenarios (constructed test fixtures) plus `verify-output` as a static pre-commit check on the staged diff.

The 2026-05-13 ecosystem-alignment audit (prior-art-research run, in-conversation) pulled Hamel Husain + Shreya Shankar's ["LLM Evals: Everything You Need to Know"](https://hamel.dev/blog/posts/evals-faq/) (Jan 2026) as the canonical practitioner-consensus source on agent/chain evaluation. The thesis is **error analysis before infrastructure**: writing evaluators before observing real failure modes produces generic metrics that "create false confidence." Custom annotation tooling fitted to a domain runs ~10× faster than generic eval platforms, but only after the first error-analysis pass tells you what to annotate. Pass rates near 100% are a red flag, not a goal — they indicate weak adversarial coverage.

Applied to habeebs-skill: the synthetic dogfood scenarios approach Hamel's red-flag pattern by construction (test fixtures are designed to pass the relevant check). The `verify-output` skill is evaluator-first — it encodes KNOWN slop classes (unjustified comments, half-finished implementations, dead code, defensive validation past trusted boundaries, repeated boilerplate, feature creep, backward-compat shims for unshipped code). The chain has no mechanism for **finding NEW failure categories** that emerge from real chain runs — categories that `verify-output`'s ruleset doesn't yet encode.

The audit's prescription, lifted from Hamel's framework: pair the static evaluator (`verify-output`) with a post-incident **error-analysis** loop that examines real conversation traces from chain runs that went sideways. Each postmortem documents the failure category — a category that, once named, can be added to `verify-output`'s ruleset OR captured as a new failure-mode pattern in a SKILL.md. This is the feedback loop that turns static evals into living evals.

The decision is needed NOW because v1.10.0 is the natural release boundary for absorbing the audit's findings, and the postmortem mechanism is doc-only (markdown convention + directory + template) — it ships in days, not weeks. Deferring it means v1.10.0 ships the audit's findings without the operational loop that makes them actionable.

The grill record (`specs/v1.10.0-context-engineering-alignment-grill.md` § Item Q3) closed two related sub-decisions: (a) postmortems and `verify-output` are **complementary at different loop positions**, not peers with overlapping scope; (b) postmortems ship as a **section in `using-habeebs-skill`** for v1.10.0 — not a standalone skill — with a v1.11.0 promotion criterion if uptake passes a threshold.

## Decision

We will adopt error-analysis-first as habeebs-skill's evals philosophy and introduce a chain-postmortem cadence complementary to `verify-output`. Specifically:

- **Classification — `verify-output` and `chain-postmortem` are complementary, NOT peers.**
  - `verify-output` (ADR-0008): **static pre-commit check** on the **staged diff**, encodes **KNOWN slop classes** at commit time. Output: block-commit OR annotate-with-concerns. Runs on every `tdd-loop` Pass 5c.
  - `chain-postmortem` (this ADR): **post-incident error-analysis** on the **full conversation trace** from a chain run that went sideways. Output: **NEW failure categories** documented as durable markdown that feeds back into `verify-output`'s ruleset and/or SKILL.md anti-pattern lists. Runs manually when the user (or a future agent) decides a chain run merits review.

  Different inputs (diff vs. trace), different timing (before commit vs. after problem), different outputs (block-commit vs. new-rules-discovered). Combining them into one mechanism would conflate the static evaluator's job (catch known patterns at commit) with the dynamic loop's job (find new patterns from production). Hamel's specific warning is against eval-driven development — treating evaluators as the primary signal rather than as a *consequence* of error analysis.

- **Postmortem cadence ships as a section in `using-habeebs-skill/SKILL.md` for v1.10.0.** Specifically: a new section titled `## When chain runs go wrong — postmortem cadence` documenting the trigger conditions (user says "that didn't work well", a chain run produced a wrong-shaped output, a slice landed but with concerns, a dispatched subagent BLOCKED unexpectedly), the artifact (one markdown file at `docs/agents/postmortems/YYYY-MM-DD-<slug>.md`), and the template (transition-failure-matrix structure — see next bullet).

- **New directory `docs/agents/postmortems/`** with a `README.md` template that documents the transition-failure-matrix structure. Each postmortem captures: (a) the user prompt that triggered the chain, (b) the expected outcome, (c) the actual outcome, (d) the **last-successful-phase × first-failure-phase grid** (Hamel's transition-failure-matrix — names exactly where the chain went off the rails), (e) the failure category (named in prose; aspires to become a v1.11.0+ `verify-output` rule or SKILL.md anti-pattern bullet), (f) the fix that was applied (or "left open"), (g) the v1.11.0+ candidate rule this failure suggests.

- **`verify-output/SKILL.md` cross-references the postmortem mechanism** with a single "see also" pointer: "When `verify-output` keeps missing a failure class, a postmortem at `docs/agents/postmortems/` is the canonical place to document the new category and propose a rule for the next release."

- **At least one retrospective postmortem committed** in Slice 3: the 2026-05-12 missed-categories incident that drove Phase 2.5 critic adoption (see ADR-0004 § Context — "the user's pain ('we missed hooks, missed subagent-driven patterns')"). Backfilling one real example anchors the directory and shows future users what a postmortem looks like.

- **v1.11.0 promotion criterion** (the section→skill upgrade path): if 10+ real postmortems land in 90 days OR a user explicitly requests a dedicated `/postmortem` skill → promote the section to a standalone `chain-postmortem` SKILL.md with a description tuned to failure-shaped trigger phrases ("the chain went sideways", "this didn't work", "why did the slice fail"). This promotion is opt-in based on observed uptake, not pre-decided — the section path tests the demand cheaply (lower description-budget pressure, fewer SKILL.md files to maintain) before committing to a SKILL.md surface.

The decision frames the static evaluator and the dynamic loop as **inputs to each other**: postmortems generate the rules that `verify-output` enforces; `verify-output` enforces the rules; postmortems find the rules `verify-output` missed. Together they form a single feedback loop with two phases — Hamel's error-analysis-before-infrastructure principle applied to a markdown-only chain.

## Consequences

### Positive

- Pairs the existing static evaluator with a dynamic error-analysis loop, satisfying Hamel's principle and closing the audit's "no real-trace error analysis" gap.
- The transition-failure-matrix structure gives postmortems a concrete schema — postmortem authoring becomes filling a template, not creative writing.
- Cross-references from `verify-output` mean users who hit slop-class misses are routed to the postmortem mechanism, not left to invent their own response.
- Future Phase 0 reconciliation outcomes can cite recent postmortems as evidence; the audit log compounds.
- ADR-0011 becomes Tier 0 prior art for any future research on chain quality / evals.
- The v1.11.0 promotion path keeps the section→skill upgrade reversible and demand-driven; we don't ship a skill that nobody triggers.

### Negative / Accepted trade-offs

- **Postmortem cadence is aspirational, not enforced.** No CI or hook fires when a chain run goes sideways; the user (or agent) has to decide to write one. Accepted: ADR-0002 binds (no runtime substrate); the cadence is a convention, not an automation. Hamel's 100/cycle minimum is unreachable for an OSS plugin; even 1-10/quarter is load-bearing.
- **Section in `using-habeebs-skill` is less discoverable than a standalone skill.** Description-driven trigger is the load-bearing mechanism per Anthropic Skills 2.0; a section under an umbrella skill doesn't get its own trigger surface. Accepted: the v1.11.0 promotion criterion converts the section to a skill once uptake demand is empirically observed.
- **`docs/agents/postmortems/` adds a new tracked-artifact directory.** Long-running repos may accumulate many records. Accepted: revisit trigger fires at 100 records to introduce retention policy.
- **Retrospective postmortems (like the 2026-05-12 missed-categories one) blur the line between "happened recently" and "happened at a date that's far enough in the past that the trace is gone."** Accepted: better to backfill one example with imperfect trace fidelity than to ship the directory empty. The README template explicitly invites retrospective entries with "trace-from-memory" tagging.
- **Postmortems and `verify-output` may briefly disagree on a borderline failure** before the postmortem-driven rule lands in `verify-output`. Accepted: that's the loop working — disagreement IS the signal that a new rule is needed.

### Operational impact

- **No new install steps for users.** All artifacts are markdown additions inside the plugin.
- **`docs/agents/postmortems/.gitkeep` is added** in Slice 3 to anchor the convention.
- **`tests/dogfood/15-postmortem-structure/`** (added in Slice 3) asserts the README template contains the required transition-failure-matrix sections.
- **v1.10.0 manifest bump is MINOR.** Additive — `verify-output` semantics unchanged; new section + new directory + new template + cross-reference.

## Alternatives considered

### Ship a standalone `chain-postmortem` skill in v1.10.0

Create a new SKILL.md with a description tuned to failure-shaped phrases, full progressive disclosure under `skills/chain-postmortem/`. **Rejected** for v1.10.0 because uptake is unknown — the audit surfaced the need but no real-user data confirms postmortem-shaped triggers happen often enough to earn a SKILL.md slot. Description-budget pressure from v1.9.0's recent trim makes adding a new description costly; the v1.11.0 promotion path tests demand cheaply first. **Decision is reversible:** if uptake passes the v1.11.0 promotion criterion, the section→skill promotion is straightforward.

### Treat `verify-output` and postmortems as peers with overlapping scope

Leave the relationship undefined; let users pick whichever mechanism feels right per case. **Rejected** because Hamel's specific warning is against eval-driven development — the failure mode is treating evaluators (static rules) and error analysis (dynamic discovery) as interchangeable, which biases toward writing more evaluators instead of doing the analysis. Explicit classification ("static pre-commit" vs. "post-incident error-analysis") forecloses that drift.

### Skip postmortems; just keep adding to `verify-output`'s ruleset opportunistically

Let `verify-output` grow organically as users notice slop classes; don't introduce a formal error-analysis loop. **Rejected** because this is the path Hamel explicitly warns against: evaluators grow without the underlying analysis, and the rules become folklore rather than evidence-derived. The transition-failure-matrix template makes the analysis structured and the rule-derivation traceable.

### CI-enforced postmortem cadence (a hook that fires when a chain run flags itself as failed)

Wire a Claude Code hook to require a postmortem entry before the next chain invocation if the previous one BLOCKED. **Rejected** because ADR-0002 binds (no runtime substrate); the cadence is conventional, not automated. Hooks could be reconsidered if revisit trigger fires (postmortems trending to zero per quarter).

## Revisit triggers

This ADR should be reopened if any of:

- **Q1 promotion fires:** 10+ real postmortems land in 90 days OR explicit user request for `/postmortem` skill → promote section to standalone `chain-postmortem` SKILL.md. Land in v1.11.0.
- **Postmortem volume reaches >20/quarter** → manual cadence may merit lightweight CI tooling (would require ADR-0002 amendment).
- **Postmortem volume trends to zero per quarter** → cadence isn't working; either the conventional trigger phrases aren't surfacing or chain runs aren't failing meaningfully. Re-examine triggers OR consider hook enforcement.
- **`verify-output` rule count grows past ~20** without a corresponding postmortem trail → rules are becoming folklore; revisit the loop and require postmortem citations for new rules.
- **Hamel/Shreya publish a v2 evals framework** with concrete schema deltas → revisit the transition-failure-matrix structure.
- **`docs/agents/postmortems/` exceeds 100 records** → introduce retention policy with `/sync` cleanup pass; old postmortems migrate to `docs/agents/postmortems/archive/`.

## References

- Research: prior-art-research run 2026-05-13 (in-conversation; archived as [`docs/agents/research/v1.10.0-context-engineering-alignment-research.md`](../research/v1.10.0-context-engineering-alignment-research.md) in Slice 0)
- Spec: [`specs/v1.10.0-context-engineering-alignment`](../specs/v1.10.0-context-engineering-alignment.md) § Slice 3
- Grill: [`specs/v1.10.0-context-engineering-alignment-grill`](../specs/v1.10.0-context-engineering-alignment-grill.md) § Item Q1, Q3
- Sister ADRs:
  - [`adrs/0008-verify-output-skill-scope`](./0008-verify-output-skill-scope.md) — classifies the static evaluator; this ADR adds the dynamic-loop counterpart
  - [`adrs/0002-habeebs-skill-standalone`](./0002-habeebs-skill-standalone.md) — preserved (markdown-only postmortems, no runtime substrate)
  - [`adrs/0009-docs-agents-references-convention`](./0009-docs-agents-references-convention.md) — `docs/agents/postmortems/` follows the same convention pattern as `references/` and `dispatches/`
- External sources:
  - [Hamel Husain + Shreya Shankar — LLM Evals: Everything You Need to Know](https://hamel.dev/blog/posts/evals-faq/) — canonical source for error-analysis-before-infrastructure; transition-failure-matrix structure
  - [Hamel Husain — Your AI Product Needs Evals (2024)](https://hamel.dev/blog/posts/evals/) — earlier essay; classification of static vs. dynamic evals
  - [Shreya Shankar — Operationalizing Machine Learning](https://ucbepic.github.io/) — agent failure modes / ML production
  - [Cognition AI — Don't Build Multi-Agents](https://cognition.ai/blog/dont-build-multi-agents) — handoff-cascading-failure mode that postmortems can isolate

### Reference implementations cited

- **Transition-failure-matrix:** Hamel + Shreya's evals FAQ — Cited because the postmortem template adopts the "last successful state × first failure" grid structure as the canonical schema for chain-run error analysis.

---

## Changelog

- 2026-05-13 — Initial ADR, Accepted same day (v1.10.0 release; implementation lands in Slice 3).
