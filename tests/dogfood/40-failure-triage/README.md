# Dogfood 40 — The failure-triage rule

Verifies spec slice #1 of `loop-harness`: every verification failure in tdd-loop (unexpected RED in Phases 2–4, verify-output BLOCKED in Pass 5c) is classified on cheap signals and routed three ways under a bounded retry budget — transient, structural, or spec-implicated.

| File | Type | Asserts |
|---|---|---|
| `check-failure-triage.sh` | Executable (bash) | triage covers both failure surfaces; three routes with actions; same-error-twice string comparison; history-less defaults; retry budget of exactly 2 as convention; exhaustion → BLOCKED + halt payload; verify-output BLOCKED bounded at 1 fix attempt; systematic-debugging auto-invoke with evidence payload; re-grill edge referenced unchanged |
| `40a-transient-rerun.md` | LLM behavior | Error-shaped first failure → one fresh-context re-run, failure text recorded |
| `40b-structural-autoinvoke.md` | LLM behavior | Assertion-shaped failure → systematic-debugging auto-invoked in fresh context with evidence |
| `40c-budget-exhaustion-halt.md` | LLM behavior | Budget spent → BLOCKED with halt payload, no third attempt |

Run the executable half: `bash tests/dogfood/40-failure-triage/check-failure-triage.sh`
