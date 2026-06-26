---
name: prior-art-research
description: Research-grounded implementation discovery before building anything non-trivial. ALWAYS use when user says "let's build X", "I want to add Y", "how should I implement Z", "design this", "architect this", or describes a feature with multiple valid approaches. Do not use for trivial CRUD, bug fixes, or API-surface questions (Context7 handles those).
---

# Prior-Art Research

**SURVEY, THEN DECIDE — NEVER SURVEY WITHOUT RECOMMENDING ONE.**

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
- Bug fixes with known causes (use `/debug` / `systematic-debugging` instead)
- API surface questions ("how do I call X library?") — Context7 covers this
- Pure refactoring of existing code — use `deep-modules` instead

## Core workflow

The skill runs in phases 0 through 7, plus three gates (2.5 coverage critic, 6.4 HITL pivot, 6.5 archive). Phase 0 always runs when a repo is open. Phases 1-2 always run. Phase 3 chooses the **tier** (Quick / Balanced / Deep) that the whole chain run inherits; Phases 4-5 scale with it. Phases 6-7 always run.

### Phase 0 — Reconnaissance (look before you ask)

**Discipline:** before asking the user anything, grep the open repo for the answers. The user shouldn't have to tell you what `package.json` already says. The chain is at its weakest when it asks cold questions that the codebase has already answered.

Walk `references/recon-checklist.md` and probe every applicable manifest. Then run the **staleness-check protocol** per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md):

- **File fresh** → load it; skip to Phase 1 with the cache populated.
- **File stale** → emit the staleness banner and refresh inline (prior-art-research is the canonical SYSTEM_CONTEXT.md writer; other chain skills only read).
- **File missing** → populate from probe results following `references/system-context-template.md`, write it, and ask the user to confirm/correct the inferred fields before moving on.

See the shared protocol doc for the canonical mtime-check command, banner format, and failure-mode fallbacks (git-history-unavailable, file-malformed). This skill's Phase 0 is the only place a chain skill is permitted to write SYSTEM_CONTEXT.md.

The cached file is loaded by every subsequent chain skill (`draft-spec`, `socratic-grill`, `decision-record`, `write-plan`, `tdd-loop`) so the rest of the chain inherits the recon for free.

Phase 0 NEVER runs when no repo is open (chat-only mode); Phase 1 absorbs full responsibility for context capture in that case.

### Phase 1 — Fill the gaps

Phase 0 populated most of the structural context. Ask only what couldn't be inferred. Don't re-ask what the cache already answered.

Ask questions plainly. Do not preface them with explanations of why you're asking, why there are this many, or what you already know. State the questions and stop. Stage them in two messages (2 then 3) — never dump all five at once.

**Scale the asking to the anticipated tier.** Phase 1 precedes the formal tier choice (Phase 3), but the scope is usually legible from the prompt. If the scope is obviously Quick — a single sub-problem and shipping speed signalled in the prompt — collapse Phase 1 to the 2 foundational questions, or to a single confirmation line when Phase 0 and the prompt already cover them, and proceed on assumptions tagged `[assumed]`. Reserve the full staged 2-then-3 for Deep-tier scopes. This gate is adaptive, never a hard block.

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
- **Look at:** specific projects/teams/architectures to fetch first (e.g., "see how Linear's sync engine handles this", "our internal billing service's retry layer")
- **Avoid:** out-of-scope terms or anti-patterns (e.g., "no Redis", "skip Kafka", "not interested in serverless")

Steering is **optional anchoring, not prescription**. If the user provides anchors that conflict with strong evidence found in Phase 4-5, the agent must override the anchor and explain why in Phase 6 (see `references/steering-hints.md`). Decomposition still runs autonomously in Phase 2; anchors weight Phase 4 query construction and source ranking, they do not replace the Phase 2 sub-problem split.

Worked examples and the override rule live in `references/steering-hints.md`.

If the user's initial prompt already answers some of these, skip those and only ask what's missing. If the user gives partial or "I don't know" answers, accept them and proceed — flag those unknowns explicitly in the final Context section with `[assumed]` or `[unknown]` tags. The recommendation is only as good as the inputs; mark them honestly.

