# ADR-0018: Implement the dormant artifact-recording contracts — `parallel-dev` Phase 7.5 (dispatch records) and `prior-art-research` Phase 6.5 (research archives)

**Status:** Accepted
**Date:** 2026-05-22
**Deciders:** Modie (Habeeb)

## Context

A holistic audit of `docs/` on 2026-05-22 surfaced two declared artifact locations whose write step had never been implemented:

1. **`docs/agents/dispatches/`** — established by [ADR-0004](./0004-parallel-subagent-dispatch-contract.md) Part 2 (Accepted 2026-05-13): *"Every parallel dispatch produces one JSON file at `docs/agents/dispatches/<dispatch-id>.json` containing the input + return record for every subagent."* The schema is canonical in `skills/parallel-dev/references/dispatch-record-template.md` § Section 4. The `.gitkeep` lands in v1.7.0 per ADR-0004 § Operational impact. **But `skills/parallel-dev/SKILL.md` has no phase that actually writes the file.** Phase 5 captures timing/SHAs/tokens; Phase 6 aggregates; Phase 7 verifies — and the file is referenced descriptively (*"Note this in the dispatch record for future calibration"*) but never named as a deliverable. The directory has been empty since v1.7.0 (May 2026); zero records have ever been written.

2. **`docs/agents/research/`** — created in v1.10.0 (Slice 0) by an ad-hoc spec instruction to capture that release's `prior-art-research` synthesis as a file. **No `prior-art-research` SKILL.md phase declares an archival convention.** Phase 7 ends with HANDOFF lines and a steering flush; nothing writes the Phase 6 report to disk. The directory holds exactly one file (the v1.10.0 archive); every other release (v1.5, v1.7, v1.8, v1.9, v1.13, v1.14, v1.15, v1.16) ran research that lived only in-conversation and was discarded after synthesis into the spec's "Concrete picks" table.

Both gaps share a shape: a contract or convention declared a file location, but no skill instruction actually produced the file. The audit triggered the user-facing decisions on 2026-05-22; this ADR locks them.

The decision is needed BEFORE further chain runs land on `main`, because (a) without Part A, every parallel-dev dispatch continues to forfeit its audit trail (the ADR-0004 revisit trigger at 1000 records can never fire) and (b) without Part B, every Deep-tier research run continues to discard its evidence base, leaving only the compressed reconciliation entry in `SYSTEM_CONTEXT.md` § Last reconciliation outcome.

## Decision

We will implement both write steps as explicit skill phases. The directories already exist; the schemas already exist; this ADR commits the writers.

### Part A — `parallel-dev` Phase 7.5: Write the dispatch record

Add a Phase 7.5 to `skills/parallel-dev/SKILL.md` between Phase 7 (Verify the whole) and the Return contract section:

- **When:** After Phase 7 verification completes, before control returns to the invoking skill.
- **What:** Write a single JSON file at `docs/agents/dispatches/<dispatch-id>.json` matching the schema in `skills/parallel-dev/references/dispatch-record-template.md` § Section 4. The `<dispatch-id>` is the same ulid or short hash generated in Phase 4 and used in every subagent's commit-message trailer.
- **Fields populated:** all 5 top-level (`dispatch_id`, `invoker`, `started_at`, `completed_at`, `parent_task`, `plan_ref`, `concurrency_used`); the `independence_verification` block (from Phase 2); the `subagents` array (one entry per subagent with `status`, `commit_shas`, `duration_ms`, `total_tokens`, `notes`/`blocker`/`context_request`, `worktree_path`, `branch`); the `aggregate` block (`outcome` reflects Phase 7's verdict); the `re_dispatches` array (empty if no re-dispatch happened).
- **Failure mode:** If the write fails (filesystem full, permission denied), emit a one-line `⚠ Could not write dispatch record at <path>: <error>. Audit trail incomplete.` and proceed — the parallel work has already succeeded; losing the audit log MUST NOT poison successful results. ADR-0004's audit invariant degrades gracefully on tooling failure (same pattern as the SYSTEM_CONTEXT staleness-check protocol's Case A fallback).
- **Always-on:** No tier conditionality. ADR-0004 Part 2 mandates every dispatch produces a record; this ADR implements that mandate verbatim. (Tier conditionality lives one layer up — whether a chain *uses* parallel-dev at all is the Deep-tier decision; once it dispatches, recording is unconditional.)

### Part B — `prior-art-research` Phase 6.5: Archive the report

