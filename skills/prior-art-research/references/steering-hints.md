# Steering Hints — Optional Anchors for Phase 1

Steering is **optional anchoring**, not prescription. The user can supply hints when they already have hunches about which design space matters; the agent treats those hints as *weighting*, not as *rules*. Decomposition still runs autonomously in Phase 2; anchors weight Phase 4 query construction and source ranking.

## The three slots

All optional, all free-text, all single-line where possible.

| Slot | Question it answers | Weighting effect |
|---|---|---|
| **Anchor** | "Which terms or techniques should I bias queries toward?" | Added as positive query terms; sources matching anchor terms get a tier boost |
| **Look at** | "Which specific projects, teams, or architectures should I fetch first?" | Added to the Phase 5 deep-fetch list before tier-driven discovery runs |
| **Avoid** | "Which terms or anti-patterns should I exclude?" | Added as negative query terms (`-redis`); sources matching avoid terms get filtered post-hoc with a one-line note in the report |

## When steering is appropriate

- The user has already done some informal research and wants to anchor the search to what they've seen.
- The user has hard organizational constraints (e.g., "we can't add Redis to the stack") that should narrow the result set immediately.
- The user wants the chain to evaluate a *specific* technique they're considering, not survey the whole space.

## When steering is inappropriate

- The user has a vague idea ("I want a real-time editor") with no design intuition. Anchors would be guesses, not hints.
- The user is explicitly asking for a survey of options. Anchoring undercuts that.
- The user supplies anchors that contradict their own stated priorities (e.g., anchor "FAANG-scale CRDT" + priority "shipping speed"). Surface the conflict in Phase 1 before searching.

## The override rule

**Anchors are hypotheses, not rules.** If Phase 4-5 evidence strongly contradicts an anchor, the agent must override it and explain why in the Phase 6 *Steering reconciliation* section.

For each anchor, the report must state one of:

- **Honored** — anchor matched the evidence; recommendation incorporates it directly.
- **Honored with caveat** — anchor mostly fits; here's the limit (e.g., "token bucket fits, but only if you accept burst budget tracking; recommendation has the caveat").
- **Overridden** — evidence pointed elsewhere; here's the contradicting source and the alternative recommendation.

Anchors silently ignored are a bug. Every anchor in Phase 1 must show up in Phase 6 reconciliation, or it should never have been registered.

## Worked examples

### Example 1 — Rate limiter (well-anchored)

**User input (Phase 1):**

> Building a rate limiter for a Node + Postgres app on Fly.io. ~50 req/s peak. No Redis. Priorities: operational simplicity, correctness.
>
> **Anchor:** token bucket, sliding-window counter
> **Look at:** Stripe Idempotency-Key post, Cloudflare's edge rate-limiter writeup
> **Avoid:** Redis, anything requiring a separate datastore

**Effect on Phase 4:**

- Queries become: `"token bucket" postgres rate limiter`, `"sliding window counter" postgres`, `stripe idempotency rate limit`, `cloudflare rate limit edge`
- Stripe and Cloudflare sources are deep-fetched first.
- Any source that reaches Phase 5 mentioning Redis as the primary store is filtered with a one-line "Avoided per steering" note.

**Effect on Phase 6 reconciliation:**

- Anchor "token bucket": Honored — Stripe's pattern matches; recommendation uses Postgres-backed token bucket.
- Anchor "sliding-window counter": Honored with caveat — fits sub-100 req/s but loses precision under bursty traffic; recommendation uses token bucket as primary, sliding-window as fallback for analytics.
- Avoid "Redis": Honored — all recommended approaches use Postgres only.

### Example 2 — Background jobs (anchor overridden)

**User input (Phase 1):**

> Need background jobs for a Django app on Heroku. Low volume. Priorities: shipping speed, operational simplicity.
>
> **Anchor:** Celery
> **Avoid:** complexity

**Effect on Phase 4-6:**

- Queries include Celery, but also `procrastinate`, `django-q2`, `dramatiq` (Phase 2 decomposition adds these — anchors don't replace decomposition).
- Phase 5 deep-fetch finds that Celery requires Redis or RabbitMQ on Heroku, contradicting the "avoid complexity" priority.

**Effect on Phase 6 reconciliation:**

- Anchor "Celery": **Overridden** — Celery requires a broker (Redis/RabbitMQ) on Heroku, which adds a managed-service line item and a second failure mode. `procrastinate` (Postgres-backed) ships in a day with no broker. Source: procrastinate README + a 2024 blog comparing Heroku-deployment friction. Recommendation: use `procrastinate`; revisit Celery only if you outgrow Postgres LISTEN/NOTIFY throughput (~1k jobs/sec).

### Example 3 — No steering (default flow)

**User input (Phase 1):**

> I want to add full-text search to my app. Postgres-backed. ~10k docs. Don't know what to use.

No steering provided. Phase 2 echoes nothing. Phase 4 runs unweighted. Phase 6 has no reconciliation section. This is the canonical "vague idea, let the agent decompose" case.

## Inheritance through the chain

Steering is written into `docs/agents/SYSTEM_CONTEXT.md` under an `## Active steering` section so downstream chain skills (`draft-spec`, `socratic-grill`, `decision-record`) inherit the same anchors and avoid-list. The reconciliation outcome from Phase 6 also lands in SYSTEM_CONTEXT so an overridden anchor doesn't haunt the spec.

If steering changes mid-chain (user revises), update SYSTEM_CONTEXT in place — the chain reads it on every skill activation.

## Anti-patterns

- **Treating anchors as rules.** Defeats the purpose. The agent's job is to find the best pattern; anchors say "look here first," not "you must pick this."
- **Empty steering for show.** If the user says "no preferences," skip the slots; don't fabricate anchors.
- **Echoing anchors but never reconciling.** Every anchor must appear in Phase 6 reconciliation with a verdict.
- **Hiding the override.** If the agent overrides an anchor, the override must be loud — first paragraph of the recommendation, not buried in a footnote.
