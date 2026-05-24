# ADR-0019: Amend ADR-0002 to permit advisory in-flight reads of in-repo session state

**Status:** Accepted
**Date:** 2026-05-22
**Deciders:** Modie (Habeeb)
**Tier:** Deep (inherited from research and grill)

## Context

The v1.16.0 research run for cross-session conflict detection (two concurrent Claude Code sessions touching the same line — Session A fixing a bug at lines 40-50 of `foo.ts` while Session B refactors the same function) ran into a hard substrate-rule conflict.

The proposed mechanism — a Vim-swap-style session sidecar in `$(git rev-parse --git-common-dir)/habeebs-sessions/<id>.json` embedding PID + hostname + start-time + worktree path + `git stash create` SHA, paired with `git merge-tree --write-tree` for overlap detection — passes three of ADR-0004 Part 2's four substrate-tests but fails the fourth cleanly. ADR-0004 admits `docs/agents/dispatches/*.json` as legal because (1) no daemon, (2) no IPC, (3) no concurrent access to the same artifact, (4) **no in-flight reads** — dispatch records are consumed post-hoc. Session sidecars require in-flight reads by design: Session B reads Session A's sidecar **during Session A's lifetime**. That's not a bug; it's the whole point.

Either ADR-0002 forbids this mechanism, or it admits a tightly-scoped carve-out. Forbidding it sends the chain back to either (a) silent overwrites (the do-nothing baseline JetBrains and VS Code already demonstrate as inadequate), (b) post-hoc detection at `pre-push` only (catches conflicts late, after work is committed), or (c) server-mediated locking (`git-lfs` style — explicitly rejected by ADR-0002). None of these resolves the user's literal scenario.

The decision is needed NOW because the research → grill chain has locked the architecture pending exactly this substrate clarification, and without an ADR the next research run will re-litigate the question.

## Decision

We will write a tightly-scoped carve-out to ADR-0002 permitting **advisory in-flight reads** of in-repo state artifacts, plus two corollary architectural commitments for the cross-session conflict detection mechanism.

### Decision 1 — The four-sub-clause guard

In-flight reads of in-repo state artifacts are permitted when **all four** of the following hold:

- **(a) Advisory, not authoritative.** The reader's correctness does not depend on the writer's liveness. A stale, torn, or missing artifact must not silently break the reader — it must surface as a degraded mode (e.g., "peer liveness inconclusive; falling back to TTL heuristic"), not as a wrong answer.
- **(b) Defined stale-data contract.** The reader has an explicit contract for stale, torn, and missing data. For session sidecars this means: `node process.kill(pid, 0)` liveness probe + start-time cross-check + 24h TTL fallback (`liveness_ttl_seconds` policy field, default 86400).
- **(c) Per-writer-unique artifact.** Each writer writes its own file. No two sessions ever write the same path. Path naming MUST encode a session-unique identifier (UUID, PID + start-time hash, or equivalent).
- **(d) Read-only across writers.** Peers stat-and-parse; they never modify each other's artifacts. Mutation requires the writer's own subsequent write to its own file.

Drop any sub-clause and the carve-out leaks. (a) without (b) recreates silent-failure modes; (b) without (a) tempts shipping a "block until peer commits" feature that resurrects the runtime-substrate problem; (c) without (d) opens the door to peer-mediated state machines; (d) without (c) leaves shared-file races unresolved.

### Decision 2 — Action menu vocabulary lock-in

When the cross-session conflict detection mechanism halts Session B on overlap with Session A, the inline-prompt action menu is **fixed at five options**, with both keystroke forms accepted:

| Key | Action | Behavior |
|---|---|---|
| `[1/m]` | Merge | Drop into `git`'s `<<<<<<<` markers in the working tree; open `$EDITOR` |
| `[2/s]` | Sequence | Session B waits; mechanism re-dispatches after Session A's sidecar clears |
| `[3/t]` | Transfer | Write a follow-up note for Session A to read; Session B abandons its change |
| `[4/a]` | Abort | Session B drops its branch + worktree state |
| `[5/w]` | Worktree-out | Session B branches into its own worktree on `worktree-out/<8-char-uuid>` and continues independently |

**`transfer` replaces `handoff`** to dodge the universal `[h]elp` keystroke convention. The menu accepts letters and numbers per apt/pacman/npm-init precedent.

### Decision 3 — `prefer_worktree` deferral with explicit revisit trigger

The proactive worktree policy (`prefer_worktree: <work_type>`) does **not** ship in v1. Only the reactive `[5/w] Worktree-out` action lands. Revisit trigger: if reactive halts feel annoying to the user after a few weeks of routine use, `prefer_worktree` is re-proposed in v1.1 with a defined work-type taxonomy and default list. The deferral is captured here (not in a separate ADR) so future research finds it as Tier 0 prior art and does not re-propose it cold.

