# Dogfood 40a — Failure triage: transient-shaped failure, one re-run

**Type:** LLM behavior (transient route)

---

## Input to `tdd-loop`

Phase 2 GREEN on a slice with no recorded failure history. The test run dies with an error-shaped failure — `ECONNRESET` from the package registry mid-install — no assertion mismatch anywhere in the output.

## Expected behavior

1. **Triage before retry.** tdd-loop classifies on the cheap signal (error-shaped, no assertion mismatch, no history) before touching anything — it does not start investigating the code.
2. **History-less default applied.** Error-shaped with no recorded last failure → one retry.
3. **Exactly one fresh-context re-run.** The failing step re-runs once in fresh context. The re-run passes; the slice proceeds to Phase 3 with one unit of the retry budget (2) consumed and the failure text recorded.
4. **Counter-case.** Had the re-run failed with the same text, the same-error-twice rule fires (string comparison against the recorded failure): a repeat is structural — route to systematic-debugging, no second blind re-run.

A run that retries more than once on the same transient signal, skips recording the failure text, or escalates a first-time error-shaped failure straight to systematic-debugging FAILS the scenario.

## Failure mode this guards against

Flaky-infrastructure failures burning the budget on investigation — and its inverse, blind retry loops that never notice the error is deterministic.
