---
Status: Proposed | Accepted | Deprecated | Superseded by ADR-NNNN
Date-Created: YYYY-MM-DD
Last-Reviewed: YYYY-MM-DD
Superseded-By: null
Tier: Quick | Balanced | Deep
Deciders: [Names or roles]
---

# ADR-NNNN: [Title in present-tense, action-oriented]

**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-NNNN
**Date:** YYYY-MM-DD
**Deciders:** [Names or roles]
**Tier:** Quick | Balanced | Deep (when produced by a chain run; omit for stand-alone ADRs)

> The YAML frontmatter block above is the v1.22.0 Piece 5 telemetry convention (PascalCase keys; deliberate-review semantics on `Last-Reviewed:`). The markdown-emphasis block below mirrors the frontmatter for human readability and is what previous ADRs use. New ADRs ship with both; existing ADRs (0001-0022) carry only the markdown block and back-fill is a v1.23.0+ candidate.

## Context

[The problem this ADR addresses. Include:
- What's being built or changed
- Scale and constraints (users, RPS, data volume, hard requirements)
- What already exists (greenfield, retrofit, replacement)
- Why this decision is needed NOW
Be specific. Two paragraphs max.]

## Decision

We will [action, in active voice]. Specifically:

- [Concrete pick 1]
- [Concrete pick 2]
- [Concrete pick 3]

[1-2 paragraphs of reasoning. Tie back to the Context — the choice should be defensible given the constraints listed.]

## Consequences

### Positive

- [Benefit 1]
- [Benefit 2]

### Negative / Accepted trade-offs

- [Trade-off 1 — what we gave up explicitly]
- [Trade-off 2]

### Operational impact

- [How it affects deploys, monitoring, on-call, cost]

## Alternatives considered

### [Alternative 1 name]

[1-2 sentences describing it. Why rejected: 1 sentence.]

### [Alternative 2 name]

[Same structure]

### [Alternative 3 name]

[Same structure]

[2-4 alternatives total. Each should be a real option from the research, not a strawman.]

## Revisit triggers

This ADR should be reopened if any of:

- [Scale milestone — "if concurrent users exceed N"]
- [Capability gap — "if we need to support feature X that this architecture can't"]
- [Market change — "if vendor X changes pricing / sunsets product Y"]
- [Cost threshold — "if monthly cost of this approach exceeds $N"]

## References

- Research: [Link to `prior-art-research` output]
- Spec: [Link to `draft-spec` output]
- Grill: [Link to `socratic-grill` output]
- Plan: [Link to `write-plan` output, if one exists yet]
- External sources:
  - [Source 1]
  - [Source 2]

### Reference implementations cited

(Only when the ADR relies on a specific external reference impl. Delete this subsection if not applicable.)

- **[Capability name]:** [link or repo] — [why this implementation is cited].

---

## Changelog

- YYYY-MM-DD — Initial ADR, status Proposed
- YYYY-MM-DD — Status moved to Accepted, implementation started in slice #N
