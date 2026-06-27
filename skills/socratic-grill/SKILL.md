---
name: socratic-grill
description: Walk the user through the Design, pressure-test every aspect, write resolved decisions back into it, and earn sign-off before code. Use when draft-spec emits "HANDOFF: grill ready", the user types "/grill", or says "pressure-test this". Do not use to brainstorm options or for pure debugging.
disable-model-invocation: true
---

# Socratic Grill — pressure-test the Design and earn sign-off

**NO DECISION EXITS AS "WE'LL SEE."**

This skill is the user's comprehension-and-sign-off gate. You walk the user through the Design in
plain language so they understand exactly what is being built and why, then pressure-test every
ambiguous aspect until each one is decided. You write the resolutions back into the Design's
**Decided** section — there is no separate grill record. The user signs off on the Design. Only
then does the Machine layer (slicing, `tdd-loop`) begin.

The mode is Socratic: ask one question at a time, surface the assumption, force a concrete
answer. Never accept "it depends" without naming what it depends on AND committing to a path.

Write and speak in the house voice — see [`docs/agents/references/skill-voice.md`](../../docs/agents/references/skill-voice.md).

## When to use this skill

**Trigger on:**

- A `draft-spec` output ended with `HANDOFF: grill ready`
- A Design has a non-empty **Open questions** section
- The user uses hedging language ("probably," "we'll see," "tentatively")
- The user invoked `/grill` explicitly
- You're about to start implementation and notice ambiguous parts of the Design

**Do NOT trigger on:**

- Tasks with only one reasonable approach (don't manufacture ambiguity)
- Exploration / brainstorming (use `prior-art-research`)
- Pure debugging (the bug is the ambiguity-killer there)

## Core workflow

### Pre-flight — Environment check

Before Phase 1, verify `docs/agents/SYSTEM_CONTEXT.md` exists. If missing, halt with:

> **SETUP REQUIRED:** `docs/agents/SYSTEM_CONTEXT.md` missing. Run `/groundwork` (preferred — one-shot bootstrap) or `/research` (writes the file via Phase 0 reconnaissance) first.

Do not proceed without the environment-binding cache.

**Staleness check:** Before reading SYSTEM_CONTEXT.md, run the staleness-check protocol per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md). If stale, emit the banner and annotate inferences with `[stale]`. This skill only READS SYSTEM_CONTEXT.md.

### Phase 1 — Walk the Design, then inventory the open questions

First, **walk the user through the Design in plain language.** State, in two or three sentences,
what we're building and why this approach — so the user starts from understanding, not from a
wall of text. Then build the grilling agenda from:

1. The Design's **Open questions** section
2. Decisions in the Design marked "tentatively" or "to be confirmed"
3. Any hedging language in the user's prose
4. Key decisions stated with a choice but no reasoning
5. The intended decomposition — the eventual slice table — enters as one standing item, grilled
   on the slice-shape axis at the Design level: is the scope right, what would you cut, is this
   one feature or several? (The literal slices are produced later by `vertical-slice`; here you
   pressure-test the shape, not the mechanics.)

Show the user the list and ask if you missed anything. The list IS the agenda.

**Inherit the tier.** Read the `Tier:` field from the Design header (Quick / Balanced / Deep — see
[`docs/agents/references/tier-scale.md`](../../docs/agents/references/tier-scale.md)). The tier
scales *how much* grilling runs, never *whether* a real ambiguity gets resolved:

- **Quick** — grill runs *only if* the agenda is non-empty. If empty, record "no open items —
  grill skipped" and hand off. If non-empty, run one focused round on exactly those items. A
  non-empty agenda is *always* grilled, even at Quick.
- **Balanced** — full 8-axis grill (Phase 2).
- **Deep** — full grill, multiple rounds where an item stays unresolved.

**Mental-model probes.** These check the USER's expectations by making them produce understanding,
not affirm it. Count scaled by tier (Quick 1 / Balanced 2 / Deep 3, in this order):

1. **Premortem** — "It's six months out and this failed. What happened?" Restate the inverse as
   success criteria.
2. **Door classification** — "Take the highest-impact decision here: one-way or two-way door?"
   Every "two-way" gets one follow-up — "what's the undo cost, concretely?" — recorded. One
   follow-up, then accept.
3. **Concrete example** — "Walk me through one concrete example of the riskiest behavior: real
   input, real expected output." A rule the user can't exemplify is one they don't yet hold.

Write the answers into the Design's **Decided** section (success criteria, door labels with undo
costs). `decision-record` reads the one-way-door labels; `write-plan` reads the success criteria.

**Domain extension — agent products:** If the Design is for an agent / assistant / copilot /
chatbot / LLM workflow / RAG system (an LLM call on the critical path), invoke `agent-factors-check`
before Phase 2. It returns 6–13 extra Socratic questions (tool-call schemas, state unification,
pause/resume, human-as-tool, trigger surfaces, pre-fetch). Interleave them. Skip for generic CRUD /
web / mobile with no LLM orchestration. At Quick, skip the proactive sweep but grill any agenda
item that already touches an agent factor.

**Domain extension — developer-facing products:** If the Design is for a CLI, SDK, library API,
plugin, or framework, invoke `devex-review` before Phase 2. It returns one Socratic question per
developer-experience gap (onboarding, first-run roleplay, ergonomics, error messages, docs,
upgrades). Interleave them. Both extensions can fire on one Design. Skip for non-developer-facing
products.

