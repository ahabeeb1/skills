# Dogfood Test 08 — HITL label vocabulary extension

**Date:** 2026-05-11
**Skill under test:** `skills/vertical-slice/references/hitl-vs-afk.md` (extended vocabulary) + Phase 4 of `skills/vertical-slice/SKILL.md` + downstream consumers (`parallel-dev`, `tdd-loop`).
**Tester:** Claude Opus 4.7 (this session)
**Intent:** Pressure-test the three-label system (`AFK:full-auto` / `HITL:inline` / `HITL:approval-gate`) on realistic slice mixes, including borderline cases.

---

## Scenario

A real-shaped feature batch: "Add usage-based billing for the API tier." This batch touches a Stripe integration, a database schema change, a new domain entity, a production-data migration, and a customer-facing dashboard update. Each slice is a different shape — ideal for stress-testing label assignment.

## Inputs

Eight slices, freshly decomposed by `vertical-slice`. Tester applies Phase 4 labeling to each.

1. Add `usage_events` Postgres table with columns `(id, tenant_id, ts, units, sku)`.
2. Implement `recordUsage(tenant, sku, units)` helper.
3. Aggregate hourly usage rollup job (cron-driven).
4. Decide on the domain name for the entity (`UsageEvent`? `MeteredEvent`? `BillableEvent`?).
5. Wire usage rollups to Stripe subscription items.
6. Backfill `usage_events` from the legacy `request_log` table for in-production tenants.
7. Show usage on the customer dashboard.
8. Flip "enable usage billing" feature flag to 100%.

---

## Actual run output (Phase 4 of `vertical-slice` per the new rules)

### Slice 1 — Add `usage_events` table → `AFK:full-auto`

Mechanical migration; schema spec'd; no ambiguity. No human input needed.

### Slice 2 — `recordUsage` helper → `AFK:full-auto`

Pure helper, tests can be written from spec. Default state.

### Slice 3 — Hourly rollup job → `AFK:full-auto`

Cron job code is mechanical; spec defines aggregation. AFK.

### Slice 4 — Name the entity → `HITL:inline`

**Reason:** Spec lists three candidate names but doesn't pick. The decision is conversational ("which feels right in our domain language?"), the decider is in the active chat session, and the decision is reversible by find-and-replace later.

**Gate detail:** "Pick one of {UsageEvent, MeteredEvent, BillableEvent}. Asked of the user in the active session."

### Slice 5 — Wire to Stripe → `AFK:full-auto`

Stripe SDK call shape is in the docs; spec has the wiring. **But hold on** — applying the labels honestly: this slice depends on a `STRIPE_SECRET_KEY` env var that has to be set in production by someone with secrets access. Is that an out-of-band approval? **No** — it's a config prerequisite, not an in-slice approval. The slice itself is mechanical. Label: `AFK:full-auto`, with a note in the slice's `Notes` field: "Requires `STRIPE_SECRET_KEY` set in production before slice ships."

(This nuance — "prerequisite is not the same as approval-gate" — is a case the extended vocabulary handles cleanly.)

### Slice 6 — Backfill from legacy table → `HITL:approval-gate`

**Reason:** Production data migration. Writes new rows to `usage_events` based on historical `request_log` entries. If the backfill is wrong, customers get billed incorrectly. Needs DBA / on-call approval before running on prod.

**Gate detail:** "On-call DBA approval via Slack #data-eng before running backfill. Dry-run output (`SELECT COUNT(*) ... GROUP BY tenant_id`) must be reviewed and approved."

Canonical impl pattern: humanlayer-style approval gate. ADR for this batch should cite humanlayer in References as the reference impl for this pattern.

### Slice 7 — Dashboard update → `AFK:full-auto`

UI work; design is spec'd. Mechanical.

### Slice 8 — Flip flag to 100% → `HITL:approval-gate`

**Reason:** Production canary promotion. Spec says: "Hold at 10% for 72h, then promote to 100% with eng-manager + PM approval." Approver is out-of-band; paper trail required.

