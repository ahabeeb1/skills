---
name: prior-art-research
description: Research-grounded implementation discovery. Before building any non-trivial feature, find 3-5 production implementations of approximately-X by real teams, extract the actual patterns they used (architecture, decisions, trade-offs, what they migrated from), and recommend an approach grounded in those patterns rather than generic best-practices. Make sure to use this skill whenever the user says they want to "build", "implement", "design", "architect", or "add" any non-trivial feature, system, integration, or capability — even when they don't explicitly ask for research. Especially trigger when the user has a vague idea but no concrete approach, when the design space is large, or when multiple credible approaches exist. Do NOT use for trivial CRUD endpoints, single-function utilities, bug fixes with known causes, or API surface questions (Context7 handles those). This is convergent research, NOT divergent brainstorming.
next-skills: [draft-spec, socratic-grill, decision-record]
---

# Prior-Art Research

**The premise:** Before you build X, find how the best teams actually shipped X. Then ground your implementation in those proven patterns, not in theoretical best-practices.

This is convergent research. Generic brainstorming generates novel options; this skill finds the patterns that already work in production at the scale you care about, and recommends one.

## When to use this skill

**Trigger on these signals (even if the user doesn't say "research"):**

- User wants to build, implement, design, architect, or add a non-trivial feature, system, integration, or capability
- User has a vague idea but no concrete approach ("I want a real-time collaborative editor")
- Multiple credible architectures exist for the problem
- The design space is large enough that picking wrong has real downstream cost
- The user mentions a domain you don't have strong production patterns for in context

**Do NOT trigger on:**

- Trivial CRUD endpoints with one obvious approach
- Single-function utilities
- Bug fixes with known causes (use `/diagnose` or systematic debugging instead)
- API surface questions ("how do I call X library?") — Context7 covers this
- Pure refactoring of existing code — use `deep-modules` instead

## Core workflow

The skill runs in 8 phases (0 through 7). Phase 0 always runs when a repo is open. Phases 1-2 always run. Phases 3-5 scale with mode (Quick vs Deep). Phases 6-7 always run.

### Phase 0 — Reconnaissance (look before you ask)

**Discipline:** before asking the user anything, grep the open repo for the answers. The user shouldn't have to tell you what `package.json` already says. The chain is at its weakest when it asks cold questions that the codebase has already answered.

Walk `references/recon-checklist.md` and probe every applicable manifest. Then check for a cached `docs/agents/SYSTEM_CONTEXT.md`:

- **If the file exists AND no tracked manifest has been modified since the file's mtime** (check via `git log --since "<file_mtime>" -- <manifest_paths>`): load it; skip to Phase 1 with the cache populated.
- **If the file exists BUT manifests changed since:** emit a single banner — `⚠ SYSTEM_CONTEXT.md is stale (X changed since YYYY-MM-DD). Refresh? (Y/n)` — and proceed accordingly. Never overwrite silently.
- **If the file does NOT exist:** populate it from probe results following `references/system-context-template.md`, write it, and ask the user to confirm/correct the inferred fields before moving on.

The cached file is loaded by every subsequent chain skill (`draft-spec`, `socratic-grill`, `decision-record`) so the rest of the chain inherits the recon for free.

Phase 0 NEVER runs when no repo is open (chat-only mode); Phase 1 absorbs full responsibility for context capture in that case.

### Phase 1 — Fill the gaps

Phase 0 populated most of the structural context. Now ask only what couldn't be inferred — and frame asks as *gap-filling*, not cold interrogation:

> "I see Node 20 + Express + Postgres 16, single VM via Fly.io, no Redis. Two open questions: target scale and whether this is greenfield."

Don't drown the user in five questions at once — stage them. If the cache already answered a question below, skip it.

**First message (2 questions, asked together):**

1. **What exactly are you building?** (One sentence is fine)
2. **What's your stack and any hard constraints?** (Languages, frameworks, infra, "must run on Lambda," "no external services," etc.)

**Second message after the first answers (3 questions, asked together):**

3. **What scale are you targeting?** (Users, requests/sec, data volume — order of magnitude is fine; "no idea, just shipping a v1" is also fine)
4. **Greenfield, retrofit, or replacement?**
5. **Top 2 priorities** from: shipping speed, operational simplicity, scale headroom, cost, correctness

**Optional steering (the user may volunteer this; never demand it):**

If the user already has hunches about *which design space* to look at — keywords, technique names, architectures they want considered first, or things they explicitly want to avoid — capture that in the same message they answer 3-5. Three slots, all optional, all free-text:

- **Anchor:** terms or techniques to bias queries toward (e.g., "token bucket, sliding-window", "CRDT", "Stripe Idempotency-Key pattern")
- **Look at:** specific projects/teams/architectures to fetch first (e.g., "see how Linear's sync engine handles this", "the BeanBot retrieval layer")
- **Avoid:** out-of-scope terms or anti-patterns (e.g., "no Redis", "skip Kafka", "not interested in serverless")

Steering is **optional anchoring, not prescription**. If the user provides anchors that conflict with strong evidence found in Phase 4-5, the agent must override the anchor and explain why in Phase 6 (see `references/steering-hints.md`). Decomposition still runs autonomously in Phase 2; anchors weight Phase 4 query construction and source ranking, they do not replace the Phase 2 sub-problem split.

Worked examples and the override rule live in `references/steering-hints.md`.

If the user's initial prompt already answers some of these, skip those and only ask what's missing. If the user gives partial or "I don't know" answers, accept them and proceed — flag those unknowns explicitly in the final Context section with `[assumed]` or `[unknown]` tags. The recommendation is only as good as the inputs; mark them honestly.

**Internal precedent check (mandatory if a local repo is open):**

Before going external, grep the open repo for related patterns:
- Search file names: `grep -ri "<feature_keyword>" --include="*.md" docs/ ADR-* 2>/dev/null`
- Search for existing ADRs in `docs/agents/adrs/`, `docs/architecture/`, or `docs/decisions/`
- For Modie specifically: also check sibling repos referenced in CLAUDE.md (BeanBot, salahi.app, AEGIS) if accessible

If you find internal prior art, surface it FIRST in the case studies section as a Tier 0 source. Don't skip this step even when external research feels easier — your own past decisions are higher-signal than any blog post.

### Phase 2 — Decompose

Break the feature into 2-4 searchable sub-problems. Each sub-problem should be a real architectural question other teams have written about.

**Example: "real-time collaborative editor"**
- Conflict resolution (CRDT vs OT vs server-authoritative)
- Presence / awareness (cursors, selections, user list)
- Persistence model (operation log vs snapshot vs hybrid)
- Transport (WebSocket vs WebTransport vs SSE+POST)

**Example: "multi-tenant SaaS billing"**
- Tenant isolation (DB-per-tenant vs schema-per-tenant vs row-level)
- Usage metering (event sourcing vs aggregation vs vendor like Stripe Metering)
- Plan/entitlement model (feature flags vs entitlements service vs hardcoded)
- Reconciliation with payment provider

Present the decomposition to the user before searching. They'll often add or remove sub-problems based on what they actually care about.

**If steering hints were captured in Phase 1, echo them back here** in a single line above the decomposition so the user sees what was registered before search burns budget:

> `Steering received — Anchor: <terms>; Look at: <sources>; Avoid: <terms>. (Echo for confirmation; will weight Phase 4 queries.)`

If any slot was empty, omit it from the echo. If no steering was provided, skip the line entirely — silence is the default.

### Phase 2.5 — Category-completeness critic (coverage gate)

**Why this exists:** a single-agent Phase 2 planner reliably misses entire categories of architectural concern. The chain's bleeding pain (documented 2026-05-12) was a research run that missed `hooks / event handlers` and `subagent-driven patterns` for habeebs-skill itself — and the chain blindly proceeded against the incomplete decomposition. Phase 2.5 is the coverage gate that catches this.

**What runs:** dispatch ONE `category-completeness-critic` subagent (see `skills/parallel-dev/agents/category-completeness-critic.md`) via `parallel-dev` Phase 4 (single-subagent dispatch is allowed). The critic receives the proposed decomposition + Phase 1 context + the SYSTEM_CONTEXT preamble. It returns either:

- **APPROVED** — the decomposition is complete; proceed to Phase 3 unchanged.
- **ADDITIONS PROPOSED** — N missing categories with rationales, each with a suggested sub-problem.

**How the lead responds:**

For each proposed addition, the lead does exactly one of:

1. **Accept** — add the suggested sub-problem to the decomposition. Note "Phase 2.5: accepted (critic surfaced this)" in the running notes for the final report.
2. **Reject with written reason** — explicitly state why the category is non-applicable for this feature + context. The reason is captured in the **Phase 2.5 outcome** section of the final report (`references/output-template.md`). Silent rejection is forbidden.

**Iteration cap:** Phase 2.5 runs exactly ONCE. No re-fan-out, no second pass. If the critic missed something the user later spots, that's a v1.8.0+ improvement candidate (Phase 6 CitationAgent equivalent). The bounded loop keeps Phase 2.5 from becoming a coverage-debate hole.

**When this phase is skipped:**

- Quick mode with 1 sub-problem AND the user picked "shipping speed" as top priority — the coverage critic adds overhead worth more than the catch rate at trivial scope. Note the skip in the report's Phase 2.5 outcome section.
- The user explicitly invokes `/research --skip-coverage-critic` (documented escape valve; intended only when the user has already done their own coverage audit).

**Acceptance bar (dogfood-tested):**

The critic must pass the four-scenario adversarial suite at `tests/dogfood/09-category-critic/`:

- 09a (missing-observability), 09b (missing-hooks), 09c (missing-security): critic MUST surface the planted gap
- 09d (no-gap control): critic MUST return APPROVED with zero hallucinated additions

If the critic fails any scenario, the Phase 2.5 prompt requires tuning before the chain ships. Failure-loud is the design intent — silent rubber-stamping is the failure mode this whole phase exists to prevent.

### Phase 3 — Choose mode

**Quick mode** (default for tight scopes, ~5 min):
- Single agent (this one)
- ~5 sources total across all sub-problems
- Skim engineering blogs, light GitHub spot-checks
- Best for: well-trodden problems, single-sub-problem features, time-boxed exploration

**Deep mode** (use for ambitious or unfamiliar scopes, ~15-20 min):
- Dispatch one subagent per sub-problem (see `parallel-dev` skill for orchestration)
- Each subagent fetches 3-5 sources for its sub-problem
- 10-20 sources total
- Best for: greenfield architecture, ambitious scale, unfamiliar domains, multi-sub-problem features

**Auto-select:** if Phase 2 produced 1-2 sub-problems and the user picked "shipping speed" as a top priority, default to Quick. Otherwise Deep. The user can override with `--quick` or `--deep`.

State the chosen mode and reason in one line before proceeding.

### Phase 4 — Search by source tier

Search in priority order. **Always start with T1 and T2.** Drop to lower tiers only if the upper tiers come up dry.

See `references/source-tiers.md` for the curated list of high-signal engineering blogs by domain.

- **Tier 1 — Engineering blogs from teams that actually shipped it.** Uber, Stripe, Discord, Figma, Cloudflare, LinkedIn, Notion, Shopify, Airbnb, Slack, Pinterest, Dropbox, GitHub, Vercel, Anthropic, OpenAI, Databricks, Snowflake, Netflix, Amazon (Builders' Library). These post-mortems describe what they actually did at scale.
- **Tier 2 — GitHub repos shipping similar features.** Read the actual code, not just READMEs. Look at the directory structure, the abstractions, the migration history.
- **Tier 3 — Conference talks, RFCs, ADRs in OSS projects.** QCon, Strange Loop, PWLConf, RailsConf. ADRs from Kubernetes, Rust, etc.
- **Tier 4 — HackerNews/Reddit practitioner threads.** Where engineers argue trade-offs with real numbers.
- **Tier 5 — Official docs / tutorials.** Lowest signal. Usually theoretical, not battle-tested.

**Query construction:** content nouns, not meta-words. "uber dispatch system architecture" not "how do companies build dispatch." Include the actual technology when you have one ("postgres logical replication" not "database replication").

**Internal precedent first:** if there's a local repo open, grep it for related patterns BEFORE going external. An existing internal solution at the right scale is higher signal than any blog post.

### Phase 5 — Deep-fetch the top 3-5 sources

`web_search` returns snippets. Snippets lie about architecture. Always `web_fetch` the full content of the most promising sources.

Per source, extract:

1. **Architecture** — components, data flow, where the network boundaries are. Sketch it in 1-2 sentences.
2. **Key decisions and why** — the explicit trade-off they called out. "We chose X over Y because Z."
3. **Migrations** — what they had before and why they replaced it. Migrations encode the strongest evidence of which approaches don't work.
4. **Scale** — actual numbers. Users, RPS, data volume, latency budgets.
5. **Trade-offs they accepted** — what they explicitly gave up. This is the most often-missed signal.

If a source is interesting but doesn't include #3 or #5, it's probably a marketing post, not an engineering post. Down-rank it.

### Phase 6 — Synthesize

Produce the output using the template in `references/output-template.md`. The structure:

0. **Executive summary** — 2-3 sentences. Lead with the recommendation and the headline trade-off. Reader should be able to act on this paragraph alone if they trust the research.
1. **Problem** — terse restatement of what's being built (1-2 sentences)
2. **Case studies** — 3-5 case studies, 2-4 lines each, with citations
3. **Patterns** — patterns that emerged across sources. If multiple patterns compete, name each and call out when each fits.
4. **Recommendation for your context** — the specific approach you'd take given the user's scale/stack/constraints from Phase 1. Be opinionated. Anti-patterns to AVOID: surveying without recommending, hedging with "it depends" without saying what it depends ON.
5. **Specific decisions to make next** — the 3-6 concrete decisions the user now has to make to move from architecture to implementation. These feed directly into `socratic-grill` and `draft-spec`.
6. **Open questions** — anything the research didn't resolve.
7. **Sources** — linked, with one-line annotations of what each one was useful for.

**Steering reconciliation (only if steering was captured in Phase 1):** add a sub-section between Recommendation and Decisions-to-make-next titled `Steering reconciliation`. For each anchor, state one of: **Honored** (anchor matched the evidence), **Honored with caveat** (mostly fits but here's the limit), or **Overridden** (evidence pointed elsewhere; here's the contradicting source and what we recommended instead). Anchors silently ignored are a bug — every anchor must show up here, or removed from the steering line. This section is what keeps anchors from becoming silent anchoring bias.

**Template applies when research actually runs.** If you declined the request (anti-trigger fired) or halted at Phase 1 (insufficient context), produce a much shorter output: a one-line status, what you need from the user, and a path forward. Don't pad with empty template sections.

### Phase 7 — Hand off and flush steering

End the response with explicit handoff lines. The downstream skills look for these.

```
HANDOFF: spec ready — invoke `draft-spec` to turn this into an implementation spec.
HANDOFF: grill ready — invoke `socratic-grill` to drive ambiguity out of the open questions and decisions above.
HANDOFF: record ready — once spec + grill complete, invoke `decision-record` to capture the chosen architecture as an ADR.
```

**Then flush steering** if `SYSTEM_CONTEXT.md` has an `## Active steering` section with content. Move the block to a `## Last reconciliation outcome` section dated today. This keeps anchors from bleeding across unrelated chain runs. See `references/steering-hints.md` § "Flush at end of chain" for the exact format and the opt-in-persistence rule for multi-chain campaigns.

If the chain terminated without a Phase 6 report (declined / halted), still flush — stale anchors with no reconciliation are worse than no anchors.

## Anti-patterns this skill guards against

These are the failure modes the skill explicitly prevents. If you find yourself doing any of these, STOP and restart.

- **FAANG-scale solutions for non-FAANG-scale problems.** Discord's Elixir-based voice infra is not the right reference for a 50-user internal tool. Filter for relevance to the user's stated scale.
- **Surveying without recommending.** "Here are five approaches. Pick one!" is not the output. The output is a recommendation with alternatives.
- **Restating blog conclusions verbatim.** Extract the *pattern*, not the prose. If you can't describe the architecture in your own words, you haven't understood it.
- **Recency bias.** The newest blog post isn't automatically the best pattern. A 2017 Stripe post about idempotency is more valuable than a 2025 tutorial that doesn't mention failure modes.
- **Theoretical when real exists.** If a real team has published their actual architecture, prefer it over an "industry best practice" article.
- **Letting copyright leak in.** Never reproduce more than 15 words from any one source. Paraphrase. The output is your synthesis, not their text.

## Output format strictness

Always follow the template in `references/output-template.md`. The downstream skills (`draft-spec`, `socratic-grill`, `decision-record`) parse this structure. Deviating breaks the chain.

## Examples

**Example 1 — Quick mode, well-trodden problem:**

User: "I want to add background job processing to my Django app."

Phase 1: Asks scale (low — single server, <100 jobs/sec), stack (Django + Postgres on Heroku), constraints (no Redis preferred), existing (greenfield), priorities (operational simplicity, shipping speed).

Phase 2: One sub-problem — "background job runner for low-volume Python/Postgres."

Phase 3: Quick mode. Single sub-problem, simplicity priority.

Phase 4-5: Searches T1 for "django background jobs without redis" + T2 for `django-q2`, `procrastinate`, `dramatiq`. Fetches procrastinate's README + a 2023 blog post comparing options.

Phase 6: Recommends `procrastinate` (Postgres-backed, no Redis, mature). Alternatives: `django-q2` for simplicity, RQ if Redis becomes acceptable later. Decisions: retry policy, dead-letter handling, monitoring.

Phase 7: Hands off to `draft-spec`.

**Example 2 — Deep mode, ambitious scope:**

User: "I want to build a real-time collaborative document editor."

Phase 1: Scale (target: 1k concurrent docs, 5-10 users per doc), stack (Node + Postgres, deploying on AWS), constraints (must work offline), existing (greenfield), priorities (correctness, scale headroom).

Phase 2: Four sub-problems: conflict resolution, presence, persistence, transport.

Phase 3: Deep mode. Multiple sub-problems, correctness priority, offline constraint adds depth.

Phase 4-5: Dispatches 4 subagents in parallel. Each fetches 3-5 sources. CRDT subagent fetches Figma's Yjs writeup, Linear's sync engine post, Automerge docs. Presence subagent fetches Liveblocks and Convex posts. Etc.

Phase 6: Synthesizes. Recommends Yjs (CRDT with strong offline support) + Hocuspocus server + Postgres for snapshots + WebSocket primary transport with SSE fallback. Alternatives: Automerge (different perf profile), server-authoritative OT (Google Docs model — much more code).

Phase 7: Hands off — many open questions for `socratic-grill`.

## Internal sources note

For Modie specifically: BeanBot, salahi.app, and the AEGIS/BOL automation projects are personal-precedent sources. When researching anything that touches NL2SQL, RAG, prayer time aggregation, OCR pipelines, or ECS Fargate patterns, search the local repos for prior solutions BEFORE going external. Your own ADRs are Tier 0.

## See also

- `draft-spec` — turns the recommendation into an implementation spec
- `socratic-grill` — drives ambiguity out of decisions and open questions
- `decision-record` — captures the chosen architecture as an ADR
- `parallel-dev` — orchestration primitive used in Deep mode
- `references/source-tiers.md` — curated engineering blogs by domain
- `references/output-template.md` — strict output format
- `references/extraction-checklist.md` — what to pull from each source
- `references/steering-hints.md` — optional steering anchors (Anchor / Look at / Avoid) and the override rule