ADR-0002's status is updated to `Accepted (amended by 0018)` and a forward link is added to its References section.

## Consequences

### Positive

- The cross-session conflict detection mechanism is unblocked — sidecars, overlap probes, and the layered trigger mix become legal under a clearly-bounded carve-out.
- Future ADR-0002 audits have a tight rule to test against rather than re-litigating the in-flight-read question from scratch. The four sub-clauses are concrete enough to apply mechanically.
- `using-worktrees` is elevated from "adjacent precedent" to a load-bearing skill the mechanism invokes (for `[5/w] Worktree-out`), strengthening internal-skill composition without violating ADR-0002.
- The menu vocabulary lock-in removes a UX uncertainty that would otherwise resurface in every adjacent design (`socratic-grill` halt prompts, `parallel-dev` HITL prompts, `verify-output` decision menus).
- The `prefer_worktree` deferral keeps v1 spec surface tight while leaving a clear path to v1.1 if reactive resolution proves insufficient.

### Negative / Accepted trade-offs

- The substrate rule is no longer "no in-flight reads, full stop." Future readers must internalize the four-sub-clause guard. We accept the cognitive load because the alternative (forbidding the carve-out entirely and accepting silent overwrites or post-hoc-only detection) is worse.
- Signals remain **advisory, not authoritative**. Two collaborators on different machines who both ignore the SessionStart warning can still produce a conflict — caught at `pre-push`, but not prevented at edit time. Authoritative cross-checkout mutex is permanently off the table for this carve-out.
- The `transfer` rename costs nothing in greenfield (no existing users of `handoff`) but is worth noting: future skills that emit halt menus must use `transfer` to stay consistent, not `handoff`.
- The `prefer_worktree` deferral leaves the "by work being done" policy axis from the original Phase 1 user requirement partially unfulfilled in v1. The reactive `[5/w] Worktree-out` covers the user's literal scenario; the proactive lever is the additive layer that's deferred.

### Operational impact

- No CI/CD changes (consistent with `## Notable absences` in SYSTEM_CONTEXT.md).
- New tracked artifact directory: `docs/agents/conflicts/<id>.json` (sibling to `docs/agents/dispatches/`). Same `git check-ignore` posture as dispatches (tracked, not gitignored).
- New runtime artifact directory: `$(git rev-parse --git-common-dir)/habeebs-sessions/<id>.json` — auto-gitignored by virtue of living inside `.git/`. Shared across every worktree of the same repo.
- New policy schema fields in `.claude/habeebs-policy.json`: `pretool_use: bool` (default `false`), `liveness_ttl_seconds: int` (default 86400), `require_signed_signals: bool` (default `false` for solo, opt-in for collab). `prefer_worktree` field reserved for v1.1; rejected if present in v1.
- ADR-0002 status field updated to `Accepted (amended by 0018)`.

## Alternatives considered

### Alternative 1 — Forbid in-flight reads; accept post-hoc-only detection at `pre-push`

Keep ADR-0002 untouched. The mechanism only fires at `pre-push`, after Session B has already committed potentially-overlapping changes. Rejected because this defers detection past the point where the user can meaningfully act — by `pre-push`, the work is committed and the cheapest resolution paths (`merge`, `worktree-out`) are more expensive. This re-creates the silent-overwrite failure mode JetBrains and VS Code already demonstrate as inadequate, and ignores the user's explicit Phase 1 lock on "halt + surface diffs."

### Alternative 2 — Amend ADR-0004 Part 2 in place to cover session state

Extend the existing dispatch-record carve-out to also admit session sidecars. Rejected because ADR-0004 is scoped to *parallel-dev dispatch records* — bolting session-state semantics onto it grows ADR-0004 beyond its title and obscures both concerns. The new-ADR-cross-referencing-old-ADRs pattern (ADR-0005/0006/0010 expanding ADR-0001) is the precedent.

### Alternative 3 — Bare-existence locks (`index.lock` shape) without PID embedding

