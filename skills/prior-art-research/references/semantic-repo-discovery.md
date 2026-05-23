# Semantic Repo Discovery (Phase 4 Tier 2 technique)

> **Scope:** Phase 4 Tier 2 native semantic-search loop — NL feature description → query expansion → corpus search → LLM rerank → ranked candidates. Implemented entirely with primitives every Claude Code session already has. No API key, no SaaS, no runtime substrate. See [ADR-0017](../../../docs/agents/adrs/0017-semantic-repo-discovery-port.md) for the port precedent + fire-rule reasoning + alternatives rejected.

## Premise

A natural-language description ("local AI assistant that remembers screen activity") should surface *semantically relevant* repos, not just keyword matches. Tools like [reposeek.ai](https://docs.reposeek.ai/) solve this with a hosted semantic-search API. We solve the same problem natively — the agent is the semantic engine and `gh search repos` + WebSearch are the corpus — so habeebs-skill remains standalone per [ADR-0002](../../../docs/agents/adrs/0002-habeebs-skill-standalone.md). Phase 1 already loads the LLM with feature description, stack, scale, constraints, and priorities; that's stronger query context than any hosted service gets cold.

## Fire-rule — when this loop runs

The fire-rule is **load-bearing** under [ADR-0010](../../../docs/agents/adrs/0010-system-context-contents-prune.md)'s prune test: the loop must earn its slot. Always-on firing fails the test for keyword-rich queries; never firing fails it for NL-rich queries. **Fire conditionally, bias toward firing** — false-skip is a correctness cost (returns noise/tutorials instead of reference implementations), false-fire is only a token cost (extra tool calls; keyword query still succeeds).

**Three-test rule.** Skip ONLY when ALL three of these fail:

- **(a)** the feature description contains no recognized library/framework/technology name (`react`, `django`, `postgres`, `kafka`, `crdt`, `webrtc`, `procrastinate`, `yjs`, ...)
- **(b)** the feature description contains no quoted CLI command or API name (`"gh search repos"`, `"WebSocket"`, `"send_message"`)
- **(c)** the feature description is >6 words

When any one test trips, FIRE the loop. Default to firing under ambiguity.

**Decision-logging (mandatory).** Record the fire-decision + which test tripped in the Phase 4 working notes. Without this, the fire-rule has no audit trail and dogfood scenarios at `tests/dogfood/20-semantic-repo-discovery/` cannot validate calibration.

Example log lines:

```
fire-decision: SKIP — all three tests failed (description: "django background jobs without redis"; recognized tech: django/redis; ≤6 words)
fire-decision: FIRE — test (c) tripped (description: "local AI assistant that remembers screen activity"; 8 words; no recognized tech; no quoted API)
```

## Tier-gating

Inherited from [tier-scale.md](../../../docs/agents/references/tier-scale.md). Behavior per tier:

- **Quick** — **SKIPPED unconditionally.** Quick is already gated to single-sub-problem low-ambiguity features; the loop's overhead doesn't earn its slot at this tier. Use `gh search repos` with the obvious keyword.
- **Balanced** — runs *for NL-framed queries only*, per the three-test fire-rule above.
- **Deep** — runs *per sub-problem*. Each subagent dispatched in Phase 4 fan-out invokes the loop independently for its own sub-problem. No shared state, no merge contract — the parent `prior-art-research` agent merges ranked-candidate lists at the source-fetcher synthesis step.

## The loop (5 steps)

1. **Expand** the NL feature description into 3-5 candidate query strings.
2. **Search** each candidate via `gh search repos` (preferred) or `WebSearch site:github.com` (fallback when `gh` unavailable).
3. **Skim** the top READMEs (first ~50 lines) for the candidates.
4. **Re-rank** by the rubric below.
5. **Return** the top 3-5 deduplicated repos with a one-line semantic-match summary each.

### Step 1 — Query expansion

Given the feature description from Phase 1 and the sub-problem from Phase 2, generate 3-5 query strings that vary along these axes:

- **Capability name** — "collaborative editor", "rate limiter", "feature flag"
- **Technical primitive** — "CRDT", "token bucket", "percentage rollout"
- **User-facing shape** — "real-time", "self-hosted", "edge"
- **Stack qualifier** — only if Phase 1 captured one ("django", "rust", "deno")

Avoid meta-words ("how to", "best practices") — those find tutorials, not implementations.

**Example.** Feature: *real-time collaborative document editor* — stack: Node + Postgres.

- `crdt collaborative editor`
- `yjs hocuspocus`
- `operational transform document editor nodejs`
- `realtime sync engine`
- `multiplayer text editor websocket`

### Step 2 — Search (preferred path)

```bash
gh search repos "<query>" --sort stars --limit 10 \
  --json name,description,stargazerCount,updatedAt,url,language
```

If signal is noisy, narrow to actively-maintained repos:

```bash
gh search repos "<query>" --updated '>2024-01-01' --stars '>50' --limit 10 \
  --json name,description,stargazerCount,updatedAt,url
```

### Step 3 — Skim

For each candidate (cap at the top 10 across all queries, deduplicated), pull the README:

```bash
gh api repos/<owner>/<name>/readme -H "Accept: application/vnd.github.raw" | head -100
```

WebFetch fallback:

```
WebFetch https://github.com/<owner>/<name>
  prompt: "Extract what this repo does, primary architecture choices, and any scale claims."
```

### Step 4 — Re-rank

Score each candidate 0-7:

| Signal | Points | Why |
|---|---|---|
| README description matches NL intent (LLM judges) | 2 | Most direct signal |
| Activity in last 90 days (commits or releases) | 1 | Dead repos rarely teach |
| ≥100 stars | 1 | Weak quality proxy; deliberately under-weighted vs README match |
| Language matches user stack | 1 | Higher relevance for adaptation |
| Has `ARCHITECTURE.md` / `docs/architecture.md` / equivalent | 2 | Production-grade documentation |

**Drop candidates scoring ≤2.** Better to surface 3 strong than 7 noisy. Keyword matches that fail the semantic check are exactly what this loop exists to filter out.

### Step 5 — Return

Output a short table in the Phase 4 working notes (not yet in the final report — that's Phase 6):

```
Repo                       | Score | Why it matches the NL intent
yjs/yjs                    | 7     | CRDT engine; production-tested; deep architecture docs
ueberdosis/hocuspocus      | 6     | yjs-native server; node + ws; matches "self-hosted"
automerge/automerge        | 5     | Alt CRDT; rust core w/ JS binding; comparison candidate
```

Candidates scoring ≥5 enter Phase 5 (deep-fetch) as Tier 2 sources.

## Degradation ladder

The loop requires at least one corpus-access primitive. The ladder, in order:

1. **`gh search repos`** if available (preferred — structured JSON, rich filters, no scraping).
2. **`WebSearch site:github.com`** if `gh` unavailable or auth fails.
3. **Skip Tier 2 entirely + report the gap** in the Phase 6 Sources section if both are unavailable.

**Never prompt the user to install `gh`.** Per ADR-0002 ("no new install steps") and ADR-0017's explicit decision, the chain gracefully degrades and reports the gap. The user can install `gh` on their own if they want; next invocation upgrades automatically. The chain doesn't impose dependencies.

## When NOT to use this technique

(Beyond the fire-rule, these are stronger SKIP signals — they override even a tripped test.)

- **Precise-tech queries** already compress to a good keyword query; expansion adds noise, not signal. The fire-rule's tests (a) and (b) catch most of these.
- **Quick tier** — explicitly gated out (see Tier-gating above).
- **No `gh` and no WebSearch available** — fall back to Tier 1 (blogs) and note the gap in the final report's Sources section. Don't fabricate. Don't hallucinate repo names.

## Anti-patterns

- **Running the loop on every Phase 4 invocation.** It's fire-rule-gated for a reason; over-firing fails the prune test.
- **Trusting star count over semantic match.** A 50k-star tutorial repo that's keyword-adjacent but architecturally irrelevant is worse than a 200-star repo with the exact pattern. The rubric deliberately weights description-match at 2 points and stars at 1.
- **Skipping Step 4 because Step 3 "looked good."** The re-rank is what separates this from a fancy `gh search` wrapper. Without it the technique degrades to GitHub's own ranking.
- **Letting fire-decisions go unlogged.** Without the audit trail the dogfood scenarios can't validate calibration; OQ1 from the grill (deferred-with-trigger) becomes un-revisitable.

## Why this isn't a service call

[ADR-0002](../../../docs/agents/adrs/0002-habeebs-skill-standalone.md) makes habeebs-skill standalone — zero runtime substrate dependencies. Calling reposeek.ai (or any hosted semantic-repo-search API) would convert an in-repo skill into a SaaS-dependent skill, with an API key every user has to provision and a budget every chain run has to charge against. The semantic-discovery *idea* is valuable; the lock-in isn't worth it. The loop above captures the idea using primitives every Claude Code session already has.

## See also

- [ADR-0017](../../../docs/agents/adrs/0017-semantic-repo-discovery-port.md) — port precedent, fire-rule reasoning, rejected alternatives
- [`source-tiers.md`](source-tiers.md) Tier 2 — invocation pointer
- [`tier-scale.md`](../../../docs/agents/references/tier-scale.md) — tier propagation contract
- `tests/dogfood/20-semantic-repo-discovery/` — fire-rule + degradation calibration scenarios
- [RepoRift (arxiv 2408.11058)](https://arxiv.org/pdf/2408.11058) — vocabulary-mismatch agent pattern; validates query-expansion arm
- [LLM Reranking Generalization Study (EMNLP 2025)](https://github.com/DataScienceUIBK/llm-reranking-generalization-study) — validates LLM-as-reranker as the dominant 2025 pattern
