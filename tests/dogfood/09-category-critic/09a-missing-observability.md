# Dogfood 09a — Category critic: missing observability

**Type:** Positive (planted gap)
**Planted missing category:** `Observability / metrics / alerting`

---

## Input to `prior-art-research`

**Feature (Phase 1 message 1):**

> Build a background job queue for our Django app. Jobs are mostly invoice generation and PDF rendering. We want retries, dead-letter handling, and rate-limited execution per tenant.

**Phase 1 context (gap-fill answers):**

- Stack: Django 5 + Postgres 16, single VM on Fly.io, no Redis available
- Scale: ~500 jobs/min peak, low single digits per second average; ~50 tenants
- Constraints: must not require additional infrastructure (no Redis)
- Existing: brownfield, currently using `django-q2` which we're outgrowing
- Priorities: operational simplicity, correctness

**No steering anchors provided.**

## Synthetic Phase 2 decomposition (input to Phase 2.5 critic)

The planner produced:

```json
{
  "proposed_decomposition": [
    "Queue backend (Postgres-backed vs broker-based)",
    "Worker pool model (single process vs multi-process vs distributed)",
    "Retry / dead-letter semantics",
    "Per-tenant rate limiting"
  ]
}
```

## Expected critic output

**Verdict:** ADDITIONS PROPOSED

**Categories the critic MUST surface:**

- `Observability / metrics / alerting` — at 500 jobs/min across 50 tenants, the user will not know when retries are spiking or when one tenant is starving others without per-tenant metrics. Missing this category means production failure mode discovery via customer complaints, not dashboards.

**Acceptable additional surfacings (bonus, not required):**

- `Cost / token budget / rate limits` — only if interpreted generously (this is a CPU job, not LLM)
- `Failure injection / chaos / resilience` — worker-crash-mid-job semantics

**Forbidden (would indicate hallucination):**

- `Subagent / multi-agent orchestration` — N/A for a CPU job queue
- `Pre-fetch / context loading` — N/A
- `Schema evolution / API versioning` — N/A for internal queue
- `Trigger surfaces` — not the bleeding gap; jobs are already enqueued by app code

## Pass / fail

- **Pass:** `Observability / metrics / alerting` appears in the critic's `Proposed additions` list with a rationale that mentions per-tenant metrics or retry-spike detection
- **Fail (false negative):** critic returns APPROVED — silent rubber-stamping, the failure mode the slice exists to prevent
- **Fail (false positive):** critic surfaces ≥2 forbidden categories above — hallucination

## Why this scenario

Observability is the category planners reliably forget for backend infrastructure work because it doesn't change the runtime behavior visibly — the queue "works" without metrics, until it doesn't. This is a high-frequency real-world miss.