Insert a Phase 6.5 in `skills/prior-art-research/SKILL.md` between Phase 6 (Synthesize) and Phase 7 (Hand off and flush steering):

- **When:** After the Phase 6 report is composed, before HANDOFF lines are emitted.
- **What:** Write the full Phase 6 report verbatim to `docs/agents/research/<slug>-research.md`. The `<slug>` is the same feature slug used downstream by `draft-spec` (e.g., `v1.10.0-context-engineering-alignment-research.md`) — the user names it explicitly OR `prior-art-research` derives it from the Phase 1 problem statement.
- **Content:** the report includes all 8 standard sections (Executive summary / Problem / Case studies / Patterns / Recommendation / Steering reconciliation if applicable / Decisions to make next / Open questions / Sources). Phase 7's HANDOFF lines name the file path so downstream skills (`draft-spec`, `socratic-grill`) can read the archive instead of relying on in-conversation context.
- **Tier-conditional** per [ADR-0016](./0016-chain-wide-depth-tier.md):
  - **Deep tier:** REQUIRED. Multi-source synthesis with subagent fan-out is worth preserving.
  - **Balanced tier:** OPTIONAL. Default-off; lead writes only if the synthesis contains decisions or evidence the user might want to revisit.
  - **Quick tier:** SKIPPED. A ~5-source Quick synthesis is terse enough that the spec's "Concrete picks" table preserves everything load-bearing.
- **Failure mode:** Same graceful degradation — `⚠ Could not write research archive at <path>: <error>. Proceeding to HANDOFF.` Research success is not held hostage to archival failure.

## Consequences

### Positive

- ADR-0004 Part 2 stops being aspirational. `docs/agents/dispatches/` becomes a real audit log; the revisit trigger at 1000 records becomes reachable; `socratic-grill` can re-grill a failed slice by reading dispatch records instead of re-asking the user.
- Deep-tier research stops losing its evidence. Future audits ("why did we pick X for Y in v1.N?") have a file to read instead of a hole where conversation used to be. The `SYSTEM_CONTEXT.md` reconciliation log becomes the compressed index; the archive becomes the expanded body.
- Downstream chain skills can read the archive instead of receiving Phase 6 output through HANDOFF prose. The full-doc-read contract (`using-habeebs-skill` § HANDOFF semantics) now applies uniformly — the archive IS the doc to read.
- Both writes are markdown/JSON only; ADR-0002's no-runtime-substrate invariant is preserved.

### Negative / Accepted trade-offs

- **`docs/agents/dispatches/` will start growing.** Until v1.16, the directory was empty, so retention was a non-issue. Once Phase 7.5 lands, every parallel-dev dispatch writes one JSON file. Accepted: ADR-0004's existing revisit trigger at 1000 records is now reachable; retention via `/sync` cleanup pass becomes a real follow-up at that volume, not a hypothetical.
- **`docs/agents/research/` will grow with every Deep-tier run.** A Deep research report can be 150-300 lines of markdown. Accepted: the rate is low (Deep runs are infrequent — maybe one per release), file count tracks ADR count roughly, and the files compress well.
- **In-conversation Phase 6 output and the archived file can diverge** if the agent edits the report after writing. Accepted: Phase 6.5 sits BEFORE Phase 7 HANDOFF; the write is the canonical commit point. Post-write edits MUST update the file too (treat the file as the source of truth from Phase 6.5 onward).
- **Slug collisions across runs.** If two research runs use the same slug, the second overwrites the first. Accepted: same shape as spec/grill file naming; the convention is user-driven and slug uniqueness is the user's call. A future revisit trigger fires if collisions surface in practice.
- **Part B's tier conditionality requires Phase 6.5 to know the tier.** Trivially satisfied — the tier is in the research report header per ADR-0016 (`**Tier:**`), set in Phase 3 and inherited by every downstream phase including 6.5.

### Operational impact

- **No new install steps for users.** Both changes are skill-text additions inside the plugin.
- **No new top-level directories.** Both `docs/agents/dispatches/` and `docs/agents/research/` already exist.
- **SYSTEM_CONTEXT.md gains a one-line note under § Methodology / agent setup** that both contracts are now write-implemented (helps the Phase 0 reconnaissance pass surface "dispatches/ is no longer empty by design" to future audits).
- **No CI / build changes.** Markdown + JSON only.

## Alternatives considered

### Amend the declarations to match current behavior (do nothing in code)

