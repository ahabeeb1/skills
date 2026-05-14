# SYSTEM_CONTEXT.md — Template

Written by `prior-art-research` Phase 0 reconnaissance. Lives at `docs/agents/SYSTEM_CONTEXT.md`. Loaded by every subsequent chain skill so the rest of the chain inherits the recon for free.

Edit by hand whenever it's wrong. The skill will detect staleness via `git log` against tracked manifest files; on stale, it prompts before overwriting.

## Scope (per ADR-0010)

This file carries **non-re-derivable cross-session state only**. Anthropic's [Claude Code best-practices](https://code.claude.com/docs/en/best-practices) prune test applies: *"Would removing this cause Claude to make mistakes?"* If Claude can derive it from `package.json` / `git log` / imports on a fresh invocation, **don't persist it here.**

**DO NOT persist** (re-derivable by Claude on read; persisting violates Anthropic's ❌ Exclude rule):

- Stack — Runtime / Framework / Test runner / Type-checker (Claude greps manifests)
- Persistence — Datastore / ORM / Migrations location (Claude reads config + imports)
- Deployment shape — Topology / Regions / CI/CD / Observability (Claude reads CI config + Dockerfile + monitoring config)
- External services (Claude reads imports + env)
- Recent hot files (`git log --since` runs instantly)

**DO persist** (cross-session state OR inference too expensive to redo per invocation):

- Scale envelope — not in code
- Methodology / agent setup — user-answered config from `setup-habeebs-skill`
- Active steering — opt-in anchors that persist across chain runs
- Last reconciliation outcome — dated summaries from past `prior-art-research` runs (the value of this file across invocations)
- Notable absences — inferential prior knowledge; requires synthesizing across files to reconstruct
- Project mode — one-line judgment (brownfield/greenfield/replacement); derivable but expensive

---

# SYSTEM_CONTEXT

**Last refreshed:** YYYY-MM-DD
**Refreshed by:** prior-art-research Phase 0 reconnaissance
**Schema:** per ADR-0010 (contents-prune; non-re-derivable cross-session state only)

## Scale envelope

- **Users (MAU / DAU):** [number, or `[unknown]` / `[assumed: 5,000 MAU]`]
- **Peak request rate:** [e.g., 50 req/s peak, 10 req/s sustained, or `[unknown]`]
- **Data volume:** [e.g., 12M rows, 8GB, or `[unknown]`]
- **Latency budget:** [e.g., p95 < 300ms, or `[unknown]`]

## Methodology / agent setup

- **habeebs-skill configured:** Yes (via `setup-habeebs-skill` on YYYY-MM-DD) | No
- **Issue tracker:** [GitHub Issues / Linear / Local markdown / Other]
- **Triage labels:** [link to docs/agents/triage-labels.md, or "default"]
- **Domain glossary:** [link to docs/agents/GLOSSARY.md, or "not yet populated"]
- **Latest ADR:** [e.g., ADR-0012 / "no ADRs yet"]

## Notable absences

(Things you'd expect but didn't find. Inferential — often more valuable than what's there. Includes anything Phase 0 couldn't determine — accept `[unknown]` and proceed with `[assumed]` tags downstream.)

- [e.g., No rate limiter currently]
- [e.g., No background job runner]
- [e.g., No structured logging]
- [e.g., No feature flag system]
- [e.g., Exact user count — order of magnitude only]
- [e.g., Whether multi-tenancy is on the near-term roadmap]

## Project mode

- **brownfield** | **greenfield** | **replacement** — one-line judgment with optional context (e.g., "brownfield — v1.x live in production since 2024, mid-rewrite of auth subsystem")

## Active steering

(Optional. Captured by `prior-art-research` Phase 1 if the user supplied anchors. Inherited by `draft-spec`, `socratic-grill`, and `decision-record` so the whole chain respects the same hints. Updated in place when the user revises. Flushed after the related research run completes per Phase 7 — see `references/steering-hints.md` § "Flush at end of chain".)

- **Anchor:** [terms/techniques to bias toward, or `[none]`]
- **Look at:** [specific projects/teams/sources to fetch first, or `[none]`]
- **Avoid:** [out-of-scope terms or anti-patterns, or `[none]`]

## Last reconciliation outcome

(Dated summaries from past `prior-art-research` Phase 6 runs. Cross-session memory — this is the file's primary value across invocations. Append new entries; never overwrite. Older entries may be archived if the file grows past ~5KB.)

**YYYY-MM-DD — topic: [research-run topic]**

- Anchor "[...]" : Honored | Honored with caveat | Overridden — [1-line reason]
- Look-at "[source]" : Honored | Overridden — [1-line reason]
- Avoid "[...]" : Honored
- Phase 2.5 critic outcome: APPROVED | ADDITIONS PROPOSED (N accepted / M rejected with reason)
- Verdict: [1-2 sentences]
