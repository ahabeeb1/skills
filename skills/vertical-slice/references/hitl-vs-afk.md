# HITL vs AFK — When to label which

Every slice gets one of two labels. Default to AFK. Use HITL only when human input is genuinely required mid-slice.

## HITL — Human-In-The-Loop

The agent CANNOT complete this slice without a human input, decision, or approval. The slice contains a step that requires human judgment.

**Examples:**

- **Architectural choice the spec deferred.** "Slice 6 implements auth. The spec listed JWT-in-cookie vs JWT-in-WS-protocol vs query-param. Need to decide before implementation."
- **Domain naming.** "Implementing the customer-management module. Need to confirm: is it `Customer` or `Account` in our domain? The terms appear inconsistent in the codebase."
- **Cost / scale trade-off.** "Implementing the snapshot strategy. The cheap option costs $X/month but loses 5min of edits on crash; the safe option costs $5X/month but loses nothing. Which?"
- **Design review checkpoint.** "Slice introduces a new public API. Team wants to review before it's merged."
- **External coordination.** "Slice requires SRE to provision a new RDS instance. Block until provisioned."
- **Data migration approval.** "Slice will run an irreversible migration on production data. Need explicit go-ahead."

**Format your HITL label:**

```
### Slice 6 — Auth (HITL — decide JWT placement mid-slice)
```

The parenthetical tells the dispatcher WHY this is HITL. "HITL" alone isn't enough.

## AFK — Away From Keyboard

The agent can complete this slice autonomously. All decisions are pre-made; the test strategy is clear; the acceptance criteria are mechanical.

**Examples:**

- "Wire up the y-prosemirror binding between Tiptap and the Y.Doc, following library docs."
- "Add the schema migration for `yjs_snapshots` table with the columns specified."
- "Add CloudWatch metric `yjs.sync_lag_p99_ms` emitted by Hocuspocus on each update."
- "Write integration tests for the auth hook covering 3 cases the spec lists."

These don't require human attention. The agent reads the spec, writes the test, writes the code, runs the test, commits.

**Format your AFK label:**

```
### Slice 2 — Hocuspocus server stands up (AFK)
```

No parenthetical needed — AFK is the default state.

## Borderline cases — bias toward AFK

If you're not sure, default to AFK. Mark HITL only when something concrete demands human attention.

Reasons NOT to mark HITL even if you feel uncertain:

- "It might surface a question." Maybe. Let it surface. If it does, the agent pauses and asks — that's fine. Don't pre-label HITL for potential questions.
- "The code style is sensitive." Configure linters / formatters; don't gate every slice.
- "I want to review the implementation." Review at commit time, not mid-slice.
- "It's complex." Complexity isn't HITL. HITL is about specific human inputs needed mid-flow.

## Why this distinction matters

`parallel-dev` can dispatch AFK slices concurrently. HITL slices serialize on human attention. The more accurate your labels, the faster the team / agent ships.

If everything is HITL, you've gained nothing from autonomy. If too much is AFK and you're labeling around what should be HITL, you'll surface decisions during implementation and waste cycles unwinding bad choices.

Good slice triage = right labels.

## What HITL means at runtime

When a HITL slice enters `tdd-loop`:

1. Agent reads the slice spec
2. Agent reaches the human-input step
3. Agent pauses and surfaces the question
4. Human answers (often via `socratic-grill`)
5. Agent resumes and completes the slice

The pause is the point. Mark HITL when you want that pause.

## What AFK means at runtime

When an AFK slice enters `tdd-loop`:

1. Agent reads the slice spec
2. Agent writes the failing test (RED)
3. Agent writes the minimal code (GREEN)
4. Agent invokes `deep-modules` at REFACTOR step
5. Agent commits
6. Agent advances to the next slice

No pause needed. The slice ships.
