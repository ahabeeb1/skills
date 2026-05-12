---
name: tdd-loop
description: Red-green-refactor TDD loop, one vertical slice at a time. Writes the failing test FIRST, watches it fail with the expected error, writes the minimal code to make it pass, watches it pass, refactors (invoking deep-modules at the refactor step), runs two-stage review (spec compliance + code quality), and commits. Make sure to use this skill whenever implementation starts — after a spec is locked, after socratic-grill closes open questions, or whenever the user is about to write production code. Especially trigger when the user says "let's start building", "implement slice N", or has a vertical slice queued. Do NOT use for spike/throwaway exploration code, prototyping flows where the design is the deliverable, or for documentation-only changes.
next-skills: [deep-modules, parallel-dev, systematic-debugging, decision-record]
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
[Phase 0: decide worktree] → RED → GREEN → REFACTOR → 2-stage REVIEW → COMMIT → next slice
```

Each cycle is ONE slice from the spec. Don't combine slices. Don't skip phases. Don't skip ahead.

### Pre-flight — Environment check

Before any other phase, verify `docs/agents/SYSTEM_CONTEXT.md` exists. If missing, halt with:

> **SETUP REQUIRED:** `docs/agents/SYSTEM_CONTEXT.md` missing. Run `/groundwork` (preferred — one-shot bootstrap) or `/research` (writes the file via Phase 0 reconnaissance) first.

This skill cannot produce reliable output without the environment-binding cache. Do not proceed.

### Phase 0 — Decide whether to run in a worktree

Worktrees are valuable when they isolate concurrent or multi-commit work — they're overhead when they don't. Apply this checklist BEFORE writing the failing test:

**Invoke `using-worktrees` (auto) when ANY of:**

- This slice is one of a `parallel-dev` AFK batch (worktree is mandatory; parallel-dev already enforces this)
- The slice is expected to take **2+ commits** (typical for any feature work that touches more than one file)
- The user is currently on `main` / `master` / the default branch (don't pile feature commits onto the trunk)
- The source checkout has uncommitted changes for unrelated work (worktree prevents accidental cross-contamination)
- The spec marks the slice as touching infrastructure or migrations (the worktree's clean-baseline check is high-value insurance)

**Skip the worktree (proceed in current tree) when ANY of:**

- The slice is a **single-commit trivial change** (one file, one assertion, mechanical)
- This is a spike or throwaway exploration (the design IS the deliverable; commits don't matter)
- A worktree was already created upstream (parallel-dev, using-worktrees standalone) — you're already in it; don't nest
- The user has explicitly opted out ("don't make a worktree", "just work here")
- The runtime can't create worktrees (some sandboxed environments) — fall back, log it

**When in doubt, prefer worktree.** The cost of creating one is ~10 seconds; the cost of polluting the trunk or losing partial work to a race is much higher.

State the decision in one line before Phase 1: e.g., `Phase 0: creating worktree at ../skills-slice-1 (slice is multi-commit; currently on main).` or `Phase 0: proceeding in current tree (single-commit trivial slice).`

If the decision is "yes," hand off to `using-worktrees` now; resume Phase 1 in the returned `cwd`.

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

### Phase 5 — Two-stage review

Before declaring the slice complete, run TWO independent passes. Skipping either is the most common quality regression after RED/GREEN.

**Pass 5a — Spec-compliance review:** open the slice's spec entry side-by-side with the diff. For each acceptance criterion, name the exact line(s) of code or test that satisfies it. If you can't, the slice doesn't meet the spec — return to GREEN (or revise the spec if the criterion is now wrong). The output is one bullet per criterion mapped to a code reference.

**Pass 5b — Code-quality review:** run the `deep-modules` skill against the new code (already part of REFACTOR; do it again here as a final check before commit). Verify there's no:

- Shallow pass-through layer added without need
- Duplicated logic with a sibling slice's code
- Naming that fights the domain glossary
- Helper that's used in exactly one place and should be inlined

If 5a or 5b surfaces something material, fix in this slice's commit chain. Don't push the cleanup to "later."

### Phase 6 — Check in and advance

After passing both review stages, before starting the next slice, ask:

1. Did the slice deliver end-to-end visible value? (If no, the slice was horizontal — flag it)
2. Did any open questions surface during implementation? (If yes, capture them — re-run `socratic-grill` if material)
3. Did the implementation reveal an architectural seam the spec missed? (If yes, possible `deep-modules` candidate; possible ADR update)
4. Did an unexpected failure mode surface during RED that you didn't predict? (If yes, hand off to `systematic-debugging` rather than absorbing it.)

Then move to the next slice in dependency order. If multiple AFK slices are ready, `parallel-dev` can dispatch them concurrently (each into its own worktree via `using-worktrees`).

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

- **Upstream:** `decision-record` locks the ADR; `draft-spec` produces slices in dependency order; `write-plan` sequences slices into phases with acceptance gates (the plan, when present, is the authoritative slice order — supersedes spec-order for execution)
- **Mid-loop:** `deep-modules` is invoked at the REFACTOR step
- **Parallel dispatch:** `parallel-dev` runs AFK slices concurrently, dispatching pgroups defined by `write-plan`
- **Downstream:** as slices complete, mark the slice "Done" in the plan; when all slices in a phase are done, evaluate the phase gate before starting the next phase's slices

## See also

- `draft-spec` — produces the slices this skill consumes
- `decision-record` — locks the architecture this skill implements
- `write-plan` — sequences slices into phases with acceptance gates; defines the order this skill executes in
- `deep-modules` — invoked at the refactor step
- `parallel-dev` — dispatches parallel TDD loops on independent slices
- `vertical-slice` — defines what makes a slice implementable
- `references/test-seam-guide.md` — choosing unit vs integration vs e2e
