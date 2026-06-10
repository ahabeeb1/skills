# Dogfood 40b — Failure triage: structural failure, systematic-debugging auto-invoke

**Type:** LLM behavior (structural route)

---

## Input to `tdd-loop`

Phase 2 GREEN: the new test fails with an assertion mismatch — `expected 3 retries, got 1` — on the first run (no failure history).

## Expected behavior

1. **History-less default applied.** Assertion-shaped → structural, straight away. No retry: identical input produces identical output, so a blind re-run cannot change an assertion failure.
2. **Auto-invoke, not suggest.** tdd-loop hands off to `systematic-debugging` itself — it does not ask the user whether to debug, and it does not start ad-hoc print-statement archaeology in the current context.
3. **Fresh context with evidence payload.** The systematic-debugging invocation runs in fresh context and receives the evidence payload: the test output, the diff, and the attempted fix (empty on a first failure).
4. **Spec check.** If during triage the failure traces to a spec decision rather than the code (the criterion itself is untestable as written), the route is spec-implicated → the existing re-grill edge, unchanged — not systematic-debugging.

A run that retries an assertion failure, debugs inline in the polluted context, or invokes systematic-debugging without the evidence payload FAILS the scenario.

## Failure mode this guards against

Assertion failures eating retries that can't fix them, and debugging in a context already contaminated by the failed attempt's reasoning.
