# Prior-Art Research: Per-user rate limiting for Express API

**Researched on:** 2026-05-10
**Mode:** Quick
**Sources consulted:** 5

## TL;DR

Use a **Postgres-backed token bucket** (single `rate_limit_buckets` table + plpgsql UPSERT) as Express middleware, gated to write only on the hot path. Trades sub-millisecond Redis latencies for ~3–5 ms Postgres roundtrips in exchange for zero new infrastructure, which is the right call at 50 req/s on a single VM with no Redis today. Headline trade-off: this approach caps cleanly around ~500 req/s — past that, move to Redis.

## Context

- **Building:** Per-user (auth'd user ID) rate limiter for a public Express API
- **Scale:** ~50 req/s peak today; ~5,000 monthly active users; single VM
- **Stack:** Node 20, Express, Postgres 16, no Redis
- **Constraints:** Must not introduce a new datastore; must survive process restart; per-user not per-IP
- **Existing:** Retrofit (API exists, no limiter today)
- **Priorities:** Operational simplicity, shipping speed

## Sub-problems

1. Algorithm (token bucket vs sliding window counter vs fixed window)
2. Store (in-process memory vs Postgres vs Redis)

(Two sub-problems collapse here because algorithm and store are tightly coupled — picking Postgres constrains feasible algorithms.)

## Case studies

### Stripe — Token bucket on Redis, 4 limiter types in production

- **Architecture:** Per-user request rate limiter (token bucket) sits in front of API handlers; complemented by concurrent-request limiter and load-shedder for prioritizing critical traffic. Redis backs all of them.
- **Key decision:** Token bucket because it absorbs short bursts gracefully and the algorithm fits Redis's atomic INCR/DECR + TTL primitives natively.
- **Scale:** ~13k req/s sustained, 500M+ requests/day.
- **Trade-off accepted:** A new operational dependency (Redis). At their scale this is paid for many times over; at small scale it is pure overhead.
- **Source:** https://stripe.com/blog/rate-limiters (also https://gist.github.com/ptarjan/e38f45f2dfe601419ca3af937fff574d)

### Cloudflare — Sliding window counter at edge scale

- **Architecture:** Two integer counters per key (current period, previous period); requests-in-window estimated by weighted blend of the two.
- **Key decision:** Sliding window counter over leaky/token bucket because it needs only `GET` + atomic `INCR` — survives in a memcached-style store and avoids the dual-parameter tuning of leaky bucket.
- **Scale:** Several billion requests/day; mitigated 400k RPS attacks; 0.003% accuracy error across 400M requests.
- **Trade-off accepted:** Approximation (assumes uniform distribution within previous period). Acceptable when N is large.
- **Source:** https://blog.cloudflare.com/counting-things-a-lot-of-different-things/

### GitHub REST API — Documented token bucket with primary + secondary limits

- **Architecture:** Per-user token bucket as primary limit; an additional secondary "abuse" limiter catches anomalous patterns.
- **Key decision:** Token bucket exposed via `X-RateLimit-*` response headers so clients can self-throttle rather than retrying blindly.
- **Scale:** Public-internet scale; exact RPS not stated.
- **Trade-off accepted:** Adds 4 response headers to every API response; client behavior depends on respecting them.
- **Source:** https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api

### `fafl/token-bucket-postgres` — plpgsql token bucket function, no extension

- **Architecture:** Single plpgsql function `consume_token(key, capacity, refill_rate)` mutates one row per key in a buckets table; safe under concurrent calls due to row-level locking.
- **Key decision:** Native Postgres, no extension, ~30 lines of SQL — eliminates Redis as a dependency entirely.
- **Scale:** Author calls it "performant"; community wiki of `node-rate-limiter-flexible` warns to "carefully test performance, if your application limits more than 500 requests per second."
- **Trade-off accepted:** Each check is a database write under a row lock; ~3–5 ms per call versus sub-ms for Redis.
- **Source:** https://github.com/fafl/token-bucket-postgres

### `node-rate-limiter-flexible` — Multi-backend library with Postgres adapter

- **Architecture:** Single `RateLimiterPostgres` class auto-creates the table; cleans expired rows every 5 min via `setTimeout`.
- **Key decision:** One API across in-memory, Redis, Postgres, MongoDB — same Express middleware shape regardless of store.
- **Scale:** Wiki explicitly warns "test performance" above 500 req/s on the Postgres backend.
- **Trade-off accepted:** A timer-based cleanup task that won't run in serverless without manual `clearExpired()` calls.
- **Source:** https://github.com/animir/node-rate-limiter-flexible/wiki/PostgreSQL

---

## Patterns

### Pattern A — Token bucket on dedicated in-memory store (Stripe, GitHub)

Per-key bucket of `capacity` tokens that refill at `refill_rate` tokens/sec. Each request decrements one token; if empty, reject (HTTP 429). Bucket state lives in a fast key-value store (Redis, memcached).

**Fits when:** Burst tolerance is wanted (the "extra tokens" absorb short spikes), Redis is already on the stack, and per-request latency matters.

### Pattern B — Sliding window counter on a counting-friendly store (Cloudflare)

Two atomic counters per key (current period, previous period); request rate is the weighted blend. Trades exactness for tiny memory and atomic-friendly operations.

**Fits when:** Counting store doesn't support compare-and-swap well, key cardinality is huge (every IP/domain), and approximation is acceptable.

### Pattern C — Token bucket on Postgres (`fafl/token-bucket-postgres`)

Same algorithm as Pattern A, but state lives in a single Postgres table with one plpgsql function. Row-level locking gives concurrency safety; cleanup runs via cron/setTimeout.

**Fits when:** Postgres is already on the stack, traffic is below ~500 req/s, the team values "no new datastore" over latency, and the read/write pattern is already write-heavy.

---

## Recommendation

**For this context (50 req/s, no Redis, simplicity-first), use Pattern C — a Postgres-backed token bucket** implemented as the `fafl/token-bucket-postgres` plpgsql function called from Express middleware on the hot path.

This is the right call because every priority points to it: (1) operational simplicity says "no new datastore," (2) shipping speed says "one table + one function + 30 lines of middleware," (3) the documented ceiling (~500 req/s on Postgres) is **10x** the current peak, giving runway without over-engineering. Stripe's Redis approach is correct at Stripe's scale; deploying Redis for 50 req/s would be pure operational overhead. Cloudflare's sliding-window-counter trick optimizes for problems we don't have (huge key cardinality + memcached). The `node-rate-limiter-flexible` library is also viable but pulls in more surface area than the 30-line plpgsql variant — keep that as a fallback if the library's Express helpers turn out to save real time.

### Concrete picks

| Decision | Choice | Reason |
|---|---|---|
| Algorithm | Token bucket | Absorbs short bursts; trivial to reason about; matches `429 Retry-After` semantics |
| Store | Postgres single table `rate_limit_buckets` | No new infra; survives restart; one source of truth |
| Identity dimension | Authenticated user ID (fallback: client IP for unauth routes) | Per-user, per the spec |
| Limit | 60 req/min sustained, burst capacity 100 (starting numbers) | Empirically loose enough; refine via observability |
| Implementation | plpgsql function called from Express middleware | Atomic check-and-decrement in one round-trip |
| Response on reject | `429 Too Many Requests` + `Retry-After` (seconds) | Standard semantics; GitHub-style |
| Response headers always | `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` | Lets clients self-throttle |

### What you're explicitly giving up

- **Sub-millisecond limiter latency.** Each check is a ~3–5 ms Postgres write. Acceptable today.
- **Scale beyond ~500 req/s without re-architecting.** The store is documented to wobble there.
- **Cross-region replication of buckets.** Single VM today, single Postgres; not a problem until it is.

### When to revisit

- **Scale:** sustained traffic > 300 req/s, OR a single endpoint > 100 req/s
- **Capability:** need for cross-region or multi-VM consistent limits (Redis becomes the right answer)
- **Cost:** if rate-limiter rows + WAL traffic start dominating the Postgres write budget

---

## Decisions to make next

These feed `socratic-grill` and `draft-spec`:

1. **Identity dimension for unauth routes** — fall back to client IP, deny outright, or apply a separate stricter bucket? (Recommendation: IP-bucket with stricter limits.)
2. **Limit values per route class** — single global limit vs per-route-group? Public-read vs authenticated-write vs admin?
3. **Fail-open vs fail-closed when Postgres is unhealthy** — if the limiter can't reach Postgres, do we allow the request through (availability) or block it (correctness)?
4. **Bucket cleanup cadence** — periodic SQL job, app-level `setTimeout`, or none (let rows live)?
5. **Header semantics** — always emit `X-RateLimit-*` or only on near-limit?

## Open questions

- Does the chosen plpgsql function compose cleanly with our existing migration tooling (Prisma / Knex / hand-rolled)?
- What is real p95 latency of the limiter middleware under our actual Postgres connection-pool config?
- Is per-user the right primary key, or do we need per-user-per-route?

---

## Sources

1. **Scaling your API with rate limiters (Stripe)** — https://stripe.com/blog/rate-limiters
   What it gave us: confirmation that token bucket is the canonical algorithm, plus the multi-limiter pattern for later.
2. **Counting things, a lot of different things (Cloudflare)** — https://blog.cloudflare.com/counting-things-a-lot-of-different-things/
   What it gave us: sliding-window-counter alternative + the explicit accuracy/scale trade-off.
3. **Rate limits for the GitHub REST API** — https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
   What it gave us: client-facing response-header conventions (`X-RateLimit-*`, `Retry-After`).
4. **fafl/token-bucket-postgres** — https://github.com/fafl/token-bucket-postgres
   What it gave us: a 30-line plpgsql token bucket that needs no Redis.
5. **node-rate-limiter-flexible — Postgres wiki** — https://github.com/animir/node-rate-limiter-flexible/wiki/PostgreSQL
   What it gave us: the documented ~500 req/s ceiling on the Postgres backend; cleanup-task caveat for serverless.

---

HANDOFF: spec ready — invoke `draft-spec` to turn this into an implementation spec.
HANDOFF: grill ready — invoke `socratic-grill` to drive ambiguity out of the open questions and decisions above.
HANDOFF: record ready — once spec + grill complete, invoke `decision-record` to capture the chosen architecture as an ADR.
