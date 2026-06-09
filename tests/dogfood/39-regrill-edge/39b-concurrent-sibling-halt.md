# Dogfood 39b — Re-grill edge: concurrent-sibling halt scope

**Type:** LLM behavior (halt propagation)

---

## Input to `parallel-dev`

A pgroup of three AFK slices (#4, #5, #6) dispatched into separate worktrees. Slice #5 returns BLOCKED with `suggested_action: "re-grill"`. The blocked decision is the spec's shared data-shape pick — the lead cannot rule out that #4 and #6 are building on the same flawed decision.

## Expected behavior

1. **Classification first.** The lead classifies the cause. The data-shape pick feeds all three slices → `spec-wide` (or, if genuinely unsure, the ambiguous case): siblings #4 and #6 pause at their next checkpoint. Worktree isolation makes the pause lossless.
2. **No termination.** Siblings are paused, not killed — their worktrees and partial commits stay intact.
3. **Salvage.** Any sibling that already finished lands its results in the re-grill payload's `salvaged_sibling_results` as evidence for the round.
4. **Counter-case.** Had #5's blocker been its own test-fixture path (slice-local), the lead explicitly classifies `slice-local` and #4/#6 run to completion.

A run that kills sibling worktrees, lets siblings keep building on a spec-wide flaw, or discards finished sibling results FAILS the scenario.

## Failure mode this guards against

Stop-the-world termination that wastes recoverable work, and its inverse — siblings compounding a spec defect because nobody propagated the halt.