**Gate detail:** "Eng-manager + PM approval via Slack #eng-leads after canary metrics review. Approval requires both signatures, captured in the slice's commit message trailer."

### Label tally

- `AFK:full-auto`: 5 (slices 1, 2, 3, 5, 7)
- `HITL:inline`: 1 (slice 4)
- `HITL:approval-gate`: 2 (slices 6, 8)

**Parallelization implication (for `parallel-dev`):** the 5 AFK slices are eligible IF independent. Check: slices 1, 2, 3 are sequential (each depends on prior). Slice 5 depends on slice 3 output. Slice 7 depends on slice 3. So pgroup at best is {slice 5, slice 7} after slice 3 lands.

---

## Rubric (criterion-by-criterion)

| # | Criterion | Pass/Fail | Evidence |
|---|---|---|---|
| 1 | Every slice gets exactly one of three labels | ✅ | 8/8 labeled |
| 2 | Default-to-AFK applied where appropriate | ✅ | 5/8 AFK:full-auto |
| 3 | `HITL:inline` chosen only when decider is in active session | ✅ | Slice 4 only — domain naming, chat-present user |
| 4 | `HITL:approval-gate` chosen when approver is out-of-band OR paper trail required | ✅ | Slices 6 (DBA), 8 (eng-manager+PM) |
| 5 | Each `HITL:*` slice names the gate-detail (question or approver+channel) | ✅ | Slice 4 names the question; slices 6/8 name approver + channel |
| 6 | Prerequisite-not-approval-gate distinction held | ✅ | Slice 5 STRIPE_SECRET_KEY noted as prereq, not as gate |
| 7 | `parallel-dev` would correctly accept only AFK:full-auto slices | ✅ | 5 eligible slices identified; HITL:* slices excluded |
| 8 | humanlayer cited for `HITL:approval-gate` reference impl | ✅ | Pattern referenced for slice 6 |
| 9 | Migration note honored (no bare HITL/AFK labels emitted) | ✅ | All labels use suffix form |

**Aggregate: 9/9 on happy path.**

---

## Adversarial cases

### A1 — Tester mislabels HITL:inline for a DBA-on-call decision

**Input:** Slice 6 (backfill) was labeled `HITL:inline` because "the DBA is on-call and reachable via Slack DM."

**Expected behavior:** The hitl-vs-afk.md decision table should catch this. DBA-on-call is an out-of-band approver named by org chart, not a chat-session participant. Re-label to `HITL:approval-gate`.

**Actual behavior:** ✅ Decision table rule "Decision-maker is on a different team / org / org-chart level" fired. Re-labeled to approval-gate. Paper trail need (production data write) also fires the table's "requires paper trail" rule.

**Weakness surfaced:** Decision table has 6 signal rules. Two of them fired here, reinforcing the call. But the rules are not *prioritized* — what if signals conflict? E.g., "decision-maker is currently in chat" (inline) AND "decision requires paper trail" (approval-gate). The reference doc says "the audit-trail need is the stronger signal" but that's prose, not a rule.

**Recommendation:** Add a "tiebreaker hierarchy" subsection to hitl-vs-afk.md: paper trail > org-chart approval > chat-session presence. → **Will edit before v1.4.0 ships.**

### A2 — Hidden human dependency on AFK:full-auto slice

**Input:** Slice 5 (Stripe wiring) was labeled `AFK:full-auto`. But during implementation, the slice surfaces that the production Stripe account needs to be enabled for usage-based pricing — requires Stripe admin approval, out-of-band.

**Expected behavior:** The vocabulary doesn't explicitly handle "AFK that discovers it needs approval mid-slice." Need a clear runtime behavior.

**Actual behavior:** ⚠️ The current SKILL.md says nothing explicit about mid-slice discovery of an approval need. The agent would naturally pause and surface the issue — but the slice label is now wrong, and there's no instruction to update it.

**Weakness surfaced:** **Real gap.** Reality: slices sometimes turn out to need approval after labeling. Need a runtime rule: if an AFK slice discovers a mid-slice approval need, halt, re-label to `HITL:approval-gate`, and capture in the spec change log.

