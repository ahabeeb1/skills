# Dogfood 20c — gh-unavailable WebSearch fallback (rung 2)

**Type:** Degradation (rung 2 of the three-rung ladder)
**Planted condition:** Fire-rule trips (NL-rich feature), `gh` CLI is unavailable or unauthenticated, `WebSearch` is available
**Expected behavior:** Loop runs via `WebSearch site:github.com` fallback; final report's Sources section notes which corpus path was used

---

## Input to `prior-art-research`

Same feature as 20a (NL-rich):

> I want to build a local AI assistant that remembers what I've been working on across my screen activity, so I can pick up where I left off.

**Planted environment:** `gh --version` returns non-zero OR `gh auth status` reports unauthenticated (simulated by harness or by running in a sandbox without `gh` installed).

## Expected fire-decision trace (Phase 4 working notes)

```
fire-decision: FIRE
  test (c): TRIPPED — 23 words (>6)
corpus-access: gh unavailable (rung 1 failed) → falling back to WebSearch site:github.com (rung 2)
```

## Expected loop output

The loop's Step 2 (Search) uses `WebSearch site:github.com "<query>"` for each expanded query instead of `gh search repos`. Steps 1, 3, 4, 5 run normally. Step 3 (Skim) still works because `WebFetch https://github.com/<owner>/<name>` is available even without `gh`.

Candidates surface as in 20a; scoring discipline unchanged. Sources section of the final Phase 6 report contains a note like:

```
Note: gh CLI was unavailable during this run; Tier 2 corpus accessed via WebSearch site:github.com. Results may be less precise than `gh search repos` due to snippet-based ranking.
```

## Pass / fail

- **Pass:** Loop fires correctly (as in 20a); corpus-access path log shows rung-1-to-rung-2 fallback; Step 2 uses WebSearch; final report Sources section notes the corpus path. At least 2 candidates score ≥5.
- **Fail (no fallback):** Loop fires but Step 2 either uses `gh` anyway (impossible per planted condition) or errors out / silently produces zero candidates. Degradation ladder is broken.
- **Fail (silent fallback):** Loop falls back correctly but doesn't emit the `corpus-access: ...` trace. Future debugging of "why are the candidates lower-quality?" has no signal to find.
- **Fail (prompts user to install gh):** Per ADR-0017 explicit decision, the chain MUST NOT prompt the user to install `gh`. If the agent emits any prompt suggesting the user install or authenticate `gh`, the scenario fails — this violates ADR-0002's "no new install steps."

## Why this scenario

Tests the rung-1-to-rung-2 transition of the degradation ladder. ADR-0017's Operational impact section commits to graceful degradation; if the ladder doesn't actually work, the loop is brittle the moment a user runs without `gh` configured (which is the default state for most Claude Code users — `gh` is not part of the standard install).

Secondary purpose: verifies the "never prompt to install" decision is enforced. The temptation to nudge the user toward installing `gh` is strong (it does improve quality) but conflicts with ADR-0002. This scenario is the test that keeps the implementation honest.
