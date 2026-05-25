---
name: vertical-slice
description: Decomposes a spec or plan into vertical slices (tracer bullets) — each cutting through ALL integration layers end-to-end, never a horizontal slice of one layer. Tags each slice HITL (human-in-the-loop required) or AFK (autonomous-friendly). Optionally publishes slices to the configured issue tracker. Make sure to use this skill whenever a plan, spec, PRD, or feature description needs to be broken into work items — especially when the user says "break this down", "create tickets", or "what are the steps". Do NOT use to re-slice already-sliced work or for trivial single-slice tasks.
disable-model-invocation: true
---

# Vertical Slice

Break a plan into slices that each demonstrate end-to-end value. Horizontal slicing (layer by layer) is the most common decomposition mistake — it produces work items that look done individually but never actually ship.

A vertical slice is a tracer bullet: it goes all the way from one end of the system to the other, even if narrow. A horizontal slice is a brick wall: each layer is complete, but until ALL the layers exist, nothing works.

## When to use this skill

**Trigger on:**

- `draft-spec` is decomposing its work (this skill is the decomposition primitive)
- The user pastes a plan, PRD, or feature description and says "break this down" / "create tickets" / "what are the steps"
- A research recommendation needs to become work items
- After `socratic-grill` resolves ambiguity and the work is ready to ticket
- The user invokes `/slice` explicitly

**Do NOT trigger on:**

