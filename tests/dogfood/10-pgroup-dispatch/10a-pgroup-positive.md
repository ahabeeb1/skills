# Dogfood 10a — Pgroup dispatch positive

**Type:** Positive (3-slice plan with one ≥2-member pgroup)
**Expected verdict:** Pgroup-1A dispatches in same turn; sequential continuation; dispatch record written

---

## Synthetic plan (input to `tdd-loop`)

A toy plan at `docs/agents/plans/dogfood-10a-toy.md` (created for this test, NOT a real product plan):

```
| ID | Name                       | Label         | Phase | pgroup    | Blocked by | Est  |
|----|----------------------------|---------------|-------|-----------|------------|------|
| #1 | Write file A               | AFK:full-auto | 1     | pgroup-1A | —          | 0.1d |
| #2 | Write file B               | AFK:full-auto | 1     | pgroup-1A | —          | 0.1d |
| #3 | Reference both files in C  | AFK:full-auto | 2     | pgroup-2A | #1, #2     | 0.1d |
```

Slices #1 and #2 are explicitly independent (different file paths, no shared state). Slice #3 depends on both.

## Expected `tdd-loop` Phase 0.5 behavior

**Turn 1:**
- Phase 0.5 Step 1: reads plan, identifies next unfinished pgroup as `pgroup-1A` with size 2
- Phase 0.5 Step 2 (idempotent check): `git log --grep "Dispatch-id:"` returns no dispatches; `git branch --list 'slice-*'` returns no slice branches; classifies #1 and #2 as Pending
- Phase 0.5 Step 3: pgroup size ≥2, all pending → dispatch via `parallel-dev`
- `parallel-dev` Phase 4: dispatches subagent A (slice #1, worktree A, branch slice-1-a) and subagent B (slice #2, worktree B, branch slice-2-b) **in the same turn** (single Agent tool message with two spawn requests)
- Each subagent runs its own Phase 1-6 cycle in its worktree
- Both return `STATUS: DONE` with commit SHAs
- Phase 0.5 Step 4: aggregates statuses; both DONE → mark slices complete in plan
- Phase 0.5 Step 5: pgroup-1A drained → advance to pgroup-2A (which contains only #3)
- Phase 0.5 Step 6: pgroup-2A is single slice → fall through to Phase 1 sequentially against slice #3

**Turn 2 (sequential after pgroup-1A completed):**
- Slice #3 proceeds through standard Phase 1-6 (RED-GREEN-REFACTOR-REVIEW-COMMIT)

**Side effect — dispatch record:**
- `docs/agents/dispatches/<dispatch-id>.json` written by `parallel-dev` after both subagents return
- Record contains: `dispatch_id`, `invoker: "tdd-loop-phase-0.5"`, `plan_ref: "dogfood-10a-toy:pgroup-1A"`, `concurrency_used: 2`, both subagents' returns with statuses, durations, tokens, commit_shas
- File is **not read** during the rest of the chain — audit log only

## Pass criteria

- [ ] Slices #1 and #2 dispatch in the same `tdd-loop` turn (verifiable: single Agent-tool-call message with both spawn requests)
- [ ] Slice #3 does NOT start until both #1 and #2 have returned
- [ ] `docs/agents/dispatches/<some-id>.json` exists after pgroup-1A completes
- [ ] The dispatch record matches the schema in `skills/parallel-dev/references/dispatch-record-template.md`
- [ ] No skill reads the dispatch record before pgroup-2A completes (audit-only invariant)
- [ ] On a kill-and-resume test (kill `tdd-loop` between Turn 1 and Turn 2, then re-invoke):
  - Phase 0.5 Step 2 detects #1 and #2 are already DONE via `git log --grep`
  - No re-dispatch of #1 or #2 happens
  - Chain resumes with slice #3 directly

## Fail conditions

- **Fail (positive case false negative):** pgroup-1A's slices dispatch sequentially or in separate turns — wiring is broken
- **Fail (idempotency broken):** kill-and-resume re-dispatches completed slices — git-as-durability-layer invariant violated
- **Fail (dispatch record absent or malformed):** the audit trail isn't populated — ADR-0004 Part 2 violated
- **Fail (record read mid-chain):** any skill grep's `docs/agents/dispatches/` during execution — substrate violation

## Why this scenario

This is the canonical "happy path" test for the entire wiring. If 10a fails, the slice didn't ship its core deliverable. Modie reads this output verbatim before slice #8 squash-merge.
