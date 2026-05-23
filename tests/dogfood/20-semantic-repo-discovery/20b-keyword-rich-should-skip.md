# Dogfood 20b — keyword-rich SHOULD SKIP (false-fire control)

**Type:** Negative control — the load-bearing scenario
**Planted condition:** Feature names specific libraries, ≤6 words, no NL framing
**Expected fire-decision:** **SKIP** (all three tests fail-to-trip)

This scenario is the **most important of the four** for fire-rule calibration. It catches the failure mode where the agent fires the loop on a keyword-rich query that already compresses to a clean `gh search repos` invocation — burning extra tool calls + LLM rerank passes for no improvement over the baseline. A loop that fires on 20b silently degrades every keyword-rich research run.

---

## Input to `prior-art-research`

**Feature (Phase 1 message 1):**

> Django background jobs without Redis.

**Phase 1 context (gap-fill answers):**

- Stack: Django 5 + Postgres 16, single VM
- Scale: ~50 jobs/min, internal tool
- Constraints: no Redis available
- Existing: greenfield
- Priorities: shipping speed, operational simplicity

**No steering anchors. Tier auto-detected:** Quick OR Balanced (1 sub-problem, low ambiguity, 1 hard constraint).

## Expected fire-decision trace (Phase 4 working notes)

```
fire-decision: SKIP — all three tests failed
  test (a): FAILED-to-trip — recognized tech present ("Django", "Redis")
  test (b): FAILED-to-trip — no quoted CLI/API idiom, but irrelevant given (a)
  test (c): FAILED-to-trip — 5 words (≤6)
  fallback: plain `gh search repos "django background jobs postgres"` (Tier 2 keyword path)
```

## Pass / fail

- **Pass:** Phase 4 working notes contain `fire-decision: SKIP` citing all three failed-to-trip with specific reasons. Agent falls through to plain `gh search repos` with keyword query. Loop's Steps 1-5 do NOT execute.
- **Fail (false-fire — load-bearing):** Loop fires anyway. Either (i) decision log shows a tripped test the agent should not have called tripped (e.g., claiming "django" is not a recognized name), or (ii) loop executes without a fire-decision log. **This is the failure mode the fire-rule exists to prevent under ADR-0010's prune test.** Always-on firing fails the prune test for this exact query class.
- **Fail (no decision log):** Loop correctly skips but doesn't emit the SKIP trace. Calibration cannot be audited.

## Why this scenario

If 20b false-fires consistently, the technique violates ADR-0017's load-bearing constraint: *"the conditional fire-rule is what makes the technique pass [the prune] test."* The asymmetric-failure analysis in the grill record (2026-05-22) explicitly identified false-fire as token cost (acceptable in moderation) and false-skip as correctness cost (unacceptable), but a fire-rule that biases so far toward firing that it false-fires on *every* keyword query inverts the prune test — the loop runs always, the gate is theater.

The ADR-0017 revisit trigger *"2+ postmortems cite false-fire → tune the fire-rule threshold"* is operationalized here: if 20b fails twice in production research runs, one of the three tests needs strengthening. Likeliest candidate: test (a) extending its recognized-name list, or test (c) lowering the word-count threshold.

20b also exercises the fall-through to plain `gh search repos`, so secondarily it verifies the Tier 2 keyword path still works when the loop is skipped — important because slice 3 of the implementation modified the SKILL.md Phase 4 Tier 2 bullet.
