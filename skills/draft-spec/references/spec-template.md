# Implementation Spec: [Feature Name]

**Slug:** `feature-slug`
**Status:** Draft | Grilled | Locked | In-progress | Done
**Version:** vX.Y.Z (the release this spec ships in — lives here, NOT in the filename)
**Release:** vX.Y.Z (alias of Version; keep both or drop one — the point is the version is recoverable from frontmatter so spec→plan→release traceability survives dated naming)
**Tier:** Quick | Balanced | Deep (inherited from the research report)
**Spec'd from:** [Link to research output or ADR]
**Spec'd on:** [Date]

> Filename convention: `docs/agents/specs/YYYY-MM-DD-<feature-slug>.md` (dated at creation, slug is the uniqueness key). The version is carried above, not in the filename.

## TL;DR

[2-3 sentences: what we're building, the architectural shape, the number of slices and rough timeline.]

## Architecture

[2-4 sentences from the research recommendation. Components, data flow, network boundaries.]

```
[ASCII or simple text diagram of the architecture, if helpful]
```

## Concrete picks (from research)

| Decision | Choice | Reason |
|---|---|---|
| [Sub-problem 1] | [Pick] | [1 line] |
| ... | ... | ... |

## Trade-offs accepted

- [Trade-off 1 from research]
- [Trade-off 2 from research]

## Open questions (feed `socratic-grill`)

If non-empty, run `socratic-grill` before implementation:

- [ ] [Open question 1]
- [ ] [Open question 2]

---

## Vertical slices

Numbered in dependency order. Each slice cuts end-to-end. HITL = human-in-the-loop required; AFK = autonomous-friendly.

### Slice 1 — [Name] ([HITL | AFK])

**Description:** [1-2 sentences describing the end-to-end behavior]

**Acceptance criteria:**
- [ ] [Measurable criterion 1]
- [ ] [Measurable criterion 2]

**Test strategy:** [Unit | Integration | E2E | Manual smoke] — at `path/to/test_file.ext`

**Blocked by:** None | #N

**Notes:** [Optional — anything that didn't fit above]

### Slice 2 — [Name] ([HITL | AFK])

[Same format]

**Blocked by:** #1

### Slice 3 — [Name] ([HITL | AFK])

[Same format. Continue for all slices.]

---

## Dependency DAG (if 5+ slices)

```
1 → 2 → 4
    ↓
    3 → 5
```

## Parallelization

AFK slices with no shared dependencies can run via `parallel-dev`:

- Group A (parallel): #2, #3
- Group B (parallel): #5, #6
- Sequential: #1, #4

## Revisit triggers

Scale or capability conditions that mean the spec needs to be re-evaluated:

- [Trigger 1]
- [Trigger 2]

---

HANDOFF: grill ready — invoke `socratic-grill` to resolve open questions and challenge ambiguous decisions.
HANDOFF: record ready — invoke `decision-record` after grill to capture as an ADR.
HANDOFF: implementation ready — invoke `tdd-loop` per slice in dependency order.
