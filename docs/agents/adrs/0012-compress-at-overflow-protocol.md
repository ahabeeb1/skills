# ADR-0012: Adopt the Compress-at-overflow protocol — markdown-only summary-and-flush, 7-section template, passive doc for v1.10.0

**Status:** Accepted — amended in place 2026-05-22: template path moved from `docs/agents/templates/session-summary-template.md` to `skills/using-habeebs-skill/references/session-summary-template.md` (single-consumer skill, per ADR-0009's 3-consumer threshold; `docs/agents/templates/` retired).
**Date:** 2026-05-13 (Proposed and Accepted same day — v1.10.0 release slice) → 2026-05-22 (Amended — template relocation)
**Deciders:** Modie (Habeeb)

## Context

The 2026-05-13 ecosystem-alignment audit (prior-art-research run, in-conversation) pulled LangChain's ["Context Engineering for Agents"](https://blog.langchain.com/context-engineering-for-agents/) (Jul 2025) as the canonical practitioner framing for what an agent's context window engineering looks like. The essay names four orthogonal moves agents can make on their context: **Write** (persist outside the window for later retrieval), **Select** (pull relevant context in at decision points), **Compress** (summarize to fit within the window), **Isolate** (split context across execution spaces, e.g., subagents).

Mapping the four moves onto habeebs-skill's chain (per the audit's coverage table) revealed strong coverage of three of the four: Write (SYSTEM_CONTEXT.md, ADRs, dispatch records), Select (prior-art-research fetches, socratic-grill re-pull, verify-output diff-scope), Isolate (parallel-dev dispatch contract per ADR-0004; verify-output fresh-context critic). Compress is partially covered **at ingest** by the extraction checklist's ≤15-word quote rule in `prior-art-research`, but there is **no Compress-at-overflow move** — no mechanism for compressing the running conversation when it approaches context-window pressure during a long session.

Anthropic's Claude Code harness auto-compacts at 95% of the window — but this only helps within a single harness session. The habeebs-skill chain operates across sessions (research → spec → grill → record → plan → tdd), and a single long session can easily run a `tdd-loop` across 20+ slices or a debugging session past the prompt-cache TTL boundary, accumulating tool feedback and intermediate state that the harness compaction may or may not preserve correctly. LangChain's essay cites Anthropic data that **multi-agent architectures consume up to 15× more tokens than single-agent chat**; Drew Breunig's taxonomy (adopted by LangChain) names **Context Distraction** ("long context degrades performance") and **Context Confusion** ("superfluous content steers wrong answers") as two of the four canonical failure modes.

The decision is needed NOW because v1.10.0 is the natural release boundary, and the Compress-at-overflow move is doc-only (markdown protocol + template + cross-references) — it ships in hours, not days. Deferring it means v1.10.0 ships an audit that named the gap without filling it.

The grill record (`specs/v1.10.0-context-engineering-alignment-grill.md` § Items Q4, Q8) closed two related sub-decisions: (a) v1.10.0 ships the **passive-doc** version (markdown convention + section in `using-habeebs-skill`), with an active-skill candidate deferred to v1.11.0 if empirical evidence justifies it; (b) the summary template is a **rich 7-section schema** that lets a fresh sub-session resume without a Phase 1 cold start.

## Decision

We will adopt a markdown-only Compress-at-overflow protocol as a passive convention for v1.10.0. Specifically:

- **Trigger condition** (when to invoke summary-and-flush): the running session approaches context pressure — conventional signals include conversation length approaching the prompt-cache TTL boundary, tool feedback accumulating past obvious-relevance, the agent noticing it has re-read the same file multiple times, OR the user explicitly saying "this session is getting long." The protocol is **agent-initiated** under user direction, not automatically detected. Per ADR-0002, no runtime substrate detects the condition.

- **Action: summary-and-flush.** The agent writes a markdown summary to `.scratch/session-summary-<timestamp>.md` using the 7-section template (below), then signals to the user that a fresh sub-session should be started which loads the summary plus the currently-active artifacts (spec, ADRs in flight, current slice file, recent commits). The fresh sub-session inherits enough context to continue work mid-chain without a Phase 1 cold start.

