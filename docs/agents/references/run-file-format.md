# Run-file format — per-run loop bookkeeping

Canonical reference for the **run file**, the loop harness's only new artifact
class: one tracked markdown file per `/tdd --loop` run, carrying mutable
bookkeeping (frontmatter), the structured **halt report**, and the
**RUN_SUMMARY** morning read. Established by the loop-harness spec
([2026-06-09-loop-harness.md](../specs/2026-06-09-loop-harness.md), slice 4)
and its grill record. This doc defines *formats* — the loop driver's algorithm
and halt-policy table live in `tdd-loop`, the reviewer contract in
`parallel-dev`.

## Location and naming

```
docs/agents/dispatches/run-<run-id>.md
```

One file per loop run, tracked markdown. Run files are a
**second record class** inside the existing dispatch-record directory
(grill decision: the
dispatch-record contract widens; no new directory, no new writer path —
`docs/agents/dispatches/` already carries the ADR-0021 runtime-writer-path
classification). The first record class — per-pgroup dispatch JSON — is
defined in
[`skills/parallel-dev/references/dispatch-record-template.md`](../../../skills/parallel-dev/references/dispatch-record-template.md).

## Frontmatter fields

Every run file opens with a YAML frontmatter block. All fields are required:

| Field | Semantics |
|---|---|
| `run_id` | Unique run identifier; also the filename suffix and the `/tdd --resume <run-id>` argument. |
| `plan_ref` | The plan (or spec) whose slice work-list this run executes. |
| `session_id` | Identity of the Claude Code session that owns the run — the resume guard key. |
| `worktree` | Absolute path of the worktree the run is bound to. |
| `branch` | Branch the run commits to. |
| `started_at` | ISO-8601 timestamp of run start. |
| `updated_at` | ISO-8601 timestamp of the last iteration's write. |
| `iteration_count` | Iterations consumed so far; incremented each loop pass. |
| `iteration_ceiling` | The **effective ceiling** — default 2× open slices, or the `--max-iterations` override; recorded here either way, so the file alone answers "how much budget is left". |
| `retries.<slice-id>` | Per-slice retry counters (one entry per slice that has retried; budget semantics defined in `tdd-loop`). |
| `last_error_hash.<slice-id>` | Hash of the last recorded failure per slice; powers the same-error-twice triage rule. |
| `status` | `running | done | blocked` — the run's terminal or in-flight state. |

## Session/worktree scoping (the resume guard)

The run file is scoped to the session and worktree recorded in its
frontmatter. A resume MUST check the **session-identity** field
(`session_id`, cross-checked against `worktree`) before touching the file —
a mismatch halts with the file untouched. This is the guard against the
cross-session resume-hijack class (Claude Code issue #15047): a second
session must never adopt, mutate, or resume another session's run.

## Writer rule

The run file is **skill-written only** — `tdd-loop` loop mode writes it each
iteration and at run end. **Hooks never write it** (ADR-0003 Rule 3 stands
untouched: hooks never own state). No other skill writes a run file it did
not create.

## Advisory-only semantics and staleness contract

The run file is a convenience view, never authoritative. Git refs and
dispatch records are the **durability layer**; the run file must never be the
sole source of truth — any reader whose correctness would depend on it must
fall back to git. The staleness contract follows the ADR-0019 shape
(advisory-not-authoritative + defined stale-data contract + per-writer-unique
file + read-only across writers):

- **Stale detection:** a run file is stale when its recorded state disagrees
  with git — compare its recorded commit SHAs and `iteration_count`
  against git (`git log` on `branch` since `started_at`). Git wins.
- **Degraded mode:** a stale, torn, or missing run file surfaces as
  "run state inconclusive — re-inspect plan + git before resuming", never as
  a wrong answer acted on silently.
- Per-writer-unique and read-only-across-writers hold by construction:
  one file per `run_id`, one writing session per file (the resume guard
  above).

## Halt-report format

One format for every halt class — re-grill, budget exhaustion, reviewer
block, and parked gate all write the same block. It is the re-grill learning
payload's 7 fields extended with 3 summary fields:

| Field | Semantics |
|---|---|
| `blocked_slice` | Slice that parked. |
| `blocked_decision` | The spec/plan decision implicated, when one is. |
| `expected_vs_observed` | What the slice contract promised vs what happened. |
| `evidence` | Raw failure evidence (test output, diff, finding). |
| `attempted_resolutions` | What the loop already tried (retries, fix rounds). |
| `scope_classification` | Blast radius — what scope parks with this halt. |
| `salvaged_sibling_results` | Completed sibling work that survives the halt. |
| `cause` | Halt class: re-grill, budget exhaustion, reviewer block, or parked gate. |
| `evidence-summary` | One-paragraph human digest of `evidence`. |
| `options` | The actions available to the human at resume. |

## RUN_SUMMARY format

Written once, at run end (either terminal state) — the morning read. It
contains, in order:

1. **Per-slice status table** — one row per slice in the run's work-list:
   slice id, terminal status, iterations/retries consumed, commit SHAs.
2. **Halts queued** — every halt report from the run, in full, in halt order.
3. **Provisional actions awaiting ratification** — every confirmation gate
   the loop passed provisionally, with its green-check evidence, listed for
   human ratification.
4. Each halt section names the resume command: `/tdd --resume <run-id>`.

## Format freeze

The format above is frozen at ship:
**no breaking field changes without a grill round**. Additive, optional
fields are not breaking. (Recorded undo
cost of the harness: one minor release + CHANGELOG migration note — the
freeze is what keeps that cost honest.)

## See also

- [`skills/parallel-dev/references/dispatch-record-template.md`](../../../skills/parallel-dev/references/dispatch-record-template.md) — the sibling record class
- [ADR-0019](../adrs/0019-amend-adr-0002-for-advisory-in-flight-reads.md) — the four-sub-clause advisory-read guard this staleness contract instantiates
- [ADR-0003](../adrs/0003-hooks-scope.md) — Rule 3, why hooks never write this file
- [2026-06-09-loop-harness-grill.md](../specs/2026-06-09-loop-harness-grill.md) — Item 5 (directory), Item 6 (ceiling), Item 12 (resume command)
