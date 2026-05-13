# ADR-0008: Add `verify-output` skill — post-tdd anti-slop pass with ANNOTATE default and GATE opt-in

**Status:** Accepted
**Date:** 2026-05-13
**Deciders:** ahabeeb1

## Context

The 2026-05-13 ecosystem alignment audit surfaced a coverage gap: habeebs-skill has rigorous pre-implementation review (`socratic-grill` for ambiguity-killing, `agent-factors-check` for LLM-product gaps) and an in-implementation review at the refactor step of `tdd-loop` (which invokes `deep-modules` for shallow-module deepening + a two-stage spec-compliance/code-quality check). It has **no dedicated post-implementation output-quality pass** between tests passing (GREEN) and committing.

Peer ecosystems do have this pass. OMC ships `ai-slop-cleaner` and `ultraqa` skills for explicit anti-slop verification after generation. Their motivating failure mode — well-tested code that nonetheless ships with unjustified comments, defensive validation on impossible cases, half-finished implementations, premature abstractions, or backward-compat shims for unshipped code — maps cleanly onto rules already written in this repo's `CLAUDE.md`:

> Don't add features, refactor, or introduce abstractions beyond what the task requires.
> Don't add error handling, fallbacks, or validation for scenarios that can't happen.
> Default to writing no comments.
> Avoid backwards-compatibility hacks.

Tests passing doesn't catch any of these — they're not test-detectable failures, they're code-shape problems that drift in past the test boundary. `deep-modules` catches *some* of them (shallow modules, pass-through layers) but not all (e.g., unjustified comments are out of `deep-modules`' scope; they don't change interface shape).

This ADR establishes `verify-output` as the dedicated post-generation slop pass and defines its scope, default mode, and integration with the existing chain.

## Decision

We will create a new skill at `skills/verify-output/` that runs between `tdd-loop`'s GREEN step (tests passing) and the commit step. The skill scans the staged diff against a slop-heuristics doc and returns one of the four ADR-0004 statuses.

Specifically:

- **Slot in the chain:** between `tdd-loop` GREEN (after the two-stage spec-compliance/code-quality review) and the commit. NOT a replacement for `deep-modules` (which fires earlier at the refactor step on interface shape); `verify-output` covers code-shape concerns `deep-modules` doesn't.
- **Default mode: ANNOTATE.** Returns `DONE` (clean) or `DONE_WITH_CONCERNS` (slop found, listed in the output) by default. Does NOT block the commit on moderate slop.
- **`BLOCKED` returns only on severe slop**, defined as: functions containing `TODO`, `pass`, or `throw new NotImplementedError`-equivalent (half-finished implementations); unreachable code; imports/variables/parameters declared but never used in the staged diff. Severe slop is binary — code is in a "not actually done" state, and shipping it is worse than shipping the moderate-slop alternative.
- **GATE mode is opt-in** via skill arg `verify-output --gate`. In GATE mode, moderate slop also blocks the commit. Documented for projects/teams that want stricter enforcement.
- **Does NOT invoke `deep-modules` internally.** Separate concern, fires at a different chain step. The two skills compose by sitting at different slots, not by nesting.
- **4-status return per ADR-0004:** `DONE` | `DONE_WITH_CONCERNS` | `BLOCKED` | `NEEDS_CONTEXT`. The `NEEDS_CONTEXT` status lands when the slop scan finds something ambiguous (e.g., a defensive validation that could be either legitimate boundary-trust or paranoid — the skill asks the human rather than guessing).
- **`agent-factors-check` invoked against verify-output's own design before commit.** Since `verify-output` is itself an LLM workflow with a tool-call schema (4-status return), state (staged diff), and a pause/resume question (the `NEEDS_CONTEXT` case maps to F6 pause/resume + F7 human-as-tool), the meta-skill must self-apply. Resulting Socratic questions fold into `references/slop-heuristics.md` and the SKILL.md pause/resume protocol.
- **Slop heuristics source:** `references/slop-heuristics.md` lifts four rules from `CLAUDE.md` verbatim (user-authored canon, no copyright concern) — feature creep, defensive validation past trusted boundaries, unjustified comments, backward-compat hacks. Adds three paraphrased OMC-inspired heuristics (≤10 words quoted per source): repeated boilerplate suggesting a missed abstraction; over-validation past system boundaries; backward-compat shims for unshipped code. Each heuristic carries a positive example + counter-example.

This decision is anchored by ADR-0002 (no runtime substrate — `verify-output` is markdown + step-by-step instructions, no daemon, no MCP server) and ADR-0004 (4-status return contract).

## Consequences

### Positive

- Closes a documented coverage gap surfaced by the ecosystem audit. Habeebs-skill goes from "good pre-impl rigor + good in-impl refactor" to "good across all three lifecycle phases (pre / during / post)."
- ANNOTATE default keeps the chain non-coercive — the user retains agency over what counts as ship-worthy. GATE mode is available for stricter contexts (security-critical code, regulated environments) without forcing it on everyone.
- The severe-slop blocking criteria are binary and mechanically detectable — `BLOCKED` should produce zero false positives in normal usage. Moderate slop is judgment-call-shaped and rightly stays advisory.
- Separating `verify-output` from `deep-modules` keeps each skill deep — Ousterhout-style — instead of one mega-review-skill that tries to cover interface shape and code shape and slop in a single pass.
- The chain-self-application requirement (`agent-factors-check` against verify-output) is the same rigor habeebs-skill demands of *user* LLM products; dogfooding it on a habeebs-skill skill keeps the methodology honest.
- `references/slop-heuristics.md` lifting from `CLAUDE.md` keeps a single source of truth — if the user updates `CLAUDE.md`'s anti-slop rules, the slop-heuristics doc gets a one-line update in sync.

