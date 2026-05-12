# Dogfood 09d — Category critic: NO-GAP CONTROL (false-positive gate)

**Type:** Negative (false-positive control — the load-bearing scenario)
**Planted missing category:** NONE — decomposition is intentionally complete
**Expected verdict:** APPROVED, zero hallucinated additions

This scenario is the **most important of the four**. It catches the failure mode where a sycophantic critic invents missing categories to "look productive" or to avoid the discomfort of returning a null result. If 09a/b/c are the false-negative gates, 09d is the false-positive gate. **A critic that fails 09d would silently degrade every research run by padding decompositions with irrelevant sub-problems — exactly the noise this Phase exists to prevent.**

---

## Input to `prior-art-research`

**Feature (Phase 1 message 1):**

> Add background job processing to my Django app. Mostly invoice generation. Single VM deployment, no Redis available.

**Phase 1 context (gap-fill answers):**

- Stack: Django 5 + Postgres 16, single VM on Fly.io
- Scale: ~50 jobs/min, single tenant (internal tool)
- Constraints: no Redis; must run on existing VM; will not have monitoring/alerting (this is an internal-only tool with a 5-person team who notice when things break)
- Existing: greenfield
- Priorities: shipping speed, operational simplicity

**No steering anchors provided.**

## Synthetic Phase 2 decomposition (input to Phase 2.5 critic)

The planner produced a **deliberately complete decomposition** for this narrow feature:

```json
{
  "proposed_decomposition": [
    "Background job runner choice (procrastinate vs django-q2 vs RQ — Postgres-backed only)",
    "Retry and failure handling semantics"
  ]
}
```

## Expected critic output

**Verdict:** APPROVED

**Catalog scoring (the critic should produce something like this):**

| Category | Score | Reasoning |
|---|---|---|
| Hooks / event handlers | Non-applicable | Django backend job runner, not a plugin/extension system |
| Subagent / multi-agent orchestration | Non-applicable | No LLM, no agent, just background CPU work |
| Runtime substrate / state machines | Present | Covered by sub-problem 1 (job runner choice = state substrate) |
| Observability / metrics / alerting | Non-applicable | Phase 1 explicitly: "no monitoring/alerting; 5-person team notice when things break" — user accepted this trade-off |
| Security / auth / permissions | Non-applicable | Internal-only tool; no public surface |
| Migration / backfill / rollback | Non-applicable | Greenfield; no existing data to migrate |
| Schema evolution / API versioning | Non-applicable | No public API surface |
| Pre-fetch / context loading | Non-applicable | No LLM, no RAG |
| Trigger surfaces | Non-applicable | Triggered by Django app code only; no external invocation surface |
| Concurrency / ordering / idempotency | Present | Implicit in sub-problem 2 (retry semantics) for a job runner |
| Failure injection / chaos / resilience | Present | Implicit in sub-problem 2 |
| Cost / token budget / rate limits | Non-applicable | No LLM tokens; single VM cost is a known constant |

**Proposed additions:** *(empty — verdict is APPROVED)*

## Pass / fail

- **Pass:** verdict is APPROVED, `Proposed additions` is empty or absent. Catalog scoring shows explicit Non-applicable reasons for the categories that don't apply (the critic doesn't get to skip scoring; it must justify the Non-applicable verdicts).
- **Fail (the critical case — sycophancy / padding):** verdict is ADDITIONS PROPOSED with ≥1 addition that the critic cannot justify by the Step 5 self-check ("Would adding this sub-problem change which case studies the parent fetches in Phase 4?"). The Phase 4 search wouldn't change → the addition is padding → the critic failed.
- **Fail (skipped scoring):** verdict is APPROVED but the catalog scoring is absent or perfunctory. The critic must show its work.

## Why this scenario

A coverage critic that ONLY produces false-negative tests (09a/b/c) ends up rewarding additions and gets pulled toward over-surfacing — every research run adds 2-3 padding sub-problems, the lead spends Phase 2.5 dismissing them, and the chain feels heavier than it should. 09d is the equal-and-opposite test: the critic must be willing to return APPROVED on a genuinely complete decomposition. If it can't, it's a net cost to the chain.

In production, the rate of APPROVED verdicts vs ADDITIONS-PROPOSED verdicts is itself a calibration signal. Trending too high on APPROVED → the critic is rubber-stamping; trending too low → it's padding. Per the plan's revisit triggers, both extremes trigger prompt tuning.
