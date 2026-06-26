---
Status: Accepted
Date-Created: 2026-06-26
Last-Reviewed: 2026-06-26
Superseded-By: null
Tier: Balanced
Deciders: Modie (project lead)
---

# Split the chain into a plain-language Human layer and a technical Machine layer, with a single Design artifact

**Status:** Accepted
**Date:** 2026-06-26
**Deciders:** Modie (project lead)
**Tier:** Balanced

## Context

The chain produces five artifacts per feature — research report, spec, grill record, ADR,
plan. A long-time user reported that the chain "lacks clarity… just a bunch of jargon… no
insight into what I am implementing… all the skills mashed together." The root cause is that
the *why* of a feature — what is being built and the reasoning behind it — is scattered across
four documents (research recommendation, spec architecture section, grill record, ADR), none of
which is a single plain-language thing the user reads to understand the feature. The spec in
particular mixes human-facing design content (architecture, picks, trade-offs) with
machine-facing execution detail (vertical slices, test seams, dependency ordering), so the
reasoning is buried inside a document written for the implementer.

The user's own model: they live in the part of the chain that decides *what* and *why*; once
they understand and approve that, the implementation mechanics are for the subagents —
"whatever works best for subagent TDD and gets the most correct output." obra/superpowers
validates this split — its `brainstorming` skill produces one plain-language design doc
(`docs/superpowers/specs/…-design.md`) from dialogue, then hands to `writing-plans` for the
machine detail.

## Decision

We will divide the chain into two layers and redefine the spec as the **Design**.

- **Human layer** (plain language, readable cold): `prior-art-research → the Design → socratic-grill`.
  The Design is the single artifact that states what we're building, why this approach, the key
  decisions, and the trade-offs. `socratic-grill` walks the user through it, interrogates every
  relevant aspect, and earns explicit sign-off.
- **Machine layer** (technical, optimized for subagent TDD): the slice list, `tdd-loop`, and
  `parallel-dev`. The user does not read these.
- **"spec" is redefined to mean the Design.** `draft-spec` (`/spec`) now produces the Design.
  The vertical-slice decomposition moves out of `draft-spec` and becomes a machine sub-artifact
  generated from the approved Design by `vertical-slice` / `tdd-loop` intake.
- **Skill directory names and slash commands are unchanged.** Only behavior, outputs, and prose
  change — no rename churn, no routing/sync/frontmatter-parity breakage.

The Design lives at `docs/agents/specs/YYYY-MM-DD-<slug>-design.md` (reusing `specs/`; no new
authored directory).

## Consequences

### Positive

- One plain-language document carries the entire what/why. The "where is the why" confusion
  disappears.
- The human reads three artifacts (research, Design, grilled Design), not five.
- Machine-layer documents stay terse and technical — optimized for subagent correctness rather
  than torn between two audiences.

### Negative / Accepted trade-offs

- "spec" now means something different from its prior meaning (a sliced implementation doc).
  Existing references across skills and docs must be updated in one pass.
- The slice list is generated later in the flow (after sign-off) rather than during `draft-spec`,
  so the machine intake step gains responsibility it did not have before.

### Operational impact

- `draft-spec`, `socratic-grill`, `vertical-slice`, and `tdd-loop` change behavior; CLAUDE.md,
  `using-habeebs-skill`, `tier-scale.md`, and README change to describe the new shape. Dogfood
  tests asserting the old artifact shape are updated in the same release.

## Alternatives considered

### Keep five artifacts, add a plain-English "design brief" front page

Add one readable summary doc that fronts the existing chain. Rejected: it adds a sixth artifact
rather than removing redundancy, and the buried-why problem (design content trapped inside the
spec and ADR) remains.

### Adopt superpowers' workflow wholesale

Replace our chain with superpowers' six phases. Rejected: discards our distinctive value (depth
tiers, ADRs as durable memory, `parallel-dev`) for a net-lateral move. We adopt its layer split
and voice, not its skill set.

### Collapse design and grill into one step

Have `socratic-grill` both produce and interrogate the Design. Rejected for this ADR: the user
chose a dedicated Design doc that exists *before* grilling, so they can read the design first and
then have it pressure-tested. (The grill record still merges *into* the Design — see the
companion decision.)

## Revisit triggers

This ADR should be reopened if any of:

- Users report the single Design doc has grown too large to read cold (split it by concern).
- The machine slice-generation step proves unreliable without the design-time slicing context
  that `draft-spec` used to carry (move slicing back earlier).
- A future harness needs the slice list available before sign-off (re-sequence the layers).

## References

- Plan: this change's implementation plan (clarity / human-machine-split release).
- ADR-0021 — [methodology-folder-cuts](./0021-methodology-folder-cuts.md) — established the
  precedent of folding grill-records into specs.
- ADR-0023 — [methodology-bundle-v1.22](./0023-methodology-bundle-v1.22.md) — established the
  plain-English plan format this generalizes across the chain.
- External: obra/superpowers `brainstorming` and `writing-plans` skills (design-doc-from-dialogue
  then machine plan).

---

## Changelog

- 2026-06-26 — Initial ADR, status Accepted.
