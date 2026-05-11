---
name: systematic-debugging
description: Root-cause debugging via reproduce → minimize → hypothesis-driven probe → fix → regression-test → postmortem. Replaces "try things until it stops failing" with a structured method that produces evidence at each step. Make sure to use this skill whenever the user reports a bug, a test starts failing, behavior is unexpected, or something "worked yesterday." Especially trigger when previous fix attempts have failed (the cycle of vibe-fixes is the failure mode this skill exists to prevent). Inspired by Superpowers' systematic-debugging and OMC's trace lane. Do NOT use for already-understood bugs where the fix is obvious (just fix), for performance investigations without a known regression (use profiling/observability), or for "is this a bug" questions where the spec itself is unclear (use socratic-grill on the spec first).
next-skills: [tdd-loop, decision-record]
---

# Systematic Debugging

A bug is a hypothesis-mismatch event: the running system disagrees with your model of it. Debugging is the disciplined practice of finding which hypothesis was wrong. Random code edits don't qualify — they sometimes change the symptom without telling you why.

This skill replaces "try things until it stops failing" with a procedure that produces evidence at each step. Every hypothesis is either confirmed or refuted by a probe, not by a guess.

## When to use this skill

**Trigger on:**

- A bug is reported (production, staging, local — doesn't matter)
- A test that used to pass now fails (regression)
- Behavior diverges from spec / docs / expectations
- "It worked yesterday" — the regression bisect is built into Phase 3
- Previous fix attempts have NOT solved the problem (this is the canonical anti-vibe trigger)
- A `tdd-loop` RED phase shows a failure mode different from what was expected

**Do NOT trigger on:**

- A bug whose cause is already understood — just fix it
- Open-ended performance investigation with no known regression — use profiling/observability
- "Is this a bug?" questions where the spec is unclear — `socratic-grill` the spec first
- Build / lint errors — those have direct mechanical fixes

## Core workflow

### Phase 1 — Reproduce

You cannot debug what you cannot reliably trigger. The first deliverable of this skill is a **reliable reproduction**, not a fix.

1. Capture the report: what input, what observed behavior, what expected behavior?
2. Reproduce locally (or in the same environment if local isn't possible). Record the exact command, input, env state.
3. If reproduction is flaky (succeeds 1 in 10): the bug is concurrency-, timing-, or state-dependent. Note it as such and continue — Phase 2 will work to make it deterministic.

If you cannot reproduce, halt and ask the user for more information. **Do not start trying fixes without a reproduction.** The fix you'd apply has no way to be verified.

### Phase 2 — Minimize

Reduce the reproduction to the smallest possible case. Each minimization step is a probe:

- Remove unrelated code: does the bug still reproduce? If yes, that code wasn't load-bearing. If no, you've narrowed the suspect surface.
- Substitute simpler inputs: does the bug still reproduce on `"hello"` instead of the user's 4KB JSON? If yes, the bug is structural, not data-dependent.
- Disable plausibly-unrelated subsystems (cache, async wrapper, retries, middleware layers): does the bug still reproduce? Each "yes" eliminates a suspect; each "no" focuses you.

The end state is the smallest possible reproduction — a few lines of code or a single input that reliably triggers the bug. **This minimization itself is the most valuable artifact of debugging.** It will become the regression test in Phase 5.

### Phase 3 — Root-cause via hypothesis-driven probes

You have a minimized reproduction. Now find which assumption was wrong.

For each plausible hypothesis:

1. State it explicitly: "I believe the failure is caused by X."
2. Predict what probe output would confirm or refute it.
3. Run the probe (logging, debugger, git bisect, isolated test, etc.).
4. Compare output to prediction. **Update hypothesis based on evidence, not vibes.**

Useful probe types:

- **Logging probe** — insert a log at the boundary you suspect; rerun. What state crossed that boundary?
- **Binary search via git bisect** — for regressions where "it worked yesterday" is true. Each bisect step is a probe that halves the suspect commit range.
- **Isolation probe** — call the suspect function with its expected inputs in a fresh test; does it fail the same way? If yes, the bug is in that function. If no, the bug is in how it's called or in surrounding state.
- **Differential probe** — compare two cases that differ in exactly one variable. Does only one fail?
- **Capture-and-replay probe** — record real inputs from production, replay locally; does the local replay fail too?

Hypotheses must be falsifiable. "Maybe something is wrong with the auth flow" is not a hypothesis; "The token is being sent without the `Bearer ` prefix when the user has no last_login timestamp" is.

If your hypothesis-disconfirms keep coming up, the bug is likely in code you haven't yet considered (env vars, framework defaults, an interaction you assumed was inert). Expand the suspect surface and continue.

### Phase 4 — Fix

Once root cause is known:

1. **Confirm the cause IS the cause** — apply a probe that should make the symptom go away if your hypothesis is right (e.g., monkey-patch the suspect function to bypass the bug). If the symptom changes as predicted, fix the underlying code. If not, your hypothesis was wrong — return to Phase 3.
2. **Write the minimal fix.** Don't refactor adjacent code in the same change; that's a separate task and confuses git blame later.
3. **Don't suppress symptoms.** A try/catch that swallows the error is not a fix — it's a symptom-hider. The fix removes the cause.

### Phase 5 — Regression test

The minimized reproduction from Phase 2 becomes a permanent test:

1. Add the minimized repro as a test that **would have failed** before your fix.
2. Run the test on the unfixed code (or the fix temporarily reverted) — confirm it fails.
3. Apply the fix — confirm the test now passes.
4. Commit fix and test together.

Without this step, the bug will return. With this step, the test is the bug's tombstone.

### Phase 6 — Postmortem (for non-trivial bugs)

For any bug that took more than ~30 minutes to root-cause, or any bug that hit production, write a one-page postmortem to `docs/agents/postmortems/<date>-<slug>.md`:

```
# <One-line description>

**Date:** YYYY-MM-DD
**Impact:** <who/what was affected, for how long>
**Root cause:** <one paragraph; the assumption that turned out to be false>
**Why we didn't catch it earlier:** <missing test, missing review, observability gap, etc.>
**Fix:** <link to commit>
**Prevention:** <what changes so this class of bug can't recur>
```

If the root cause exposes an architectural problem (not just a code bug), the postmortem should hand off to `decision-record` — the prevention may be an ADR.

## Anti-patterns this skill guards against

- **Trying fixes without a reproduction.** Each "try" is wasted: you have no way to verify it worked except waiting for the bug to recur.
- **Stopping at the first hypothesis that seems to work.** Sometimes a fix changes the symptom without addressing the cause. The hypothesis must be confirmed by a directed probe, not by "the test passes now."
- **Suppressing the symptom.** `try/catch` that swallows the error. Default value that masks `undefined`. Retry that hides the underlying flake. These are not fixes.
- **Skipping the regression test.** The bug WILL return.
- **Refactoring during the fix.** Two changes in one commit confuse `git blame` later. Land the fix, then refactor separately.
- **Calling debugging done when the symptom goes away.** Did you find the assumption that was wrong? If not, you got lucky, not informed.
- **Burning the entire context on a debugger session that never converges.** If 30+ minutes of probes have produced no narrowing, restart — your hypotheses are likely too broad or the suspect surface too wide.

## Integration with the chain

- **Used standalone** when a bug shows up
- **Invoked from `tdd-loop`** when a RED-phase test fails with an unexpected error mode (test isn't testing what you think it is)
- **Hands off to `tdd-loop`** for the fix + regression test (the fix is itself a slice)
- **Hands off to `decision-record`** when the root cause exposes an architectural problem — the prevention is an ADR

## See also

- `tdd-loop` — implements the fix as a slice; the regression test from Phase 5 is the slice's RED phase
- `decision-record` — captures architectural-level preventions
- `socratic-grill` — use first when the bug is actually a spec ambiguity
- Superpowers' `systematic-debugging` — pattern source
- OMC `trace` — adjacent (causal investigation with competing hypotheses)