**Recommendation:** Add to `hitl-vs-afk.md`: "If an `AFK:full-auto` slice discovers a mid-slice approval need at runtime, halt the slice, re-label to `HITL:approval-gate` with the discovered approver/channel, capture the discovery in the spec change log, and resume only after approval." → **Will edit before v1.4.0 ships.**

### A3 — Approver named "the team"

**Input:** A slice's gate detail says "Approval from the team via Slack #eng."

**Expected behavior:** Skill should reject. "The team" is not a named approver. If approval is from "anyone in the channel", what's the routing?

**Actual behavior:** ✅ Caught. hitl-vs-afk.md's format example shows: "DBA approval before run, Slack #data-eng" — a specific role + channel. "The team" is too vague to wire up.

**Weakness surfaced:** The example is in the doc but the rejection isn't explicit. A tester might leave "the team" and move on. The skill should *reject* this pattern, not just provide a counter-example.

**Recommendation:** Add a validation rule to vertical-slice's Phase 4 quality checklist: "Gate detail names a specific role (singular or quorum-named) and a specific channel. 'The team' / 'anyone' / 'whoever's around' are rejected." → **Will edit before v1.4.0 ships.**

### A4 — `parallel-dev` mistakenly dispatched an HITL:inline slice

**Input:** A tester invokes `parallel-dev` on slices {1, 2, 3, 4}. Slice 4 is `HITL:inline`.

**Expected behavior:** `parallel-dev` Phase 1 / Phase 2 should reject the batch. Only `AFK:full-auto` is eligible.

**Actual behavior:** ✅ `parallel-dev` Phase 1 ("Decompose") names eligibility per slice. The updated language now excludes both HITL variants. Batch rejected; tester re-dispatches with {1, 2, 3} only.

**Weakness surfaced:** None. The wiring held.

### A5 — Migrating an old `HITL` label (no suffix)

**Input:** An existing spec from before v1.4.0 has slices labeled `HITL` (no suffix). User asks to update the spec for the new release.

**Expected behavior:** Migration note in hitl-vs-afk.md kicks in: audit the parenthetical reason; out-of-band approver named → `HITL:approval-gate`, otherwise → `HITL:inline`. Don't bulk-rename completed work.

**Actual behavior:** ✅ Three old slices reviewed:
- "HITL — decide JWT placement mid-slice" → reason indicates in-chat decision → `HITL:inline`.
- "HITL — DBA approval for migration" → reason indicates out-of-band approver → `HITL:approval-gate`.
- "HITL — review at slice complete" → ambiguous, defaults to `HITL:inline` (no out-of-band signal).

**Weakness surfaced:** The third case ("review at slice complete") highlights an unrelated pattern — review at slice END is not what HITL labels are for. HITL is mid-slice gating. End-of-slice review is the three-stage review in `tdd-loop` Phase 5. This isn't a vocabulary bug — it's a labeling-discipline issue.

**Recommendation:** Add to hitl-vs-afk.md "Borderline cases" section: "End-of-slice review is NOT HITL. End-of-slice review happens in `tdd-loop` Phase 5 (three-stage review). HITL labels mid-slice gates only." → **Will edit before v1.4.0 ships.**

---

## Honest weaknesses surfaced

Four findings, all small edits:

1. **A1 — Tiebreaker hierarchy missing.** Fixing in v1.4.0.
2. **A2 — Mid-slice approval-discovery has no defined runtime rule.** Fixing in v1.4.0.
3. **A3 — Vague approver names not explicitly rejected.** Fixing in v1.4.0.
4. **A5 — End-of-slice review confused with HITL labeling.** Clarifying in v1.4.0.

No structural redesigns needed. The three-label vocabulary held under stress; the gaps are all *edge case clarifications*.

## Recommendation

- **Vocabulary is mergeable** with the four small edits applied before v1.4.0 ships.
- **All four edits land in `hitl-vs-afk.md` and `vertical-slice/SKILL.md` Phase 4 quality checklist.**

## Test result

**PASS** with four in-flight edits applied before v1.4.0 release.
