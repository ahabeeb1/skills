# Slice Labels — When to label which

Every slice gets exactly one of three labels. The label tells the dispatcher (`tdd-loop`, `parallel-dev`) whether and how a human gates the slice.

```
HITL:inline           — human reviews/decides in the chat session, mid-slice
HITL:approval-gate    — human approves OUT-OF-BAND (Slack / email / external workflow)
AFK:full-auto         — no human in the loop; safe for parallel-dev autonomous dispatch
```

Default to `AFK:full-auto`. Use `HITL:*` only when human input is genuinely required mid-slice. Distinguish `inline` from `approval-gate` by *where* the human is when they gate — sitting in the chat session, or somewhere else entirely.

---

## HITL:inline — Human in the chat, mid-slice

The agent will pause mid-slice and surface a question to whoever is in the active session. The human answers in the chat; the agent resumes.

**Examples:**

- **Architectural choice the spec deferred.** "Slice 6 implements auth. The spec listed JWT-in-cookie vs JWT-in-WS-protocol vs query-param. Need to decide before implementation."
- **Domain naming.** "Implementing the customer-management module. Need to confirm: is it `Customer` or `Account` in our domain?"
- **Cost / scale trade-off surfaced mid-implementation.** "Cheap option = $X/month, 5min crash window; safe option = $5X/month, zero loss. Which?"

**When to use:** the human is *already in the session* — there's no need for a notification, ticket, or approval workflow. The pause is conversational.

**Format:**

```
### Slice 6 — Auth (HITL:inline — decide JWT placement mid-slice)
```

The parenthetical tells the dispatcher WHY this is HITL. "HITL:inline" alone isn't enough.

---

## HITL:approval-gate — Human approves out-of-band

The slice cannot proceed without an explicit approval from a person who is **not in the chat session**. The agent blocks on a notification (Slack / email / queue) until approval arrives, then resumes.

**Examples:**

- **Production data migration approval.** "Slice will run an irreversible migration on production data. Needs explicit go-ahead from on-call DBA."
- **Spend / billing decision.** "Slice provisions a $400/month resource. Needs eng-manager approval."
- **External coordination.** "Slice requires SRE to provision a new RDS instance. Block until SRE confirms."
- **Compliance / legal sign-off.** "Slice changes how PII is logged. Needs legal review."
- **Production canary promotion.** "Slice flips 100% rollout. Needs PM approval after canary metrics review."

**When to use:** the approver is offline, busy, or in a different org. The gate is asynchronous. The agent must be able to wait without burning context.