- **Summary template — 7 sections:**

  1. **Active artifacts** — file paths for: current spec, ADRs being authored, current slice file, current grill record (if any), current postmortem (if any). One bulleted list of paths.
  2. **Current slice** — slice number + name + acceptance-criteria status. Which boxes are checked, which are still open, which acceptance criterion the agent was working on at flush time.
  3. **Last successful action** — what worked last: commit SHA + message, OR "test X passed" with a path, OR "file Y written" with a path. The anchor point a fresh sub-session can rewind to.
  4. **What's blocking** — the immediate next action, and any blocker: missing input from the user, a failing test with the error, an open grill question that gates the next step.
  5. **Open grill Qs from this session** — IDs from grill records that drove the current set of decisions. Useful when the next session needs to re-read the rationale for why something is shaped a certain way.
  6. **Recent test state** — last dogfood / test run outcome (pass/fail/which scenarios), and any red commits since.
  7. **Branch / worktree pointer** — current branch name, worktree path (if relevant), commit SHA at flush time. Lets the fresh session orient itself in the git graph immediately.

- **Template skeleton committed at `skills/using-habeebs-skill/references/session-summary-template.md`** as a copyable scaffold. Users (and agents) populate the 7 sections per flush.

- **Section in `using-habeebs-skill/SKILL.md`** titled `## When sessions grow long — summary-and-flush` (4-8 sentences plus a worked example showing the 7-section template populated for a typical mid-tdd-loop flush). The section names the trigger signals, the action, and the template path.

- **Cross-reference from `tdd-loop/SKILL.md`** — a single "see also" pointer at the bottom of the SKILL.md noting that long tdd-loop runs (20+ slices in one conversation) are the most likely overflow site and that the summary-and-flush protocol applies. No new section in `tdd-loop/SKILL.md` — just the cross-reference, to keep the SKILL.md focused.

- **v1.11.0 active-skill promotion criterion** (the passive→active upgrade path): if 3+ postmortems land in `docs/agents/postmortems/` (per ADR-0011) showing Context Distraction OR Context Confusion as the failure mode → promote the passive-doc protocol to an active skill (`chain-overflow-flush` or similar) with a description tuned to "session is getting long" / "context feels heavy" trigger phrases, and a richer detection heuristic (conversation length thresholds, prompt-cache TTL pressure inference, repeated-file-read detection). The promotion is opt-in and evidence-driven — same pattern as ADR-0011's Q1 promotion criterion for postmortems.

The decision picks the cheapest mechanism that fills LangChain's missing 4th context-engineering move while preserving ADR-0002. The 7-section template is rich enough that a fresh sub-session ramps up without cold-start cost; the passive-doc shape leaves room for a v1.11.0 active-skill upgrade if real overflow events compound.

## Consequences

### Positive

- Fills the 4th LangChain context-engineering move (Compress-at-overflow), closing the audit's named gap.
- The 7-section template encodes exactly what a fresh sub-session needs to continue work — no Phase 1 cold start, no re-reading the spec from scratch.
- Pairs naturally with ADR-0011 postmortems: postmortems that name Context Distraction or Context Confusion as the failure mode directly feed the v1.11.0 active-skill promotion criterion.
- ADR-0012 itself becomes Tier 0 prior art for any future research on chain context economy.
- The passive-doc shape preserves ADR-0002 (markdown-only) and tests demand for an active skill cheaply.
- Crosscutting cross-reference from `tdd-loop` routes the most likely overflow site to the protocol without bloating `tdd-loop/SKILL.md` itself.

### Negative / Accepted trade-offs

