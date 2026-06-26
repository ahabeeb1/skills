---
name: vertical-slice
description: Decompose a signed-off Design into vertical slices (HITL or AFK) for tdd-loop — the machine-layer step. Use when socratic-grill signs off a Design, the user types "/slice", or says "break this down". Do not use before sign-off or to re-slice already-sliced work.
disable-model-invocation: true
---

# Vertical Slice — turn the signed-off Design into work items

**EVERY SLICE SHIPS END-TO-END VALUE. NO HORIZONTAL SLICES.**

This is the first Machine-layer step. The Design is signed off; the user understands what's being
built. Now decompose it into slices a subagent can implement with `tdd-loop`. A vertical slice is
a tracer bullet — it goes all the way through the system, even if narrow. A horizontal slice is a
brick wall — each layer is complete, but nothing works until all layers exist. Slices are
machine-facing: optimize them for correct subagent output, not for the user to read.

Write in the house voice — see [`docs/agents/references/skill-voice.md`](../../docs/agents/references/skill-voice.md).

## When to use this skill

**Trigger on:**

- `socratic-grill` signed off a Design and emitted `HANDOFF: implementation ready`
- The user types `/slice`, or says "break this down" / "create tickets" / "what are the steps"
- A signed-off Design needs to become implementation work items

**Do NOT trigger on:**

- A Design that isn't signed off yet (run `socratic-grill` to sign-off first)
- Work that's already sliced (refine, don't re-decompose)
- Trivial tasks that fit in one slice
- A single bug fix (one work item, no slicing)

## Core principles

### Vertical, not horizontal

A vertical slice cuts through all the integration layers needed to demonstrate value — the
narrowest scenario that touches the same layers a full feature touches.

- **Vertical (good):** "User can log in with email + password" — DB schema, auth service, API
  route, frontend form, session storage, one login path. "User can create a doc that persists
  across reload" — DB, API, frontend, one doc shape.
- **Horizontal (bad):** "Build the database layer." "Build the auth service." "Add types." Each
  is done in isolation and demonstrates nothing until the others exist.

### Tracer bullet, not feature-complete

Slice 1 is the narrowest version that proves the path — not the polished version with error
handling, retries, observability, edge cases. Those are later slices. You learn most by getting
one path through the full stack working.

### Slice labels (3 values)

- **`AFK:full-auto`** — no human in the loop. Agent implements, tests, commits autonomously.
  Dispatchable to `parallel-dev`. Default to this.
- **`HITL:inline`** — a human in the active chat answers a question mid-slice (domain naming, a
  deferred architectural choice). Cheap, conversational pause.
- **`HITL:approval-gate`** — a human approves out-of-band before the slice proceeds (Slack / email
  / queue). Use when the approver is offline, a paper trail is required, or the approver is named
  by org chart.

The full decision tree lives in `references/hitl-vs-afk.md`.

## Core workflow

### Phase 1 — Read the signed-off Design

Locate the signed-off Design (`docs/agents/specs/YYYY-MM-DD-<slug>-design.md`, `Status: Signed-off`).
Extract the end-to-end behavior, the Key decisions, and the Decided section. If the Design isn't
signed off, halt and route to `socratic-grill`. If no Design exists, route to `draft-spec`.

### Phase 2 — Identify the narrowest end-to-end path