Change ADR-0004 Part 2 from *"every dispatch produces a record"* to *"the schema is canonical; recording is opt-in for forensic runs."* Delete the empty `docs/agents/research/` folder + its one file. **Rejected** because (a) the audit-trail value of dispatch records is real (`socratic-grill` re-grilling a failed slice + future calibration of parallelism gain), (b) discarding Deep-tier research evidence makes future "why did we pick X?" audits unanswerable, and (c) the methodology principle is that declared artifacts get implemented, not deprecated to match a missing implementation.

### Implement Part A only (skip the research archive)

Wire up the dispatch-record write but leave research archival as a per-spec ad-hoc instruction (the v1.10.0 Slice 0 pattern). **Rejected** because the gap is the same shape (declared location, no skill writer); fixing one and leaving the other reproduces the inconsistency the audit surfaced. Tier conditionality keeps the cost bounded — Quick-tier runs skip the archive entirely.

### Centralize artifact-recording in a post-chain hook

Add a `post-chain-record` hook that gathers dispatch records + research reports + any other per-run artifacts in one bulk write at chain end. **Rejected** because (a) ADR-0003 scopes hooks to warn-only / block-only — they don't own state, (b) it adds a runtime indirection between work and artifact (the per-phase write is simpler and more readable), and (c) different artifacts have different write timing (dispatch records need the verification outcome; research archives need to precede HANDOFF) — a single end-of-chain hook misses both natural commit points.

### Generate a unified `chain-trace` record per chain run

Write one master JSON file per chain invocation that aggregates all phase outputs (research, spec, grill, ADR, plan, dispatch records). **Rejected** because (a) the chain has no runtime orchestrator that observes all phases (each skill writes its own artifact), (b) such a trace duplicates content already in the per-phase artifacts, and (c) per ADR-0002, no substrate exists to maintain the cross-phase view.

## Revisit triggers

This ADR should be reopened if any of:

- **`docs/agents/dispatches/` exceeds 1000 records** (this was already ADR-0004's trigger; now reachable). Introduce retention policy via `/sync` cleanup pass.
- **`docs/agents/research/` exceeds ~50 files.** Consider sub-categorization (`research/by-release/`, `research/by-feature/`) or pruning archives whose ADRs are superseded.
- **Two research archives collide on slug** (a user names a second run with an existing slug). Introduce slug-disambiguation rule (timestamp suffix or numeric increment).
- **A parallel-dev dispatch silently loses its record** (write succeeds but the JSON is malformed enough that consumers can't parse it). Add a Phase 7.5 sub-step that round-trips the JSON through a parser before declaring SUCCESS.
- **Phase 6.5 archival becomes a perceived ceremony tax at Balanced tier** (users routinely override to skip it). Demote Balanced from OPTIONAL to SKIPPED; keep Deep as REQUIRED.
- **A research archive contradicts the spec or ADR that descended from it** without anyone catching the contradiction. Add a `verify-output` rule that grep-checks descended-artifact claims against the archive's "Recommendation" section.

## References

- Implements: [ADR-0004 Part 2](./0004-parallel-subagent-dispatch-contract.md) — locked the dispatch-record location and schema in v1.7.0; this ADR commits the writer.
- Schema: [`skills/parallel-dev/references/dispatch-record-template.md`](../../../skills/parallel-dev/references/dispatch-record-template.md) § Section 4 — the JSON shape Phase 7.5 produces.
- Inherits tier conditionality from: [ADR-0016](./0016-chain-wide-depth-tier.md) — the tier governs whether Phase 6.5 fires; the propagation is via the research-report header (`**Tier:**`).
- Reconciliation pattern: [`docs/agents/SYSTEM_CONTEXT.md`](../SYSTEM_CONTEXT.md) § Last reconciliation outcome — the compressed index that research archives now expand on.
- Sister ADRs:
  - [ADR-0001](./0001-environment-binding-via-system-context.md) — load-bearing protocol principle; this ADR follows the same pattern (declared location → write step → consumers read).
  - [ADR-0002](./0002-habeebs-skill-standalone.md) — no-runtime-substrate invariant; both Phase 7.5 (JSON write) and Phase 6.5 (markdown write) are static file writes, ADR-0002 untouched.
  - [ADR-0009](./0009-docs-agents-references-convention.md) — established `docs/agents/` as the canonical chain-shared artifact root; both write targets sit under it.

---

## Changelog

- 2026-05-22 — Initial ADR, Accepted same day. Trigger: holistic audit of `docs/` surfaced two unimplemented contracts; user authorized both writers via interactive decision.
