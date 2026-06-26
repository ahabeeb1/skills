---
name: draft-spec
description: Write the Design — a plain-language doc of what we're building, why, and the key decisions and trade-offs. Use when prior-art-research emits "HANDOFF: spec ready" or the user types "/spec". Do not use to decompose into slices (machine layer, after grill sign-off) or to debug an existing Design.
disable-model-invocation: true
---

# Draft Spec — write the Design

**NO IMPLEMENTATION BEFORE THE USER UNDERSTANDS THE DESIGN.**

This skill turns the research recommendation into the **Design**: one plain-language document
that says what we're building, why this approach, the key decisions, and the trade-offs. The
user reads the Design to understand the feature. It is the Human layer — write it to be read
cold. Slicing, tests, and sequencing are the Machine layer; they come later, after the grill
earns sign-off. Do not put them here.

Write the Design in the house voice — see [`docs/agents/references/skill-voice.md`](../../docs/agents/references/skill-voice.md).

## When to use this skill

**Trigger on:**

- A `prior-art-research` output ended with `HANDOFF: spec ready`
- The user invoked `/spec` explicitly
- The user pasted a research recommendation and asked "now what?"
- The conversation has converged on an approach and the user wants it written up

**Do NOT trigger on:**

- Vague intent with no chosen approach (run `prior-art-research` first)
- A request to decompose into slices (that is the Machine layer — happens after grill sign-off)
- A request to debug or pressure-test an existing Design (use `socratic-grill`)

## Core workflow

### Pre-flight — Environment check

Before Phase 1, verify `docs/agents/SYSTEM_CONTEXT.md` exists. If missing, halt with:

> **SETUP REQUIRED:** `docs/agents/SYSTEM_CONTEXT.md` missing. Run `/groundwork` (preferred — one-shot bootstrap) or `/research` (writes the file via Phase 0 reconnaissance) first.

This skill cannot produce a reliable Design without the environment-binding cache. Do not proceed.

**Staleness check:** Before reading SYSTEM_CONTEXT.md, run the staleness-check protocol per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md). If stale, emit the banner and annotate any inference drawn from the cache with `[stale]`. This skill is a READER — only `prior-art-research` Phase 0 writes SYSTEM_CONTEXT.md.

### Phase 1 — Locate the recommendation

The Design is built from a research recommendation. Find it, in order:

1. The most recent `prior-art-research` output in the conversation, OR
2. An ADR the user pointed to (`docs/agents/adrs/...`), OR
3. The user's prose description of the chosen approach

If none exists, halt and ask: "I need a chosen approach to design from. Either invoke
`prior-art-research` first, or describe the approach you've settled on."

### Phase 2 — Pull the design inputs

From the recommendation, pull:

- **Tier** — the `**Tier:**` field in the research report header (Quick / Balanced / Deep). This
  skill inherits it; it does not re-decide it. Echo it into the Design header. See
  [`docs/agents/references/tier-scale.md`](../../docs/agents/references/tier-scale.md). If the
  report has no `Tier:` field, default to Balanced.
- **What we're building** — the one-paragraph shape of the feature.
- **Why this approach** — the reasoning from the research Recommendation section.
- **Key decisions** — the table of concrete picks and the reason for each.
- **Trade-offs** — what we're explicitly giving up.
- **Open questions** — anything research didn't resolve.

### Phase 3 — Write the Design in plain language

Follow `references/design-template.md` exactly. Lead with what we're building, in language a
non-expert reads cold. Then why this approach, the key decisions and their trade-offs, what we're
explicitly NOT doing, and the open questions that go to the grill.

The tier scales the Design's depth, never whether the user understands it:

- **Quick** — short Overview, key decisions, trade-offs, open questions. No long alternatives walk.
- **Balanced** — full template.
- **Deep** — full template plus a fuller why-this-approach with the rejected alternatives.

Leave the **Decided** section empty with the placeholder. `socratic-grill` writes resolutions into
it; there is no separate grill record.

Every "should," "probably," or "we'll figure it out later" is a future bug. Put it in **Open
questions** so the grill catches it — do not paper over it.

### Phase 4 — Write the Design document

Write to `docs/agents/specs/YYYY-MM-DD-<feature-slug>-design.md` (the `-design` suffix marks it as
the Design; the slug is the uniqueness key). Halt loud if the dated filename already exists —
demand a more specific slug. If the repo has no convention yet, write to
`.scratch/YYYY-MM-DD-<feature-slug>-design.md`; if no filesystem is available, write it inline.

### Phase 5 — Hand off

Recap in one or two plain sentences what the Design says and what happens next, then:

```
HANDOFF: grill ready — invoke `socratic-grill` to walk the user through this Design, pressure-test every aspect, and earn sign-off before any code.
```

Do not hand off to slicing or `tdd-loop` from here. The Machine layer starts only after the grill
signs off.

## Anti-patterns this skill guards against

| Thought | Reality |
|---|---|
| "I'll add the slice breakdown while I'm here." | Slices are the Machine layer. They come after sign-off. A Design full of slice mechanics is unreadable to the user. |
| "This 'should' is obvious — I'll just decide it." | Every "should" is a future bug. Put it in Open questions; let the grill resolve it with the user. |
| "The research said X; I'll recommend Y because it's better." | The Design traces to the research. If you want Y, halt and re-research — don't drift the Design. |
| "I'll pre-decide the micro-optimizations now." | Capture trade-offs and revisit triggers, not premature optimization the implementation will reveal. |
| "Plain language wastes space — I'll write it tersely." | The user reads this to understand the feature. Cold-readable is the whole job. |

## See also

- `prior-art-research` — upstream; produces the recommendation this Design is built from
- `socratic-grill` — downstream; walks the user through the Design and earns sign-off
- `vertical-slice` — the Machine-layer decomposition that runs AFTER sign-off
- `decision-record` — writes an ADR only when the Design has a one-way-door decision
- `references/design-template.md` — strict format for the Design document
- `docs/agents/references/skill-voice.md` — the house voice this Design is written in
- `docs/agents/references/tier-scale.md` — the tier this Design inherits and how it shapes depth
