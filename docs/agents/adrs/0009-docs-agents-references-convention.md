# ADR-0009: Establish `docs/agents/references/` as the directory convention for chain-shared cross-cutting helpers

**Status:** Accepted
**Date:** 2026-05-13
**Deciders:** ahabeeb1

## Context

habeebs-skill has, since v1.4, organized auxiliary documentation under `skills/<name>/references/` — one references directory per skill, lazy-loaded via Read only when the SKILL.md body instructs. This matches Anthropic's canonical progressive-disclosure pattern from `anthropics/skills/skill-creator`. 11 of 14 skills carry their own `references/` directory today.

The 2026-05-13 ecosystem alignment audit (slice 6 of v1.9.0) surfaced a class of helper that doesn't fit the per-skill model: the **SYSTEM_CONTEXT.md mtime-staleness check protocol**. Today this protocol is defined inline in `skills/prior-art-research/SKILL.md` Phase 0. Ten of 14 skills *read* SYSTEM_CONTEXT.md but only `prior-art-research` enforces the staleness check; the other nine implicitly trust the file. Slice 6 extracts the protocol into a shared reference doc so all 10 consumers can invoke the same canonical check.

Where should the shared doc live? Three locations were considered (see Alternatives):

1. `skills/prior-art-research/references/system-context-staleness-check.md` — keep it where the canonical version is today.
2. `skills/_shared/references/system-context-staleness-check.md` — invent a new shared-skill directory.
3. `docs/agents/references/system-context-staleness-check.md` — extend the existing `docs/agents/` doc layer.

The grill resolved on option 3 (`docs/agents/references/`). This ADR codifies that as a directory convention so future cross-cutting helpers have an obvious home.

## Decision

We will establish **`docs/agents/references/`** as the canonical directory for cross-cutting documentation that is consumed by 3 or more skills. The directory parallels the existing `docs/agents/{adrs,specs,plans,dispatches}/` layout, which is already the canonical location for chain-shared artifacts.

Specifically:

- **Cross-cutting threshold:** A helper qualifies for `docs/agents/references/` when it is consumed by **3 or more skills**, OR when it documents a protocol that is enforced repo-wide (rather than skill-locally). Below the 3-consumer threshold, helpers stay in their owning skill's `skills/<name>/references/` directory.
- **First inhabitant:** `docs/agents/references/system-context-staleness-check.md` — lands as part of v1.9.0 slice 6. Consumed by all 10 skills that read SYSTEM_CONTEXT.md.
- **Naming:** lowercase-hyphen filenames. No numbering (unlike ADRs/specs, references aren't sequential decisions; they're protocol docs that get edited in place).
- **Layout flat for now:** no sub-categorization. Revisit if the directory grows past ~5 files.
- **Discoverability:** new entries get a one-line mention in the top-level `docs/agents/README.md` (or equivalent index) — or, if no top-level README exists, in `docs/agents/adrs/README.md` § Conventions section as an addendum.

The 3-consumer rule is a guardrail against premature DRY — single-use helpers stay co-located with the skill that owns them.

## Consequences

### Positive

- Future cross-cutting protocols (citation conventions for `prior-art-research`, common assertion scripts for dogfood scenarios, repo-wide verification rituals) have an obvious home — no per-helper directory-placement decision needed.
- Parallels the established `docs/agents/{adrs,specs,plans,dispatches}/` pattern; reduces cognitive load by reusing the layout instinct already trained on those subdirectories.
- The 3-consumer threshold prevents DRY-thrash: helpers used by 1-2 skills don't migrate to a shared location just because someone *might* reuse them later (YAGNI). Locality of edit cost stays with the owning skill until the helper is genuinely shared.
- Single source of truth for shared protocols — the mtime-check doc, once extracted, can be edited in one place and all 10 consumers pick up the change.
- Aligns with ADR-0001's load-bearing-protocol principle: protocols that govern multiple skills should be documented once, centrally.

### Negative / Accepted trade-offs

