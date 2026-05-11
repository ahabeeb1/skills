# SYSTEM_CONTEXT.md — Template

Written by `prior-art-research` Phase 0 reconnaissance. Lives at `docs/agents/SYSTEM_CONTEXT.md`. Loaded by every subsequent chain skill so the rest of the chain inherits the recon for free.

Edit by hand whenever it's wrong. The skill will detect staleness via `git log` against tracked manifest files; on stale, it prompts before overwriting.

---

# SYSTEM_CONTEXT

**Last refreshed:** YYYY-MM-DD
**Refreshed by:** prior-art-research Phase 0 reconnaissance
**Tracked manifests:** (the files whose modification triggers a staleness banner — keep this list aligned with what you actually probed)

```
package.json
prisma/schema.prisma
Dockerfile
fly.toml
.github/workflows/deploy.yml
```

## Stack

- **Runtime:** [e.g., Node 20.11, Python 3.12, Go 1.22]
- **Framework:** [e.g., Express 4.18, Django 5.0, Gin]
- **Test runner:** [e.g., Vitest, pytest, go test]
- **Type-checker / linter:** [e.g., tsc strict, mypy, golangci-lint]

## Persistence

- **Primary datastore:** [e.g., Postgres 16 on managed RDS]
- **ORM / driver:** [e.g., Prisma 5, SQLAlchemy 2, pgx]
- **Migrations location:** [e.g., prisma/migrations/]
- **Other datastores:** [Redis? Mongo? S3? Vector DB? Or "none"]

## Deployment shape

- **Topology:** [e.g., single VM on Fly.io / k8s on EKS / Vercel serverless / AWS Lambda]
- **Regions:** [e.g., us-east-1 only / multi-region active-active]
- **CI/CD:** [e.g., GitHub Actions → Fly deploy on main]
- **Observability:** [e.g., Datadog APM + Sentry / "none currently"]

## External services

(Anything `.env.example` or wire-level config reveals. One bullet per service.)

- [e.g., Stripe — payments]
- [e.g., SendGrid — transactional email]
- [e.g., S3 — user uploads]

## Scale envelope

- **Users (MAU / DAU):** [number, or `[unknown]` / `[assumed: 5,000 MAU]`]
- **Peak request rate:** [e.g., 50 req/s peak, 10 req/s sustained, or `[unknown]`]
- **Data volume:** [e.g., 12M rows, 8GB, or `[unknown]`]
- **Latency budget:** [e.g., p95 < 300ms, or `[unknown]`]

## Methodology / agent setup

- **habeebs-skill configured:** Yes (via `setup-habeebs-skill` on YYYY-MM-DD) | No
- **Issue tracker:** [GitHub Issues / Linear / Local markdown / Other]
- **Triage labels:** [link to docs/agents/triage-labels.md, or "default"]
- **Domain glossary:** [link to docs/agents/CONTEXT.md, or "not yet populated"]
- **Latest ADR:** [e.g., ADR-0007 / "no ADRs yet"]

## Recent hot files

(From `git log --since="60 days" --stat`. The 3-7 paths the team has touched most often. Tells the agent which seams are likely live.)

- `path/one.ts`
- `path/two.ts`
- ...

## Notable absences

(Things you'd expect but didn't find. Often more valuable than what's there.)

- [e.g., No rate limiter currently]
- [e.g., No background job runner]
- [e.g., No structured logging]
- [e.g., No feature flag system]

## Open / unknown

Anything Phase 0 couldn't determine. The user is expected to fill these in (or accept `[unknown]` and proceed with `[assumed]` tags downstream).

- [e.g., Exact user count — order of magnitude only]
- [e.g., Whether multi-tenancy is on the near-term roadmap]

## Active steering

(Optional. Captured by `prior-art-research` Phase 1 if the user supplied anchors. Inherited by `draft-spec`, `socratic-grill`, and `decision-record` so the whole chain respects the same hints. Updated in place when the user revises. Cleared after the related research run completes if no longer relevant.)

- **Anchor:** [terms/techniques to bias toward, or `[none]`]
- **Look at:** [specific projects/teams/sources to fetch first, or `[none]`]
- **Avoid:** [out-of-scope terms or anti-patterns, or `[none]`]
- **Last reconciliation outcome:** [link or short summary from the most recent Phase 6 reconciliation — e.g., "Celery anchor overridden 2026-05-10; recommendation uses procrastinate"]
