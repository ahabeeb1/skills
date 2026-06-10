# Dogfood 40c — Failure triage: budget exhaustion halts well-formed

**Type:** LLM behavior (bounded-retry exhaustion)

---

## Input to `tdd-loop`

A slice that has already consumed its retry budget of 2: one transient re-run (recorded failure A), then a structural round through systematic-debugging whose fix still fails (recorded failure B). Verification fails a third time.

## Expected behavior

1. **No third attempt.** The budget is exactly 2 per slice; tdd-loop does not re-run, re-debug, or quietly widen the budget because the fix "feels close."
2. **BLOCKED with a halt payload.** Exhaustion emits `BLOCKED` carrying the failure history (both recorded failure texts, what each route attempted) — enough for a human to resume without replaying the run.
3. **verify-output variant.** Same shape on the Pass 5c surface: a verify-output `BLOCKED` gets exactly 1 fresh-context fix attempt; the same finding surviving the fix → halt, never a second identical attempt.
4. **Counter-case.** A slice with budget remaining and a NEW failure text (string comparison says not a repeat) re-triages normally — exhaustion only fires when the budget is actually spent.

A run that takes a third attempt, emits a bare BLOCKED with no failure history, or retries an identical verify-output fix FAILS the scenario.

## Failure mode this guards against

Runaway correction loops burning tokens on a fix that has already proved it doesn't converge — the budget exists to make halting the default, not the exception.
