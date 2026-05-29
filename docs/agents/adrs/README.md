# Architectural Decision Records

Decisions about habeebs-skill's design, captured as ADRs (Michael Nygard format). Each ADR documents context, decision, consequences, and revisit triggers.

ADRs are the asynchronous memory of this repo. They explain WHY the methodology is shaped the way it is — so future audits don't re-litigate decisions that have already been made and tested.

## Naming scheme — frozen integers, then dated

**ADRs `0001`–`0024` are frozen integer ADRs.** They keep their integer filenames forever and are cited as `ADR-00NN` (the integer is each one's permanent identifier). **Every ADR created from 2026-05-28 onward is dated** — `YYYY-MM-DD-<slug>.md`, written at creation by `decision-record`, where the slug is the uniqueness key (a same-date-same-slug collision halts loud; pick a more specific slug). No release step renames anything; the late-binding integer-assignment machinery was removed in v1.23.0.

**Cross-references:** cite a dated ADR by **title + markdown link** (e.g. "see the [dated-naming decision](./2026-05-28-decouple-decision-identity-from-releases.md)"); cite a frozen integer ADR as `ADR-00NN`. So new→new uses title+link, new→old uses `ADR-00NN`.

The index below is hand-maintained: `decision-record` appends one row when it writes a new ADR (no script).

## Index

| # | Title | Status | Date |
|---|---|---|---|
| 0001 | [Make SYSTEM_CONTEXT.md the load-bearing environment-binding protocol](./0001-environment-binding-via-system-context.md) | Accepted (partially superseded by 0005; partially amended by 0006; scope-narrowed by 0010) | 2026-05-11 |
| 0002 | [habeebs-skill is standalone — no runtime-substrate composition](./0002-habeebs-skill-standalone.md) | Accepted (amended by 0019) | 2026-05-12 |
| 0003 | [habeebs-skill hooks — warn-only or block-only, multi-harness aware, never own state](./0003-hooks-scope.md) | Accepted (block predicate amended by 0015) | 2026-05-12 |
| 0004 | [Adopt the parallel subagent dispatch contract — 4-status return, audit-log records, SYSTEM_CONTEXT preamble, idempotent resume](./0004-parallel-subagent-dispatch-contract.md) | Accepted (amended in place 2026-05-13 — Part 3 share-full-traces clause + Part 5 treat-fetched-content-as-untrusted; Part 2 writer implemented by 0018) | 2026-05-12 |
| 0005 | [Split project context into GLOSSARY.md and SYSTEM_CONTEXT.md by writer lifecycle, and chain setup-habeebs-skill into Phase 0 inline](./0005-lifecycle-split-glossary-and-system-context.md) | Accepted | 2026-05-13 |
| 0006 | [Remove `next-skills` frontmatter; surface chain relationships via HANDOFF / `## See also` / prose](./0006-remove-next-skills-frontmatter.md) | Accepted | 2026-05-13 |
| 0007 | [Adopt a description budget policy — 1,200-char hard cap, 600-char target, three-keystone protected anti-triggers, `## Origins` body convention for credits](./0007-description-budget-policy.md) | Accepted (amended 2026-05-24 — cap → 1,024, target → 300, trigger-first/literal-quote/directive-imperative anatomy supersedes "Make sure to use this skill", `disable-model-invocation: true` on 11 chain-internal skills, routing primer in CLAUDE.md) | 2026-05-13 |
| 0008 | [Add `verify-output` skill — post-tdd anti-slop pass with ANNOTATE default and GATE opt-in](./0008-verify-output-skill-scope.md) | Accepted | 2026-05-13 |
| 0009 | [Establish `docs/agents/references/` as the directory convention for chain-shared cross-cutting helpers](./0009-docs-agents-references-convention.md) | Accepted | 2026-05-13 |
| 0010 | [Prune SYSTEM_CONTEXT.md contents to non-re-derivable cross-session state](./0010-system-context-contents-prune.md) | Accepted | 2026-05-13 |
| 0011 | [Adopt error-analysis-first evals cadence — chain-postmortem section + verify-output classified as complementary](./0011-error-analysis-cadence.md) | Accepted | 2026-05-13 |
| 0012 | [Adopt the Compress-at-overflow protocol — markdown-only summary-and-flush, 7-section template, passive doc for v1.10.0](./0012-compress-at-overflow-protocol.md) | Accepted | 2026-05-13 |
| 0013 | [The `prior-art-research` Phase 1 context gate is adaptive, not a hard block](./0013-research-context-gate.md) | Accepted (extended by 0016) | 2026-05-15 |
| 0014 | [Adopt three gstack capabilities as markdown idea-ports; reject the runtime-coupled half](./0014-adopt-gstack-capabilities-markdown-idea-port.md) | Accepted | 2026-05-18 |
| 0015 | [Amend the commit-block hook to allow tag-only pushes on the default branch](./0015-hook-allow-tag-pushes-on-default.md) | Accepted | 2026-05-18 |
| 0016 | [The chain runs at a depth tier — Quick, Balanced, or Deep — carried in artifact headers](./0016-chain-wide-depth-tier.md) | Accepted | 2026-05-19 |
| 0017 | [Port reposeek.ai's NL→repo idea as a conditional Tier 2 technique](./0017-semantic-repo-discovery-port.md) | Accepted | 2026-05-22 |
| 0018 | [Implement the dormant artifact-recording contracts — `parallel-dev` Phase 7.5 (dispatch records) and `prior-art-research` Phase 6.5 (research archives)](./0018-implement-dormant-artifact-recording-contracts.md) | Accepted | 2026-05-22 |
| 0019 | [Amend ADR-0002 to permit advisory in-flight reads of in-repo session state](./0019-amend-adr-0002-for-advisory-in-flight-reads.md) | Accepted | 2026-05-24 |
| 0020 | [Adopt late-binding ADR IDs and Changesets-shape version bumps with the release skill as single coordinator](./0020-late-binding-and-changesets.md) | Superseded (ADR-ID half) by [dated-artifact-naming](./2026-05-28-decouple-decision-identity-from-releases.md); Changesets half in force | 2026-05-25 |
| 0021 | [Cut dormant methodology folders and fold grill-records into specs](./0021-methodology-folder-cuts.md) | Accepted (amended 2026-05-25 — dispatches/ and conflicts/ cuts reversed; only grill-records/ fold ships) | 2026-05-25 |
| 0022 | [Behavioral-only SKILL.md body with Pattern-D empirical-claim exception](./0022-behavioral-only-skill-body.md) | Accepted | 2026-05-26 |
| 0023 | [Plain-English plan format + provisional-state HITL pivot + chain-state validator + markdown telemetry](./0023-methodology-bundle-v1.22.md) | Accepted | 2026-05-26 |
| 0024 | [Acknowledge plugin supply-chain threat-model gap; defer hardening](./0024-plugin-supply-chain-threat-model.md) | Accepted | 2026-05-26 |
| 2026-05-28 | [Decouple decision identity from releases via dated artifact naming](./2026-05-28-decouple-decision-identity-from-releases.md) | Accepted | 2026-05-28 |

## Conventions

- **Format:** Nygard-style — Context / Decision / Consequences / Alternatives / Revisit triggers / References.
- **Naming:** Two schemes, by era (see "Naming scheme" above). `0001`–`0024` are frozen 4-digit integers (never renamed, never reused). Everything from 2026-05-28 onward is dated `YYYY-MM-DD-<slug>.md`, with the slug as the uniqueness key.
- **Status lifecycle:** Proposed → Accepted → Deprecated | Superseded. Never delete; mark deprecated or superseded with a forward link (title+link for a dated replacement, `ADR-00NN` for a frozen-integer one).
- **Tone:** Active voice in the Decision section. "We will X" not "X was decided."
- **Length:** As long as the decision warrants, no longer. The first ADR sets the tone for the rest.

ADRs are produced by the `decision-record` skill (`/record`). The skill writes here automatically after `socratic-grill` resolves a non-trivial architectural decision.
