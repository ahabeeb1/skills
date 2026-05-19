# Depth-tier calibration set

15 tier-detection cases for the `prior-art-research` Phase 3 auto-detect rule,
plus the invariant checks. Scoring rule (canonical:
[`tier-scale.md`](../../../docs/agents/references/tier-scale.md)) — three
signals, each {low 0, medium 1, high 2}:

- **ambiguity** — partial / `[assumed]` / `[unknown]` answers after Phase 1: 0-1 low, 2-3 medium, 4+ high
- **sub-problems** — Phase 2 count: 1 low, 2-3 medium, 4+ high
- **constraints** — hard constraints; one that rules out a common architecture counts double: 0-1 low, 2-3 medium, 4+ high

Sum → **0-1 Quick**, **2-4 Balanced**, **5-6 Deep**. Guards: ambiguity-high → at
least Balanced; shipping-speed top-2 + computed Balanced → Quick; correctness
top-2 + greenfield + computed Balanced → Deep.

Each case fixes the post-Phase-1/2 state so the score is reproducible. The
`Expected tier` is the label graded against.

---

## Tier-detection cases

### T01 — add a `/healthz` endpoint
**Post-Phase-1:** ambiguity = 0 unresolved → low (0); constraints = none → low (0); priorities = shipping speed, operational simplicity
**Post-Phase-2:** 1 sub-problem → low (0)
**Score:** 0 + 0 + 0 = 0 → **Quick**
**Expected tier:** Quick

### T02 — background job processing for a Django app
**Post-Phase-1:** ambiguity = 1 `[assumed]` (job volume) → low (0); constraints = "no Redis preferred" (soft, 1) → low (0); priorities = shipping speed, operational simplicity
**Post-Phase-2:** 1 sub-problem (Postgres-backed job runner) → low (0)
**Score:** 0 + 0 + 0 = 0 → **Quick**
**Expected tier:** Quick

### T03 — add CSV export to an admin dashboard *(borderline 1↔2)*
**Post-Phase-1:** ambiguity = 2 `[assumed]` (max row count, async vs sync) → medium (1); constraints = none → low (0); priorities = shipping speed, correctness
**Post-Phase-2:** 1 sub-problem → low (0)
**Score:** 1 + 0 + 0 = 1 → **Quick** (one notch below Balanced)
**Expected tier:** Quick

### T04 — webhook delivery with retries *(borderline 1↔2)*
**Post-Phase-1:** ambiguity = 2 `[assumed]` (delivery SLA, dead-letter policy) → medium (1); constraints = "at-least-once delivery" (1 hard) → low (0); priorities = correctness, operational simplicity
**Post-Phase-2:** 2 sub-problems (delivery transport, retry/backoff) → medium (1)
**Score:** 1 + 1 + 0 = 2 → **Balanced**
**Expected tier:** Balanced

### T05 — full-text search over a product catalog
**Post-Phase-1:** ambiguity = 1 `[assumed]` → low (0); constraints = "stay on Postgres", "p95 < 200ms" (2 hard) → medium (1); priorities = operational simplicity, scale headroom
**Post-Phase-2:** 3 sub-problems (indexing, ranking, index sync) → medium (1)
**Score:** 0 + 1 + 1 = 2 → **Balanced**
**Expected tier:** Balanced

### T06 — add SSO (SAML + OIDC) to an existing app
**Post-Phase-1:** ambiguity = 3 `[assumed]` (IdP list, JIT provisioning, session model) → medium (1); constraints = "existing user table", "no downtime for current logins" (2 hard) → medium (1); priorities = correctness, operational simplicity
**Post-Phase-2:** 3 sub-problems (protocol handling, identity linking, session issuance) → medium (1)
**Score:** 1 + 1 + 1 = 3 → **Balanced**
**Expected tier:** Balanced

### T07 — in-app notification banner, "ship it this week" *(shipping-speed guard)*
**Post-Phase-1:** ambiguity = 1 `[assumed]` → low (0); constraints = "must work on the existing React frontend", "no new service" (2) → medium (1); priorities = **shipping speed**, operational simplicity
**Post-Phase-2:** 2 sub-problems (delivery, dismissal/persistence) → medium (1)
**Score:** 0 + 1 + 1 = 2 → computed Balanced; **shipping-speed top-2 guard drops it to Quick**
**Expected tier:** Quick

### T08 — "something to help users onboard faster" *(ambiguity floor)*
**Post-Phase-1:** ambiguity = 5 still `[unknown]`/`[assumed]` after follow-ups (what "faster" means, which users, success metric, surface, scope) → high (2); constraints = none → low (0); priorities = `[unknown]`
**Post-Phase-2:** 1 sub-problem → low (0)
**Score:** 2 + 0 + 0 = 2 → **Balanced**; ambiguity-floor guard confirms it cannot be Quick
**Expected tier:** Balanced

