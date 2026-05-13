# ADR-0007: Adopt a description budget policy — 1,200-char hard cap, 600-char target, three-keystone protected anti-triggers, `## Origins` body convention for credits

**Status:** Accepted
**Date:** 2026-05-13
**Deciders:** ahabeeb1

## Context

The Claude Code Skills 2.0 spec imposes a **1,536-character hard cap** on each skill's `description` (combined with `when_to_use`) in the always-loaded skill-listing budget. Beyond the cap, descriptions are truncated mid-string, stripping the trigger keywords that typically appear later in habeebs-skill's "Make sure to use this skill when…" pattern. The skill-listing budget defaults to **1% of the context window**, so all 14 skill descriptions live in the prompt on every turn.

The 2026-05-13 ecosystem alignment audit measured habeebs-skill description lengths: max 946 chars (`prior-art-research`), avg 785 chars across 14 skills, ~11,000 chars total per skill listing. All descriptions are under the 1,536-char hard cap — but the audit identified ~20-30% verbosity that adds no trigger value:

- "Inspired by Superpowers/OMC/mattpocock" credits embedded in descriptions (acknowledgments, not triggers)
- Verbose "Do NOT use for X, Y, Z, A, B, C" anti-trigger enumerations beyond the 2-3 highest-precision cases
- Restatements of the capability already covered by the opening capability statement

At the same time, **Anthropic's own guidance explicitly recommends "pushy" descriptions** to combat undertriggering — capability statement followed by enumerated "Use when X, Y, or Z" patterns, plus anti-trigger clauses. The audit also surfaced that three habeebs-skill skills — `prior-art-research`, `socratic-grill`, `tdd-loop` — have the widest catchment (they trigger on common user phrases like "I want to build" / hedging language / "let's start coding") and would *over-trigger* without robust anti-trigger lists.

This ADR establishes the description-budget policy that balances pushy-triggering against per-turn token economy, and codifies it for all future skill authoring.

## Decision

We will adopt the following description budget policy across all habeebs-skill SKILL.md files (existing 14 and any future skills):

