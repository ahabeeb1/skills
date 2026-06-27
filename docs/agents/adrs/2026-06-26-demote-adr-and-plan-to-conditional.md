---
Status: Accepted
Date-Created: 2026-06-26
Last-Reviewed: 2026-06-26
Superseded-By: null
Tier: Balanced
Deciders: Modie (project lead)
---

# Demote the ADR to one-way-door decisions only and the plan to multi-phase work only; merge the grill record into the Design

**Status:** Accepted
**Date:** 2026-06-26
**Deciders:** Modie (project lead)
**Tier:** Balanced

## Context

With the Design established as the single human artifact (companion decision), two of the
remaining artifacts are largely redundant with it, and a third overlaps the machine slice list:

- The **grill record** (`-grill.md`) captured the resolved decisions, trade-offs, and revisit
  triggers. The Design now carries exactly this content in its Decided section. Two documents
  hold the same information.
- The **ADR** re-derives decisions, consequences, alternatives, and revisit triggers that the
  Design already records. For a reversible, low-blast-radius decision the ADR adds ceremony
  without durability value — `tier-scale.md` already skips it at the Quick tier for precisely
  this reason.
- The **plan** re-states slice ordering and parallelization that the machine slice list already
  expresses. For single-phase work it is pure duplication — `write-plan` is already skip-able at
  Quick.

The user asked us to "think about what value each md file brings" and cut redundancy.

## Decision

We will make the previously-mandatory artifacts conditional, and merge the grill record into the
Design.

- **The grill record merges into the Design.** `socratic-grill` writes its resolutions back into
  the Design's Decided section. No separate `-grill.md` file on the common path.
- **An ADR is written only for a one-way-door / irreversible / high-blast-radius decision.** This
  makes today's Quick-tier rule the universal default across all tiers. A genuine one-way-door
  decision is *always* recorded (per `tier-scale.md` invariant 1); everything else lives in the
  Design.
- **A plan is written only for genuinely multi-phase / staged-rollout work** with real phase
  gates. Otherwise the machine slice list and its ordering *are* the plan.

The common path for a typical feature drops from five artifacts to three: research, Design,
grilled Design.

## Consequences

### Positive

- One human artifact (the Design) holds the what/why and the resolved decisions — no hunting
  across grill record and ADR.
- ADRs become rare and meaningful: they mark the decisions whose durability actually matters
  (irreversible ones), so the ADR index stays a high-signal memory.
- No spec↔plan slice duplication on single-phase features.

### Negative / Accepted trade-offs

- Reversible decisions no longer get a standalone ADR. Recovery: they are recorded in the Design's
  Decided section, which is durable in-repo. If a reversible decision later proves load-bearing,
  promote it to an ADR then.
- The `-grill.md` artifact disappears from the common path. Any tooling or test that expected it
  must read the Design's Decided section instead.

### Operational impact

- `socratic-grill`, `decision-record`, and `write-plan` change behavior. Dogfood tests that
  assert a separate grill record or a mandatory ADR/plan are updated in the same release.
- The `-regrill` mechanism patches the Design rather than writing a separate record.

## Alternatives considered

### Keep the ADR and plan mandatory

Status quo. Rejected: it is the redundancy the user explicitly asked us to cut, and it keeps the
why spread across documents.

### Drop ADRs entirely

Tempting for simplicity. Rejected: irreversible decisions genuinely need durable, discoverable
memory that survives the Design doc's lifecycle — the ADR index is that memory. We keep ADRs for
exactly those cases.

### Keep a separate grill record but make it terse

Rejected: two documents covering the same decisions is the confusion we are removing. Merging into
the Design is strictly simpler.

## Revisit triggers

This ADR should be reopened if any of:

- Designs routinely accumulate so many Decided items that a separate record improves readability.
- Single-phase features start needing phase gates often enough that an always-on plan is warranted.
- The "one-way door" test proves too ambiguous in practice and ADRs are written too often or too
  rarely (tighten the test).

## References

- Companion: [human-machine layer split + Design artifact](./2026-06-26-split-human-design-and-machine-layers.md).
- ADR-0016 — [chain-wide-depth-tier](./0016-chain-wide-depth-tier.md) — the Quick-tier
  conditional rules this generalizes.
- ADR-0021 — [methodology-folder-cuts](./0021-methodology-folder-cuts.md) — prior grill-records
  fold precedent.

---

## Changelog

- 2026-06-26 — Initial ADR, status Accepted.