### T09 — real-time collaborative document editor *(correctness-bump guard)*
**Post-Phase-1:** ambiguity = 1 `[assumed]` → low (0); constraints = "must work offline" (rules out server-authoritative — counts double → 2 effective) → medium (1); priorities = **correctness**, scale headroom; project = **greenfield**
**Post-Phase-2:** 4 sub-problems (conflict resolution, presence, persistence, transport) → high (2)
**Score:** 0 + 2 + 1 = 3 → computed Balanced; **correctness + greenfield guard bumps it to Deep**
**Expected tier:** Deep

### T10 — zero-downtime monolith→identity-service auth migration
**Post-Phase-1:** ambiguity = 4 `[assumed]` (cutover strategy, token format, rollback, session bridging) → high (2); constraints = "zero downtime", "no forced re-login", "keep current token format readable" (3 hard) → medium (1) — and zero-downtime rules out a stop-the-world cutover (counts double) → high (2); priorities = correctness, operational simplicity
**Post-Phase-2:** 4 sub-problems (identity store, token bridge, traffic cutover, rollback path) → high (2)
**Score:** 2 + 2 + 2 = 6 → **Deep**
**Expected tier:** Deep

### T11 — event-sourced ledger for payments
**Post-Phase-1:** ambiguity = 2 `[assumed]` → medium (1); constraints = "exactly-once accounting", "auditable", "reconcile with PSP", "no data loss" (4 hard) → high (2); priorities = correctness, scale headroom
**Post-Phase-2:** 4 sub-problems (event store, projections, reconciliation, snapshotting) → high (2)
**Score:** 1 + 2 + 2 = 5 → **Deep**
**Expected tier:** Deep

### T12 — personalized recommendation feed *(borderline 4↔5)*
**Post-Phase-1:** ambiguity = 2 `[assumed]` (cold-start handling, refresh cadence) → medium (1); constraints = "reuse existing event pipeline", "p95 < 300ms" (2 hard) → medium (1); priorities = scale headroom, operational simplicity
**Post-Phase-2:** 4 sub-problems (candidate generation, ranking, feature store, serving) → high (2)
**Score:** 1 + 1 + 2 = 4 → **Balanced** (top of the Balanced band)
**Expected tier:** Balanced

### T13 — multi-region active-active write replication *(borderline 4↔5)*
**Post-Phase-1:** ambiguity = 3 `[assumed]` (conflict policy, region count, consistency SLA) → medium (1); constraints = "no write loss", "cross-region p99 budget", "existing Postgres" (3 hard, one rules out single-primary → counts double → 4 effective) → high (2); priorities = correctness, scale headroom
**Post-Phase-2:** 4 sub-problems (conflict resolution, routing, failover, reconciliation) → high (2)
**Score:** 1 + 2 + 2 = 5 → **Deep** (bottom of the Deep band)
**Expected tier:** Deep

### T14 — `/research --balanced` on a 1-sub-problem feature *(explicit override)*
**Prompt:** `/research --balanced add a rate-limit header to API responses`
**Auto-detect would compute:** sum 0 → Quick. **Override present** → run at Balanced; header records `Balanced (user override)`.
**Expected tier:** Balanced

### T15 — `/research --deep` on a simple feature *(explicit override)*
**Prompt:** `/research --deep add a dark-mode toggle`
**Auto-detect would compute:** sum 0 → Quick. **Override present** → run at Deep; header records `Deep (user override)`.
**Expected tier:** Deep

---

## Invariant checks

These verify `tier-scale.md`'s two invariants. All must pass.

### I1 — quality gate holds under `--quick` (open questions)
**Setup:** `/research --quick` on a feature; the resulting spec has a non-empty `Open questions` section (e.g. "auth model undecided").
**Expected:** the chain runs at Quick **and** `socratic-grill` still runs on the open questions. A `--quick` override changes the default depth — it does not let a spec with open questions skip the grill.

### I2 — quality gate holds under `--quick` (one-way-door decision)
**Setup:** `/research --quick` on a feature whose chosen approach includes a hard-to-reverse decision (e.g. a public API contract, an irreversible data migration).
**Expected:** `decision-record` still writes an ADR for that decision, even at Quick.

### I3 — ambiguity floor
**Setup:** any feature where Phase 1 leaves 4+ answers `[assumed]`/`[unknown]` (high ambiguity).
**Expected:** the auto-detect never routes it to Quick — minimum Balanced — regardless of sub-problem count or constraints. (See T08.)

### I4 — focused user-facing output
**Setup:** inspect the one-line tier announcement Phase 3 emits for every case above.
**Expected:** it cites task-based reasons only — sub-problem count, ambiguity, constraints (e.g. `Tier: Quick — 1 sub-problem, low ambiguity, no hard constraints.`). It must contain **no** token-, cost-, or time-budget justification language.
