# ADR-0004: Adopt the parallel subagent dispatch contract — 4-status return, audit-log records, SYSTEM_CONTEXT preamble, idempotent resume

**Status:** Accepted
**Date:** 2026-05-12 (Proposed) → 2026-05-13 (Accepted — 4-status return contract consumed by v1.9.0 `verify-output` skill per ADR-0008)
**Deciders:** Modie (Habeeb)

## Context

habeebs-skill v1.5.4 ships a `parallel-dev` skill that defines an *orchestration primitive* for parallel subagent dispatch — and that's it. Prior to v1.7.0, the contract is incomplete in four specific ways: (a) the return shape from each dispatched subagent is unspecified ("returns text + commit SHAs"), so the dispatcher has no machine-readable signal to drive re-dispatch or escalation; (b) the location and lifecycle of dispatch records is unspecified, so the system has no audit trail for grilling past failures; (c) each subagent is dispatched without any standardized context payload, so subagents re-run Phase 0 reconnaissance independently and may drift from the parent's environment binding; (d) interruption semantics are silent — no skill specifies what happens when a dispatch is killed mid-flight or how to resume.

The v1.7.0 release (the "parallel subagent processing" bundle) wires `parallel-dev` to its first real callers (`tdd-loop` and `write-plan`'s pgroup labels), so these contract gaps will become structural the moment the wiring lands. The prior-art-research output (in-conversation, 2026-05-12) surfaced production patterns for all four — Superpowers' 4-status return contract from `subagent-driven-development/implementer-prompt.md`, Anthropic's lead-subagent role-spec preamble pattern from the multi-agent research system writeup, and the git-as-durability-layer pattern from the multi-agent worktree literature (appxlab, Cognition Devin 2.0). The `socratic-grill` pass on the v1.7.0 spec (see `docs/agents/specs/v1.7.0-parallel-subagent-grill.md`) closed each of the four gaps with a concrete decision. This ADR locks them so they can't drift across the rest of v1.7.0's implementation or any subsequent release that touches the dispatch surface.

The decision is needed NOW — before Slice 4 of v1.7.0 lands — because Slice 4 is what physically writes the contract into `parallel-dev/SKILL.md` and `dispatch-record-template.md`. Without an ADR, the next audit will re-litigate fork-or-verbatim, dispatch-record location, preamble injection, and pause/resume semantics as four separate questions.

## Decision

We will adopt one dispatch contract with four binding parts. Specifically:

- **Part 1 — 4-status return contract, adopted verbatim from Superpowers' `subagent-driven-development/implementer-prompt.md`.** Every subagent dispatched through `parallel-dev` returns exactly one of `DONE`, `DONE_WITH_CONCERNS`, `BLOCKED`, or `NEEDS_CONTEXT`. The semantic for each status is captured in `skills/parallel-dev/SKILL.md` § Return contract (added in Slice 4). The structured BLOCKED message includes `subagent`, `slice_id`, `reason`, and `suggested_action ∈ {"edit-spec-and-redispatch", "investigate-manually", "escalate-to-maintainer"}`. The input + return JSON schemas live in `skills/parallel-dev/references/dispatch-record-template.md` as the canonical definition.
- **Part 2 — `docs/agents/dispatches/<dispatch-id>.json` as the dispatch-record artifact location.** Every parallel dispatch produces one JSON file at this path containing the input + return record for every subagent. The dispatcher is the **single writer**; no skill reads dispatch records during chain execution. The directory is an audit-only log. This is an explicit carve-out from ADR-0002 (no runtime substrate) — the substrate test fails on all four criteria (no daemon, no IPC, no concurrent access, no in-flight reads), so a static JSON file written once per dispatch is admissible.
- **Part 3 — `SYSTEM_CONTEXT.md` preamble injection as part of every subagent's input.** The dispatcher MUST read `docs/agents/SYSTEM_CONTEXT.md` and inject its full content as the `context_preamble` field in every subagent's input. Future skills that dispatch subagents (including any v1.8.0+ additions like a Phase 6 CitationAgent or a `socratic-grill` perspective-typed-critic fan-out) MUST honor this contract. This satisfies factors F3 (own context window) and F13 (pre-fetch context) from the 12-factor-agents lens (humanlayer/12-factor-agents) applied during grill.
- **Part 4 — Idempotent re-invocation as the pause/resume API.** No stateful suspend mechanism, no explicit checkpoint file, no async approval queue. Git is the durability layer: subagent commits land in their worktrees and persist across interruption. To resume, the user re-invokes `tdd-loop`; its Phase 0.5 inspects `git log --grep "Dispatch-id: <id>"` and existing branches/worktrees before dispatching, skips completed slices, and re-dispatches pending ones. Mid-flight uncommitted subagent work is lost on kill — same as any interrupted TDD cycle, resolved manually by the user. This satisfies factor F6 (Launch/Pause/Resume with Simple APIs) via simplicity.

Together, these four parts form a single coherent contract: every dispatch is a `(input_with_preamble) → (status, record_in_audit_log)` tuple, durably resumable via git replay. The contract is implementable in markdown + JSON only; no runtime substrate, no daemon, no shared mutable state.

## Consequences

### Positive

- The dispatcher gets machine-readable signal for re-dispatch and escalation (4-status return + structured BLOCKED message), enabling `tdd-loop` Phase 0.5 to act on subagent outcomes without parsing free-form text.
- Every dispatch leaves a complete, queryable audit trail in `docs/agents/dispatches/`; post-hoc grilling of "why did this slice fail?" runs against structured records, not chat history.
- Subagents inherit the parent's environment binding via the preamble, eliminating drift and the Phase-0-double-execution token cost.
- Interruptions are tractable — kill the process, re-run `tdd-loop`, the chain picks up where git left off. No special tooling needed.
- The contract converges with proven external patterns (Superpowers' return statuses, Anthropic's role-spec preamble, appxlab's worktree-as-durability) so future contributors recognize it.
- ADR-0004 becomes Tier 0 prior art for any future research on parallel-agent contracts inside this repo.

### Negative / Accepted trade-offs

- **Verbatim adoption of Superpowers' statuses creates drift risk** if Superpowers later diverges. Accepted: ADR-0004 captures the snapshot semantics; our copy is canonical for habeebs-skill independent of upstream changes. Five-whys probe in the grill closed this — every habeebs-specific candidate status (e.g., `DONE_REVIEW_PENDING`) collapses to `DONE_WITH_CONCERNS` in practice.
- **`docs/agents/dispatches/` is a new tracked-artifact category** that didn't exist before. Long-running repos may accumulate many records. Accepted: revisit trigger fires at 1000 records to introduce retention via `/sync`.
- **Mid-flight uncommitted work is lost on kill.** No checkpoint mechanism in v1.7.0. Accepted: the workload cost of a real suspend/resume API exceeds the benefit at habeebs-skill's expected scale. Revisit trigger: real-world report of harmful uncommitted-work loss.
- **`SYSTEM_CONTEXT.md` preamble injection costs ~1-2KB of context per subagent dispatch.** Accepted: dwarfed by the cost of re-running Phase 0 recon. Revisit trigger: file grows past ~5KB → inject a derived summary instead of full content.
- **The contract is opt-in only inside habeebs-skill.** External tools that consume habeebs-skill outputs (e.g., OMC, Superpowers users) are not bound. Accepted: habeebs-skill is standalone (ADR-0002); compatibility is a property of consumers, not producers.

### Operational impact

- **No new install steps for users.** All four parts are skill-text and template changes inside the plugin.
- **`docs/agents/dispatches/.gitkeep` is added** to anchor the convention in Slice 6.
- **Existing chains keep working unchanged** — the contract activates only when a skill calls into `parallel-dev`. Today only `prior-art-research` Deep mode does, and that flow is unchanged because the parent already provides equivalent context to subagents implicitly. The new wiring (Slice 6: `write-plan` → `tdd-loop` → `parallel-dev`) is the first real exercise of the full contract.
- **v1.7.0 manifest bump is MINOR** — new opt-in behavior added without breaking existing flows. Same rule habeebs-skill has applied through v1.5.x.

## Alternatives considered

### Fork the 4-status contract to add habeebs-specific statuses

Introduce `DONE_REVIEW_PENDING` and/or `BLOCKED_ON_HUMAN_INPUT` to capture habeebs-skill-specific control-flow nuances. **Rejected** because every candidate addition collapsed to one of the four canonical statuses during grill (Item 1, five-whys probe). `DONE_REVIEW_PENDING` is `DONE_WITH_CONCERNS` plus a UI affordance; `BLOCKED_ON_HUMAN_INPUT` is `BLOCKED` plus `suggested_action: "escalate-to-maintainer"`. Adding statuses now creates maintenance surface for zero observed need. Removing them later is a breaking change. Verbatim is reversible; fork is one-way.

### Dispatch records gitignored at `.dispatches/` (root)

Treat dispatch records as ephemeral process artifacts and exclude from git. **Rejected** because it forfeits the audit trail (`git log --grep "Dispatch-id:"` becomes useless; no post-hoc grilling of failures), fails factor F5 (state unification), and conflicts with the broader habeebs-skill principle that durable artifacts live in-repo. The substrate concern (ADR-0002) doesn't actually fire on a static write-once JSON file.

### Per-worktree dispatch state file

Store the dispatch record inside each subagent's worktree, with no centralized record. **Rejected** because state fragmentation breaks F5 again, and querying "what happened across all parallel runs" requires walking N worktree paths. Worktrees also get cleaned up by Phase 6 of `using-worktrees`, taking the audit trail with them.

### Lazy preamble fetch (each subagent reads `SYSTEM_CONTEXT.md` itself)

Skip the dispatcher-side preamble injection; let each subagent read `SYSTEM_CONTEXT.md` when it starts. **Rejected** because subagents would re-run Phase 0 reconnaissance independently (token waste), the file could be different across subagents if a parent edit lands mid-dispatch (drift risk), and the dispatcher-side fetch is one read vs N reads. The token cost of the preamble (~1-2KB × N subagents) is small relative to the per-subagent task budget.

### Explicit checkpoint file or stateful suspend/resume API

Persist dispatcher state (which slices are in-flight, last successful commit per slice, retry counter) to a checkpoint file readable on resume. **Rejected for v1.7.0** because git already provides durability for the only thing that matters (subagent commits), and the in-progress uncommitted state is inherently lost on interruption regardless of checkpoint mechanism. The cost of a stateful suspend API (new file format, new write protocol, new failure modes for the checkpoint itself) exceeds the value for habeebs-skill's expected workload. Revisit trigger fires if real interruptions cause harmful work loss.

## Revisit triggers

This ADR should be reopened if any of:

- A real-world dispatched-subagent case surfaces that doesn't fit any of the four canonical statuses → propose a 5th status with ADR amendment.
- Any skill starts reading dispatch records mid-chain (not just post-hoc) → the carve-out from ADR-0002 fails, the audit log has become a substrate, and ADR-0002 itself needs amendment.
- `docs/agents/SYSTEM_CONTEXT.md` grows past ~5KB → inject a derived summary or section-filtered subset instead of full content; revisit Part 3.
- A real-world re-invocation case produces incorrect results (e.g., uncommitted "almost done" work was silently discarded and the re-invoked subagent corrupted the rebuilt state) → introduce explicit checkpoint mechanism; revisit Part 4.
- The `docs/agents/dispatches/` directory exceeds 1000 records → introduce retention policy with `/sync` cleanup pass.
- Superpowers `subagent-driven-development/implementer-prompt.md` diverges from this snapshot in a way that materially changes how dispatched agents return outcomes → assess drift; either re-converge or formalize the fork.

## References

- Research: prior-art-research output (in-conversation, 2026-05-12) — "Where to add parallel subagent processing in the habeebs-skill chain"
- Spec: [`specs/v1.7.0-parallel-subagent`](../specs/v1.7.0-parallel-subagent.md)
- Grill: [`specs/v1.7.0-parallel-subagent-grill`](../specs/v1.7.0-parallel-subagent-grill.md)
- Factor check: [`specs/v1.7.0-parallel-subagent-agent-factors`](../specs/v1.7.0-parallel-subagent-agent-factors.md)
- Plan (forthcoming): `plans/0004-parallel-subagent-v1.7.0.md` — phased delivery plan for the 8 slices
- Sister ADRs:
  - [`adrs/0001-environment-binding-via-system-context`](./0001-environment-binding-via-system-context.md) — `SYSTEM_CONTEXT.md` is the load-bearing protocol Part 3 leans on
  - [`adrs/0002-habeebs-skill-standalone`](./0002-habeebs-skill-standalone.md) — ADR-0004 explicitly carves dispatch records out of the "no runtime substrate" rule; ADR-0002 body untouched
  - [`adrs/0003-hooks-scope`](./0003-hooks-scope.md) — unaffected; hooks are a v1.6.0 surface, parallel-subagent is v1.7.0
- SYSTEM_CONTEXT: [`SYSTEM_CONTEXT.md`](../SYSTEM_CONTEXT.md)
- External sources:
  - [Superpowers — `subagent-driven-development/implementer-prompt.md`](https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/implementer-prompt.md) — canonical source for the 4-status return contract
  - [Anthropic — How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — lead-subagent role-spec preamble pattern; the basis for Part 3
  - [Multi-Agent AI Coding Workflow: Git Worktrees That Scale (appxlab)](https://blog.appxlab.io/2026/03/31/multi-agent-ai-coding-workflow-git-worktrees/) — git-as-durability-layer pattern; the basis for Part 4
  - [Cognition — Devin 2.0](https://cognition.ai/blog/devin-2) — fleet-of-VMs precedent for isolated worker dispatch
  - [humanlayer/12-factor-agents](https://github.com/humanlayer/12-factor-agents) — factors F3, F6, F13 cited explicitly above

### Reference implementations cited

- **4-status return contract:** Superpowers `subagent-driven-development/implementer-prompt.md` (link above). Cited because Parts 1 + 4 of this ADR adopt the contract verbatim and rely on the persistent semantics across `DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT`.
- **12-factor-agents:** humanlayer/12-factor-agents — referenced for F3 (Own Your Context Window) and F13 (Pre-fetch Context) justifying Part 3, and for F6 (Launch/Pause/Resume with Simple APIs) justifying Part 4.

---

## Changelog

- 2026-05-12 — Initial ADR, status Proposed (implementation lands in v1.7.0 per plan 0004).
