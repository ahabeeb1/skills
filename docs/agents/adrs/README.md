# Architectural Decision Records

Decisions about habeebs-skill's design, captured as ADRs (Michael Nygard format). Each ADR documents context, decision, consequences, and revisit triggers.

ADRs are the asynchronous memory of this repo. They explain WHY the methodology is shaped the way it is — so future audits don't re-litigate decisions that have already been made and tested.

## Index

| # | Title | Status | Date |
|---|---|---|---|
| 0001 | [Make SYSTEM_CONTEXT.md the load-bearing environment-binding protocol](./0001-environment-binding-via-system-context.md) | Accepted (partially superseded by 0005; partially amended by 0006; scope-narrowed by 0010) | 2026-05-11 |
| 0002 | [habeebs-skill is standalone — no runtime-substrate composition](./0002-habeebs-skill-standalone.md) | Accepted | 2026-05-12 |
| 0003 | [habeebs-skill hooks — warn-only or block-only, multi-harness aware, never own state](./0003-hooks-scope.md) | Accepted | 2026-05-12 |
| 0004 | [Adopt the parallel subagent dispatch contract — 4-status return, audit-log records, SYSTEM_CONTEXT preamble, idempotent resume](./0004-parallel-subagent-dispatch-contract.md) | Accepted | 2026-05-12 |
| 0005 | [Split project context into GLOSSARY.md and SYSTEM_CONTEXT.md by writer lifecycle, and chain setup-habeebs-skill into Phase 0 inline](./0005-lifecycle-split-glossary-and-system-context.md) | Accepted | 2026-05-13 |
| 0006 | [Remove `next-skills` frontmatter; surface chain relationships via HANDOFF / `## See also` / prose](./0006-remove-next-skills-frontmatter.md) | Accepted | 2026-05-13 |
| 0007 | [Adopt a description budget policy — 1,200-char hard cap, 600-char target, three-keystone protected anti-triggers, `## Origins` body convention for credits](./0007-description-budget-policy.md) | Accepted | 2026-05-13 |
| 0008 | [Add `verify-output` skill — post-tdd anti-slop pass with ANNOTATE default and GATE opt-in](./0008-verify-output-skill-scope.md) | Accepted | 2026-05-13 |
| 0009 | [Establish `docs/agents/references/` as the directory convention for chain-shared cross-cutting helpers](./0009-docs-agents-references-convention.md) | Accepted | 2026-05-13 |
| 0010 | [Prune SYSTEM_CONTEXT.md contents to non-re-derivable cross-session state](./0010-system-context-contents-prune.md) | Accepted | 2026-05-13 |

## Conventions

- **Format:** Nygard-style — Context / Decision / Consequences / Alternatives / Revisit triggers / References.
- **Numbering:** Zero-padded to 4 digits, monotonically increasing. Never reuse a number.
- **Status lifecycle:** Proposed → Accepted → Deprecated | Superseded by ADR-NNNN. Never delete; mark deprecated or superseded with a forward link.
- **Tone:** Active voice in the Decision section. "We will X" not "X was decided."
- **Length:** As long as the decision warrants, no longer. The first ADR sets the tone for the rest.

ADRs are produced by the `decision-record` skill (`/record`). The skill writes here automatically after `socratic-grill` resolves a non-trivial architectural decision.