- **Protocol is agent-initiated under user direction; no runtime detection.** Risk: agent doesn't notice the overflow signal until output quality has already degraded (Context Distraction is detectable in hindsight, not always in real-time). Accepted: ADR-0002 binds; runtime detection would require a hook or substrate. The v1.11.0 active-skill promotion criterion is the path to richer detection if needed.
- **Summary-writing cost is non-trivial.** The 7-section template takes the agent 1-2 turns of context to write properly. Risk: agents skip it on small overflow events. Accepted: the alternative (1-page minimal template) trades summary-writing cost for sub-session ramp-up cost, which the grill judged worse — sub-session cold-start is the more expensive failure mode.
- **`.scratch/session-summary-*` files accumulate as session debris.** They're gitignored by convention (no `.scratch/` policy currently — Slice 5 may need to add one). Accepted: ephemeral working-set files; not durable artifacts. Cleanup is manual or automated by user environment.
- **The 7-section template will probably drift** — agents will populate it inconsistently, sections will get reordered, fields will be omitted. Accepted: passive-doc convention always drifts; the v1.11.0 active-skill promotion would enforce schema. Drift is the price of cheap iteration.
- **Cross-session continuity isn't perfect.** The fresh sub-session has the summary + active artifacts but not the full conversation trace; some nuance is lost. Accepted: same trade-off as Anthropic's "Effective harnesses for long-running agents" essay endorses — explicit summarization is the canonical fix for long-running work that overflows context.

### Operational impact

- **No new install steps for users.** All artifacts are markdown additions inside the plugin.
- **`skills/using-habeebs-skill/references/session-summary-template.md`** is the canonical template scaffold (added in Slice 5; relocated 2026-05-22).
- **`.scratch/`** convention is documented in `using-habeebs-skill/SKILL.md` (gitignored by user convention, not enforced by ADR-0012).
- **`tests/dogfood/16-session-summary-template/`** (added in Slice 5) asserts the template file presence and the 7 required sections.
- **v1.10.0 manifest bump is MINOR.** Additive — no existing behavior changes; new doc convention + new template + cross-reference.

## Alternatives considered

### Active skill in v1.10.0 — `chain-overflow-flush` SKILL.md

Ship a new SKILL.md with a description tuned to overflow-shaped trigger phrases and a richer detection heuristic baked in. **Rejected** for v1.10.0 because the empirical rate of context-overflow events is unknown — we have zero postmortems documenting Context Distraction as a failure mode. Adding a SKILL.md before observing the failure pattern is exactly the eval-driven-development anti-pattern Hamel warns against (ADR-0011 § Context). The v1.11.0 promotion criterion tests demand cheaply first. **Decision is reversible:** if 3+ postmortems surface Context Distraction, the passive→active upgrade is straightforward.

### Minimal 1-page summary template (4 sections: path + slice + last action + blocker)

Use a thinner template that takes less time to write per flush. **Rejected** because the grill (Item Q8) judged sub-session ramp-up cost > summary-writing cost. A thin summary forces the fresh sub-session to re-read the spec / ADRs / grill / postmortem from scratch to reconstruct state — Phase 1 cold start with extra steps. The 7-section template eliminates that ramp-up by carrying the relevant state directly.

### YAML-frontmatter schema for machine-readability

Express the 7 sections as YAML frontmatter (or full YAML body) for future tooling consumption. **Rejected** because there's no current consumer for the YAML structure — no tooling, hook, or skill parses session summaries. ADR-0002 allows it (markdown can contain YAML frontmatter) but YAGNI: adding a YAML schema with no consumer is over-engineering for a passive convention. If a future tool needs structured access, the markdown sections are easy to grep.

### Rely on harness auto-compaction; do nothing at the chain layer

Trust Anthropic's 95% auto-compact and assume the chain operates within a single session. **Rejected** because the chain is explicitly cross-session (research → spec → grill → record → plan → tdd is rarely one continuous session in practice), AND because harness auto-compaction is opaque — the agent doesn't get to choose what's preserved. The summary-and-flush protocol gives the agent explicit control over what survives the transition, which matters when the surviving state needs to be precise (current slice acceptance-criteria status, last successful commit SHA).

### Cross-session memory via an observation log (e.g., claude-mem style)

