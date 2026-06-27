---
Status: Accepted
Date-Created: 2026-06-26
Last-Reviewed: 2026-06-26
Superseded-By: null
Tier: Balanced
Deciders: Modie (project lead)
---

# Adopt a plain-imperative house voice — iron law, Thought→Reality tables, jargon glossed — for every skill

**Status:** Accepted
**Date:** 2026-06-26
**Deciders:** Modie (project lead)
**Tier:** Balanced

## Context

The user finds the skills hard to read — dense methodology jargon (vertical slice, pgroup, HITL,
AFK, one-way door, dispatch group, 4-status contract) used without inline definition, and skill
bodies that describe process without a memorable rule the reader carries away. They contrasted
this with obra/superpowers, which they find simple and readable. Superpowers reads simply because
of three concrete devices: a one-line **iron law** at the top of each skill
(`NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST`), **plain imperatives** (YOU MUST / STOP /
numbered steps), and **"Thought → Reality" tables** that name the agent's own evasions and refute
them. Near-zero jargon; every rule states what to do and why in one breath.

Our skill bodies are governed by ADR-0022 (behavioral-only — present-tense imperatives, no theory
prose, no inline ADR/version/date cruft, ≤500 lines). The superpowers devices are themselves
imperative content, so they are compatible — the constraint is only that the *explanation* of the
convention lives in a reference doc, not in the bodies.

## Decision

We will adopt a single house voice across every skill, defined once in a new reference and applied
to all bodies.

- **New reference `docs/agents/references/skill-voice.md`** defines the four devices and the
  human-vs-machine layer distinction (which artifacts must read plain-English vs which stay
  technical). It is the analog of superpowers' `writing-skills` meta-skill.
- **Every chain and standalone skill opens with one iron law** — a single imperative line stating
  the skill's non-negotiable rule.
- **Anti-pattern lists become Thought→Reality tables** — two columns: the rationalization the
  agent will reach for, and the reality that refutes it.
- **Plain English first; jargon glossed.** Human-layer artifacts read cold. Any methodology term
  without a `GLOSSARY.md` entry gets a 3–8-word inline gloss on first use; terms that have a
  GLOSSARY entry are licensed by a GLOSSARY footer link.

This is the BODY analog of ADR-0007's frontmatter policy and stays within ADR-0022.

## Consequences

### Positive

- Each skill carries one memorable rule, surfaced first.
- The Thought→Reality tables pre-empt the exact shortcuts the agent (and reader) reach for, which
  is what makes superpowers feel unevadable.
- Jargon stops blocking comprehension on the human layer.

### Negative / Accepted trade-offs

- A one-time rewrite pass touches every SKILL.md. Mitigation: mechanical, phase-gated, and guarded
  by a new dogfood check so the convention does not silently regress.
- Iron laws and tables add a few lines per body. Mitigation: bodies stay ≤500 lines (ADR-0022
  ceiling); jargon removal frees space.

### Operational impact

- All skills are rewritten in one release; `bin/sync-codex.sh` regenerates the Codex tree; a new
  structural dogfood guard checks the iron-law presence and the Design template's plain-language
  sections. Readability itself remains judgment-based (postmortem-guarded), not regex-enforced.

## Alternatives considered

### Keep our prose, just gloss jargon inline

Rejected as insufficient: glossing removes the jargon wall but not the "no memorable rule / process
without punch" problem the iron-law and table devices solve.

### Adopt the voice only on the human-layer skills

Rejected: a consistent voice across all skills is easier to maintain and read; machine-layer skills
benefit from iron laws too (`NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST` is a machine-layer
law).

### Centralize all guidance in one mega-reference and keep bodies minimal

Rejected: ADR-0022 already sets the body shape; the right move is one voice reference plus
imperative bodies, not a second instruction surface that competes with the bodies.

## Revisit triggers

This ADR should be reopened if any of:

- The dogfood voice guard produces frequent false positives (refine the check or the convention).
- A skill body cannot express its rule as a single iron law without distortion (allow two).
- Anthropic publishes authoring guidance that conflicts with these devices (reconcile against it).

## References

- ADR-0022 — [behavioral-only-skill-body](./0022-behavioral-only-skill-body.md) — the body-shape
  constraint this works within.
- ADR-0007 — [description-budget-policy](./0007-description-budget-policy.md) — the frontmatter
  analog of this body-voice policy.
- ADR-0009 — [docs-agents-references-convention](./0009-docs-agents-references-convention.md) —
  governs the new `skill-voice.md` reference.
- External: obra/superpowers `writing-skills`, `test-driven-development`, `using-superpowers`
  (iron-law + Thought→Reality + plain-imperative exemplars).

---

## Changelog

- 2026-06-26 — Initial ADR, status Accepted.