Cheapest implementation: a per-session lockfile, existence-as-signal, no metadata. Rejected because Claude Code already ships with documented stale-`index.lock` bugs (anthropics/claude-code issues #11005, #28546, #57102). The negative evidence is direct: agent contexts that crash leave bare-existence locks orphaned, and the user-frustration cost is documented in Modie's own `feedback_release_tag_hook_misfire.md` memory. PID + hostname + start-time embedding is the load-bearing addition that distinguishes the Vim pattern from `index.lock`.

### Alternative 4 — Server-mediated locking (git-lfs pattern)

Strongest mutex guarantee — authoritative across distributed checkouts. Rejected outright because it requires a server, violating ADR-0002 at the level of architectural intent. `git-lfs` itself documents that it chose server-mediated locking precisely because pure-filesystem locks cannot guarantee mutex across distributed teams — habeebs-skill accepts that exact trade-off and ships an advisory-only mechanism instead.

### Alternative 5 — Continuous file-watcher daemon

Maximum precision: flag overlaps the moment two sessions touch overlapping ranges. Rejected because it requires a persistent process, violating ADR-0002 directly. The `inotify`/`FSEvents`/`ReadDirectoryChangesW` family of primitives all require a long-lived watcher, which is the substrate this whole ADR family forbids.

## Revisit triggers

This ADR should be reopened if any of:

- **Collab usage scales beyond occasional same-checkout sessions** to regular multi-machine real-time editing. At that point the advisory-only model becomes insufficient and Alternative 4 (server-mediated locking) needs re-evaluation, accepting the ADR-0002 amendment cost.
- **`PreToolUse` false-positive rate empirically lands below ~1%** (measured by user-reported false halts over installed sessions). Could flip the `pretool_use` default from `false` to `true`. Requires either telemetry (currently forbidden by ADR-0002) or aggregated user reports — practically blocked until the user reports back.
- **Windows-native liveness probe proves brittle** across PowerShell / Git Bash / WSL boundaries despite the Node `process.kill(pid, 0)` + env-string mitigation. Triggers a fallback redesign possibly involving a heartbeat-update field.
- **Conflict audit volume exceeds 1000 records** in any single repo. Triggers a retention-policy revisit consistent with ADR-0004's revisit trigger at the same threshold.
- **Reactive `[5/w] Worktree-out` halts feel annoying** to the user after a few weeks of routine use. Triggers the v1.1 design for proactive `prefer_worktree` policy.
- **A second mechanism wants to use the carve-out** for a non-session-presence purpose (e.g., long-running spike traces, agent-handoff envelopes). At that point the four-sub-clause guard needs pressure-testing against the new use case; possibly the guard is generalized further or a separate carve-out is written.

## References

- Research: [`docs/agents/research/2026-05-22-cross-session-conflict-detection.md`](../research/2026-05-22-cross-session-conflict-detection.md)
- Grill: [`docs/agents/grill-records/2026-05-22-cross-session-conflict-detection.md`](../grill-records/2026-05-22-cross-session-conflict-detection.md)
- Spec: (forthcoming — `draft-spec` runs after this ADR is locked)
- Plan: (forthcoming — `write-plan` after spec)
- Related ADRs:
  - [ADR-0002](./0002-habeebs-skill-standalone.md) — amended by this ADR; original substrate constraint
  - [ADR-0003](./0003-hooks-scope.md) — the hook scope rules the new triggers must satisfy (warn-only or block-only; multi-harness; never own state)
  - [ADR-0004](./0004-parallel-subagent-dispatch-contract.md) — the dispatch-record carve-out whose four substrate-tests this ADR amends
  - [ADR-0015](./0015-hook-allow-tag-pushes-on-default.md) — precedent for narrowing predicate on existing hook surface
- External sources:
  - [`git-merge-tree(1)`](https://git-scm.com/docs/git-merge-tree) — overlap-detection primitive
  - [`git-worktree(1)`](https://git-scm.com/docs/git-worktree) — built-in branch mutex; precedent for `git-common-dir` namespace
  - Vim `:help swap-file` — 30-year PID-embedded sidecar reference pattern
  - [anthropics/claude-code#11005, #28546, #57102](https://github.com/anthropics/claude-code/issues/11005) — negative evidence for bare-existence locking

### Reference implementations cited

- **Vim swap files (`.foo.swp`):** Canonical PID-embedded sidecar with liveness probe. Cited in the Decision-1 sub-clause (b) "defined stale-data contract" — Vim's `(STILL RUNNING)` distinction is the design pattern.
- **`git merge-tree --write-tree`:** Pure-git overlap detection. Cited as the load-bearing primitive that makes Decision-1's per-writer-unique sidecars actually answer "do these two edits conflict?" rather than the weaker "did both sessions touch this file?"
- **jj conflict-as-data:** Cited for the audit-log shape (`docs/agents/conflicts/<id>.json` as durable artifact) — the lesson is honored without adopting jj's commit-graph storage.

---

## Changelog

- 2026-05-22 — Initial ADR, status Accepted (no implementation-vs-proposed gap; the chain proceeds directly to `draft-spec` with this ADR locked).
