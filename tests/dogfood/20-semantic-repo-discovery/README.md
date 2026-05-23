# Dogfood 20 — Semantic Repo Discovery

Calibration suite for the Phase 4 Tier 2 semantic-repo-discovery loop introduced in [ADR-0017](../../../docs/agents/adrs/0017-semantic-repo-discovery-port.md). Validates the three-test fire-rule and the degradation ladder.

## Scenarios

| File | Type | Planted condition | Expected fire-decision |
|---|---|---|---|
| [20a — NL-rich SHOULD FIRE](20a-nl-rich-should-fire.md) | Positive | Feature is NL-shaped, no recognized tech, >6 words | **FIRE** (test (c) trips) |
| [20b — keyword-rich SHOULD SKIP](20b-keyword-rich-should-skip.md) | Negative control | Feature names specific libraries, short, no NL framing | **SKIP** (all three tests fail) |
| [20c — gh-unavailable WebSearch fallback](20c-gh-unavailable-should-websearch-fallback.md) | Degradation (rung 2) | Fire-rule trips; `gh` missing/unauth | Loop runs via `WebSearch site:github.com` |
| [20d — both-unavailable report-the-gap](20d-both-unavailable-should-report-gap.md) | Degradation (rung 3) | Fire-rule trips; `gh` and WebSearch both unavailable | Loop skipped; gap noted in Phase 6 Sources |

## Pass/fail bar (aggregate)

The suite passes when all four scenarios produce their expected fire-decision **and** the agent emits a decision-log line naming which test tripped (per the load-bearing observability requirement in `semantic-repo-discovery.md` § Fire-rule).

**The load-bearing scenario is 20b** — false-fire (treating a keyword-rich query as NL-rich) is the failure mode the fire-rule exists to prevent under [ADR-0010](../../../docs/agents/adrs/0010-system-context-contents-prune.md)'s prune test. A loop that fires on 20b silently degrades every keyword-rich research run with redundant tool calls.

## Why this scenario set

The grill record (2026-05-22) deferred open-question OQ1 — *"does the fire-rule false-fire enough to be load-bearing in practice?"* — with a named revisit trigger. These scenarios are the evidence base for that revisit. If the fire-rule needs tuning (per the ADR-0017 revisit triggers), the agent logs from these dogfoods are what gets audited.

20a/20b probe the fire-rule itself (positive + control). 20c/20d probe the degradation ladder (rungs 2 and 3 of the three-rung graceful fallback per ADR-0017). Rung 1 (`gh search repos` happy path) is exercised by 20a; it doesn't need its own scenario.
