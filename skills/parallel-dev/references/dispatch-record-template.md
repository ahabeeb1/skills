# Parallel Dispatch Record

Use this template to capture each `parallel-dev` invocation. Saves to a workspace log so future calibration is possible.

---

# Parallel Dispatch: [Batch name]

**Date:** YYYY-MM-DD
**Invoker:** [`prior-art-research` Deep mode | `vertical-slice` AFK group | user `/parallel`]
**Units dispatched:** [N]
**Outcome:** [SUCCESS | PARTIAL | FAILED]

## Independence verification (Phase 2)

| Check | Result |
|---|---|
| File overlap | None / [list] |
| State dependency | None / [list] |
| Resource contention | None / capped at [N] / [list] |
| Ordering semantics | Independent / [list] |
| Implicit shared state | None / [list] |

[Notes on any concerns or close calls.]

## Subagent specs

### Subagent 1 — [Name]

- **Task:** [...]
- **Input:** [...]
- **Output location:** [path]
- **Verification:** [test command / file check]

### Subagent 2 — [Name]

[Same shape]

### ... (continue for N subagents)

---

## Results

| # | Name | Status | Duration (ms) | Tokens | Output |
|---|---|---|---|---|---|
| 1 | [...] | ✅ | [...] | [...] | [path] |
| 2 | [...] | ✅ | [...] | [...] | [path] |
| 3 | [...] | ❌ | [...] | [...] | failed — [reason] |
| ... | | | | | |

**Aggregate stats:**
- Total wall time: [max of durations]
- Sequential-equivalent time: [sum of durations]
- Parallelism gain: [sequential / parallel] x

## Re-dispatches

If any subagent failed, document the re-dispatch:

| # | Original failure | Re-dispatched as | Result |
|---|---|---|---|
| 3 | [...] | sequential, simpler spec | ✅ |

## Verification of aggregate

- [ ] Tests pass after merge
- [ ] No subagent output contradicts another
- [ ] Aggregate result matches the batch's intent

## Lessons

[Any calibration notes — was this parallel dispatch worth it? Were there independence misses? Anything to avoid next time?]
