---
name: tdd-loop
description: Red-green-refactor TDD loop, one vertical slice at a time. Writes the failing test FIRST, watches it fail with the expected error, writes the minimal code to make it pass, watches it pass, refactors (invoking deep-modules at the refactor step), and commits. Make sure to use this skill whenever implementation starts — after a spec is locked, after socratic-grill closes open questions, or whenever the user is about to write production code. Especially trigger when the user says "let's start building", "implement slice N", or has a vertical slice queued. Do NOT use for spike/throwaway exploration code, prototyping flows where the design is the deliverable, or for documentation-only changes.
---

# TDD Loop

Implement one vertical slice at a time using red-green-refactor. The whole point is that the failing test EXISTS before the implementation code does — anything else is back-filling coverage, which doesn't get the benefits of TDD.

This skill is the implementation engine of the habeebs-skill chain. Once `decision-record` locks the architecture and the spec has slices ready, every slice goes through `tdd-loop`.

## When to use this skill

**Trigger on:**

- A locked spec from `draft-spec` (or post-`socratic-grill`) is queued for implementation
- The user says "implement slice N" / "start building" / "code this up"
- A bug fix where the bug is understood (write the failing test that exhibits the bug, then fix it)
- Adding new behavior to a tested module

**Do NOT trigger on:**

- Spike / throwaway exploration code (use `prototype` patterns instead — the design IS the deliverable, not the code)
- Refactoring with no behavior change (use `deep-modules` directly)
- Documentation-only changes
- Configuration tweaks with no logic

## The core loop

```
RED → GREEN → REFACTOR → COMMIT → next slice
```

Each cycle is ONE slice from the spec. Don't combine slices. Don't skip phases. Don't skip ahead.

### Phase 1 — RED: write the failing test

Pick the slice. Read its acceptance criteria. Identify the test seam (unit / integration / e2e / manual smoke — already chosen in the spec).

**Write the test file FIRST.** Before any production code. Before any scaffolding for the production code. The test must:

1. Express ONE concrete acceptance criterion (one assertion per test — or close to it)
2. Reference the not-yet-existing production code (`import { thingThatDoesntExist } from './thing'`)
3. Specify the expected behavior — not how the implementation will achieve it
4. Use the test runner's standard naming (`describe`/`it`, `test_*`, `it_should_*`, etc.)

Run the test. **Watch it fail.** Verify the failure mode is what you expected:

- File not found / import error → expected at the start of a new module
- Function not defined → expected when you've imported but not implemented
- AssertionError / expectation mismatch → expected when the implementation exists but is wrong
- Wrong error → STOP. Your test isn't testing what you think it is. Fix the test before proceeding.

### Phase 2 — GREEN: minimal code to pass

Write the MINIMUM production code that makes the test pass. Resist:

- Building infrastructure not needed by this test ("I'll need a builder pattern eventually" → no, you don't, not yet)
- Generalizing prematurely ("this could handle 5 cases" → no, handle the one case the test demands)
- Adding error handling not specified by the test
- Adding logging / observability before the slice that adds them

The shape of "minimal" depends on the test. A unit test for a pure function → write that function. An integration test for an HTTP endpoint → write the route handler, the smallest valid response.

Run the test. **Watch it pass.** If multiple tests, run the whole suite — make sure nothing broke.

### Phase 3 — REFACTOR: deepen modules, kill duplication

Now the test passes. Now you refactor — and only now.

**Invoke `deep-modules`** (the skill, or its principles if the skill isn't loaded): check the new code for shallowness, pass-through layers, duplicated logic, names that fight the domain glossary.

If you find issues:
- Apply the smallest improvement that addresses the friction
- Run the tests after each change to verify nothing broke
- Stop refactoring when the next change feels speculative — refactoring isn't infinite

If the code is already clean, skip the refactor. Don't refactor for the sake of refactoring.

### Phase 4 — COMMIT

Commit the slice. One commit per slice (or one commit per (RED, GREEN, REFACTOR) sub-step if your team prefers). The commit must include:

- The test file(s)
- The production code
- Any necessary new test fixtures / config

Commit message format suggestion:

```
<slice-tag>: <one-line description>

Slice #N from spec at <spec-path>.

What's verified by tests:
- <criterion 1>
- <criterion 2>

What's NOT in this slice (and that's OK):
- <thing intentionally deferred>
```

### Phase 5 — Check in and advance

Before starting the next slice, ask:

1. Did the slice deliver end-to-end visible value? (If no, the slice was horizontal — flag it)
2. Did any open questions surface during implementation? (If yes, capture them — re-run `socratic-grill` if material)
3. Did the implementation reveal an architectural seam the spec missed? (If yes, possible `deep-modules` candidate; possible ADR update)

Then move to the next slice in dependency order. If multiple AFK slices are ready, `parallel-dev` can dispatch them concurrently.

## Anti-patterns this skill guards against

- **Writing code before tests.** "I'll add tests after I see if this works." This is back-filling, not TDD. The whole point is using tests to drive the design.
- **Mocking the unit under test.** Mock its collaborators, not the thing you're verifying. If the test passes only because of how the mock is set up, the test is testing the mock.
- **Premature generalization.** "I'll need this to handle batch input later." No. Handle the case the current test demands. Add cases as future tests demand them.
- **Skipping the watch-it-fail step.** A test that's never failed could be silently passing for the wrong reason (typo in the assertion, never ran the failing case). Always observe failure.
- **Refactoring before green.** If the test is failing, you can't tell whether your refactor broke something. Get to green, then refactor.
- **Combining slices into one big commit.** If slice #1 ships some scaffolding and slice #2 uses it, those are still two commits.
- **Backfilling tests after implementation.** This is the most common TDD-failure mode. The discipline is: NO production code until a test demands it.
- **Treating REFACTOR as optional.** Skipping refactor consistently is how shallow modules accumulate. Run the deep-modules check even if you decide not to change anything — the decision should be explicit.

## When the loop breaks down

These are signs the slice is wrong, not that TDD is wrong:

- **You can't think of a test that drives the slice.** The slice is probably architectural ("design the auth system"). Decompose further, or move it to spec/grill.
- **The test passes immediately on a fresh run.** Either the production code already exists (slice is duplicated work) or the test is wrong (not actually testing anything). Investigate.
- **Multiple tests pass at once after writing minimal code.** Good problem to have, but verify each test actually depends on the code you wrote, not on something else.
- **The refactor reveals the architecture is fundamentally off.** Stop. Don't refactor your way into a different architecture. Hand back to `socratic-grill` or `prior-art-research`.

## Integration with the chain

- **Upstream:** `decision-record` locks the ADR; `draft-spec` produces slices in dependency order
- **Mid-loop:** `deep-modules` is invoked at the REFACTOR step
- **Parallel dispatch:** `parallel-dev` runs AFK slices concurrently
- **Downstream:** as slices complete, the spec status moves from "In-progress" → "Done"

## See also

- `draft-spec` — produces the slices this skill consumes
- `decision-record` — locks the architecture this skill implements
- `deep-modules` — invoked at the refactor step
- `parallel-dev` — dispatches parallel TDD loops on independent slices
- `vertical-slice` — defines what makes a slice implementable
- `references/test-seam-guide.md` — choosing unit vs integration vs e2e