- Work that's already sliced (don't re-decompose; just refine)
- Trivial tasks that fit in one slice (don't manufacture decomposition)
- Exploration or prototyping work where the design IS the deliverable
- A single bug fix (one ticket, no slicing needed)

## Core principles

### Vertical, not horizontal

A vertical slice cuts through all the integration layers required to demonstrate value. The narrowest possible scenario that touches the same layers a full feature touches.

**Vertical (good):**
- "User can log in with email + password" — touches DB schema, auth service, API route, frontend form, session storage. ONE login path.
- "User can create a doc that persists across page reload" — touches DB, API, frontend, edit handler. ONE doc shape.

**Horizontal (bad):**
- "Build the database layer" — done in isolation. Until the API and frontend exist, nothing demonstrates.
- "Build the authentication service" — same problem. Earns no user-visible value alone.
- "Add types" — across what? With what behavior?

### Tracer bullet, not feature-complete

The first slice should be the narrowest version that proves the path. Not the polished version. Not the version with error handling, retries, observability, edge cases. Those are subsequent slices.

Why: you learn the most by getting one path through the full stack working. The edge cases / polish are easier to slice after the path exists.

### Slice labels (3 values)

Each slice is labeled with exactly one of:

- **`AFK:full-auto`** — no human in the loop. Agent implements, tests, commits autonomously. Dispatchable to `parallel-dev`.
- **`HITL:inline`** — human in the *active chat session* answers a question mid-slice (e.g., domain naming, deferred architectural choice). Cheap, conversational pause.
- **`HITL:approval-gate`** — human approves *out-of-band* before the slice may proceed (Slack/email/queue). Use when the approver is offline, when a paper trail is required (compliance, billing), or when the approver is named by org chart.

Default to `AFK:full-auto` unless something specific requires human attention. The full decision tree (when to pick which, borderline cases, runtime semantics) lives in `references/hitl-vs-afk.md`.

## Core workflow

### Phase 1 — Read the spec

Locate the spec / plan / recommendation. Extract:

- The end-to-end behavior the feature delivers
- Constraints (existing systems, tech stack, scale)
- Already-decided architecture
- Open questions (do these block slicing or can slices proceed in parallel with grilling?)

If no spec exists, halt and route to `draft-spec` (or `prior-art-research` if no recommendation yet).

### Phase 2 — Identify the narrowest end-to-end path

What's the smallest scenario that exercises all the layers the feature touches? This is Slice 1.

Test: if you implemented only this slice, would a user see SOMETHING work? If no, the slice is still horizontal — narrow it differently.

Example: "Real-time collaborative editor" — Slice 1 is "single user can open the editor, type, save, refresh, see content persists." Not "set up Tiptap." Not "deploy a server." A narrowest-vertical that demonstrates the feature exists.

### Phase 3 — Slice the rest

For each remaining capability the spec demands, identify the slice that adds it. Build dependency-aware:

- Slice 2 adds what Slice 1 lacks AND requires least new infrastructure
- Each subsequent slice builds on prior slices, adding ONE meaningful capability

Aim for:
- 4-10 slices total for a normal feature
- 1-2 days of work per slice (or 1-3 agent turns)
- Each slice independently shippable (could merge to main without breaking anything)
- Each slice independently verifiable

If you can't get a slice under 1-2 days, decompose it further. If you have more than 10 slices, you're either too granular or the feature should be multiple features.

### Phase 4 — Label each slice (one of three values)

For each slice, ask first: **does a human need to intervene mid-slice?**

**If no →** `AFK:full-auto`. Mechanical work: write code, run tests, ship. All decisions pre-made; test strategy clear; acceptance criteria mechanical.

**If yes →** distinguish by *where* the human is:

| Signal | Label |
|---|---|
| Decision-maker is in the active chat session, can answer conversationally | `HITL:inline` |
| Decision-maker is offline / different org / org-chart approver / requires paper trail | `HITL:approval-gate` |

**`HITL:inline` signals:**
- Architectural decision the spec didn't pre-resolve (slice will surface it)
- Naming a domain concept that wasn't yet named
- Choosing between two paths the spec lists as alternatives

**`HITL:approval-gate` signals:**
- Production data migration / irreversible operation
- Spend / billing decision
- Compliance / legal / security sign-off
- External team coordination (SRE provision, vendor enablement)
- Production canary promotion

When both `inline` and `approval-gate` apply, pick `approval-gate` — the audit-trail need is the stronger signal.

Default to `AFK:full-auto`. Mark `HITL:*` only when something genuinely needs human input. The full decision tree, borderline cases, and runtime semantics live in `references/hitl-vs-afk.md`.

### Phase 5 — Order by dependency

Number slices in implementation order. A slice that depends on another must come after it. Express with `Blocked by: #N`.

Identify parallelizable groups: any set of AFK slices with no dependencies on each other can run via `parallel-dev`.

### Phase 6 — Write each slice to the spec format

For each slice, produce the entry per `draft-spec`'s spec template:

```
### Slice N — <name> (<AFK:full-auto | HITL:inline | HITL:approval-gate>)

**Description:** <end-to-end behavior in 1-2 sentences>

**Acceptance criteria:**
- [ ] <measurable 1>
- [ ] <measurable 2>

**Test strategy:** <Unit|Integration|E2E|Manual> — at <path/to/test_file>

**Blocked by:** None | #N

**Gate detail:** (required for HITL:* slices)
- For HITL:inline — name the question the human will answer
- For HITL:approval-gate — name the approver AND the channel (e.g., "On-call DBA via Slack #data-eng")

**Notes:** <optional>
```

### Phase 7 — Publish to the issue tracker (optional)

If `setup-habeebs-skill` has configured an issue tracker, publish each slice as an issue:

- GitHub: `gh issue create --title "..." --body "..." --label "..."`
- Linear: via Linear MCP or API
- Local: `.scratch/slices/<N>-<slug>.md`

Use the configured triage labels (see `setup-habeebs-skill`):
- `AFK:full-auto` slices → `afk-ready`
- `HITL:inline` slices → `needs-human-inline`
- `HITL:approval-gate` slices → `needs-approval` plus a label naming the approving team (e.g., `needs-approval/dba`)

For dependency ordering, publish in topological order so blocker references can use real issue IDs.

### Phase 8 — Hand off

```
HANDOFF: implementation ready — slices ready for tdd-loop in dependency order. Parallelizable groups: [list]. HITL slices need human attention at: [list].
```

## Anti-patterns this skill guards against

- **Horizontal slicing.** "Database layer" / "API layer" / "UI layer." Never. Each slice is vertical.
- **Slices that are too big.** "Implement the entire payment flow." Decompose.
- **Slices that are too small.** "Add one field to one model." Combine adjacent micro-slices into a meaningful unit.
- **Slices with hidden dependencies.** "Slice 5 secretly needs slice 7." Make dependencies explicit or restructure.
- **Reusing the same slice template for everything.** Slice shapes vary — research slices vs implementation slices vs migration slices.
- **Publishing to issues without configuration.** Run `setup-habeebs-skill` first; don't dump issues into a tracker the team hasn't agreed on.
- **Over-labeling HITL.** Every slice marked HITL = the agent can never run autonomously. Be ruthless about which actually need humans.

## Slice quality checklist

For each slice, verify:

- [ ] Vertical — cuts through all integration layers the feature touches
- [ ] Demonstrates end-to-end value (something works after this slice)
- [ ] Fits in 1-2 days / 1-3 agent turns
- [ ] Has measurable acceptance criteria (at least 2 checkboxes)
- [ ] Has a test strategy (Unit / Integration / E2E / Manual)
- [ ] Has a `Blocked by:` field (even if "None")
- [ ] Is labeled `AFK:full-auto`, `HITL:inline`, or `HITL:approval-gate`
- [ ] For `HITL:*` slices: gate detail names a SPECIFIC role (e.g., "on-call DBA", "eng-manager + PM quorum") and a SPECIFIC channel (Slack channel, email alias, queue name). Reject vague approvers: "the team", "anyone", "whoever's around", "engineering" without a named role.
- [ ] Doesn't secretly depend on a later slice

If any item fails, refine the slice before publishing.

## Integration with the chain

- **Invoked by `draft-spec`** in Phase 3 (decomposition)
- **Optionally publishes to** the issue tracker configured by `setup-habeebs-skill`
- **`AFK:full-auto` slices flow into** `tdd-loop` (potentially via `parallel-dev`)
- **`HITL:inline` slices flow into** `socratic-grill` to resolve the human-input question, then to `tdd-loop`
- **`HITL:approval-gate` slices flow into** an approval channel (Slack/email/queue); the slice is blocked in `tdd-loop` until approval returns

## See also

- `draft-spec` — primary consumer of this skill
- `tdd-loop` — implements each AFK slice
- `parallel-dev` — dispatches parallelizable AFK slice groups
- `socratic-grill` — resolves the human input on HITL slices
- `setup-habeebs-skill` — configures the issue tracker and triage labels this skill uses
- `references/slice-checklist.md` — quality bar for each slice
- `references/hitl-vs-afk.md` — when to label which