The smallest scenario that exercises all the layers the feature touches is Slice 1. Test: if you
implemented only this slice, would a user see SOMETHING work? If no, it's still horizontal — narrow
it differently. ("Real-time collaborative editor" → Slice 1 is "single user opens the editor,
types, saves, refreshes, content persists" — not "set up Tiptap," not "deploy a server.")

### Phase 3 — Slice the rest

Each subsequent slice builds on prior slices and adds ONE meaningful capability, requiring the
least new infrastructure. Aim for: 4–10 slices total; 1–2 days (or 1–3 agent turns) each;
independently shippable; independently verifiable. If a slice won't fit in 1–2 days, decompose
further. More than 10 slices means too granular or it should be multiple features.

### Phase 4 — Label each slice

Ask first: does a human need to intervene mid-slice? If no → `AFK:full-auto`. If yes, distinguish
by where the human is:

| Signal | Label |
|---|---|
| Decision-maker is in the active chat, can answer conversationally | `HITL:inline` |
| Decision-maker is offline / different org / approver / needs paper trail | `HITL:approval-gate` |

When both apply, pick `approval-gate` — the audit-trail need is the stronger signal. Default to
`AFK:full-auto`; mark `HITL:*` only when something genuinely needs a human.

### Phase 5 — Order by dependency

Number slices in implementation order; a slice that depends on another comes after it. Express
with `Blocked by: #N`. Any set of AFK slices with no inter-dependencies can run via `parallel-dev`.

### Phase 6 — Write the slice list

Write the slice list to `docs/agents/specs/YYYY-MM-DD-<slug>-slices.md` (the Machine-layer
sub-artifact, sharing the Design's slug). One entry per slice:

```
### Slice N — <name> (<AFK:full-auto | HITL:inline | HITL:approval-gate>)

**Description:** <end-to-end behavior in 1-2 sentences>

**Acceptance criteria:**
- [ ] <measurable 1>
- [ ] <measurable 2>

**Test strategy:** <Unit|Integration|E2E|Manual> — at <path/to/test_file>

**Blocked by:** None | #N

**Gate detail:** (required for HITL:* slices — name the question, or the approver AND channel)
```

**Fixture identifiers are confirm-at-implementation, never literals.** Where a slice references a
test-fixture identifier (dogfood scenario number, file index), write a placeholder
(`tests/dogfood/<next-free-N>-<slug>/`). These identifiers are confirm-at-implementation: the
implementer must confirm against the live tree before creating the fixture.

### Phase 7 — Publish to the issue tracker (optional)

If `setup-habeebs-skill` configured a tracker, publish each slice as an issue in topological order,
using the configured triage labels (`AFK:full-auto` → `afk-ready`; `HITL:inline` →
`needs-human-inline`; `HITL:approval-gate` → `needs-approval` plus the approving-team label).

### Phase 8 — Hand off

```
HANDOFF: implementation ready — slices ready for tdd-loop in dependency order. Parallelizable groups: [list]. HITL slices need human attention at: [list].
HANDOFF: plan ready — if the work is genuinely multi-phase, invoke write-plan to sequence these slices behind phase gates first. Skip for single-phase work.
```

## Anti-patterns this skill guards against

| Thought | Reality |
|---|---|
| "I'll slice by layer — DB, then API, then UI." | That's horizontal. Each slice must be vertical and demonstrate value alone. |
| "This slice covers the entire payment flow." | Too big. Decompose until each fits 1–2 days. |
| "Add one field to one model" is a slice. | Too small. Combine adjacent micro-slices into a meaningful unit. |
| "Slice 5 secretly needs slice 7." | Make the dependency explicit with `Blocked by:`, or restructure. |
| "Mark it HITL to be safe." | Every HITL slice blocks autonomy. Be ruthless — most slices are AFK. |
| "I'll slice before the Design is signed off." | Slicing an unapproved Design wastes work when sign-off changes it. Wait for sign-off. |

## Slice quality checklist

For each slice: vertical; demonstrates end-to-end value; fits 1–2 days / 1–3 agent turns; has ≥2
measurable acceptance criteria; has a test strategy; has a `Blocked by:` field; is labeled with one
of the three values; for `HITL:*`, names a SPECIFIC role and channel (reject "the team",
"whoever's around"); doesn't secretly depend on a later slice. If any item fails, refine first.

## See also

- `socratic-grill` — upstream; signs off the Design this skill decomposes
- `draft-spec` — writes the Design (run if none exists)
- `tdd-loop` — implements each AFK slice
- `parallel-dev` — dispatches parallelizable AFK slice groups
- `write-plan` — sequences slices behind phase gates when work is multi-phase
- `setup-habeebs-skill` — configures the issue tracker and triage labels
- `references/hitl-vs-afk.md` — when to label which
- `docs/agents/references/skill-voice.md` — the house voice
