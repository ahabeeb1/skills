# Dogfood test — running the chain end-to-end

**Date:** 2026-05-10
**Scenario:** "Add per-user rate limiting to an Express API." (Quick-mode profile per the research SKILL.)

This directory is the chain run on itself. Every artifact is a real output of the relevant skill, written against the skill's template. Use it to evaluate whether the methodology produces work worth the time it takes.

## Artifacts in order

1. **[01-research.md](./01-research.md)** — `prior-art-research` output. Real T1/T2 sources web-fetched, Quick mode, 5 case studies, opinionated recommendation. ~250 lines.
2. **[02-spec.md](./02-spec.md)** — `draft-spec` output. 5 vertical slices, all AFK, dependency-ordered, each with acceptance criteria and a named test file. 4 open questions surfaced for grill.
3. **[03-grill.md](./03-grill.md)** — `socratic-grill` output. All 4 open questions resolved across the 7 ambiguity axes; surfaced 3 new spec-level decisions; produced a 14-day tuning trigger.
4. **[04-ADR-0001-use-postgres-token-bucket-for-rate-limiting.md](./04-ADR-0001-use-postgres-token-bucket-for-rate-limiting.md)** — `decision-record` output. Numbered, present-tense title, active-voice Decision, 4 alternatives considered with explicit rejections, 4 revisit triggers, full reference chain back to research/spec/grill.

## What was NOT run

- `tdd-loop` — would have produced actual code for slice #1 (the plpgsql function + migration). Skipped because (a) the chain quality is judgeable from the upstream artifacts and (b) writing real production code against this scenario adds nothing the user can evaluate that the spec doesn't already prove.
- `parallel-dev` — slice #3, #4, #5 are parallelizable per the spec; would be exercised at TDD time.
- `vertical-slice` as a standalone — its principles are baked into Slice 1-5 of the spec; the standalone skill would only be used if we wanted to publish each slice as a GitHub issue.

## Evaluation criteria

The chain claims four properties. Check each:

| Property | Evidence in this run |
|---|---|
| **Grounded** (every choice traces to a real production team) | Stripe, Cloudflare, GitHub, two OSS Postgres implementations — all cited with URLs in `01` and re-cited in `04` |
| **Convergent** (one recommendation, not a survey) | `01` Recommendation section names ONE pattern (C — Postgres token bucket) and defends it; the other two patterns are explicitly rejected with reasons |
| **Ambiguity-killing** (no "we'll see") | `03` resolves all 4 open questions to concrete answers with axes named; no item exits as "TBD" |
| **Implementable** (downstream can start coding) | `02` produces 5 slices with acceptance criteria, test paths, and dependency ordering; an engineer can pick up Slice 1 and start writing the migration |

## Cost

- ~15 min of research (Quick mode), 3 web fetches, 5 sources cited.
- ~10 min of spec/grill/ADR drafting.
- Total: ~25 min from "I want to build X" to "the implementation queue is ready."

## How to run it yourself

In a Claude Code session with this plugin installed:

```
> I want to add per-user rate limiting to my Express API. Stack is Node 20 + Express + Postgres, no Redis, single VM, ~50 req/s peak, ~5k MAU.
```

The chain should fire `prior-art-research` automatically (matches the trigger pattern), then hand off through spec → grill → ADR. The artifacts in this directory are the expected shape of each stage.

## Assertion suites

Beyond this end-to-end run, the numbered subdirectories (`09-` … `44-`) are
per-feature assertion suites. Each is self-contained: a `check-*.sh` (or
`*_test.sh`) plus fixtures and a README. Run the whole set with
[`tests/run-all.sh`](../run-all.sh) — it aggregates exit codes across every
dogfood `check-*.sh` and the standalone hook/sidecar/etc. suites, and is the
gate the `release` skill should run before tagging.

## Known scenario-number collisions (frozen)

Scenario numbers are assigned at creation and **frozen** — they are referenced
by dated/integer ADRs, specs, and CHANGELOG entries that the no-migration-
archaeology rule (scenario 34) forbids rewriting, so a past number is never
renamed (the same discipline as the frozen integer ADRs). Two prefixes were
reused before scenario 35 (`fixture-id-late-binding`) began guarding against it:

| Prefix | Suites sharing it | Refer to by |
|---|---|---|
| `19-` | `19-cross-session-conflict-detection` (v1.16.0), `19-devex-review` (v1.19.0) | full directory name |
| `20-` | `20-semantic-repo-discovery` (the one live skills cite), `20-depth-tier` | full directory name |

Always reference these by full directory name, never the bare number. Scenario 35
prevents new collisions; these two are historical artifacts, left in place.
