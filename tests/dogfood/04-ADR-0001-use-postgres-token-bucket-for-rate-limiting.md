# ADR-0001: Use Postgres-backed token bucket for per-user API rate limiting

**Status:** Proposed
**Date:** 2026-05-10
**Deciders:** Modie

## Context

The Express API has no rate limiter today. Peak traffic is ~50 req/s, ~5,000 MAU, single VM, Postgres 16, no Redis. A single rogue script can already saturate the API; legitimate users have no protection from each other or from one bad client.

A limiter is needed now because two incidents in the last month traced back to one user's misconfigured retry loop, and the team has explicitly chosen "operational simplicity + shipping speed" as priorities — meaning the limiter must NOT introduce a new datastore.

## Decision

We will implement per-user-per-route-class rate limiting as a Postgres-backed token bucket. Specifically:

- A migration adds the `rate_limit_buckets` table and the `consume_token(key, capacity, refill_rate)` plpgsql function (adapted from `fafl/token-bucket-postgres`).
- Express middleware `rateLimit(config)` resolves the bucket key as `${req.user?.id ?? req.ip}:${routeClass}`, calls `consume_token`, and either continues the request or responds `429 Too Many Requests` with `Retry-After` and the `X-RateLimit-*` header set.
- Three named configurations: `publicRead` (120/min, burst 200), `authedWrite` (60/min, burst 100), `admin` (600/min, burst 1,000).
- **Fail-open** posture when Postgres is unhealthy — the middleware logs at `error` level, increments `rate_limit_fail_open` Prometheus counter, and lets the request through. On-call is paged if `rate_limit_fail_open / total_requests > 1%` sustained for 5 minutes.
- Stale rows (no activity in 24h) cleaned hourly by an in-process `node-cron` job.

This choice is defensible given the constraints: token bucket is the canonical algorithm (Stripe, GitHub); putting the state in Postgres is what `fafl/token-bucket-postgres` and `node-rate-limiter-flexible` were built for; the `~500 req/s` documented ceiling on the Postgres backend is 10x current peak, giving real runway before the architecture needs to change.

## Consequences

### Positive

- Zero new infrastructure. The limiter ships as one migration + one middleware + one cron job.
- Single source of truth for limiter state — Postgres backups already cover it.
- Per-route-class isolation prevents one user's noisy `admin` endpoint usage from starving their `publicRead`.
- Fail-open keeps the API available during DB blips; counter + alert makes that posture observable.

### Negative / Accepted trade-offs

- Each request costs an additional ~3–5 ms Postgres roundtrip.
- The architecture caps at ~500 req/s before we have to revisit.
- The limiter cannot enforce limits across multiple VMs (we have one today — not a problem now).
- During Postgres outages, the limiter does not protect the API; we accept this in exchange for availability.

### Operational impact

- Adds one Prometheus counter for rejections, one for fail-open events.
- Adds one Grafana panel (`rate_limit_*` metrics) — to be added in slice #4.
- Adds one alert: page on-call if `rate_limit_fail_open` rate > 1% sustained for 5 min.
- Adds one structured log line per rejection and per fail-open event.
- Adds a 14-day calendar reminder to tune limit values based on observed p99 of legitimate use.

## Alternatives considered

### Redis-backed token bucket (Stripe pattern)

The canonical at-scale solution: Redis as the limiter store. Rejected because introducing Redis violates the "no new datastore" priority. Revisit if/when traffic exceeds ~300 req/s sustained or we go multi-VM.

### Sliding window counter on Postgres (Cloudflare pattern)

Two-counter weighted blend. Rejected because the algorithm shines when the store doesn't support compare-and-swap (memcached); Postgres already gives us row-level locks and atomic transactions, so the algorithmic complexity buys nothing in our context.

### `node-rate-limiter-flexible` library on the Postgres backend

A drop-in library with multi-backend support. Rejected for the first version because its surface area is larger than our needs (multiple stores, multiple algorithms), and we can keep this dependency-free. Kept as a fallback if the hand-rolled approach surfaces gaps.

### In-process in-memory limiter

Cheapest possible. Rejected because limiter state would not survive process restart (rejection counts reset every deploy) and would not work the moment we run more than one process. Not a future-proof base.

## Revisit triggers

This ADR should be reopened if any of:

- Sustained traffic > 300 req/s, OR any single endpoint > 100 req/s
- Deployment moves to more than one app instance (cron-in-process and per-VM Postgres calls both need rethink)
- `rate_limit_fail_open` rate sustained > 1% (Postgres or pool issues — investigate root cause before tuning the limiter)
- The 14-day tuning checkpoint reveals that real legitimate p99 usage is within 2x of our limit (limit is too tight) OR more than 20x below (limit is too loose)

## References

- Research: `tests/dogfood/01-research.md`
- Spec: `tests/dogfood/02-spec.md`
- Grill: `tests/dogfood/03-grill.md`
- External sources:
  - https://stripe.com/blog/rate-limiters
  - https://blog.cloudflare.com/counting-things-a-lot-of-different-things/
  - https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
  - https://github.com/fafl/token-bucket-postgres
  - https://github.com/animir/node-rate-limiter-flexible/wiki/PostgreSQL

---

## Changelog

- 2026-05-10 — Initial ADR, status Proposed