**Canonical reference implementation:** [humanlayer](https://github.com/humanlayer/humanlayer) — `@hl.require_approval()` decorators that route to Slack/email and resume cleanly when approval arrives. Cite humanlayer in the ADR when an approval-gate slice's mechanism needs to be locked.

**Format:**

```
### Slice 9 — Migrate user_pii table (HITL:approval-gate — DBA approval before run, Slack #data-eng)
```

The parenthetical names the approver AND the channel. Without those, the dispatcher doesn't know how to wait.

---

## AFK:full-auto — No human in the loop

The agent can complete this slice end-to-end without human input. All decisions are pre-made; test strategy is clear; acceptance criteria are mechanical.

**Examples:**

- "Wire up the y-prosemirror binding between Tiptap and the Y.Doc, following library docs."
- "Add schema migration for `yjs_snapshots` with the columns specified."
- "Emit CloudWatch metric `yjs.sync_lag_p99_ms` from Hocuspocus on each update."
- "Write integration tests for the auth hook covering 3 cases the spec lists."

**Format:**

```
### Slice 2 — Hocuspocus server stands up (AFK:full-auto)
```

No parenthetical needed — AFK is the default state.

---

## Borderline cases — bias toward AFK:full-auto

If you're not sure, default to AFK. Mark HITL only when something concrete demands human attention.

Reasons NOT to mark HITL even if you feel uncertain:

- "It might surface a question." Let it surface. The agent will pause and ask. Don't pre-label HITL for *potential* questions.
- "The code style is sensitive." Configure linters / formatters; don't gate every slice.
- "I want to review the implementation." Review at commit time, not mid-slice.
- "It's complex." Complexity isn't HITL. HITL is about specific human inputs needed mid-flow.
- "End-of-slice review." Reviewing the implementation AFTER it's written is **not** HITL. That's the two-stage review in `tdd-loop` Phase 5 (spec-compliance + code-quality). HITL labels gate slices *mid-flow*, before/during implementation, not after.

## Choosing between `inline` and `approval-gate`

| Signal | Likely label |
|---|---|
| Decision-maker is currently in the chat | `HITL:inline` |
| Decision-maker is on a different team / org / org-chart level | `HITL:approval-gate` |
| Decision can be answered in one sentence by anyone in the room | `HITL:inline` |
| Decision requires a paper trail (compliance / audit / billing) | `HITL:approval-gate` |
| Decision must wait for after-hours / off-cycle review | `HITL:approval-gate` |
| Decision needs an approver named by org chart, not by who's typing | `HITL:approval-gate` |

When signals conflict, apply this **tiebreaker hierarchy** (top wins):

1. **Paper trail / audit requirement** → `HITL:approval-gate`. Compliance, billing, irreversible operations always need the record.
2. **Org-chart approval** (decision-maker is named by role, not by who's typing) → `HITL:approval-gate`. Even if they happen to be in the chat.
3. **Off-cycle / async timing** (decision must wait for review windows, off-hours) → `HITL:approval-gate`.
4. **Chat-session presence** (decision-maker is here right now, conversational answer is fine) → `HITL:inline`.

Example: chat-present DBA who would normally answer inline — but the slice runs an irreversible data migration. Tiebreaker (1) wins → `HITL:approval-gate`. The paper trail need is the higher rule.

## Why this distinction matters

`parallel-dev` will dispatch only `AFK:full-auto` slices concurrently. `HITL:inline` slices serialize on chat-session attention. `HITL:approval-gate` slices serialize on out-of-band approval and are typically the longest poles.

The more accurate your labels, the faster the team / agent ships:

- Mislabeling AFK as HITL → wasted human cycles, blocked autonomous batches.
- Mislabeling HITL:inline as AFK → agent silently makes a decision it shouldn't, surfaces later as a bad commit.
- Mislabeling HITL:approval-gate as HITL:inline → agent pauses for a chat-present human, then realizes the actual approver isn't there, blocks anyway, but now in a degraded state.

## Mid-slice discovery — when an AFK slice turns out to need approval

If an `AFK:full-auto` slice discovers a mid-slice approval need at runtime (a hidden Stripe config gate, an unscoped permission, a vendor enablement step):

1. **Halt the slice.** Don't try to work around or proceed.
2. **Re-label** the slice to `HITL:approval-gate` (or `HITL:inline` if the decider happens to be in the chat).
3. **Update the gate detail** with the discovered approver + channel.
4. **Capture the discovery** in the spec's change log: date, slice number, what surfaced, who's now blocking.
5. **Resume only after approval.**

This is not a failure of labeling — it's the runtime catching what static labeling couldn't predict. The labels are a model of the slice's gating requirements; the runtime gets the final word.

## What each label means at runtime

### HITL:inline

1. Agent reads the slice spec
2. Agent reaches the human-input step
3. Agent pauses, surfaces the question in the chat
4. Human in the chat answers (often via `socratic-grill`)
5. Agent resumes and completes the slice

### HITL:approval-gate

1. Agent reads the slice spec
2. Agent reaches the approval step
3. Agent emits a request via the configured channel (Slack message / email / humanlayer `require_approval` call)
4. Agent suspends — pause state captured per F6 of agent-factors-check (where applicable)
5. Approver acts out-of-band; the response flows back through the same channel
6. Agent resumes and completes the slice

### AFK:full-auto

1. Agent reads the slice spec
2. Agent writes the failing test (RED)
3. Agent writes the minimal code (GREEN)
4. Agent invokes `deep-modules` at REFACTOR step
5. Agent commits
6. Agent advances to the next slice

No pause needed. The slice ships.

## Migration note (existing slices)

Old labels (`HITL`, `AFK` without suffix) should be re-labeled on next touch:

- Bare `AFK` → `AFK:full-auto`
- Bare `HITL` → audit the parenthetical reason. Out-of-band approver named → `HITL:approval-gate`. Otherwise → `HITL:inline`.

Don't bulk-rename old slices in completed work — preserve historical context. Only rewrite labels for slices still in-flight or being re-planned.
