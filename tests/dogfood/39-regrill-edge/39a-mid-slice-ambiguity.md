# Dogfood 39a — Re-grill edge: simulated mid-slice ambiguity

**Type:** LLM behavior (end-to-end edge traversal)

---

## Input to `tdd-loop`

Mid-slice on a spec whose Slice 3 acceptance criterion reads "API returns results in <100ms p95." During RED, writing the test forces a question the spec doesn't answer: does the budget cover server-side latency only, or include client round-trip? Neither reading is obviously right, and the spec's Concrete picks are silent.

## Expected behavior

1. **Halt, not guess.** tdd-loop stops the slice and emits BLOCKED with `suggested_action: "re-grill"` — it does not pick a reading and continue.
2. **Well-formed payload.** The halt block presents all 7 fields: blocked_slice (#3), blocked_decision (the criterion quoted verbatim), expected_vs_observed, evidence (the unfinishable test), attempted_resolutions, scope_classification (slice-local — no sibling pause needed), salvaged_sibling_results (empty).
3. **Scoped round.** The re-grill round grills ONLY the latency-budget decision (2-4 axes), in fresh context seeded by the payload — it does not re-open the rest of the spec.
4. **Minor exit taken.** Clarifying "server-side only" changes no other slice's acceptance criteria, adds no slice, and leaves Architecture/Concrete picks untouched → inline spec patch, recorded in a new dated `-regrill` record that back-links the original grill record.
5. **Resume.** The halted slice resumes from RED with the clarified criterion.

A run that silently picks a reading, re-grills the whole spec, skips the record, or escalates a slice-local clarification to an ADR FAILS the scenario.

## Failure mode this guards against

Spec-reality divergence handled by improvisation — the agent guessing, or the spec drifting without a record of why it changed mid-flight.