### Negative / Accepted trade-offs

- Adds one skill to the always-loaded skill-listing budget (~600 chars description, under the ADR-0007 hard cap). Net token change for v1.9.0 is still negative because slice 1 trims save more than slice 3 adds.
- `BLOCKED` on a half-finished implementation might create friction when a developer intentionally lands a function with `TODO` (e.g., a stub for a future slice). Mitigated by ANNOTATE default — only `--gate` mode actually blocks the commit on this.
- Defining "severe slop" as binary is a one-way door for the criteria — adding new severe-slop heuristics later changes the blocking surface, which could surprise users. Mitigated by the explicit Revisit trigger below.
- The seven slop heuristics (4 + 3) are a snapshot of current canon; they will drift as the user's `CLAUDE.md` evolves and as more peer ecosystems publish slop-checking guidance. Document drift is the maintenance cost.
- `agent-factors-check` running against verify-output during slice 3 implementation adds chain overhead — fair, since this is exactly the rigor habeebs-skill exists to enforce.

### Operational impact

- Slice 3 of v1.9.0 owns the new skill + slop-heuristics doc + tdd-loop integration + dogfood scenarios.
- `tdd-loop`'s "Refactor and review" phase gets an updated invocation: after the two-stage review, before the commit, call `verify-output`. The integration is a single new line in `tdd-loop/SKILL.md`.
- Dogfood scenarios at `tests/dogfood/11-verify-output/` cover three fixtures (planted moderate slop / clean control / severe slop). Future heuristic additions require a fixture update.
- No new dependencies, no runtime substrate, no MCP — pure markdown + git diff parsing.

## Alternatives considered

### Extend `deep-modules` to cover slop heuristics

Make the existing skill cover both interface shape and code shape. **Rejected** because it violates Ousterhout's deep-module principle — `deep-modules` is already deep on interface shape; bundling code-shape slop would create a shallow mega-skill that tries to do two things. Separating keeps each skill's interface narrow.

### Inline anti-slop checks into `tdd-loop`'s two-stage review

Add a third review stage to `tdd-loop` instead of a new skill. **Rejected** because `tdd-loop` is already long (254 lines); adding a third review stage inline pushes it past the ADR-0007 implicit-budget zone. Extracting `verify-output` as a separate skill keeps `tdd-loop` focused on red-green-refactor.

### Default to GATE mode (block on any slop)

Make the strict mode the default. **Rejected** because the audit showed peer-ecosystem anti-slop tools (OMC `ai-slop-cleaner`) annotate by default — coercive defaults breed user resentment and learned-helplessness around the warnings. ANNOTATE-default + opt-in-GATE matches the precedent and respects user agency.

### Run `verify-output` BEFORE GREEN (i.e., during red phase to catch test slop too)

Position the skill earlier. **Rejected** because the slop heuristics ("unused imports," "half-finished impl") are noise during red phase — tests are *supposed* to fail in red, half-finished impls are by design. Post-GREEN is the only honest slot.

### Use a static linter (eslint/ruff) instead of an LLM skill

Lean on existing tooling. **Rejected** because the slop heuristics targeted here ("defensive validation past trusted boundaries," "premature abstraction," "backward-compat for unshipped code") are *judgment calls*, not lint rules. A static linter catches a different (also valuable) class of problem; the two compose rather than substitute. habeebs-skill is a methodology plugin, not a linter ecosystem.

## Revisit triggers

This ADR should be reopened if any of:

- **`verify-output` produces sustained false positives in `BLOCKED` mode (>5%).** Tighten the severe-slop criteria or move them to `DONE_WITH_CONCERNS`.
- **Users report `verify-output` is too lenient.** The ANNOTATE-default debate reopens; consider promoting GATE to default or adding a stricter `--strict` mode between ANNOTATE and GATE.
- **A static linter convention emerges that overlaps with the seven heuristics.** Refactor to defer overlapping heuristics to the linter and keep `verify-output` focused on judgment-call slop.
- **Slice 3's `agent-factors-check` invocation surfaces a structural problem** with the 4-status return as designed (e.g., the F6 pause/resume case is unworkable inline). Re-architect the skill before shipping.
- **`CLAUDE.md`'s anti-slop rules drift significantly.** Sync `references/slop-heuristics.md` and consider whether a CHANGELOG entry under verify-output is warranted.
- **A peer ecosystem ships a meaningfully different slop-detection approach** (e.g., AST-based scan, embedding-based semantic similarity). Re-research in the spirit of `prior-art-research`.

## References

- Research: `docs/agents/SYSTEM_CONTEXT.md` § Last reconciliation outcome (2026-05-13 — habeebs-skill ecosystem audit)
- Spec: `docs/agents/specs/v1.9.0-ecosystem-alignment.md` (Slice 3)
- Grill: `docs/agents/specs/v1.9.0-ecosystem-alignment-grill.md` (Items 4, 5, 9)
- Related: [ADR-0002](./0002-habeebs-skill-standalone.md) (no runtime substrate); [ADR-0004](./0004-parallel-subagent-dispatch-contract.md) (4-status return contract)
- External sources:
  - [Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) — `ai-slop-cleaner`, `ultraqa` motivating prior art
  - `CLAUDE.md` (repo root) — canonical anti-slop rules; the four lifted heuristics

---

## Changelog

- 2026-05-13 — Initial ADR, status Accepted (decision locked by user's v1.9.0 scope approval)
