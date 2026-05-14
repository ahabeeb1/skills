# Chain postmortems

Per [ADR-0011](../adrs/0011-error-analysis-cadence.md), this directory holds error-analysis records on real habeebs-skill chain runs that went sideways. The structure follows Hamel Husain + Shreya Shankar's [LLM Evals FAQ](https://hamel.dev/blog/posts/evals-faq/) transition-failure-matrix shape: name where the chain went off the rails so the failure category can feed back into `verify-output`'s ruleset, a SKILL.md anti-pattern list, or a new ADR.

## When to write a postmortem

Postmortems are *not* status updates. They are written when:

- A chain run produced a wrong-shaped output (spec missed a sub-problem; grill missed a question; ADR locked something later proven wrong)
- A slice landed with concerns (`verify-output` returned `DONE_WITH_CONCERNS`; behavior diverged from spec)
- A dispatched subagent BLOCKED unexpectedly
- The user says "that didn't work" / "this chain went sideways"
- A previously-passing dogfood scenario started failing

Postmortems are *not* required after every chain run. The cadence is event-driven: incident → postmortem. Hamel's aspirational 100/cycle is unreachable for an OSS plugin; 10-20/quarter is load-bearing.

## File naming

`YYYY-MM-DD-<short-slug>.md` — e.g., `2026-05-12-missed-categories-phase-2.5-critic.md`. The date is when the incident *was discovered*, not when the chain originally ran (retrospective backfills are fine and use the discovery date).

## Template structure

Every postmortem fills these sections in order:

### 1. Summary

One paragraph. What happened and why it mattered. Reader should be able to act on the postmortem after reading this paragraph alone if they trust the analysis.

### 2. User prompt that triggered the chain

The literal user input (or a faithful paraphrase if the original is lost). Anchors the incident to a real trigger surface — what would the chain have to detect to catch this earlier?

### 3. Expected outcome

What the user (or future-author) expected the chain to do. Be concrete: "produce a 4-sub-problem decomposition covering X, Y, Z, W" not "do good research."

### 4. Actual outcome

What actually happened. Same level of concreteness. The gap between Expected and Actual is the failure surface.

### 5. Transition-failure matrix

The core diagnostic. A small table or prose grid mapping:

- **Last successful phase / step:** the phase that produced the right output (or "Phase 0" if the chain mis-fired from the start)
- **First failure phase / step:** the phase where the wrong-shaped output entered the chain
- **What the failure phase missed:** the specific category or sub-problem it should have surfaced

This is the load-bearing schema. If you can't fill the matrix, the postmortem isn't ready — re-examine the trace.

### 6. Failure category

One named category in 3-7 words. Examples: "missed-architectural-categories", "stale-system-context-poisoning", "subagent-context-divergence", "description-trigger-collision". The category is what will be cited by future authors as the named anti-pattern.

### 7. Fix applied (or "left open")

What was done to address the incident. "Added Phase 2.5 category-completeness critic in v1.6.0" is a fix. "Left open — revisit at v1.11.0 if recurs" is also valid.

### 8. v1.X.Y+ candidate rule

If this failure category should become a `verify-output` rule, a SKILL.md anti-pattern bullet, or a new ADR — name it here with target release. Example: "`verify-output` rule candidate: detect SYSTEM_CONTEXT staleness > 7 days at Phase 0 read; target v1.11.0."

### 9. Notes / trace fidelity

Optional. If the postmortem is retrospective (incident occurred well before discovery), tag the trace as `[trace-from-memory]` rather than `[full-trace-reviewed]` so readers know how to weight the analysis.

## Retrospective entries

Backfilling a postmortem for an incident that happened months ago is OK and encouraged when the lesson is still load-bearing. Tag the trace fidelity as `[trace-from-memory]` and prepend the file's Summary with `**Retrospective — recorded YYYY-MM-DD; incident occurred YYYY-MM-DD.**`

## Pre-merge dogfood

The dogfood scenario at [`tests/dogfood/15-postmortem-structure/`](../../../tests/dogfood/15-postmortem-structure/) asserts that every file in this directory other than this README and `.gitkeep` has the required sections (Summary / User prompt / Expected / Actual / Matrix / Category / Fix / Candidate rule). The structure check is the minimum bar; quality is human-graded.
