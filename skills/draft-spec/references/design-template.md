# Design Template

Lives at `docs/agents/specs/YYYY-MM-DD-<slug>-design.md` (dated at creation; the `-design`
suffix marks it as the Design). Written by `draft-spec`. The **Decided** section is filled in by
`socratic-grill` — there is no separate grill record.

This is a **Human-layer** artifact: the user reads it to understand the feature. It MUST read
cold, top to bottom, with no prior context. Plain English first; gloss any term that lacks a
GLOSSARY entry on first use (see [`skill-voice.md`](../../../docs/agents/references/skill-voice.md)).
No slice tables, no test seams, no dependency graphs — those are the Machine layer and come after
sign-off.

Copy from here. Replace bracketed placeholders. Keep every section unless it genuinely does not
apply (mark unused ones "N/A — reason").

---

```yaml
---
Status: Draft | Grilled | Signed-off | Superseded
Date-Created: YYYY-MM-DD
Last-Reviewed: YYYY-MM-DD
Superseded-By: null
Version: vX.Y.Z      # the release this Design ships in; carries spec->release traceability (the version that left the filename). Bound at release; optional pre-release.
Release: vX.Y.Z      # alias of Version; keep both or drop one.
Tier: Quick | Balanced | Deep
---
```

# Design: [present-tense name of what we're building]

## Overview

[3–5 plain-English sentences. What are we building, for whom, and what will the user be able to
do when it ships? A reader who only reads this paragraph knows what the feature is. No jargon
cliff — if you must use a methodology term, gloss it here.]

## Why this approach

[2–4 sentences. Why this shape and not the obvious alternatives, tied to the research and to the
user's stated priorities. Name the one or two alternatives we rejected and why, in one line each.
This is the "why" the user is here to understand — make it legible.]

## Key decisions and trade-offs

[The handful of decisions that define the feature. For each: what we chose, in one line, and what
we give up by choosing it. Prose or a short list — not a slice table. Example:]

- **[Decision]:** we will [choice], because [reason]. Trade-off: [what we give up].
- **[Decision]:** we will [choice], because [reason]. Trade-off: [what we give up].

## What we're explicitly NOT doing

[The scope boundary. What a reasonable person might expect us to build but we are deliberately
leaving out — and why. Ruthless YAGNI. This prevents the feature from quietly growing.]

- [Not doing X — reason / deferred to later]
- [Not doing Y — reason]

## Open questions

[Everything unresolved. Every "should," "probably," and "we'll figure it out later" goes here.
`socratic-grill` works this list with the user. Empty is allowed only if there is genuinely
nothing ambiguous.]

- [Question 1]
- [Question 2]

## Decided

[EMPTY at draft time. `socratic-grill` writes resolutions here as it works the open questions:
each item, the answer the user committed to, and — for a reversible decision — the undo cost, or
for a deferred one, the trigger that reopens it. When this section is filled and the user has
signed off, the Design is the single record of what we're building and why.]

_(none yet — filled during the grill)_

### User mental model

[Written by `socratic-grill` from the Phase 1 mental-model probes (count varies by tier).
`write-plan` reads the success criteria as acceptance-gate candidates; `decision-record` reads
the door classifications into ADR consequences.]

- **Success criteria** (premortem inverse): [what must be true for the user to call this
  shipped-and-working]
- **Door classifications:** [each high-impact decision → one-way | two-way, with the recorded
  concrete undo cost for every two-way label]
- **Premortem risks worth tracking:** [failure narratives the user volunteered that aren't already
  covered above]

## References

- Research: [`research/<slug>-research`](../research/<slug>-research.md) (when produced by a
  Deep-tier run) or the in-conversation recommendation.
- SYSTEM_CONTEXT: [`SYSTEM_CONTEXT.md`](../SYSTEM_CONTEXT.md)

> Terms: see [GLOSSARY](../GLOSSARY.md).

---

HANDOFF: grill ready — invoke `socratic-grill` to walk the user through this Design, pressure-test every aspect, and earn sign-off before any code.
