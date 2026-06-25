# Phase Gate Examples

A phase gate is the contractual binary criterion that must be true before the next phase starts. Most planning failures trace to soft, internal-only, or tautological gates. This reference shows the line between a gate that holds the plan together and a gate that's decorative.

## The two tests

A gate is acceptable only if BOTH tests pass:

1. **Binary in production.** You can answer "is this true?" with yes/no, measured against production (or production-equivalent) signals. Not "we feel good about it."
2. **User-observable or system-observable.** Either the user notices the outcome, or a monitoring system observes it. Internal-process events (tests pass, code reviewed) don't count.

## Good gates (use these as templates)

| Gate                                                                                                  | Why it works                                                              |
|-------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------|
| "100% of canary cohort can create + reload a doc with zero data-loss reports over 48h."               | Binary; production-measured; user-observable.                             |
| "p95 read latency < 80ms on production traffic for a rolling 24h window."                             | Binary; production-measured; system-observable; SLO-aligned.              |
| "All FK migrations applied; zero queries hitting the old schema for 7 days (via query log audit)."   | Binary; verifiable from logs; closes the migration phase decisively.       |
| "Rate limiter active on 100% of traffic; rate-limit-rejection rate < 0.5% over 72h."                  | Binary; production signal; threshold is contractual.                       |
| "Feature flag `yjs_enabled` removed from codebase; only the new path remains."                        | Binary; code-observable; closes a one-way-door phase definitively.         |
| "Search returns results in < 200ms p95 for the top 1000 queries by frequency, measured via RUM."     | Binary; user-facing; performance SLO.                                     |

## Bad gates (reject these — they don't gate anything)

| Bad gate                                          | Why it fails                                                | How to fix                                                                                       |
|---------------------------------------------------|-------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| "All tests pass."                                 | Already required per slice. Doesn't gate the *phase*.       | Replace with a production signal: "Feature deployed; no error-rate regression vs prior 7d."     |
| "Code reviewed."                                  | Process event, not outcome. Says nothing about correctness. | Replace with the outcome the code enables: "User X can do Y in production."                      |
| "Tasks done."                                     | Tautological — phase contains the tasks; doneness is circular. | Restate as the *result* of the tasks, not the tasks themselves.                                |
| "Team feels confident."                           | Not binary; not measurable.                                 | Find the signal that grounds the confidence — "p99 errors < 0.1%" or similar.                    |
| "Documentation updated."                          | Process. Doesn't gate the user-visible outcome.             | Drop, or move to "definition of done" for each slice. Phase gate is a higher bar.                |
| "Slack approval from PM."                         | Social, not measurable. Approval is necessary but not the gate. | Combine: PM approval is a *prerequisite*; the gate is the production signal post-approval.    |
| "Performance is acceptable."                       | Not binary.                                                 | Replace with the SLO: "p95 < 200ms" or whatever the spec demands.                                |

## Gate patterns by phase shape

### "Land it" phase (first real user value)
- Gate: A specific user journey works end-to-end on production for a canary cohort, observed in logs.
- Example: "A user in the canary cohort can complete the new signup flow; conversion rate ≥ prior baseline."

### "Scale it" phase (extend to full traffic)
- Gate: Production signal on full traffic vs. prior baseline.
- Example: "100% of signups now go through the new flow; conversion ≥ prior 7d baseline."

### "Migrate it" phase (replace the old path)
- Gate: Old path receives zero traffic; new path is fully active.
- Example: "Old `/api/v1/save` endpoint receives 0 requests for 7 days; ready to delete."

### "Harden it" phase (operational maturity)
- Gate: SLO-aligned production signal sustained over a contractual window.
- Example: "p95 latency < SLO target on rolling 24h window; error budget burn rate < 2x."

### "Clean it up" phase (remove the migration scaffolding)
- Gate: Code-observable. The scaffolding is gone.
- Example: "Legacy code path deleted; feature flag removed; no references to the old name remain."

## Anti-pattern: the "definition of done" disguised as a gate

If your gate reads like a slice's acceptance criteria, it's not a phase gate — it's a slice criterion that's been promoted out of habit. Phase gates are at least one level of aggregation above slices.

Test: if you delete the gate, can the phase still be "done"? If yes (because each slice's individual gates compose into doneness), then your phase gate is decorative. Phase gates exist to gate the *transition* to the next phase, not to ratify the current one.

## When a phase legitimately has no rollback

Some phases are one-way doors — once shipped, you can't revert (data migrations, schema changes, certain external integrations). That's fine, but the plan must declare it explicitly:

```
Rollback hook: ONE-WAY DOOR — no rollback after gate passes.
  Compensating control: Gate raised — extra canary phase + executive sign-off before gate criteria evaluated.
```

A silent one-way door is worse than an explicit one-way door. The compensating control (higher gate, executive sign-off, extended canary) is how you trade off the risk.

## When the plan can't define a gate

If a phase genuinely has no observable gate (rare — usually means the phase shouldn't exist as its own phase), one of:

1. **Fold it forward** into the next phase whose gate covers both.
2. **Fold it backward** into the previous phase.
3. **Replace it** with a "research / spike" task that's run via `prior-art-research`, not as part of the implementation plan.

A phase with no gate is not a phase — it's a holding pen for work that doesn't fit.
