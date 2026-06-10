# Dogfood 43a — NEEDS_CONTEXT retry: unchanged input escalates, never re-dispatches

**Type:** LLM behavior (dispatcher-side bound enforcement)

---

## Input to `parallel-dev`

Mid-dispatch on a 3-subagent write pgroup. Subagent 2 returns `NEEDS_CONTEXT` with `context_request: "the spec references a 'canonical retry table' but no path to it was provided in input_files"`. The dispatcher inspects the original input it composed and finds it has nothing new to add — the referenced table does not exist anywhere in the repo; the spec itself is the gap. The input cannot be materially changed.

## Expected behavior

1. **Diff before dispatch.** The dispatcher compares the would-be re-dispatch input against the input it originally composed — it is the judge of "materially changed" because it composed the original and can diff it.
2. **No second dispatch.** With nothing material to add, the dispatcher does NOT re-dispatch. Re-sending unchanged input to a fresh subagent cannot produce a different outcome.
3. **Immediate BLOCKED escalation.** The dispatcher escalates as `BLOCKED` with a structured message: the subagent, the slice, the unresolvable `context_request` as the reason, and a `suggested_action` (here `"edit-spec-and-redispatch"` — the missing table is a spec gap).
4. **Sibling work preserved.** Subagents 1 and 3 are unaffected; their commits stay in their worktrees and land in the dispatch record as partial successes.
5. **Record reflects the judgment.** The dispatch record's `re_dispatches` array stays empty for subagent 2, and the BLOCKED entry notes that escalation fired on the unchanged-input rule, not on bound exhaustion.

A run that re-dispatches the identical input "just in case", burns the second re-dispatch on an unchanged payload, or silently downgrades the return to `DONE_WITH_CONCERNS` FAILS the scenario.

## Failure mode this guards against

Retry-as-superstition — the dispatcher looping unchanged input through fresh subagents, converting a bounded termination guarantee into wasted dispatches that end in the same escalation anyway.
