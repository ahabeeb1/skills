# Parallel Dispatch — Contract + Record Template

This file is the canonical contract reference for `parallel-dev` (ADR-0004). It defines:

1. The **input JSON schema** every subagent is dispatched with
2. The **return JSON schema** every subagent must emit (the 4-status contract)
3. The **dispatch record** file shape written at `docs/agents/dispatches/<dispatch-id>.json` after the pgroup completes
4. The **BLOCKED structured message** shape surfaced to the user when a subagent halts a pgroup

Sub-skills that consume `parallel-dev` outputs (today: `tdd-loop` Phase 0.5, `prior-art-research` Deep tier synthesis) MUST honor these schemas. Free-form text returns are non-compliant — the contract is machine-readable.

---

## 1. Subagent input schema

Every dispatched subagent receives:

```json
{
  "dispatch_id": "string — ulid or short hash from parallel-dev Phase 4",
  "subagent_name": "string — name of the agent prompt being invoked (e.g., 'source-fetcher')",
  "task": "string — what to do, 1-3 sentences",
  "input_files": ["string — file paths the subagent reads"],
  "output_path": "string — exact deliverable location, when applicable",
  "constraints": ["string — explicit anti-touches"],
  "verification": "string — how the dispatcher will know success",
  "worktree_path": "string — required for artifact-producing subagents; absent for research-only",
  "branch": "string — required for artifact-producing subagents; absent for research-only",
  "context_preamble": "string — REQUIRED per ADR-0004 Part 3. Full content of docs/agents/SYSTEM_CONTEXT.md, injected so subagents inherit the parent's environment binding (stack, scale envelope, deployment shape, project mode) without re-running Phase 0 reconnaissance."
}
```

**`context_preamble` is mandatory.** A subagent dispatched without it MUST return `STATUS: NEEDS_CONTEXT` with `context_request: "missing context_preamble per ADR-0004"`. The dispatcher fixes the omission on re-dispatch.

---

## 2. Subagent return schema (the 4-status contract)

Every subagent returns exactly one structured response matching this schema:

```json
{
  "status": "DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT",
  "commit_shas": ["string — git SHAs of any commits the subagent made; [] for research-only"],
  "duration_ms": "integer — wall-clock duration from dispatch to return",
  "total_tokens": "integer — total tokens consumed by the subagent",
  "notes": "string — required when status = DONE_WITH_CONCERNS; free-form description of the concern",
  "blocker": "string — required when status = BLOCKED; one-line description of why work could not complete",
  "context_request": "string — required when status = NEEDS_CONTEXT; names the missing input"
}
```

Field requirements per status:

| Status | `notes` | `blocker` | `context_request` |
|---|---|---|---|
| `DONE` | optional | absent | absent |
| `DONE_WITH_CONCERNS` | **required** | absent | absent |
| `BLOCKED` | optional | **required** | absent |
| `NEEDS_CONTEXT` | optional | absent | **required** |

Status semantics are defined canonically in `skills/parallel-dev/SKILL.md` § Return contract.

---

## 3. BLOCKED structured message shape

When a subagent returns `BLOCKED`, the dispatcher surfaces a structured message to the user (NOT free-form text). The dispatcher composes the message from the subagent's return + dispatch context:

```json
{
  "type": "BLOCKED",
  "subagent": "string — subagent_name from the input schema",
  "slice_id": "string — e.g. '#5' from the active plan, when applicable; otherwise null",
  "reason": "string — copy of the subagent's `blocker` field",
  "suggested_action": "edit-spec-and-redispatch | investigate-manually | escalate-to-maintainer"
}
```

The `suggested_action` enum tells the user what kind of intervention helps:

- **`edit-spec-and-redispatch`** — the spec / task instructions were incomplete; user edits and re-runs the chain. Most common.
- **`investigate-manually`** — the blocker is environmental (missing tool, broken dependency, infra issue). User investigates outside the chain.
- **`escalate-to-maintainer`** — the blocker is structural (a habeebs-skill bug, a contract mismatch, an unresolved ADR question). User opens an issue or pings the maintainer.

If the subagent did not surface a `suggested_action` in its return, the dispatcher defaults to `investigate-manually` and notes the absence.

---

## 4. Dispatch record file shape

After a pgroup completes (all subagents have returned), the dispatcher writes one JSON file at:

```
docs/agents/dispatches/<dispatch-id>.json
```

The dispatcher is the **single writer**. No skill reads dispatch records during chain execution. The directory is an audit-only log per ADR-0004 Part 2.

