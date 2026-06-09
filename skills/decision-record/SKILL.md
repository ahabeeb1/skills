---
name: decision-record
description: Capture a chosen architecture as an ADR. Use when socratic-grill emits "HANDOFF: record ready", user types "/record", "lock this in", "document this decision", or after a non-trivial architectural choice. Do not use for trivial config (file naming, formatter rules) or code documentation.
disable-model-invocation: true
---

# Decision Record

Capture a chosen architecture as an ADR so future research, future hires, and future-you can understand WHY the system is shaped the way it is.

ADRs are the asynchronous memory of a codebase. The pattern is established (Michael Nygard's ADR format, refined by many teams). This skill enforces it for habeebs-skill chain outputs so research and decisions accumulate into reusable prior art.

## When to use this skill

**Trigger on:**

- `socratic-grill` produced `HANDOFF: record ready`
- A non-trivial architectural decision has been made
- The user says "let's lock this in" / "document this" / "write this up"
- A spec is about to enter `tdd-loop` and lacks an ADR

**Do NOT trigger on:**

- Trivial choices (file naming, formatter, linter rules)
- Implementation details (function signatures, internal helpers)
- Decisions that will obviously change next sprint (premature codification)
- Code documentation (that's docstrings / inline comments)

## Core workflow

### Pre-flight — Environment check

Before Phase 1, verify `docs/agents/SYSTEM_CONTEXT.md` exists. If missing, halt with:

> **SETUP REQUIRED:** `docs/agents/SYSTEM_CONTEXT.md` missing. Run `/groundwork` (preferred — one-shot bootstrap) or `/research` (writes the file via Phase 0 reconnaissance) first.

This skill cannot produce reliable output without the environment-binding cache. Do not proceed to Phase 1.

**Staleness check:** Before reading SYSTEM_CONTEXT.md, run the staleness-check protocol per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md). If stale, emit the banner and proceed with a clear `[stale]` annotation on any inferences drawn from the cache. This skill is a READER — only `prior-art-research` Phase 0 writes SYSTEM_CONTEXT.md.

### Phase 1 — Locate the ADR home

Where do ADRs live in this repo? Check in order:

1. `docs/agents/adrs/` (habeebs-skill convention from `setup-habeebs-skill`)
2. `docs/architecture/decisions/` (common convention)
3. `docs/adr/`, `adr/`, or `.adr/`
4. Anywhere a `0001-*.md` or `001-*.md` file already exists

If none found, ask: "Where should ADRs live? Default is `docs/agents/adrs/`. Y/N or specify."

### Phase 2 — Name the ADR

Write the ADR's filename: `YYYY-MM-DD-<slug>.md`, where the date is today and the slug is a lowercase-hyphenated title.

**The slug — not the date — is the uniqueness key.** Two ADRs on the same day are fine because their slugs differ; the date prefix is for chronological sorting.

**Halt loud on a true duplicate.** Before writing, check whether `docs/agents/adrs/YYYY-MM-DD-<slug>.md` already exists. If it does, **refuse to write**: no overwrite, no suffix, no counter. Demand a more specific slug, then retry.

### Phase 3 — Choose the title slug

Title: present-tense, action-oriented, concrete. "Use Yjs for collaborative editing conflict resolution" — not "Collaborative editing" or "Considering options for sync."

Slug: lowercase, hyphenated, ≤8 words, descriptive enough to be unique on its day. Filename: `YYYY-MM-DD-<slug>.md` (e.g., `2026-05-29-use-yjs-for-collaborative-editing.md`).

### Phase 4 — Gather inputs

Pull from upstream skill outputs:

- **Research recommendation** — for Context and Alternatives sections
- **Spec** — for the actual chosen architecture
- **Grill record** — for accepted trade-offs and revisit triggers; when it carries a **User mental model** section, pull its door classifications (and recorded undo costs) into the Consequences section
- **Tier** — the `**Tier:**` field from the spec / grill record header (Quick / Balanced / Deep — see [`docs/agents/references/tier-scale.md`](../../docs/agents/references/tier-scale.md)).

If any upstream artifact is missing, halt and ask the user to provide it (or run the upstream skill first).

**The tier sets whether an ADR is written and how deep — never its correctness.**

- **Quick** — write an ADR *only* when the decision is a one-way door or high-blast-radius (the same bar as the "Documenting reversible decisions" anti-pattern below). If every decision in the spec is reversible and low-blast-radius, there is nothing to record — note "no one-way-door decision — ADR skipped" and hand off. A genuine one-way-door decision is *always* recorded, even at Quick, and even under a `--quick` override — that is `tier-scale.md` invariant 1.
- **Balanced** — write the ADR using the standard template.
- **Deep** — write the ADR in full, with ≥3 alternatives in the Alternatives section.

### Phase 5 — Write the ADR

Follow `references/adr-template.md` exactly. The template has TWO header blocks (the v1.22.0 Piece 5 telemetry convention):

**YAML frontmatter** (PascalCase keys; load-bearing for the release skill's editorial scan):

```yaml
---
Status: Proposed | Accepted | Deprecated | Superseded by ADR-NNNN
Date-Created: YYYY-MM-DD     # never changes after initial write
Last-Reviewed: YYYY-MM-DD    # deliberate-review timestamp; NOT auto-bumped on every commit
Superseded-By: null          # path to replacement ADR; null until superseded
Tier: Quick | Balanced | Deep
Deciders: [Names or roles]
---
```

**Markdown-emphasis block** (mirrors frontmatter for human readability):

```markdown
**Status:** ...
**Date:** YYYY-MM-DD
**Deciders:** ...
**Tier:** ...
```

Both blocks are required for new ADRs. Set `Date-Created` and `Last-Reviewed` to the same date on initial write. The release skill's Phase 10 editorial scan reads `Last-Reviewed:` on minor+major releases to detect dormancy — auto-bumping on every commit would defeat the signal.

Sections following the headers:

1. **Title** — present-tense action
2. **Context** — the problem, the constraints, the scale. From research Context section.
3. **Decision** — what we chose, in ACTIVE voice. "We will use Yjs..." not "It was decided that Yjs would be used..."
4. **Consequences** — positive, negative, accepted trade-offs. From research + grill.
5. **Alternatives considered** — alternatives with one-line rejections, from the research Patterns section. 2-4 at Balanced; ≥3 at Deep.
6. **Revisit triggers** — scale milestones, capability gaps, market changes. From research + grill.
7. **References** — links to research output, spec, grill record, external sources.

Echo the inherited tier into both the YAML `Tier:` field AND the markdown `**Tier:**` field.

**ADRs without YAML frontmatter** (the markdown-emphasis block alone) are valid — they predate the telemetry convention. Don't retrofit them when writing a new ADR; back-fill is its own task with its own ADR. The release skill's editorial scan tolerates the absence (skips files without YAML frontmatter).

### Phase 6 — Append the ADR index row

The dated filename exists now, so write the index entry now. Hand-append one row to the `adrs/README.md` index table for the new ADR — `| [<Title>](./YYYY-MM-DD-<slug>.md) | <Status> | <date> |` in the same column shape as the existing rows. No script runs; the index is maintained by this skill at write time, one row per ADR. Keep the row in the table proper (after the last existing row), not below the Conventions section.

If the README is missing entirely (greenfield repo), create the skeleton table with a one-line header, then add this ADR's row.

**Cross-reference convention.** Cite a dated ADR by **title + markdown link** — e.g. "see the [dated-naming decision](./YYYY-MM-DD-<slug>.md)" — never by a bare date-slug string in prose. Cite an integer-named ADR (`0001`–`0024`) as `ADR-00NN`.

### Phase 7 — Hand off

```
HANDOFF: implementation ready — ADR locked.
  Next: `write-plan` to sequence slices into phases with acceptance gates, OR (if the slice list is trivial and ordering is obvious) skip directly to `tdd-loop`.
  Decision rule: invoke `write-plan` when there are 3+ slices, when ordering isn't obvious, or before any `parallel-dev` dispatch.
HANDOFF: future research — this ADR is now Tier 0 prior art. Future `prior-art-research` invocations on adjacent problems should check it.
```

## Anti-patterns this skill guards against

- **Vague Context.** "We needed a way to handle concurrent edits." → No — what scale, what constraints, what alternatives existed?
- **Passive voice in Decision.** "It was determined that..." → Who decided? Use "We chose X because Y."
- **Hindsight rewrite.** Don't pretend you considered alternatives you didn't. The Alternatives section should reflect actual research.
- **Skipping Consequences.** Every choice has trade-offs. If you can't name what you gave up, you haven't thought hard enough.
- **Forgetting Revisit Triggers.** ADRs aren't gravestones. State the conditions that should re-open them.
- **Documenting reversible decisions.** Save ADRs for one-way doors and high-blast-radius decisions. Don't ADR every commit-message format choice.
- **Re-litigating in the ADR.** Don't recapitulate the entire research in the ADR. Link to research, summarize the outcome.

## Status field semantics

- **Proposed** — written but not yet acted on. Implementation hasn't started.
- **Accepted** — implementation has started or is complete. This is the current state of the system.
- **Deprecated** — no longer current but kept for historical context.
- **Superseded** — explicitly replaced by a newer ADR. Always link forward: by title+markdown-link when the replacement is a dated ADR, or as `ADR-00NN` when it is one of the frozen integer ADRs.

Move from Proposed → Accepted on the same commit that starts the implementation. Never delete an ADR — mark it Deprecated or Superseded.

## See also

- `prior-art-research` — upstream; provides Context and Alternatives
- `draft-spec` — upstream; provides the specific architecture
- `socratic-grill` — upstream; provides accepted trade-offs and revisit triggers
- `tdd-loop` — downstream; implements against the locked ADR
- `references/adr-template.md` — strict ADR format
- `docs/agents/references/tier-scale.md` — the tier that gates whether an ADR is written and how deep
