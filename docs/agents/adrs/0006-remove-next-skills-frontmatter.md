# ADR-0006: Remove `next-skills` frontmatter; surface chain relationships via HANDOFF / `## See also` / prose

**Status:** Accepted
**Date:** 2026-05-13
**Deciders:** ahabeeb1

## Context

Eleven of habeebs-skill's 14 SKILL.md files carry a custom `next-skills:` frontmatter field (e.g., `next-skills: [draft-spec, socratic-grill, decision-record]`). The field was a habeebs-skill invention dating to v1.4 — a machine-readable chain successor pointer intended to make the research → spec → grill → record → plan → tdd pipeline explicit in metadata.

The 2026-05-13 ecosystem alignment audit (see `docs/agents/specs/v1.9.0-ecosystem-alignment.md`) revealed that **`next-skills` is not a recognized field in the Claude Code Skills 2.0 frontmatter spec**. The harness silently ignores it. Across the four peer ecosystems examined — Anthropic's `anthropics/skills`, `obra/superpowers`, `mattpocock/skills`, `Yeachan-Heo/oh-my-claudecode` — none use a chain-frontmatter field. All compose skills via prose mentions, explicit handoff lines, or pure trigger discovery.

habeebs-skill already has a stronger and harness-visible chain mechanism: explicit `HANDOFF: <state> ready — invoke X` lines at the bottom of each skill's output, which downstream skills are documented to parse. The `next-skills` field is therefore redundant metadata that loads on every skill listing and provides zero behavioral signal to the runtime. This decision removes the field and consolidates chain-relationship discovery into three documented surfaces.

## Decision

We will remove the `next-skills:` frontmatter line from all 14 `skills/*/SKILL.md` files. Chain relationships will surface exclusively through three body-level mechanisms:

- **`HANDOFF:` lines** in skill output (the canonical machine-parseable handoff — already established as the chain's runtime contract)
- **`## See also` body sections** listing related skills with one-line context (lazy-loaded with SKILL.md body — costs nothing in always-loaded skill-listing budget)
- **Explicit prose mentions** in step text (e.g., "invoke `parallel-dev` to dispatch 4 subagents")

We will enforce the surface-coverage rule with a chain-integrity assertion script at `tests/dogfood/10-description-budget/chain-integrity.sh`. The script reads pre-removal `next-skills` lines from git history, then for each `(source_skill, target_skill)` pair greps the source SKILL.md body for the target name appearing in at least one of the three surfaces. The script runs as part of the slice-2 PR pre-merge dogfood suite.

This partially amends **ADR-0001** (load-bearing protocol via SYSTEM_CONTEXT.md): ADR-0001 never explicitly required `next-skills`, but the field was an implicit load-bearing assumption in some early chain documentation. The amendment is that chain relationships are body-level surfaces, never frontmatter.

## Consequences

### Positive

- Removes a recurring per-skill-listing token cost (the field is in the always-loaded metadata budget; ~11-15 chars × 11 skills ≈ 130 chars / ~33 tokens recovered, modest but free).
- Brings habeebs-skill into structural alignment with all four peer ecosystems audited — reduces the friction of users coming from those ecosystems.
- Eliminates the silently-broken contract (users could believe `next-skills` was being honored by the harness; it wasn't).
- The chain-integrity script makes chain relationships *testable* in CI for the first time — stronger than a frontmatter field which carried no enforcement.
- Lazy-loaded body sections (`## See also`) cost nothing until the SKILL.md actually triggers — a strict improvement over always-loaded frontmatter.

### Negative / Accepted trade-offs

- Tools (if any ever appear) that wanted to *visualize* the skill chain from frontmatter alone now need to parse SKILL.md bodies to extract `HANDOFF:` lines and `## See also` sections. No such tools exist today.
- One-way door for the v1.9.0 release: if Anthropic later formalizes a `next-skills` (or equivalent) frontmatter field in Skills 2.x, we'll need to re-introduce it. Mitigated by the explicit Revisit trigger below.
- Chain-relationship verification now lives in a bash assertion script instead of a frontmatter field — slightly more fragile (depends on naming conventions, case sensitivity), but offset by being actually enforceable.

### Operational impact

- All 14 SKILL.md frontmatter blocks need a one-line edit; mechanical refactor.
- Slice 2 of v1.9.0 owns the removal + script. Slice 1 ships first and is independent (description-trim).
- Tests/dogfood scenario gains a new assertion script — small surface, no new dependencies.

## Alternatives considered

### Keep `next-skills` as a documented habeebs-skill custom field

Document it explicitly as habeebs-skill metadata, ignored by the harness but useful for documentation/visualization. **Rejected** because the always-loaded cost is real and the only benefit is a future-imagined tool that doesn't exist; the cost-benefit doesn't pencil today.

### Formalize `next-skills` and propose it upstream to Anthropic

Submit the convention to the Claude Code Skills spec. **Rejected** as out of scope and slow — habeebs-skill is a single-repo plugin, not a spec-shaping effort. Anthropic's spec evolution is opaque and would block v1.9.0.

### Move `next-skills` into a separate `chain.json` file per skill

Keep the machine-readable pointer but out of the always-loaded frontmatter. **Rejected** because it introduces a new file convention with no consumer; the `HANDOFF:` line already does this job at zero extra cost.

### Surface chain relationships ONLY via HANDOFF, drop `## See also`

Use only the runtime mechanism. **Rejected** because `## See also` covers static relationships (e.g., `parallel-dev` is used by `prior-art-research` Deep mode and by `vertical-slice`) that don't show up in HANDOFF lines, which describe end-of-skill transitions.

## Revisit triggers

This ADR should be reopened if any of:

- **Anthropic publishes a Skills 2.x spec that formalizes `next-skills` or an equivalent chain-frontmatter field.** Re-add the field per the new spec; align with the canonical name and shape.
- **Chain visualization tools emerge that parse skill metadata.** If a meaningful ecosystem of tooling appears that depends on frontmatter chain pointers, the cost-benefit changes.
- **The chain-integrity script becomes a maintenance burden** (>1 false positive per quarter, or fundamental difficulty matching skill names in prose). Replace with a structured re-introduction of `next-skills` as documented custom metadata.
- **`HANDOFF:` lines drift in form or disappear from some skills.** If the canonical handoff mechanism erodes, chain-relationship discovery loses its primary surface and we need a fallback.

## References

- Research: `docs/agents/SYSTEM_CONTEXT.md` § Last reconciliation outcome (2026-05-13 — habeebs-skill ecosystem audit)
- Spec: `docs/agents/specs/v1.9.0-ecosystem-alignment.md` (Slice 2)
- Grill: `docs/agents/specs/v1.9.0-ecosystem-alignment-grill.md` (Item 3)
- Related: [ADR-0001](./0001-environment-binding-via-system-context.md) (partially amended; chain-relationship surfaces are body-level, not frontmatter)
- External sources:
  - [Claude Code Skills docs](https://code.claude.com/docs/en/skills) — canonical frontmatter spec
  - [obra/superpowers](https://github.com/obra/superpowers) — composition via prose mentions
  - [mattpocock/skills](https://github.com/mattpocock/skills) — composition via prose mentions

---

## Changelog

- 2026-05-13 — Initial ADR, status Accepted (decision locked by user's "include all in scope" approval of v1.9.0)