- Adds a new top-level directory the user/auditor has to know about. Mitigated by parallel naming with existing `docs/agents/` subdirs.
- Cross-cutting docs are slightly more "expensive" to find for someone reading a SKILL.md body — they have to follow a relative link out of `skills/<name>/` into `docs/agents/references/`. Mitigated by SKILL.md bodies using explicit relative paths in Read instructions.
- The 3-consumer threshold is a judgment call, not a mechanical rule. Borderline cases (a helper used by 2 skills "but likely a third soon") will require taste. Documented as Revisit trigger.
- One-way door for v1.9.0: once `docs/agents/references/` exists and is referenced by 10 SKILL.md files, retracting it would require a coordinated 10-file edit. Mitigated by the parallel-with-existing-directories defense — this convention will only need retraction if `docs/agents/` itself is reorganized, which would be a much bigger event.

### Operational impact

- v1.9.0 slice 6 owns the directory creation + first inhabitant + retrofit of 10 SKILL.md files.
- No CI/build changes needed (markdown only, no runtime).
- Future ADRs that introduce cross-cutting protocols (e.g., a future "agent dispatch audit protocol" beyond ADR-0004) should drop their reference doc here.

## Alternatives considered

### `skills/prior-art-research/references/system-context-staleness-check.md` (keep at origin)

Don't move the protocol; leave it where the canonical version lives today. **Rejected** because it implies ownership by `prior-art-research`, but 10 skills consume the protocol equally. Leaving the doc inside one skill's references directory misrepresents the dependency graph.

### `skills/_shared/references/` (invent a new shared-skill convention)

Create a new pseudo-skill directory for shared docs. **Rejected** because (a) it introduces a directory that isn't actually a skill (no SKILL.md) and would clutter `skills/` with a non-skill, (b) it duplicates the role that `docs/agents/` already plays in the repo for chain-shared artifacts.

### `docs/references/` (top-level outside `docs/agents/`)

Use a top-level docs subdirectory not nested under `agents`. **Rejected** because it splits the chain-shared-artifacts surface across two top-level docs locations (`docs/agents/` for ADRs/specs/plans/dispatches and `docs/references/` for protocols). Keeping everything under `docs/agents/` keeps the chain-context surface in one place.

### Inline in `docs/agents/adrs/` as a meta-ADR

Document protocols as ADRs themselves. **Rejected** because ADRs are decisions with a fixed shape (Context / Decision / Consequences / Alternatives / Revisit triggers). Protocols are recipes — the "decision" framing distorts them. Use ADRs for decisions, reference docs for protocols.

## Revisit triggers

This ADR should be reopened if any of:

- **`docs/agents/references/` grows past ~5 files.** Consider sub-categorization (`docs/agents/references/protocols/`, `docs/agents/references/conventions/`) or pruning unused entries.
- **The 3-consumer threshold produces sustained borderline-case debate.** Revisit the threshold — lower to 2, raise to 4, or replace with a "consumed by 2+ chain skills (not engineering primitives)" refinement.
- **A skill-specific helper gets promoted to `docs/agents/references/` and is later found to be used by only 1 skill again.** Demotion path: move back to `skills/<name>/references/`, update all references. The directory must reflect actual cross-cutting use.
- **The `docs/agents/` directory is reorganized at the meta-level** (e.g., flattened to `docs/`, renamed for harness-compatibility reasons). This convention follows the parent directory's fate.
- **A peer ecosystem publishes a meaningfully different shared-docs convention** that we want to align with for portability. Re-research before changing.

## References

- Research: `docs/agents/SYSTEM_CONTEXT.md` § Last reconciliation outcome (2026-05-13 — habeebs-skill ecosystem audit)
- Spec: `docs/agents/specs/v1.9.0-ecosystem-alignment.md` (Slice 6 + Architecture section)
- Grill: `docs/agents/specs/v1.9.0-ecosystem-alignment-grill.md` (Item 8)
- Related: [ADR-0001](./0001-environment-binding-via-system-context.md) (load-bearing protocol principle); [ADR-0005](./0005-lifecycle-split-glossary-and-system-context.md) (writer-lifecycle split that surfaced the mtime-check need)
- External sources:
  - [anthropics/skills](https://github.com/anthropics/skills) — per-skill `references/` directory pattern (the per-skill side of the rule)
  - [Diátaxis](https://diataxis.fr/) — documentation taxonomy supporting the protocol-as-reference framing

---

## Changelog

- 2026-05-13 — Initial ADR, status Accepted (decision locked by user's v1.9.0 scope approval)
