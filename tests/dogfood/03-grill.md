# Grill Record: Per-user rate limiting

**From spec:** `tests/dogfood/02-spec.md`
**Date:** 2026-05-10

## Items grilled

### Item 1 — Fail-open vs fail-closed when Postgres is unhealthy

**Starting state:** Spec listed both options without commitment.

**Axes grilled:** Failure modes, Reversibility, Observability

- **Failure modes:** If the function call throws/timeouts, the middleware has two choices: pass the request through (fail-open) or block (fail-closed). Postgres being unhealthy is correlated with the API itself being unhealthy — a database outage will already cause most endpoints to fail downstream. Returning 429 to clients during a DB outage gives them a misleading signal ("you are rate-limited") rather than the true one ("the system is degraded, retry later").
- **Reversibility:** This is a one-way door per request (the request either passes or doesn't). The decision is fully reversible at the code level (one constant flip), so it doesn't need maximum rigor — but observability of the chosen behavior is non-negotiable.
- **Observability:** Whichever choice we make, every fallback must emit a high-cardinality log line AND increment a counter so we can detect it. If 5% of requests are bypassing the limiter because of DB blips, ops needs to see that on a graph.

**Resolution:** **Fail-open.** The limiter is an availability mechanism, not a security boundary; degrading it open during a DB outage is the right trade. Every fail-open event emits `rate_limit_fail_open` counter + structured log including the underlying error. If `rate_limit_fail_open` rate exceeds 1% sustained, page on-call.

### Item 2 — Key cardinality: per-user OR per-user-per-route

**Starting state:** Spec recommended encoding route class in the key but didn't fully justify it.

**Axes grilled:** Scale, Failure modes

- **Scale:** Per-user-per-route multiplies the row count by the number of route groups. With 3 groups and 5,000 MAU that's 15k rows steady-state — trivial. With 50 route classes it would be 250k rows — still trivial.
- **Failure modes:** Single per-user bucket means a single noisy script burns the user's whole API quota for everything, including unrelated endpoints (their /me lookups die because their /reports endpoint went crazy). Per-route-class isolates the blast radius — admin endpoints can't starve out public endpoints for the same user.

**Resolution:** **Per-user-per-route-class.** Three route classes day one (`publicRead`, `authedWrite`, `admin`). Key format: `<userId-or-ip>:<routeClass>`. Move to per-endpoint only if a single endpoint develops abusive patterns that the route-class limit doesn't catch.

### Item 3 — Default limit values

**Starting state:** Spec proposed 60/min sustained, burst 100, applied globally.

**Axes grilled:** Performance, Reversibility

- **Performance:** Current peak is 50 req/s globally, ~5,000 MAU. A user making 60 req/min sustained is **way** above the median; the limit should bite scrapers, not normal users. The Auth0/GitHub-style move is to make the limit "generous enough that normal users never see it; clear enough that abusers do."
- **Reversibility:** Limit values live in config — fully reversible. Don't over-optimize at spec time.

**Resolution:** **Start with three configs, tune via observability:**
- `publicRead`: 120 req/min, burst 200 (unauth or auth, read-only)
- `authedWrite`: 60 req/min, burst 100 (auth required, mutating)
- `admin`: 600 req/min, burst 1,000 (auth + admin role)

Revisit at the 14-day mark: pull p95/p99 per-user request rate from logs; the limit should sit at 4–5x the p99 of legitimate use.

### Item 4 — Cleanup job placement

**Starting state:** Spec listed three options (node-cron, system cron, k8s CronJob).

**Axes grilled:** Operational simplicity, Failure modes

- **Operational simplicity:** Single-VM deployment today → no k8s. node-cron requires no extra ops surface; system cron requires writing a separate shell script and managing crontab entries.
- **Failure modes:** node-cron runs in the same process — if the app crashes mid-cleanup, the next process restart picks it up naturally. System cron would need its own monitoring.

**Resolution:** **In-process `node-cron`** running hourly. When the deployment moves off single VM, this gets revisited as part of the broader scheduling story (revisit trigger: "more than one app instance").

## New decisions surfaced during grilling

- **`rate_limit_fail_open` counter** must exist as part of slice #4 (was implicit in observability slice; now explicit).
- **Three named route-class configs** become part of slice #3's spec (was a single config; now three).
- **14-day tuning checkpoint** added to the operational handover — not a code deliverable, but a calendar reminder.

## Updates to push back into the spec

- Slice #2 acceptance criterion: "If `consume_token` throws, the middleware logs at `error` level, increments `rate_limit_fail_open`, and calls `next()` (fail-open)."
- Slice #3 description: bucket key is `${identity}:${routeClass}` and there are 3 named configs (`publicRead`, `authedWrite`, `admin`) with the values above.
- Slice #4 acceptance criterion: `rate_limit_fail_open` counter exists alongside `rate_limit_rejections_total`.

## Items to add to the ADR

- Fail-open posture is the headline reversible-but-load-bearing decision; ADR should record it explicitly with the alerting threshold (1% sustained).
- Per-user-per-route-class key shape — future researchers should know we considered and rejected single-per-user.
- The 14-day tuning trigger.

---

HANDOFF: spec update ready — apply the three updates above directly to `tests/dogfood/02-spec.md`.
HANDOFF: record ready — invoke `decision-record` to capture fail-open posture, route-class key shape, and revisit triggers.
