# Phase 0 — Reconnaissance Checklist

Probe these files/paths before asking the user anything. Capture findings into the in-memory recon record; persist the digest into `docs/agents/SYSTEM_CONTEXT.md` (see `system-context-template.md`).

If a probe is irrelevant (wrong language ecosystem), skip it — don't run probes you can't interpret.

## Language / runtime

| Probe | Tells you |
|---|---|
| `package.json` (`engines`, `dependencies`, `devDependencies`, `scripts`) | Node version, framework (Express, Fastify, Next, NestJS), test runner, deps |
| `pyproject.toml` / `requirements.txt` / `setup.py` / `Pipfile` | Python version, framework (Django, FastAPI, Flask), key libraries |
| `Cargo.toml` | Rust edition, dependencies |
| `go.mod` | Go version, modules |
| `pom.xml` / `build.gradle` / `build.gradle.kts` | JVM build tool, dependencies |
| `Gemfile` / `*.gemspec` | Ruby version, framework (Rails, Sinatra), gems |
| `composer.json` | PHP framework |
| `.tool-versions` / `.nvmrc` / `.python-version` / `.ruby-version` | Pinned runtime versions |

## Data / persistence

| Probe | Tells you |
|---|---|
| `prisma/schema.prisma` | Postgres/MySQL schema, models, relations |
| `db/schema.rb` / `db/structure.sql` | Rails schema |
| `migrations/` / `prisma/migrations/` / `db/migrate/` | Migration history; how active is the schema? |
| `*.sql` at root or `sql/`, `schema/` | Hand-rolled schema |
| `alembic/versions/` | SQLAlchemy migrations |
| `models/` or `app/models/` | ORM model files |
| `mongoose/`, `schema.json` in repo root, etc. | Mongo / other DB shape |

## Deployment / infra

| Probe | Tells you |
|---|---|
| `Dockerfile` / `docker-compose.yml` | Containerization, base image, exposed ports |
| `fly.toml` | Fly.io single-or-multi region, machine size |
| `vercel.json` | Vercel deployment, framework presets |
| `serverless.yml` / `sam.yaml` / `template.yaml` | Serverless (Lambda) |
| `terraform/` / `*.tf` | Cloud infra; AWS/GCP/Azure footprint |
| `k8s/` / `kustomize/` / `helm/` | Kubernetes shape |
| `Procfile` | Heroku or Heroku-shaped deploys |
| `.github/workflows/` | CI/CD targets, deploy frequency |

## External services / dependencies

| Probe | Tells you |
|---|---|
| `.env.example` / `.env.sample` / `.env.local.example` | What external services are wired (Stripe, Sendgrid, Redis, S3, OpenAI…) |
| `config/*.{yml,toml,json}` (if `.gitignore` doesn't hide it) | Service hostnames, feature flags |
| `package.json` deps for `redis`, `bull`, `bullmq`, `kafka`, `nats` | Queue/stream infrastructure |
| `package.json` deps for `pg`, `mysql2`, `mongodb`, `mongoose` | DB clients in use |

## Conventions / methodology

| Probe | Tells you |
|---|---|
| `AGENTS.md` / `CLAUDE.md` at repo root | Existing agent instructions |
| `docs/agents/` | habeebs-skill setup — issue tracker, labels, ADRs, CONTEXT |
| `docs/agents/adrs/` | Prior decisions (Tier-0 prior art) |
| `docs/agents/CONTEXT.md` | Domain glossary |
| `CONTRIBUTING.md` | Branching model, review process |
| `.editorconfig`, `.prettierrc`, `tsconfig.json` | Style/strictness baseline |

## Recent activity

| Probe | Tells you |
|---|---|
| `git log --since="60 days" --pretty=format:'%ad %s' --date=short` (head 30) | What's been hot |
| `git log --since="60 days" --stat` (head 30) | What files have been changing |
| Open issues / PRs (`gh pr list`, `gh issue list` if available) | What's actively in flight |
| `tests/` recent activity | Quality bar trend |

## How to write the SYSTEM_CONTEXT.md digest

Don't dump raw output. Compress to:

- **Stack:** one line ("Node 20, Express 4.18, Postgres 16, Prisma 5")
- **Deploy:** one line ("Single VM on Fly.io, Docker, no orchestrator")
- **Datastores:** one line ("Postgres only; no Redis; no Mongo")
- **External services:** one line ("Stripe (payments), SendGrid (email), S3 (assets)")
- **Scale envelope:** known numbers OR "[unknown, ask user]"
- **Methodology:** "habeebs-skill configured (docs/agents/, ADRs at 0006)" OR "not configured"
- **Recent hot files:** 3-7 paths
- **Notable absences:** things you'd expect but didn't find ("no rate limiter currently"; "no observability stack")

Each line is asserted; the user can correct any of them in Phase 1.

## What NOT to do

- Don't read every source file — sample manifests, schema, and a handful of recent commits
- Don't infer scale from code shape — ask the user; mark `[assumed]` if they don't know
- Don't overwrite an existing `SYSTEM_CONTEXT.md` without the stale-banner workflow
- Don't probe paths the user has gitignored (respect privacy)
