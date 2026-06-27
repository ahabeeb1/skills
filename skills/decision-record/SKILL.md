---
name: decision-record
description: Capture a one-way-door (irreversible) decision as an ADR. Use when socratic-grill emits "HANDOFF: record ready" and the Design has an irreversible decision, or the user types "/record". Do not use for reversible decisions (they live in the Design) or trivial config.
disable-model-invocation: true
---

# Decision Record — ADR the one-way doors

**ONLY ONE-WAY DOORS GET AN ADR.**

An ADR is durable, discoverable memory for a decision that is expensive or impossible to reverse.
Reversible decisions already live in the Design's **Decided** section — do not duplicate them
here. Write an ADR only when the decision is a one-way door or high-blast-radius. A genuine
one-way-door decision is *always* recorded, even at the Quick tier and even under a `--quick`
override.

Write in the house voice — see [`docs/agents/references/skill-voice.md`](../../docs/agents/references/skill-voice.md).

## When to use this skill

**Trigger on:**

- `socratic-grill` produced `HANDOFF: record ready` AND the Design's Decided section contains a
  one-way-door / irreversible / high-blast-radius decision
- The user says "lock this in" / "document this decision" about an irreversible choice

**Do NOT trigger on:**

- Reversible, low-blast-radius decisions (they live in the Design's Decided section)
- Trivial choices (file naming, formatter, linter rules)
- Implementation details (function signatures, internal helpers)
- Code documentation (docstrings / inline comments)

## Core workflow

### Pre-flight — Environment check

Before Phase 1, verify `docs/agents/SYSTEM_CONTEXT.md` exists. If missing, halt with:

> **SETUP REQUIRED:** `docs/agents/SYSTEM_CONTEXT.md` missing. Run `/groundwork` (preferred — one-shot bootstrap) or `/research` (writes the file via Phase 0 reconnaissance) first.

**Staleness check:** Before reading SYSTEM_CONTEXT.md, run the staleness-check protocol per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md). This skill only READS SYSTEM_CONTEXT.md.

### Phase 1 — Confirm there is a one-way door

Read the signed-off Design's **Decided** section. Find the decision(s) classified as one-way
doors in the **User mental model** subsection (door classifications). If every decision is a
two-way door (reversible, low undo cost), STOP: write "no one-way-door decision — ADR skipped"
and hand off. Do not manufacture an ADR for a reversible decision.

### Phase 2 — Locate the ADR home and name the file

ADRs live in `docs/agents/adrs/`. Name the file `YYYY-MM-DD-<slug>.md` — today's date, a
lowercase-hyphenated title slug (≤8 words). The dated name is written **at creation** (no later
renaming, no integer late-binding). The slug is the uniqueness key; two ADRs on one day are fine
if their slugs differ. **Halt loud on a true duplicate** — if `docs/agents/adrs/YYYY-MM-DD-<slug>.md`
already exists, refuse to write: no overwrite, no suffix. Demand a more specific slug.

### Phase 3 — Gather inputs from the Design

Pull from the signed-off Design:

- **Context** — the Overview and Why-this-approach sections.
- **Decision** — the one-way-door pick from Key decisions / Decided.
- **Consequences** — the trade-offs from Key decisions, plus the door classifications and recorded
  undo costs from the Decided section's **User mental model** subsection.
- **Alternatives** — the rejected options named in Why-this-approach.
- **Tier** — the `Tier:` field from the Design header.

If the Design is missing, halt and ask for it (or run the upstream skills first).

The tier scales ADR depth, never whether a one-way door is recorded: **Quick** — standard template;
**Balanced** — standard template; **Deep** — full template with ≥3 alternatives.

### Phase 4 — Write the ADR

Follow `references/adr-template.md` exactly. It has two header blocks (YAML frontmatter with
PascalCase keys for the release editorial scan, plus a markdown-emphasis block for readability).
Set `Date-Created` and `Last-Reviewed` to today on first write. Sections: Title (present-tense
action), Context, Decision (active voice — "We will X because Y"), Consequences (positive /
negative / operational), Alternatives considered, Revisit triggers, References (link the Design).
Echo the inherited tier into both `Tier:` fields.

### Phase 5 — Append the ADR index row

Hand-append one row to `docs/agents/adrs/README.md`'s index table:
`| YYYY-MM-DD | [<Title>](./YYYY-MM-DD-<slug>.md) | <Status> | <date> |`, in the same shape as the
existing rows, after the last row. Cite a dated ADR by title + markdown link; cite a frozen
integer ADR (`0001`–`0024`) as `ADR-00NN`.

### Phase 6 — Hand off

Recap in one plain sentence what was locked and why it's irreversible, then:

```
HANDOFF: implementation ready — ADR locked. Next: implement via tdd-loop, or write-plan first if the work is genuinely multi-phase.
HANDOFF: future research — this ADR is now Tier-0 prior art. Future prior-art-research on adjacent problems should check it.
```

## Anti-patterns this skill guards against

| Thought | Reality |
|---|---|
| "Every decision deserves an ADR." | Only one-way doors do. Reversible decisions live in the Design. An ADR per commit is noise. |
| "It was decided that X would be used." | Passive voice hides the decider. Write "We chose X because Y." |
| "I'll list alternatives I didn't actually consider." | Hindsight strawmen are worthless. The Alternatives section reflects the real research. |
| "I'll skip Consequences — the choice is obviously right." | Every choice gives something up. If you can't name it, you haven't thought hard enough. |
| "ADRs are permanent records, no need for triggers." | ADRs aren't gravestones. State the conditions that reopen them. |

## Status field semantics

- **Proposed** — written, implementation not started.
- **Accepted** — implementation started or complete; current state of the system.
- **Deprecated** — no longer current, kept for history.
- **Superseded** — replaced by a newer ADR; always forward-link (title+link for a dated
  replacement, `ADR-00NN` for a frozen-integer one).

Move Proposed → Accepted on the commit that starts implementation. Never delete an ADR.

## See also

- `socratic-grill` — upstream; the signed-off Design and its one-way-door classifications
- `draft-spec` — upstream; the Design that holds the decision and its rationale
- `write-plan` — downstream; sequences multi-phase work after the ADR locks
- `tdd-loop` — downstream; implements against the locked decision
- `references/adr-template.md` — strict ADR format
- `docs/agents/references/skill-voice.md` — the house voice
- `docs/agents/references/tier-scale.md` — the tier that scales ADR depth
