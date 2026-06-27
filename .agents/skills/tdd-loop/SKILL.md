---
name: tdd-loop
description: Red-green-refactor TDD on one vertical slice at a time. Use when user types "/tdd", "let's start building", "implement slice N", "spec is locked", or after write-plan emits "HANDOFF: implementation ready". Do not use for throwaway exploration, prototyping, or documentation-only changes.
disable-model-invocation: true
---

# TDD Loop

**NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.**

Implement one vertical slice at a time using red-green-refactor. The failing test EXISTS before the implementation code does — if you didn't watch the test fail, you don't know it tests the right thing. Anything else is back-filling coverage, which doesn't get the benefits of TDD.

This skill is the implementation engine and the start of the Machine layer. Once `socratic-grill` signs off the Design and `vertical-slice` produces the slice list, every slice goes through `tdd-loop`.

## When to use this skill

**Trigger on:**

- A signed-off Design with a slice list from `vertical-slice` is queued for implementation
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
[Phase 0: decide worktree] → [Phase 0.5: plan inspection — pgroup auto-dispatch + idempotent resume] → RED → GREEN → REFACTOR → 3-stage REVIEW → COMMIT → next slice
```

Each cycle is ONE slice from the slice list. Don't combine slices. Don't skip phases. Don't skip ahead.

Phase 0.5 reads the active plan and, when a pgroup of size ≥2 is ready, hands off to `parallel-dev` for concurrent dispatch — each subagent runs its own Phase 1-6 cycle in its own worktree. Single-slice flows pass through Phase 0.5 unchanged.

### Pre-flight — Environment check

Before any other phase, verify `docs/agents/SYSTEM_CONTEXT.md` exists. If missing, halt with:

> **SETUP REQUIRED:** `docs/agents/SYSTEM_CONTEXT.md` missing. Run `/groundwork` (preferred — one-shot bootstrap) or `/research` (writes the file via Phase 0 reconnaissance) first.

This skill cannot produce reliable output without the environment-binding cache. Do not proceed.

**Staleness check:** Before reading SYSTEM_CONTEXT.md, run the staleness-check protocol per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md). If stale, emit the banner and proceed with a clear `[stale]` annotation on any inferences drawn from the cache. This skill is a READER — only `prior-art-research` Phase 0 writes SYSTEM_CONTEXT.md.

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

**Editing this plugin's own `hooks/` or `skills/` in this repo?** The installed plugin copy is what runs at session time; an edit to a hook or skill in the checkout takes effect only after the plugin reinstalls and reloads. Expect the previously-installed behavior mid-slice — verify against the installed version before treating a stale hook/skill as a bug in your new code.

State the decision in one line before Phase 1: e.g., `Phase 0: creating worktree at ../skills-slice-1 (slice is multi-commit; currently on main).` or `Phase 0: proceeding in current tree (single-commit trivial slice).`

If the decision is "yes," hand off to `using-worktrees` now; resume Phase 1 in the returned `cwd`.

### Phase 0.5 — Plan inspection: pgroup auto-dispatch + idempotent re-invocation

(Runs only when an active plan exists at `docs/agents/plans/<slug>.md`. Skipped when there's no active plan or the plan has been flagged Done.)

Under `/tdd --loop` this phase is each iteration's inspect step — see [§ Loop mode](#loop-mode--tdd---loop) below. Without the flag it runs once, exactly as written here.

**No plan is an expected state, not a degraded one.** A **Quick**-tier chain (see the `**Tier:**` field on the spec — [`docs/agents/references/tier-scale.md`](../../docs/agents/references/tier-scale.md)) deliberately skips `write-plan`; `tdd-loop` then runs the spec's slice order directly, sequentially. Do not emit a setup warning or hunt for a missing plan — fall through to Phase 1. `tdd-loop` itself always runs in full at every tier; the tier scales the *design* that precedes implementation, never the TDD rigor.

**Step 1 — Inspect the active plan.** Read the slice table and parallelization map. Identify the next unfinished pgroup in dependency order. Determine its size.

**Step 2 — Idempotent re-invocation check (the resume mechanic).** Before dispatching anything, inspect the dispatch history:

```bash
git log --grep "Dispatch-id:" --oneline
git log --grep "Slice: #" --oneline
git branch --list 'slice-*'
ls docs/agents/dispatches/ 2>/dev/null
```

For each slice in the next pgroup, classify:

- **Already completed** — there exists a commit (on this branch or merged) tagged with the slice id. Skip it; mark as `DONE` in the plan.
- **In-flight** — a `slice-<N>-*` branch or worktree exists but no completion commit. Treat as `BLOCKED — investigate-manually` and surface to the user (don't auto-resume someone else's mid-edit).
- **Pending** — no trace. Dispatch fresh in Step 3.

This is the pause/resume API: git is the durability layer. Killing the chain mid-pgroup and re-running `tdd-loop` will skip completed slices and re-dispatch only pending ones. **No checkpoint file is consulted** — only git refs and dispatch records (audit log).

**Step 3 — Dispatch decision.**

- **Pgroup size < 2 OR plan absent:** fall through to Phase 1 (sequential single-slice TDD). No dispatch.
- **Pgroup size ≥ 2 AND ALL members are pending:** hand off to `parallel-dev` for concurrent dispatch (one subagent per slice, each in its own worktree per `using-worktrees`). Return to Phase 0.5 Step 4 when all subagents have returned.
- **Pgroup size ≥ 2 AND some members are already DONE:** dispatch only the pending members. Concurrency cap from `parallel-dev` Phase 4 still applies (default 5; opt-in per-pgroup override).

**Step 4 — Status aggregation per the 4-status contract** (canonical semantics in `skills/parallel-dev/SKILL.md` § Return contract):

| Status returned by subagent | tdd-loop's action |
|---|---|
| `DONE` | Mark slice complete in the plan; advance |
| `DONE_WITH_CONCERNS` | Mark slice complete; **emit a warning to the user** with the `notes` field content; append `notes` to the dispatch record at `docs/agents/dispatches/<dispatch-id>.json` |
| `BLOCKED` | Halt the pgroup; surface the **structured BLOCKED message** (`{type, subagent, slice_id, reason, suggested_action}`) to the user; do NOT auto-re-dispatch |
| `NEEDS_CONTEXT` | Re-dispatch the slice with corrected input (typically: a clarification to the spec or a fix to the input contract), up to 2 re-dispatches total (the dispatch contract's amended Part 1 bound). Each re-dispatch requires materially changed input — the dispatcher judges "materially changed" (it composed the original input and can diff it). Unchanged input, or exhausting the bound, escalates immediately as `BLOCKED` with `suggested_action: "edit-spec-and-redispatch"` |

**Step 5 — Loop or descend.**

- If the pgroup completed cleanly (all `DONE` or `DONE_WITH_CONCERNS`): advance to the next pgroup; re-enter Step 1.
- If any slice returned `BLOCKED`: halt. User decides next steps. Phase 0.5 exits; sequential phases (1-6) do NOT run for the halted pgroup.
- If you've drained all pgroups in the active phase: evaluate the phase's acceptance gate (per plan). On gate-pass, advance to the next phase's first pgroup. On gate-fail, halt and surface the gate failure.

**Step 6 — Single-slice fallthrough.** When the active plan has no pgroup ≥ 2 ready (or no plan at all), Phase 0.5 produces no dispatches and `tdd-loop` proceeds to Phase 1 against the next single slice. Important regression-test invariant: Phase 0.5 MUST no-op cleanly on single-slice plans (verified by `tests/dogfood/10-pgroup-dispatch/10b-no-pgroup-control.md`).

**What Phase 0.5 does NOT do:**

- It does not write to dispatch records mid-pgroup — only `parallel-dev` writes, after all subagents return (single-writer invariant).
- It does not read dispatch records *during* chain execution — they are an audit log, not a substrate.
- It does not skip the `using-worktrees` Phase 0 check; each dispatched subagent still gets its own worktree.
- It does not auto-merge concurrent worktrees — merge to main remains sequential with rebase-then-test (per `using-worktrees` Phase 5).

### Phase 1 — RED: write the failing test

Pick the slice. Read its acceptance criteria. Identify the test seam (unit / integration / e2e / manual smoke — already chosen in the spec).

**Confirm fixture identifiers against the live tree before you create the fixture.** Test-fixture identifiers — dogfood scenario numbers, ADR slugs, file indices, sequence suffixes — are confirm-at-implementation values, never the literal the spec or plan wrote. The spec's number is a snapshot that drifts when a sibling slice lands first. Glob the live tree for the next free identifier (e.g. `ls tests/dogfood/ | grep -oE '^[0-9]+' | sort -n | tail -1`, then increment), and use that. If the number the spec named is already taken, the next free identifier wins; do not collide. The rule in one line: confirm against the live tree, never trust the spec literal.

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

### Phase 4 — Three-stage review

Before committing, run THREE independent passes. Skipping any is the most common quality regression after RED/GREEN. Review precedes COMMIT (Phase 5) — never the reverse.

**Pass 4a — Spec-compliance review:** open the slice's spec entry side-by-side with the diff. For each acceptance criterion, name the exact line(s) of code or test that satisfies it. If you can't, the slice doesn't meet the spec — return to GREEN (or revise the spec if the criterion is now wrong). The output is one bullet per criterion mapped to a code reference.

**Pass 4b — Code-quality review:** run the `deep-modules` skill against the new code (already part of REFACTOR; do it again here as a final check before commit). Verify there's no:

- Shallow pass-through layer added without need
- Duplicated logic with a sibling slice's code
- Naming that fights the domain glossary
- Helper that's used in exactly one place and should be inlined

**Pass 4c — Anti-slop review (verify-output):** stage the slice's diff (`git add` the relevant files) and invoke [`verify-output`](../verify-output/SKILL.md). The skill scans for the seven slop heuristics (unjustified comments, defensive validation past trusted boundaries, half-finished implementations, dead code, repeated boilerplate, feature creep, backward-compat shims for unshipped code). 4-status return:

- `DONE` → proceed to Phase 5 COMMIT.
- `DONE_WITH_CONCERNS` → read the concerns, decide deliberately; ANNOTATE mode is the default and does NOT block. Proceed to commit (or fix and re-run if the concerns are worth addressing).
- `BLOCKED` → severe slop found (half-finished impl, unreachable code, declared-and-unused). The commit is halted. Fix the concerns and re-run Pass 4c — the fix attempt is bounded by the failure-triage rule below (one fresh-context attempt, then halt) — OR commit with `--override <ref>` if the stub is intentional and tracked (the override is recorded in the commit message and is `git log`-auditable).
- `NEEDS_CONTEXT` → an ambiguous case the skill couldn't decide. Surface to the user, resolve, re-run.

Pass 4c is invoked in ANNOTATE mode by default. Projects that want stricter enforcement configure `verify-output --gate` in their setup (moderate slop becomes blocking).

If 4a, 4b, or 4c surfaces something material, fix in this slice's commit chain. Don't push the cleanup to "later."

### Phase 5 — COMMIT

Only after all three review passes are clean, commit the slice. One commit per slice (or one commit per (RED, GREEN, REFACTOR) sub-step if your team prefers). The commit must include:

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

### Phase 6 — Check in and advance

After the commit lands (all three review passes were clean), before starting the next slice, ask:

1. Did the slice deliver end-to-end visible value? (If no, the slice was horizontal — flag it)
2. Did any open questions surface during implementation? (If material, take the re-grill edge below — don't absorb the ambiguity, and don't re-run a full grill)
3. Did the implementation reveal an architectural seam the spec missed? (If yes, possible `deep-modules` candidate; possible ADR update)
4. Did an unexpected failure mode surface during RED that you didn't predict? (If yes, hand off to `systematic-debugging` rather than absorbing it.)

Then move to the next slice in dependency order. If multiple AFK slices are ready, `parallel-dev` can dispatch them concurrently (each into its own worktree via `using-worktrees`).

## The re-grill edge — when implementation contradicts the spec

Sometimes the slice is fine but the spec decision underneath it isn't — RED can't express the acceptance criterion, GREEN reveals an unstated constraint, or review surfaces a contradiction. Don't guess a reading and don't absorb it: halt the slice through the re-grill edge.

**Halt.** Emit `BLOCKED` with `suggested_action: "re-grill"` and a learning payload of exactly these fields:

- `blocked_slice` — the slice number
- `blocked_decision` — the spec decision at fault, quoted verbatim
- `expected_vs_observed` — what the spec implied vs what implementation revealed
- `evidence` — test output / file references
- `attempted_resolutions` — what was tried before halting
- `scope_classification` — `spec-wide` or `slice-local`; governs sibling handling per `parallel-dev`'s halt-scope rule
- `salvaged_sibling_results` — finished sibling outcomes worth feeding the round (empty when running sequentially)

**Surface it as a fixed-format halt block** — what blocked, the payload summary, and exactly two exits:

```
## Slice halted — re-grill required