**Internal precedent check (mandatory if a local repo is open):**

Before going external, grep the open repo for related patterns:
- Search file names: `grep -ri "<feature_keyword>" --include="*.md" docs/ ADR-* 2>/dev/null`
- Search for existing ADRs in `docs/agents/adrs/`, `docs/architecture/`, or `docs/decisions/`
- Also check any sibling/adjacent repos the consuming repo's `CLAUDE.md` or `docs/agents/SYSTEM_CONTEXT.md` names as internal precedent, if accessible

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

**If steering hints were captured in Phase 1, echo them back here** in a single line above the decomposition:

> `Steering — Anchor: <terms>; Look at: <sources>; Avoid: <terms>.`

If any slot was empty, omit it from the echo. If no steering was provided, skip the line entirely.

### Phase 2.5 — Category-completeness critic (coverage gate)

**Why this exists:** a single-agent Phase 2 planner reliably misses entire categories of architectural concern. Without a coverage gate, the chain proceeds against incomplete decompositions and ships specs missing whole architectural axes (for example: hooks / event handlers / subagent-driven patterns). Phase 2.5 is the coverage gate that catches this.

**What runs:** dispatch ONE `category-completeness-critic` subagent (see `../../agents/category-completeness-critic.md`) via `parallel-dev` Phase 4 (single-subagent dispatch is allowed). The critic receives the proposed decomposition + Phase 1 context + the SYSTEM_CONTEXT preamble. It returns either:

- **APPROVED** — the decomposition is complete; proceed to Phase 3 unchanged.
- **ADDITIONS PROPOSED** — N missing categories with rationales, each with a suggested sub-problem.

**How the lead responds:**

For each proposed addition, the lead does exactly one of:

1. **Accept** — add the suggested sub-problem to the decomposition. Note "Phase 2.5: accepted (critic surfaced this)" in the running notes for the final report.
2. **Reject with written reason** — explicitly state why the category is non-applicable for this feature + context. The reason is captured in the **Phase 2.5 outcome** section of the final report (`references/output-template.md`). Silent rejection is forbidden.

**Iteration cap:** Phase 2.5 runs exactly ONCE. No re-fan-out, no second pass. If the critic missed something the user later spots, capture it as a postmortem candidate. The bounded loop keeps Phase 2.5 from becoming a coverage-debate hole.

**When this phase is skipped:**

