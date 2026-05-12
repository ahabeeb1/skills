# Architectural Decision Records

Decisions about habeebs-skill's design, captured as ADRs (Michael Nygard format). Each ADR documents context, decision, consequences, and revisit triggers.

ADRs are the asynchronous memory of this repo. They explain WHY the methodology is shaped the way it is — so future audits don't re-litigate decisions that have already been made and tested.

## Index

| # | Title | Status | Date |
|---|---|---|---|
| 0001 | [Make SYSTEM_CONTEXT.md the load-bearing environment-binding protocol](./0001-environment-binding-via-system-context.md) | Accepted | 2026-05-11 |
| 0002 | [habeebs-skill is standalone — no runtime-substrate composition](./0002-habeebs-skill-standalone.md) | Accepted | 2026-05-12 |
| 0003 | [habeebs-skill hooks — warn-only or block-only, multi-harness aware, never own state](./0003-hooks-scope.md) | Accepted | 2026-05-12 |

## Conventions

- **Format:** Nygard-style — Context / Decision / Consequences / Alternatives / Revisit triggers / References.
- **Numbering:** Zero-padded to 4 digits, monotonically increasing. Never reuse a number.
- **Status lifecycle:** Proposed → Accepted → Deprecated | Superseded by ADR-NNNN. Never delete; mark deprecated or superseded with a forward link.
- **Tone:** Active voice in the Decision section. "We will X" not "X was decided."
- **Length:** As long as the decision warrants, no longer. The first ADR sets the tone for the rest.

ADRs are produced by the `decision-record` skill (`/record`). The skill writes here automatically after `socratic-grill` resolves a non-trivial architectural decision.
