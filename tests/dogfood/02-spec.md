# Spec: Per-user rate limiting (Postgres token bucket)

**From research:** `tests/dogfood/01-research.md`
**Date:** 2026-05-10
**Status:** Draft (pending grill)

## Architecture

```
[Client] → [Express app]
              │
              ▼
   rateLimit(req.user.id) middleware
              │   (single SQL call)
              ▼
   Postgres: consume_token(key, capacity, refill_rate)
              │
              ▼
   200 OK            429 + Retry-After + X-RateLimit-*
```

One plpgsql function `consume_token` is the entire concurrency-safe core. Express middleware is a thin wrapper that maps `req.user.id` → key, calls the function, and translates the boolean + remaining-tokens result into either continuation or a 429 response.

## Concrete picks (from research)

| Decision | Choice |
|---|---|
| Algorithm | Token bucket |
| Store | Postgres table `rate_limit_buckets` |
| Function | `consume_token(key text, capacity int, refill_rate numeric)` returns `(allowed boolean, remaining int, reset_at timestamptz)` |
| Identity | `req.user.id` for auth'd routes; `req.ip` for unauth routes |
| Default limit | 60 req/min, burst 100 |
| Reject response | `429` + `Retry-After` (sec) |
| Always-emitted headers | `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` |

## Vertical slices

### Slice 1 — Postgres function + migration (AFK)

**Description:** Add migration creating `rate_limit_buckets` table and `consume_token` plpgsql function. Refreshes tokens lazily on each call (no background job needed at this stage).

**Acceptance criteria:**
- [ ] Migration applies cleanly on a fresh database and is idempotent
- [ ] `SELECT * FROM consume_token('test-user', 5, 1)` returns `(true, 4, …)` on first call, refuses (false) after 5 calls in <1s, and refills 1 token/sec thereafter
- [ ] Concurrent calls from two sessions never let the bucket go negative

**Test strategy:** Integration test against a real Postgres in CI — `tests/integration/rate_limit_buckets.test.ts`

**Blocked by:** None

### Slice 2 — Express middleware `rateLimit()` (AFK)

**Description:** Middleware that resolves the identity key (`req.user?.id ?? req.ip`), calls `consume_token`, sets `X-RateLimit-*` headers on every response, and returns `429` with `Retry-After` when denied.

**Acceptance criteria:**
- [ ] On an empty bucket, returns `429`, sets `Retry-After`, and does NOT call `next()`
- [ ] On a non-empty bucket, calls `next()` and sets `X-RateLimit-Remaining` correctly
- [ ] Auth'd request uses `req.user.id`; unauth request falls back to `req.ip`
- [ ] If `consume_token` throws (DB unhealthy), behavior matches the fail-open/fail-closed decision (resolved by grill)

**Test strategy:** Unit test with a mocked `consume_token`, plus one integration test against real Postgres — `tests/unit/rate_limit.middleware.test.ts` + `tests/integration/rate_limit.middleware.test.ts`

**Blocked by:** #1

### Slice 3 — Per-route-class limits (AFK)

**Description:** Allow configuring different `(capacity, refill_rate)` per route group. Provide three defaults: `publicRead`, `authedWrite`, `admin`. Each route group attaches the middleware with its own config.

**Acceptance criteria:**
- [ ] `app.use('/api/public', rateLimit(LIMITS.publicRead))` and `app.use('/api/admin', rateLimit(LIMITS.admin))` use independent buckets per user
- [ ] Bucket key encodes both user ID and route group (`user:42:public-read`)
- [ ] Limits are loaded from environment / config, not hard-coded

**Test strategy:** Integration — `tests/integration/rate_limit.route_classes.test.ts`

**Blocked by:** #2

### Slice 4 — Observability (AFK)

**Description:** Emit a structured log per rejection (`{userId, routeClass, key, remaining: 0}`) and one Prometheus counter `rate_limit_rejections_total{routeClass}`. Add a SQL query for ops to inspect `rate_limit_buckets` (top 10 most-consumed keys in last hour).

**Acceptance criteria:**
- [ ] Every 429 emits exactly one structured log line at level `warn`
- [ ] `rate_limit_rejections_total` increments by 1 per 429
- [ ] `ops/queries/top-consumers.sql` returns the right rows on a populated test DB

**Test strategy:** Unit (log emission, counter increment) + manual smoke (query on real data) — `tests/unit/rate_limit.observability.test.ts`

**Blocked by:** #2

### Slice 5 — Bucket cleanup job (AFK)

**Description:** Hourly cron (node-cron or external scheduler) that deletes rows from `rate_limit_buckets` whose `last_refill_at < now() - interval '24 hours'`.

**Acceptance criteria:**
- [ ] Job runs and removes stale rows on a populated test DB
- [ ] Job is idempotent and safe to run concurrently
- [ ] Failure of the job does not impair the limiter (the function tolerates fresh row creation)

**Test strategy:** Integration — `tests/integration/rate_limit.cleanup.test.ts`

**Blocked by:** #1

## Dependency graph

```
#1 (function + migration)
  ├── #2 (middleware) ── #3 (per-route-class) , #4 (observability)
  └── #5 (cleanup)
```

Slice #2 must finish before #3 and #4. Slices #3, #4, #5 can run in parallel via `parallel-dev`.

## Open questions (feed `socratic-grill`)

1. Fail-open vs fail-closed when Postgres is unhealthy?
2. Per-user-per-route key or just per-user?
3. Limit values: are 60/min + burst 100 actually right, or do we need finer per-route classes from day one?
4. Cleanup job in-process (node-cron) or external (system cron, k8s CronJob)?

## What's NOT in this spec (and that's OK)

- Cross-region / multi-VM limits (the recommendation explicitly defers Redis)
- Per-IP-anonymous abuse limits (separate concern; cover when a real anonymous endpoint exists)
- Distributed denial-of-service mitigation (different problem; layer 7 limiter ≠ DDoS protection)

---

HANDOFF: grill ready — invoke `socratic-grill` to resolve the four open questions above.
HANDOFF: record ready — invoke `decision-record` after grill to capture the locked architecture as an ADR.
HANDOFF: implementation ready — once grill + ADR done, run `tdd-loop` on slice #1 first; #3, #4, #5 are parallelizable after #2.
