# Grill-extension protocol — shared procedure for conditional grill extensions

Cross-cutting helper (per ADR-0009). The conditional `socratic-grill` extensions —
`agent-factors-check` (agent/LLM specs) and `devex-review` (developer-facing specs) —
share this exact procedure. Each skill keeps only what differs: its trigger test,
its checklist of items (the 13 agent factors / the 6 DX dimensions), its mapping
table, its per-item triage assignments, and its product-specific examples. The
mechanics below are identical for both; edit them here, not in each skill.

Both extensions are invoked **from** `socratic-grill`, not as standalone phases.
They add Socratic questions to the active grilling agenda; after grilling resolves
them, control returns to the main chain. Neither has a standalone DONE/BLOCKED
return — the hand-back below (`grilling agenda updated`) is the only return shape.

## Pre-flight — Environment check

Invoked from inside `socratic-grill`, the extension inherits its environment. If
invoked standalone (e.g. `/factor-check` or `/devex-review` directly), apply the
staleness-check protocol per [`system-context-staleness-check.md`](./system-context-staleness-check.md)
before reading SYSTEM_CONTEXT.md. The extension is a READER — only
`prior-art-research` Phase 0 writes SYSTEM_CONTEXT.md.

## Phase 1 — Confirm trigger

Read the spec (or the active grilling context) and apply the skill's trigger test.
If it does not apply, halt with the SKIP block:

```
SKIP: <skill-name> does not apply.
  Reason: <one line>.
  Returning control to socratic-grill.
```

If unclear, ask the skill's one-question test. Don't run on a spec the trigger
excludes — wasted tokens and noise in the grilling record.

## Phase 2 — Score each item against the spec

For each item in the skill's checklist, mark one of:

- **✓ Addressed** — spec is explicit. Cite the spec section.
- **~ Partial** — spec touches it but leaves an ambiguity. Note what's ambiguous.
- **✗ Missing** — spec is silent. Flag as a gap.
- **N/A** — item doesn't apply to this product **by design**. State the design reason.

Bias toward Partial/Missing on first pass. If tempted to mark Addressed, find the
*specific* sentence in the spec — if you can't quote it, it's Partial. **N/A is a
legitimate score** only when the item is intentionally out of scope with a stated
reason; N/A is NOT an escape hatch for "I don't know" (that's ~Partial).

## Phase 3 — Generate one Socratic question per gap

For each Partial or Missing item, write ONE concrete question for the grilling
agenda. The question must be:

- Specific to this product (use the actual entity names — tools, commands, API
  surface — from the spec, not generic "have you thought about X?")
- Single-axis (don't combine items into one question)
- Resolvable in one or two grill turns (no questions that are themselves features)

Reject vague ("is your X good?"), multi-axis ("X, Y, AND Z — what's the plan?"),
and framework-war ("should we use A or B?") questions. See the skill's own examples
for the good/bad shape.

## Phase 4 — Triage skip-able vs. must-grill

Not every gap needs grilling. Each skill assigns its items to three tiers:

- **Must-grill** (high blast radius — wrong forces a rewrite): surface ALL.
- **Should-grill** (medium — friction, not rewrites): surface only if ≥1 Partial/Missing exists.
- **Nice-to-grill** (low — resolvable later): surface only on a full-sweep request.

## Phase 5 — Hand back to socratic-grill

Produce the skill's record (per its `references/*-template.md`) and append it to the
active grill record. Output:

```
HANDOFF: grilling agenda updated — <N> new questions added from <skill-name>.
  Must-grill: <count> questions on <items>.
  Should-grill: <count> questions on <items>.
  Resume socratic-grill with these questions interleaved into the existing agenda.
```

## Shared anti-patterns

- **Running on specs the trigger excludes.** Wastes tokens, pollutes the grill record.
- **Generating design instead of questions.** The output is Socratic questions; proposing solutions is `socratic-grill`'s job after the question is asked.
- **Treating the checklist as a scorecard.** It's a gap-finder, not a grade. A spec with many Missings isn't "bad" — it's early-stage.
- **Folding all gaps into one mega-question.** Each gap gets its own question; the user may answer them across different turns.
- **Inventing items not in the skill's closed list.** A new item is a new skill or a new ADR — don't smuggle it in.
