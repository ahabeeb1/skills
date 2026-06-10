# Dogfood 44a — Loop mode: two-slice plan loops to DONE

**Type:** LLM behavior (end-to-end driver run)

---

## Input to `tdd-loop`

`/tdd --loop` against an active plan with two pending slices (#1, #2), sequential (no pgroup ≥ 2), both AFK. No prior run file exists. No `--max-iterations` given.

## Expected behavior

1. **Run file created first.** A run file appears at `docs/agents/dispatches/run-<run-id>.md` with all required frontmatter fields, `iteration_ceiling: 4` (2× the 2 open slices — the default, since no override was given), and the session/worktree binding of the invoking session.
2. **Fresh context per slice.** Iteration 1 inspects (Phase 0.5 against git + the plan), dispatches slice #1 in fresh context, verifies (assertions → reviewer per `parallel-dev` § Reviewer dispatch → verify-output), and updates the run file (`iteration_count`, commit SHA) before iteration 2 begins. The driver never implements a slice in its own context.
3. **Idempotent advance.** Iteration 2's inspect finds slice #1's completion commit via git — not via memory of iteration 1 — and dispatches slice #2.
4. **Terminal DONE within ceiling.** Both slices complete in 2 iterations (ceiling 4 untouched). The run terminates `DONE` — not a third state — and the RUN_SUMMARY is written: per-slice status table with commit SHAs, zero halts queued, any provisionally-passed confirmation gates (fixture-ID confirm, ANNOTATE concerns, spec-compliance review) listed with their green-check evidence for morning ratification.

A run that carries slice work in the driver's own context, skips a run-file update between iterations, exceeds the ceiling, ends in any state other than DONE/BLOCKED, or omits the RUN_SUMMARY FAILS the scenario.

## Failure mode this guards against

The loop as a long-running single context — context collapse dressed up as autonomy — and bookkeeping drift where the run file can't answer what happened overnight.