- Anticipated Quick tier — Phase 2.5 runs before Phase 3 formally picks the tier, so it uses the Phase 1 *anticipated* tier (the same scope read that scales Phase 1's questioning). When the scope is obviously Quick — a single sub-problem with low ambiguity — skip the critic: at trivial scope its overhead exceeds the catch rate. Note the skip in the report's Phase 2.5 outcome section.
- The user explicitly invokes `/research --skip-coverage-critic` (documented escape valve; intended only when the user has already done their own coverage audit).

**Acceptance bar (dogfood-tested):**

The critic must pass the four-scenario adversarial suite at `tests/dogfood/09-category-critic/`:

- 09a (missing-observability), 09b (missing-hooks), 09c (missing-security): critic MUST surface the planted gap
- 09d (no-gap control): critic MUST return APPROVED with zero hallucinated additions

If the critic fails any scenario, the Phase 2.5 prompt requires tuning before the chain ships. Failure-loud is the design intent — silent rubber-stamping is the failure mode this whole phase exists to prevent.

### Phase 3 — Choose tier

This phase picks the **tier** the *whole chain run* inherits — not just this
skill's research depth. The canonical tier table, the two invariants, and the
propagation contract live in [`docs/agents/references/tier-scale.md`](../../docs/agents/references/tier-scale.md);
read it. The three tiers, as they shape *this skill's* Phases 4-5:

- **Quick** — single agent, ~5 sources, skim engineering blogs + light GitHub
  spot-checks. Phase 2.5 critic skipped. Best for well-trodden,
  single-sub-problem features.
- **Balanced** — single agent, ~8-10 sources, fuller fetch. Phase 2.5 runs.
  Best for moderate-complexity features with a few sub-problems.
- **Deep** — one subagent per sub-problem (see `parallel-dev` for
  orchestration), 3-5 sources each, 10-20 total. Phase 2.5 runs. Best for
  greenfield architecture, ambitious scale, unfamiliar or ambiguous domains.

**Auto-detect.** Score three signals {low 0, medium 1, high 2}:

1. **Residual ambiguity after Phase 1** — count partial / `[assumed]` /
   `[unknown]` answers: 0-1 low, 2-3 medium, 4+ high.
2. **Sub-problem count** (from Phase 2) — 1 low, 2-3 medium, 4+ high.
3. **Constraint count / complexity** — hard constraints from Phase 1 Q2; a
   constraint that rules out a common architecture counts double: 0-1 low,
   2-3 medium, 4+ high.

Sum (0-6): **0-1 → Quick**, **2-4 → Balanced**, **5-6 → Deep**. Then apply the
guards:

- **Ambiguity floor:** if signal 1 is high, the tier is at least Balanced
  regardless of the sum — a genuinely unclear task never auto-routes to Quick.
- If "shipping speed" is a top-2 priority and the computed tier is Balanced,
  drop to Quick. Never drops Deep.
- If "correctness" is a top-2 priority and the project is greenfield and the
  computed tier is Balanced, bump to Deep.

This is a heuristic, not a hard gate. The user can override with `--quick`,
`--balanced`, or `--deep`; the override wins and is recorded with a
`(user override)` annotation in the `Tier:` header.

**State the tier and a task-based reason in one line** before proceeding —
e.g. `Tier: Quick — 1 sub-problem, low ambiguity, no hard constraints.` Cite
the signals only; never justify the tier with token, cost, or time language
(see `tier-scale.md` invariant 2). Write the chosen tier into the report
header's `**Tier:**` field (Phase 6) — every downstream chain skill reads it
from there.

### Phase 4 — Search by source tier

Search in priority order. **Always start with T1 and T2.** Drop to lower tiers only if the upper tiers come up dry.

See `references/source-tiers.md` for the curated list of high-signal engineering blogs by domain.

- **Tier 1 — Engineering blogs from teams that actually shipped it.** Uber, Stripe, Discord, Figma, Cloudflare, LinkedIn, Notion, Shopify, Airbnb, Slack, Pinterest, Dropbox, GitHub, Vercel, Anthropic, OpenAI, Databricks, Snowflake, Netflix, Amazon (Builders' Library). These post-mortems describe what they actually did at scale.
- **Tier 2 — GitHub repos shipping similar features.** Read the actual code, not just READMEs. Look at the directory structure, the abstractions, the migration history. For NL-framed feature descriptions on Balanced/Deep tiers, run the **semantic-repo-discovery loop** in [`references/semantic-repo-discovery.md`](references/semantic-repo-discovery.md) — fire-rule-gated — to surface candidates that don't compress to keyword queries. Quick skips the loop unconditionally; precise-tech queries fall through to plain `gh search repos` or WebSearch.
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

### Phase 6.4 — HITL pivot gate

After composing the Phase 6 report and BEFORE writing the Phase 6.5 archive, HALT for a human review. Surface the recommendation summary + the concrete decisions for `/spec` and wait for an explicit direction.

This gate exists to prevent wasted downstream token spend. By the time `/spec`, `/grill`, `/record`, and `/plan` finish, the chain has paid for four artifacts on top of the research. If the recommendation is in the wrong direction, halting here costs one user message; halting after `/plan` costs the artifacts AND the re-do. Most peer methodologies (Python PEP 1, Kubernetes KEP `provisional` state, Backstage BEP pre-RFC issue, obra/superpowers design sign-off — 4 of 5 surveyed in v1.22.0 research) gate BEFORE the full spec is written.

**Gate format.** Emit a clearly-labeled halt block at the end of the Phase 6 output:

```markdown
## Phase 6 ready for HITL review — pivot point

This is the new gate. **The chain is HALTED here.** Phase 6.5 archive will NOT write until you confirm direction.

[Then ask the user to pick from THREE response options:]
```

Then ask the user to choose one of three responses:

1. **(a) Approve as-is** — proceed to Phase 6.5 archive write unchanged. The recommendation as composed is correct; the chain continues.
2. **(b) Approve with pivots** — free-text edits applied to the in-conversation Phase 6 report BEFORE Phase 6.5 commits to the archive file. The user describes the pivot in prose; the agent applies the edits to the in-conversation report; then Phase 6.5 writes the (edited) report to disk. Once Phase 6.5 writes the file, the file IS the source of truth — downstream skills read the archive, not the conversation.
3. **(c) Reject + re-research with new scope** — return to Phase 2 (re-decomposition) with a new scope statement from the user. The Phase 6 report in conversation is discarded; the archive is NOT written; the chain re-enters Phase 2 with the user's new framing.

**This is a direction-confirmation gate, not an architecture menu.** Present the single opinionated recommendation, then offer the three pivot responses above (approve / approve-with-pivots / reject-and-re-scope) via the `AskUserQuestion` tool (`multiSelect: false`), allowing free-text follow-up for option (b) or (c) details. The "not a menu" rule governs the *recommendation*: zero of five surveyed peer methodologies offered a menu of competing architectures (four of five used approve/iterate), so never dilute the recommendation into a multiple-choice list of designs — the three choices here are only the pivot decision, not a design selection.

**On approve-as-is or approve-with-pivots:** apply any edits to the in-conversation report, then continue to Phase 6.5.

**On reject + re-research:** abandon the current Phase 6 report. Do NOT archive. Return to Phase 2 with the user's new scope statement. Re-run the Phase 2 decomposition, Phase 2.5 critic, Phase 3 tier check, Phase 4-5 fan-out. The new Phase 6 report then hits the pivot gate again.

**Why HITL here and not after `/spec`?** Same pivot point, lower latency. By Phase 6 the user has the recommendation + the alternatives + the trade-offs + the decisions-to-make-next. They have everything needed to pivot. Adding a separate `/spec`-pre-gate would double-gate the same decision; better to make the first gate sufficient.

**On `--auto` invocations** (no user present): the gate skips with a note in the archive ("HITL pivot gate auto-passed; no user available"). The gate's value depends on a human being present to pivot.

**On the user accepting as-is with deferrals:** if the user picks (a) but defers any sub-decisions to `/grill`, capture the deferred items as open questions in the report. The grill phase resolves them. This is the common case — the recommendation is directionally right, individual details need socratic pressure.

### Phase 6.5 — Archive the report

After Phase 6 composes the report, write it verbatim to:

```
docs/agents/research/<slug>-research.md
```

The `<slug>` is the same feature slug the user (or you) will use for the downstream spec — typically a `vX.Y.Z-<feature-name>` shape (e.g., `v1.10.0-context-engineering-alignment-research.md`). Derive from the Phase 1 problem statement if the user hasn't named it yet; confirm before writing if ambiguous.

The archive's content is the full Phase 6 output — every numbered section above (Executive summary through Sources) plus the Steering reconciliation block when applicable. Phase 7's HANDOFF lines should name the archive file path so downstream skills (`draft-spec`, `socratic-grill`) can read the durable archive instead of relying on in-conversation context.

**Tier-conditional.** The tier is in this report's header (`**Tier:**`); fire by tier:

- **Deep:** **REQUIRED.** Multi-source synthesis (10-20 sources, subagent fan-out) is worth preserving as the evidence base for future "why did we pick X?" audits.
- **Balanced:** **OPTIONAL.** Default-off. Write only if the synthesis contains decisions or evidence you expect the user to revisit; otherwise the spec's "Concrete picks" table preserves what's load-bearing.
- **Quick:** **SKIPPED.** A ~5-source Quick synthesis is terse enough that the spec carries everything that matters.

**Failure mode.** If the write fails (filesystem full, permission denied, path missing), emit one line and proceed to Phase 7:

```
⚠ Could not write research archive at <path>: <error>. Proceeding to HANDOFF.
```

Research success is not held hostage to archival failure — same shape as the dispatch-record fallback in `parallel-dev`.

**Post-write edits are file edits.** Once Phase 6.5 commits the file, the file is the source of truth. Any edit to the report (clarifying a Recommendation, adding a Source, fixing a typo surfaced in Phase 7) MUST update the on-disk archive too — don't let the conversation transcript and the archive diverge.

### Phase 7 — Hand off and flush steering

End the response with explicit handoff lines. The downstream skills look for these. **Note:** these HANDOFF lines are navigation pointers, not state payloads — downstream skills MUST read the full Phase 6 output document (the case studies, recommendations, decisions-to-make-next, open questions, sources) to do their work. When Phase 6.5 fired, the "full Phase 6 output document" IS the archive file at `docs/agents/research/<slug>-research.md` — name the path in the HANDOFF so downstream skills know what to read. See [`using-habeebs-skill` § "HANDOFF lines — navigation, not state transfer"](../using-habeebs-skill/SKILL.md) for the full-doc-read contract that governs every HANDOFF in the chain.

```
HANDOFF: spec ready — invoke `draft-spec` to turn this recommendation into the plain-language Design the user reads. Source: docs/agents/research/<slug>-research.md (when Phase 6.5 archived).
HANDOFF: grill ready — once the Design is written, invoke `socratic-grill` to walk the user through it, drive ambiguity out of the open questions and decisions above, and earn sign-off.
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

**Example 1 — Quick tier, well-trodden problem:**

User: "I want to add background job processing to my Django app."

Phase 1: Asks scale (low — single server, <100 jobs/sec), stack (Django + Postgres on Heroku), constraints (no Redis preferred), existing (greenfield), priorities (operational simplicity, shipping speed).

Phase 2: One sub-problem — "background job runner for low-volume Python/Postgres."

Phase 3: signals score 0 (1 sub-problem, low ambiguity, soft constraints) → Quick. `Tier: Quick — 1 sub-problem, low ambiguity, no hard constraints.`

Phase 4-5: Searches T1 for "django background jobs without redis" + T2 for `django-q2`, `procrastinate`, `dramatiq`. Fetches procrastinate's README + a 2023 blog post comparing options.

Phase 6: Recommends `procrastinate` (Postgres-backed, no Redis, mature). Alternatives: `django-q2` for simplicity, RQ if Redis becomes acceptable later. Decisions: retry policy, dead-letter handling, monitoring.

Phase 7: Hands off to `draft-spec`.

**Example 2 — Deep tier, ambitious scope:**

User: "I want to build a real-time collaborative document editor."

Phase 1: Scale (target: 1k concurrent docs, 5-10 users per doc), stack (Node + Postgres, deploying on AWS), constraints (must work offline), existing (greenfield), priorities (correctness, scale headroom).

Phase 2: Four sub-problems: conflict resolution, presence, persistence, transport.

Phase 3: 4 sub-problems + the offline constraint score Balanced; the correctness-priority greenfield guard bumps it to Deep. `Tier: Deep — 4 sub-problems, offline constraint, greenfield correctness priority.`

Phase 4-5: Dispatches 4 subagents in parallel. Each fetches 3-5 sources. CRDT subagent fetches Figma's Yjs writeup, Linear's sync engine post, Automerge docs. Presence subagent fetches Liveblocks and Convex posts. Etc.

Phase 6: Synthesizes. Recommends Yjs (CRDT with strong offline support) + Hocuspocus server + Postgres for snapshots + WebSocket primary transport with SSE fallback. Alternatives: Automerge (different perf profile), server-authoritative OT (Google Docs model — much more code).

Phase 7: Hands off — many open questions for `socratic-grill`.

## See also

- `draft-spec` — turns the recommendation into the Design
- `socratic-grill` — drives ambiguity out of decisions and open questions
- `decision-record` — captures the chosen architecture as an ADR
- `parallel-dev` — orchestration primitive used in the Deep tier
- `docs/agents/references/tier-scale.md` — canonical tier table, auto-detect rule, invariants
- `references/source-tiers.md` — curated engineering blogs by domain
- `references/output-template.md` — strict output format
- `references/extraction-checklist.md` — what to pull from each source
- `references/steering-hints.md` — optional steering anchors (Anchor / Look at / Avoid) and the override rule