Adopt a structured cross-session observation log with a query interface. **Rejected** per ADR-0002 — that's a runtime substrate, not a markdown convention. The 2026-05-13 morning reconciliation already considered claude-mem and rejected runtime composition. The passive-doc summary-and-flush is the markdown-only equivalent that does the same job at a smaller scale.

## Revisit triggers

This ADR should be reopened if any of:

- **Q4 promotion fires:** 3+ postmortems show Context Distraction OR Context Confusion as the failure mode → promote passive-doc to active skill. Land in v1.11.0 or v1.12.0.
- **Session summaries accumulate evidence of consistent template drift** — three or more sessions skip required sections or invent new ones → either tighten the template (mandatory vs. optional sections) or accept the drift and remove unused sections.
- **Active-skill promotion lands without postmortem evidence** because user explicitly requests it → log the request and consider promotion; the revisit trigger is the right point to formalize.
- **Anthropic publishes new long-context guidance** that changes summary-template recommendations (e.g., they document a canonical format for cross-session memory) → align the 7-section template with the new guidance.
- **Model context windows grow to ≥10M tokens** AND prompt-cache TTL extends past 1hr → the protocol may become moot; revisit whether agents actually hit overflow in practice given the new economics. Likely tied to v2.0.0 or a model-family upgrade.
- **`.scratch/` directory accumulates >100 summary files per user-repo** → introduce retention guidance (auto-delete summaries older than 7 days, or roll up into a longer-cadence digest).

## References

- Research: prior-art-research run 2026-05-13 (in-conversation; archived as [`docs/agents/research/v1.10.0-context-engineering-alignment-research.md`](../research/v1.10.0-context-engineering-alignment-research.md) in Slice 0)
- Spec: [`specs/v1.10.0-context-engineering-alignment`](../specs/v1.10.0-context-engineering-alignment.md) § Slice 5
- Grill: [`specs/v1.10.0-context-engineering-alignment-grill`](../specs/v1.10.0-context-engineering-alignment-grill.md) § Items Q4, Q8
- Sister ADRs:
  - [`adrs/0011-error-analysis-cadence`](./0011-error-analysis-cadence.md) — postmortems feed the v1.11.0 active-skill promotion criterion
  - [`adrs/0002-habeebs-skill-standalone`](./0002-habeebs-skill-standalone.md) — preserved (markdown-only protocol, no runtime substrate)
  - [`adrs/0004-parallel-subagent-dispatch-contract`](./0004-parallel-subagent-dispatch-contract.md) — share-full-traces clause complements this ADR's cross-session preservation
- External sources:
  - [LangChain — Context Engineering for Agents](https://blog.langchain.com/context-engineering-for-agents/) — canonical source for the 4 context-engineering moves (Write/Select/Compress/Isolate); names Drew Breunig's failure-mode taxonomy
  - [Harrison Chase — The Rise of Context Engineering](https://blog.langchain.com/the-rise-of-context-engineering/) — companion essay; framing on context engineering as discipline
  - [Anthropic — Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) — auto-compact at 95% as harness-level analog
  - [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — endorses explicit summarization for cross-session continuity
  - [Cognition AI — Don't Build Multi-Agents](https://cognition.ai/blog/dont-build-multi-agents) — context-as-shared-trace principle informs the summary template's "carry the active artifacts" design

### Reference implementations cited

- **Context-engineering 4 moves:** LangChain Context Engineering for Agents — Cited because ADR-0012 explicitly fills the Compress move that audit-mapped the chain's existing coverage of Write/Select/Isolate.

---

## Changelog

- 2026-05-13 — Initial ADR, Accepted same day (v1.10.0 release; implementation lands in Slice 5).
- 2026-05-22 — Amended in place: template path relocated from `docs/agents/templates/session-summary-template.md` to `skills/using-habeebs-skill/references/session-summary-template.md`. Reason: the template is consumed by exactly one skill (`using-habeebs-skill`'s Compress-at-overflow protocol); ADR-0009's 3-consumer threshold says single-skill helpers live inside the skill's own `references/`. The empty `docs/agents/templates/` directory is retired.