Blocked decision: <quoted from the spec>
<payload summary, all 7 fields>

Exits: (1) inline spec patch (minor, per the grill's blast-radius rule)
       (2) ADR escalation (substantial)
```

**Resolve and resume.** Invoke `socratic-grill`'s scoped re-grill round with the payload. When it returns — patched spec or amended ADR — the halted slice re-enters RED against the clarified criterion.

## The failure-triage rule — when verification fails

Any verification failure — an unexpected RED in Phases 2–4 (a test that should pass doesn't, or a previously-green test breaks) or a verify-output `BLOCKED` in Pass 4c — hits triage before anything is retried. Classify on cheap signals (the shape of the failure text, the failure history) — never on a deep investigation; investigation is what the structural route is for. Three routes:

- **Transient-shaped** (error-shaped output with no assertion mismatch — flaky timing, environment hiccup, nondeterministic ordering): exactly one fresh-context re-run of the failing step. A second failure means it wasn't transient — re-triage with history; the same-error-twice rule below makes it structural.
- **Structural** (assertion-shaped failure, OR same-error-twice): auto-invoke `systematic-debugging` in fresh context with an evidence payload — the test output, the diff, and the attempted fix. Never blind-retry an assertion failure: identical input produces identical output.
- **Spec-implicated** (the failure traces to a spec decision, not the code): route through the existing re-grill edge above, unchanged — the same 7-field learning payload, the same fixed-format halt block. Triage adds routing in front of the edge, not a new halt surface.

**Same-error-twice rule.** Record each failure's text. On the next failure, string-compare it against the recorded last failure: a repeat is structural — the re-run already proved it isn't transient.

**History-less first failure.** With no recorded failure to compare against, default by shape: assertion-shaped → structural (straight to systematic-debugging); error-shaped → one retry.

**Retry budget.** Each slice gets a retry budget of exactly 2 — a convention, not a tuned optimum (revisit if budgets repeatedly truncate converging fixes). Exhaustion emits `BLOCKED` with a halt payload; never keep cycling past the budget.

**verify-output `BLOCKED` (Pass 4c).** Gets exactly 1 fresh-context fix attempt. The same finding surviving the fix → halt — never a second identical attempt; a surviving finding is the same-error-twice rule firing on a review finding.

## Loop mode — `/tdd --loop`

`/tdd --loop` promotes Phase 0.5 from resume mechanism to iteration driver: point it at the active plan, walk away, and it runs the plan's work-list to a terminal state. Without the flag, none of this section applies — `tdd-loop` runs single-pass Phase 0.5 exactly as written above.

**Driver algorithm.** Each iteration: **inspect** (Phase 0.5's idempotent resume — git refs + the plan, no other state) → **dispatch** the next pending slice or pgroup → **verify** (deterministic assertions → reviewer per `parallel-dev` § Reviewer dispatch → `verify-output` Pass 4c) → **update the run file** → next. Repeat until the plan is done or a halt ends the run. Every slice is dispatched in fresh context — the driver's own context never carries slice work; repo artifacts (spec, plan, run file, git) carry everything between iterations.

**Run file.** Each iteration updates the per-run bookkeeping file defined in [`docs/agents/references/run-file-format.md`](../../docs/agents/references/run-file-format.md) — location, frontmatter fields, halt-report and RUN_SUMMARY formats all live there, never here.

**Iteration ceiling.** Defaults to 2× open slices; `--max-iterations N` overrides. Either way the effective ceiling is recorded in run-file frontmatter (the `iteration_ceiling` field per run-file-format.md), so the run file alone answers how much budget remains.

**Terminal states — exactly two.** `DONE` (plan complete) or `BLOCKED` with a halt report; no third exit — ceiling exhaustion, reviewer block, re-grill, and parked gates all terminate as the second. Run end, in either terminal state, writes the RUN_SUMMARY per run-file-format.md.

**Failure routing.** A verification failure inside the loop hits the failure-triage rule above — its transient / structural / spec-implicated routes are the loop's inner edges. The loop adds no retry rules of its own; budgets and thresholds live in the triage rule only.

### Tiered halt policy

Every HITL gate the loop can reach, classified **park** (write a halt report, queue for the human) or **provisional** (proceed, log for morning ratification):

| Gate | Class | AFK behavior |
|---|---|---|
| Decision gates (HITL-labeled slices, phase acceptance-gate failures) and structured halts (budget exhaustion, reviewer Critical finding) | **Park** | Halt report per run-file-format.md; the run continues on unaffected slices per `scope_classification`, or terminates if spec-wide |
| Re-grill halt (spec-implicated failure) | **Park** | Parks scope per `scope_classification`; re-grill halts **never self-resolve** — halt authority stays human (the Grill 2.0 re-affirmation); the loop writes the halt report and moves to unaffected slices, or terminates when the scope is spec-wide |
| Fixture-ID confirm (Phase 1) | **Provisional** | Proceed gated on green checks; logged in the run file for morning ratification |
| verify-output ANNOTATE-mode concerns (Pass 4c `DONE_WITH_CONCERNS`) | **Provisional** | Same — proceed on green checks, logged for ratification |
| Spec-compliance review (Pass 4a) | **Provisional** | Same — proceed on green checks, logged for ratification |
| Version-bump confirm | **Park** | Release-facing; the human ratifies versioning — never provisional |

### Resume — `/tdd --resume <run-id>`

The morning-after command. It reads the run file and checks the **session-identity** field FIRST, before touching anything else in the file (the #15047 guard per run-file-format.md — a mismatch halts with the file untouched). Then it finds the parked slices, replays each halt report as seed context, and re-enters RED on the parked slice against the resolved decision. Resume-by-inspection: no state beyond the run file + git.

## Anti-patterns this skill guards against

If you find yourself thinking the left column, STOP — the right column is the reality.

| Thought | Reality |
|---|---|
| "I'll add tests after I see if this works." | That's back-filling, not TDD. Tests drive the design — write them first. |
| "I'll mock the unit so the test is simple." | Mock collaborators, not the unit under test. A test that passes on mock setup is testing the mock. |
| "I'll build this to handle batch input later." | Handle only the case the current test demands. Add cases as future tests demand them. |
| "The test obviously passes — I'll skip the failing run." | A test never seen failing can pass for the wrong reason. Always watch it fail first. |
| "I'll refactor now while I'm in here." | If the test is red you can't tell what your refactor broke. Get to green, then refactor. |
| "Slice #1 scaffolding and slice #2 can share one commit." | Two slices are two commits, even when one builds on the other. |
| "I'll backfill the tests once the code works." | The most common TDD-failure mode. No production code until a test demands it. |
| "REFACTOR is optional when the code looks fine." | Skipping refactor is how shallow modules accumulate. Run the deep-modules check and make the decision explicit. |

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
- **Terminal:** when the last slice in the plan is GREEN (and verify-output passed), the chain's implementation phase is complete. Emit the release handoff so `release` becomes the next hop:

```
HANDOFF: release ready — all slices GREEN and verify-output clean. Invoke `release` to bump the version, write the CHANGELOG entry + PR body, run the doc-sync audit, and tag-push.
```

## See also

- `draft-spec` — produces the slices this skill consumes
- `decision-record` — locks the architecture this skill implements
- `write-plan` — sequences slices into phases with acceptance gates; defines the order this skill executes in
- `deep-modules` — invoked at the refactor step
- `verify-output` — invoked as Pass 4c, the anti-slop pass of the Phase 4 review (before the Phase 5 commit)
- `parallel-dev` — dispatches parallel TDD loops on independent slices
- [`using-habeebs-skill` § "When sessions grow long — summary-and-flush"](../using-habeebs-skill/SKILL.md) — long tdd-loop runs (20+ slices in one conversation) are the most likely Compress-at-overflow site; flush via the 7-section summary template at [`../using-habeebs-skill/references/session-summary-template.md`](../using-habeebs-skill/references/session-summary-template.md)
- `vertical-slice` — defines what makes a slice implementable
- `references/test-seam-guide.md` — choosing unit vs integration vs e2e