- **Hard ceiling:** ≤1,200 characters per `description` field. (Well below Anthropic's 1,536-char cap to leave headroom for any future framing additions.)
- **Target average:** ≤600 characters across all skills in the plugin. (Currently 785; trim recovers ~500-800 tokens per turn.)
- **Pushy-trigger preservation:** Every description must contain the phrase "Make sure to use this skill" (or equivalent imperative) followed by enumerated trigger phrases. Anthropic's guidance on combating undertriggering is honored as canonical.
- **Three keystone skills retain ≥2 anti-trigger bullets:** `prior-art-research`, `socratic-grill`, `tdd-loop`. These have the widest catchment and the highest cost of over-triggering. The 11 other skills condense anti-triggers to ≤1 line or remove if redundant with the capability statement.
- **`## Origins` body convention for credits:** Acknowledgments ("Inspired by X" / "Lifted from X") move out of frontmatter descriptions and into a `## Origins` section near the bottom of the SKILL.md body, after `## See also` and before any final `HANDOFF` block. Phrasing distinguishes "Inspired by" (loose parallel evolution) from "Lifted from" (direct borrowing, e.g., Ousterhout's deep-modules, Pocock's vertical-slice).

A dogfood scenario at `tests/dogfood/10-description-budget/` enforces the hard cap and target average automatically.

The policy is anchored by ADR-0001's load-bearing-protocol principle: skill descriptions are part of the always-loaded contract every chain invocation pays for, so they get budgeted accordingly.

## Consequences

### Positive

- Recovers ~500-800 tokens of always-loaded budget per turn (description-trim across 14 skills) — meaningful at 1% skill-listing budget today, increasingly meaningful as skill count grows.
- Brings descriptions structurally closer to Anthropic's canonical "capability + Use when + Do NOT use" pattern documented in `anthropics/skills/skill-creator`.
- The `## Origins` convention preserves transparent attribution (which mattered for `tdd-loop`/Pocock TDD, `vertical-slice`/Pocock tracer-bullets, `parallel-dev`/Superpowers subagent-driven-development) without paying a per-turn token tax for it.
- Three-keystone protected-anti-trigger rule is empirically grounded — these three skills have the widest user-phrase catchment and would over-fire otherwise.
- Dogfood scenario adds CI-style budget enforcement; future skill authoring can't accidentally drift past the cap.

### Negative / Accepted trade-offs

- Trimming descriptions risks losing a trigger keyword that was empirically catching some marginal user phrasing. Mitigated by preserving "Make sure to use this skill" + enumerated triggers across the board; the cuts target anti-triggers and acknowledgments, not the pushy core.
- The 600-char *target* is an average, not a hard cap — individual descriptions may exceed it (e.g., the three keystones plus any new high-catchment skills). The 1,200-char hard cap is the only mechanically enforced rule.
- The `## Origins` convention adds a body section to ~6-8 SKILL.md files that didn't have one. Small surface; small reading cost only when the SKILL.md actually triggers.
- One-way door for v1.9.0: if a future Claude Code model gets dramatically better at trigger inference, the pushy descriptions become wasted budget — but loosening is cheap (re-trim further), tightening would require this whole ADR again.

### Operational impact

- Slice 1 of v1.9.0 owns the bulk of the trim. New skills authored after v1.9.0 must pass `tests/dogfood/10-description-budget/` to merge.
- Documentation update: `skills/setup-habeebs-skill/SKILL.md` should reference this ADR when explaining the convention for future authors.
- `verify-output` (slice 3 of v1.9.0) — the first skill authored under this policy — must comply at creation time.

## Alternatives considered

### Trim only to Anthropic's 1,536-char hard cap

Match Anthropic's spec, no tighter. **Rejected** because 1,536 still leaves us paying ~22% of the 1% skill-listing budget for verbose anti-trigger enumerations and credits. The audit showed real waste below the spec ceiling.

### Move descriptions to file headers, keep frontmatter minimal

Use `name`-only frontmatter (like raw mattpocock style) and put the description in the SKILL.md body. **Rejected** — Anthropic's harness needs the description in frontmatter to make selection decisions; moving it out of metadata would silently break trigger discovery.

### Uniform anti-trigger trim across all 14 skills

Treat every skill identically. **Rejected** because three skills have demonstrably wider catchment and over-trigger without robust anti-trigger lists — empirically, "Do NOT use for trivial CRUD" in `prior-art-research` has prevented chain invocation on small tasks; that line is load-bearing.

### Per-skill description budget tuning (no global rule)

Let each SKILL.md set its own length. **Rejected** because skill authoring drifts without a global rule. The 1,200/600 numbers are defensible (well below Anthropic's cap; honors the audit's recovered-token target); a per-skill regime would re-create the problem v1.9.0 is fixing.

## Revisit triggers

This ADR should be reopened if any of:

- **Claude Code raises or removes the 1,536-char description cap.** The hard ceiling tracks the spec; re-evaluate if Anthropic loosens it.
- **Skill count grows past 20.** The always-loaded skill-listing budget approaches 5% of context window; the 600-char target should drop further (e.g., 400-500).
- **A model with materially better trigger inference ships.** If Claude trigger discovery improves to where pushy enumerations are no longer needed, descriptions can trim further.
- **The three-keystone list changes.** If a fourth skill is added that has the same wide-catchment problem, expand the protected anti-trigger list explicitly.
- **The dogfood budget assertion produces a sustained false positive rate.** Re-tune or remove the automatic enforcement if it becomes brittle.

## References

- Research: `docs/agents/SYSTEM_CONTEXT.md` § Last reconciliation outcome (2026-05-13 — habeebs-skill ecosystem audit)
- Spec: `docs/agents/specs/v1.9.0-ecosystem-alignment.md` (Slice 1)
- Grill: `docs/agents/specs/v1.9.0-ecosystem-alignment-grill.md` (Items 1, 2)
- Related: [ADR-0001](./0001-environment-binding-via-system-context.md) (skill descriptions are part of the always-loaded protocol surface)
- External sources:
  - [Claude Code Skills docs](https://code.claude.com/docs/en/skills) — 1,536-char cap, 1% skill-listing budget
  - [Anthropic Engineering — Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) — three-level progressive disclosure
  - [anthropics/skills skill-creator](https://github.com/anthropics/skills) — canonical pushy-description pattern

---

## Changelog

- 2026-05-13 — Initial ADR, status Accepted (decision locked by user's v1.9.0 scope approval)