```json
{
  "dispatch_id": "string",
  "invoker": "prior-art-research-deep | tdd-loop-phase-0.5 | vertical-slice-afk-group | user-direct-parallel",
  "started_at": "ISO-8601 timestamp",
  "completed_at": "ISO-8601 timestamp",
  "parent_task": "string — one-line description of why this pgroup ran",
  "plan_ref": "string — plan id + pgroup id, when applicable (e.g., '0004-parallel-subagent-v1.7.0:pgroup-1A')",
  "concurrency_used": "integer — actual concurrency for this dispatch (default 5; may be overridden)",
  "independence_verification": {
    "file_overlap": "none | [list]",
    "state_dependency": "none | [list]",
    "resource_contention": "none | [list]",
    "ordering_semantics": "independent | [list]",
    "implicit_shared_state": "none | [list]"
  },
  "subagents": [
    {
      "name": "string — subagent_name",
      "task": "string — task from input",
      "status": "DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT",
      "commit_shas": ["string"],
      "duration_ms": "integer",
      "total_tokens": "integer",
      "notes": "string | null",
      "blocker": "string | null",
      "context_request": "string | null",
      "worktree_path": "string | null",
      "branch": "string | null"
    }
  ],
  "aggregate": {
    "total_wall_ms": "integer — max(subagent durations)",
    "sequential_equivalent_ms": "integer — sum(subagent durations)",
    "parallelism_gain": "float — sequential / wall",
    "outcome": "SUCCESS | PARTIAL | FAILED"
  },
  "re_dispatches": [
    {
      "original_subagent": "string",
      "original_status": "BLOCKED | NEEDS_CONTEXT",
      "redispatched_at": "ISO-8601 timestamp",
      "result_status": "DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT"
    }
  ]
}
```

### Retention

Dispatch records older than 30 days are eligible for pruning via `/sync` cleanup pass (TODO in v1.8.0+ when the volume actually accumulates). Until then, retain all records — they are the audit trail for `socratic-grill` to use when re-grilling a slice that failed in the past.

### Second record class — loop-run files

`docs/agents/dispatches/` hosts two record classes: the per-pgroup dispatch
JSON above, and per-run loop bookkeeping files
(`run-<run-id>.md`, written by `tdd-loop` loop mode). The run-file format —
frontmatter fields, halt report, RUN_SUMMARY — is defined in
[`docs/agents/references/run-file-format.md`](../../../docs/agents/references/run-file-format.md).

---

## Markdown audit shape (legacy — kept for reference, NOT the authoritative record)

The pre-v1.7.0 markdown dispatch summary remains useful for human-readable audit notes. Generate it from the JSON record above if needed for a PR description or post-mortem:

```
# Parallel Dispatch: [Batch name]

**Date:** YYYY-MM-DD
**Invoker:** [`prior-art-research` Deep tier | `vertical-slice` AFK group | `tdd-loop` Phase 0.5 | user `/parallel`]
**Units dispatched:** [N]
**Outcome:** [SUCCESS | PARTIAL | FAILED]
**Authoritative record:** [`docs/agents/dispatches/<dispatch-id>.json`](../../docs/agents/dispatches/<dispatch-id>.json)

## Independence verification (Phase 2)

| Check | Result |
|---|---|
| File overlap | None / [list] |
| State dependency | None / [list] |
| Resource contention | None / capped at [N] / [list] |
| Ordering semantics | Independent / [list] |
| Implicit shared state | None / [list] |

[Notes on any concerns or close calls.]

## Subagent results

| # | Name | Status | Duration (ms) | Tokens | Notes |
|---|---|---|---|---|---|
| 1 | [...] | DONE | [...] | [...] | — |
| 2 | [...] | DONE | [...] | [...] | — |
| 3 | [...] | BLOCKED | [...] | [...] | [blocker line] |

**Aggregate:** wall-time [max] / sequential-equivalent [sum] / parallelism-gain [×]

## Re-dispatches

| # | Original failure | Re-dispatched as | Result |
|---|---|---|---|
| 3 | [...] | sequential, corrected input | DONE |

## Lessons

[Any calibration notes — was this parallel dispatch worth it? Were there independence misses? Anything to avoid next time?]
```

---

## See also

- `skills/parallel-dev/SKILL.md` § Return contract — canonical 4-status semantics
- `skills/parallel-dev/SKILL.md` § Sub-patterns — hypothesis-probe variant
- `docs/agents/adrs/0004-parallel-subagent-dispatch-contract.md` — the binding ADR
- `skills/parallel-dev/agents/source-fetcher.md` / `pattern-extractor.md` / `synthesizer.md` — agent prompts that honor this contract
