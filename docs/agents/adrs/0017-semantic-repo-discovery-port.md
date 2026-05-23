# ADR-0017: Port reposeek.ai's NL→repo idea as a conditional Tier 2 technique

**Status:** Accepted
**Date:** 2026-05-22
**Deciders:** Modie (Habeeb), via this chain run (prior-art-research → socratic-grill → decision-record)
**Tier:** Balanced

## Context

`prior-art-research` Phase 4 Tier 2 currently routes every repo-discovery query through `gh search repos` or `WebSearch site:github.com` — both keyword-search-shaped. For NL-rich feature descriptions like "local AI assistant that remembers screen activity," keyword search returns tutorials, marketing, and SEO chum instead of reference implementations. This is the *vocabulary-mismatch problem* RepoRift names: the user's words don't compress to the corpus's keywords.

[reposeek.ai](https://docs.reposeek.ai/) is a hosted service that solves this with NL→ranked-GitHub-repos semantic search via CLI + REST + `REPOSEEK_API_KEY`. ADR-0002 forbids calling the hosted service (no API key, no SaaS, no runtime substrate). ADR-0014 already established the playbook for adopting peer tools' ideas without their runtimes — applied successfully to three gstack capabilities. The decision is needed NOW because the user surfaced reposeek.ai as a desired capability against v1.15.0; without a captured decision, future audits will re-litigate the port question every time reposeek.ai (or a similar service) resurfaces.

## Decision

We will port reposeek.ai's NL→ranked-GitHub-repos *idea* into Phase 4 Tier 2 as a native markdown technique. Specifically:

- A new `skills/prior-art-research/references/semantic-repo-discovery.md` documenting the 5-step loop (expand → search → skim → rerank → return), the rubric, and the degradation ladder.
- A one-line pointer in `references/source-tiers.md` Tier 2 section.
- ~3-line conditional in `SKILL.md` Phase 4 Tier 2 bullet.
- The loop uses ONLY primitives every Claude Code session has: WebSearch, WebFetch, `gh` CLI (optional), Read/Grep, and the LLM itself as semantic engine. No API key, no SaaS, no runtime substrate.
- **Three-test fire-rule.** Skip ONLY when ALL three fail: (a) no recognized library/framework name, (b) no quoted CLI/API idiom, (c) >6 words. Bias toward firing; the agent logs which test tripped in Phase 4 working notes for dogfood auditability.
- **Tier-gating.** Quick skipped (over-investment for single-sub-problem low-ambiguity features). Balanced runs for NL-framed queries only. Deep runs per-subagent in Phase 4 fan-out.
- **Degradation ladder.** `gh search repos` → WebSearch `site:github.com` → skip Tier 2 and note the gap in the Phase 6 report. Never prompt the user to install `gh` (conflicts with ADR-0002's "no new install steps").

The choice reflects three principles. First, **standalone discipline** — ADR-0002 holds; porting the idea preserves the invariant, calling the hosted service would not. Second, **earn-its-slot via prune test** — ADR-0010's Anthropic test ("would removing this cause Claude to make mistakes?") evaluates *yes for NL-rich, no for keyword-rich*; the conditional fire-rule is what makes the technique pass. Third, **port-pattern precedent** — ADR-0014 established that habeebs-skill ports peer tools' markdown-encoded ideas while rejecting their runtimes; this is the same shape applied to a 4th capability.

## Consequences

### Positive

- Closes the vocabulary-mismatch gap in Phase 4 Tier 2 — NL feature descriptions now route to a semantic-match loop instead of degrading to keyword noise.
- No new dependency, no new API key, no new install step. ADR-0002 unamended.
- Extends ADR-0014's idea-port pattern to a 4th capability (security-audit / release / devex-review / semantic-repo-discovery), confirming the pattern as load-bearing.

### Negative / Accepted trade-offs

- **No dense vector retrieval.** The canonical 3-stage pipeline (sparse → dense → LLM rerank) is implemented as sparse + LLM rerank only. Accepted: ADR-0002 forbids a vector store; the LLM compensates by carrying both expansion and rerank.
- **Fire-rule calibration is theoretical until dogfood scenarios run.** Asymmetric failure-cost analysis (false-skip = correctness cost; false-fire = token cost) biases toward firing, but the three-test threshold may need tuning. Accepted with named revisit trigger.
- **Reposeek.ai's ranking architecture is opaque** (their docs page 404). We cannot validate "our loop does ≥80% of theirs." Accepted: we implement a known-good pattern (RepoRift + LLM-as-reranker literature), not a reverse-engineering of theirs.

### Operational impact

- One new reference doc, two file edits, four new dogfood scenarios (`tests/dogfood/20-semantic-repo-discovery/`: 20a NL-rich-fires, 20b keyword-skips, 20c gh-fallback, 20d report-the-gap).
- Ships in the next release (target v1.16.0). CHANGELOG Why-line: *"Adopt reposeek.ai's NL→ranked-GitHub-repos idea as a conditional Tier 2 technique; the fire-rule is what keeps the loop earning its slot under ADR-0010's prune test."*

## Alternatives considered

### Call reposeek.ai directly via its API

Use `REPOSEEK_API_KEY` from the environment, hit the REST endpoint, surface results. Rejected: violates ADR-0002 (API key, SaaS dependency, runtime substrate). The idea is portable in markdown; the runtime is not.

### Always-on loop (fire on every Phase 4 Tier 2 query)

Drop the fire-rule; run the loop unconditionally. Rejected: fails ADR-0010's prune test for keyword-rich queries — "django background jobs" gains nothing from query expansion + LLM rerank. Bloats token cost without improving outcomes.

### No ADR — implement quietly

Skip the ADR since the change is reversible (not a one-way door). Rejected at decision-record time: fails the meta-prune-test. Future audits encounter reposeek.ai again and re-propose composition; without a captured rejection, the decision drifts. ADR-0014 established the pattern of recording these even when reversible.

### Parallel-dispatch fan-out across queries

Use `parallel-dev` to run query-expansion / corpus fetch / re-rank steps concurrently. Rejected at Phase 2.5 critic: loop size (3-5 queries, ≤10 candidates, ≤3 deep skims) is below the threshold where `parallel-dev` overhead earns its slot. Serial is faster end-to-end.

### User override flag (`/research --semantic-search`)

Let the user force the loop on a keyword-rich query. Rejected as YAGNI: trivially additive later; no current evidence of need. Trigger named below.

## Revisit triggers

This ADR should be reopened if any of:

- 3+ postmortems cite "wanted semantic search but the fire-rule didn't fire" → add the `--semantic-search` override flag.
- 2+ postmortems cite false-fire (loop ran on keyword-rich query) → tune the fire-rule threshold or strengthen one of the three tests.
- Reposeek.ai changes posture (open-sources its ranker, drops the API-key requirement, becomes pip-installable without external service) such that direct composition becomes plausible → re-evaluate the ADR-0002 carve-out narrowly.
- The chain ports a 5th capability from a peer tool → consider promoting the markdown-idea-port pattern to its own dedicated convention doc.
- Dense-vector retrieval becomes available in habeebs-skill via a future primitive that doesn't violate ADR-0002 → re-evaluate adding stage 2 of the canonical pipeline.

## References

- Research: Phase 6 synthesis (in-conversation, this chain run, 2026-05-22)
- Grill: Phase 4 Grill Record (in-conversation, this chain run, 2026-05-22)
- Related ADRs: [ADR-0002](./0002-habeebs-skill-standalone.md) (standalone), [ADR-0010](./0010-system-context-contents-prune.md) (prune test), [ADR-0014](./0014-adopt-gstack-capabilities-markdown-idea-port.md) (idea-port precedent), [ADR-0016](./0016-chain-wide-depth-tier.md) (tier propagation)
- External sources:
  - [docs.reposeek.ai](https://docs.reposeek.ai/) — the source idea
  - [RepoRift (arxiv 2408.11058)](https://arxiv.org/pdf/2408.11058) — validates query-expansion arm; 78.2% Success@10 on CodeSearchNet
  - [LLM Reranking Generalization Study (EMNLP 2025)](https://github.com/DataScienceUIBK/llm-reranking-generalization-study) — validates LLM-as-reranker as the dominant 2025 pattern
  - [LLM-Semantic-Search pipeline](https://github.com/saleena-18/llm-semantic-search) — canonical 3-stage we adopt minus dense store
  - [`gh search repos` CLI manual](https://cli.github.com/manual/gh_search_repos) — primitive confirmed (filters, `--json` output, sort options)

### Reference implementations cited

- **RepoRift** ([arxiv 2408.11058](https://arxiv.org/pdf/2408.11058)) — multi-stream ensemble + RAG agents for vocabulary-mismatch bridging in code search. Cited because the query-expansion step in our loop is the same pattern at smaller scale (LLM as the agent, `gh search repos` as the corpus, no embedding store).

---

## Changelog

- 2026-05-22 — Initial ADR, status Accepted (light ADR per Balanced tier + non-one-way-door + meta-prune-test reasoning; implementation lands in v1.16.0)