### Phase 2 — Grill each item against the ambiguity axes

For each item, work the relevant 2–4 dimensions from `references/ambiguity-axes.md`.
The eight axes: Performance, Failure modes, Scale, Concurrency, Migration, Reversibility,
Observability, and Slice shape (is the work breakdown vertical, right-sized, correctly ordered?).

**Grilling style:**

- Ask one question at a time. Wait. Then drill deeper or move on.
- Challenge the first answer. "What if X happens?" "Why not Y?" "How do you measure that?"
- Don't accept abstract answers ("we'll log it" — log WHAT, queried HOW).
- If the user deflects, name it: "This is under-specified. Commit, or defer with a trigger."

### Phase 3 — Resolve each item

Each item exits in one of three states:

1. **Decided** — concrete answer committed. Capture it.
2. **Deferred** — revisit later, with a stated trigger condition. Capture the trigger.
3. **Out of scope** — belongs to a different problem. Punt it.

Never let an item exit as "we'll see." That is the failure mode this skill exists to prevent.

### Phase 4 — Write resolutions into the Design and earn sign-off

Edit the Design at `docs/agents/specs/YYYY-MM-DD-<slug>-design.md` in place. Do NOT write a
separate grill record.

1. Fill the Design's **Decided** section: each item, the committed answer, the undo cost (for a
   two-way door) or the trigger (for a deferred item), plus the mental-model success criteria and
   door labels.
2. If grilling changed the Overview, Why, Key decisions, or Open questions, edit those sections
   too — the Design is the single source of truth.
3. Set the Design's `Status:` to `Grilled`.
4. **Earn sign-off.** Present the updated Design and ask the user to confirm they understand it and
   approve it. On approval, set `Status:` to `Signed-off`. This is the gate into the Machine layer.

### Phase 5 — Hand off

Recap in one or two plain sentences what was decided and that the Design is signed off, then:

```
HANDOFF: implementation ready — Design signed off. Next: decompose into slices via `vertical-slice` and implement with `tdd-loop`.
HANDOFF: record ready — if the Design's Decided section contains a one-way-door decision, invoke `decision-record` to capture it as an ADR. Skip if every decision is reversible.
```

If grilling revealed a fundamental architectural problem (rare):

```
HANDOFF: re-research needed — invoke `prior-art-research` with the new constraint: [constraint].
```

## Scoped re-grill rounds

`tdd-loop` halts a slice with `suggested_action: "re-grill"` when implementation reveals a Design
decision is ambiguous or contradicted. The round that resolves it is scoped, not a full grill:

- **Fresh context.** Run it seeded only by the learning payload and the named decision.
- **Named-decision scope.** Grill only the blocked decision (2–4 axes), never the whole Design.
  Conditional extensions re-fire under the **domain-touch rule** — only the extension whose domain
  the blocked decision touches, applied to that one item, never a full proactive sweep.
- **Resolve by blast radius.** Minor (changes no other slice's acceptance criteria, adds no slice,
  leaves the Design's Overview and Key decisions untouched) → patch the Design's Decided section in
  place. Anything larger → hand off to `decision-record` for an ADR amendment.
- **Always on the record.** Write the resolution into the Design's Decided section with a dated note
  that names the blocked slice and decision and links back to the original Decided entry. The
  Design moved; the note says why. No separate record file.
- **Resume.** Hand control back to the halted slice; it re-enters RED against the clarified
  criterion. In-flight siblings follow `parallel-dev`'s halt-scope rule.

## Anti-patterns this skill guards against

| Thought | Reality |
|---|---|
| "This Design is simple — skip the grill." | Simple Designs hide the worst assumptions. If the agenda is non-empty, grill it. |
| "I'll write a separate grill record to be thorough." | The grill record is the Design's Decided section now. One human artifact, not two. |
| "'We'll figure it out later' is a fine answer." | It's the exact bug this skill prevents. Force commit-or-defer-with-trigger. |
| "I'll ask 20 questions to look rigorous." | Each question must serve a decision. Performative grilling wastes the user's time. |
| "I'll grill the budget / compliance / hiring call too." | Surface those to the user; don't try to resolve decisions that aren't yours. |
| "I'll move to slicing now that it's grilled." | Not until the user signs off. Sign-off is the gate, not grilling. |

## Grilling tone and pacing

- Direct, not abrasive. ("What happens when the connection drops mid-write?" — not "You're going
  to lose data, aren't you?")
- One axis at a time. Don't pile on.
- Acknowledge good answers briefly, then go deeper or move on.
- If the user is stuck, propose 2–3 options and ask which they prefer.
- If you're 20+ turns deep on one decision, the decision is mis-framed — reframe it.

## See also

- `draft-spec` — upstream; writes the Design this skill pressure-tests
- `prior-art-research` — fallback if grilling reveals a fundamental architectural problem
- `decision-record` — downstream; captures a one-way-door decision as an ADR
- `vertical-slice` — downstream Machine layer; decomposes the signed-off Design into slices
- `agent-factors-check` / `devex-review` — domain extensions invoked from Phase 1
- `references/ambiguity-axes.md` — the 8 dimensions to grill on
- `docs/agents/references/skill-voice.md` — the house voice
- `docs/agents/references/tier-scale.md` — the tier this grill inherits and how it scales
