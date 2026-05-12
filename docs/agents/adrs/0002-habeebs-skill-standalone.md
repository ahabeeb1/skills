# ADR-0002: habeebs-skill is standalone — no runtime-substrate composition

**Status:** Accepted
**Date:** 2026-05-12
**Deciders:** Modie (Habeeb)

## Context

The v1.5.0 self-audit (which produced ADR-0001) compared habeebs-skill against three Claude-Code-plugin ecosystem precedents: obra/superpowers, mattpocock/skills, and Yeachan-Heo/oh-my-claudecode. The OMC comparison surfaced a category confusion that needs to be locked: OMC's `.omc/state/` is a *runtime substrate* (queue state, worker claims, replay logs, interop envelopes for parallel agents); habeebs-skill's `docs/agents/SYSTEM_CONTEXT.md` + ADRs + plans are *project-fact substrate* (stack, scale, decisions, phased delivery). A subsequent audit drafted an "OMC composition policy" — the recommendation being to defer to OMC `/team` mode when multi-worker runtime needs arose.

User rejected the composition framing on 2026-05-12. habeebs-skill is a one-time-use methodology chain per feature, not an orchestration runtime. The chain runs once (research → spec → grill → record → plan → tdd), produces durable in-repo artifacts, and ends. `parallel-dev` covers the only in-chain parallelism the methodology needs — sub-agent dispatch within a single chain run, not a persistent worker pool. Importing an OMC dependency would import runtime concerns the use case doesn't have, couple the plugin to a specific Claude-Code-only ecosystem (defeating ADR-0001's portability goal), and re-litigate the question every time a new audit notices the gap.

The decision is needed NOW because v1.5.0's research output (still in conversation) explicitly proposed an OMC composition path, and without an ADR locking the rejection, the next audit will arrive at the same crossroads and quite possibly choose differently.

## Decision

We will keep habeebs-skill standalone. Specifically:

- The plugin declares no dependency on OMC, claude-mem, memsearch, vector stores, MCP servers, session-state directories, multi-worker queues, or any other runtime substrate.
- The "one-time-use per feature" model is the contract: chain runs once per feature, produces durable in-repo artifacts (`SYSTEM_CONTEXT.md`, `docs/agents/adrs/*`, `docs/agents/plans/*`, code + tests), then ends. Nothing persists outside the repo.
- `parallel-dev` is the only in-chain parallelism primitive habeebs needs. It dispatches sub-agents within a single chain run via git worktrees (per ADR-0001's single-writer invariant). It is NOT a persistent worker pool and does NOT require an external orchestrator.
- If a feature being *built* by the chain has long-running runtime concerns (queues, workers, sessions, dispatch), those are a property of the product spec the chain writes — not a property of habeebs-skill itself. The chain captures them in the spec / ADR / plan and hands off to whatever production runtime the product chooses.
- `CLAUDE.md` and `using-habeebs-skill/SKILL.md` are updated to state the standalone-by-design rule explicitly so future audits don't re-litigate.

The choice reflects three principles. First, **scope discipline**: habeebs-skill solves "one careful methodology chain per feature." OMC solves "long-running multi-worker orchestration." Conflating them imports the larger problem's complexity into the smaller problem's solution. Second, **portability** (compounding ADR-0001): the standalone constraint preserves multi-harness support (Codex, Cursor, OpenCode all read in-repo markdown; none have access to `.omc/state/` or claude-mem). Third, **decision durability**: this is the question that gets re-asked every audit. Lock it.

## Consequences

### Positive

- No external runtime to install, configure, or maintain alongside the plugin.
- Multi-harness support (Codex/Cursor/OpenCode) preserved by construction — the plugin doesn't depend on anything those harnesses can't read.
- Future audits compare habeebs-skill against runtime substrates only to *contrast* (different layers), never to consider composition. ADR-0002 short-circuits the re-litigation.
- `parallel-dev`'s remit stays sharp: in-chain sub-agent dispatch, not persistent worker management.
- Users who *also* run OMC, claude-mem, or Superpowers can do so — those tools are orthogonal, not coupled. habeebs-skill doesn't read or write to their state.

### Negative / Accepted trade-offs

- **No cross-session session-scrollback recall.** If a user works on the same feature across multiple Claude Code sessions, habeebs-skill has no native "what was I doing?" recall — they reload context from `SYSTEM_CONTEXT.md`, the active spec, the active ADR, the active plan, and the slice in flight. Acceptable because all four are git-tracked and human-readable; reload cost is bounded.
- **No native long-running runtime for the chain itself.** A chain run that needs to suspend (e.g., waiting for a HITL:approval-gate slice to clear out-of-band) doesn't have a habeebs-native suspend/resume mechanism. The plan's slice table is the suspend-resume primitive — when the user comes back, the plan tells them which slice to resume. Acceptable because most chain phases are minute-scale; the long-wait case (approval-gate) is exactly where the plan-as-state-doc shines.
- **Per-machine state isn't deduplicated.** Two Claude Code sessions on the same repo on the same machine each start the chain from cold. Acceptable because `SYSTEM_CONTEXT.md`'s Phase 0 staleness check makes cold-start cheap.

### Operational impact

- No new install steps, no new dependencies in `plugin.json`, no MCP servers required.
- `CLAUDE.md` "What this plugin is NOT" section needs a one-line update so existing wording ("composes with OMC's orchestration") doesn't contradict this ADR. The v1.5.2 plan covers it.
- `using-habeebs-skill/SKILL.md` needs a new "Standalone by design" subsection so the rule is visible to every agent invocation that loads the chain intro.

## Alternatives considered

### Compose with OMC at the runtime-substrate layer

Defer to OMC `/team` mode or `/ultrawork` when habeebs slices need true parallel runtime (multiple concurrent workers writing to repo). habeebs-skill would document the seam: "habeebs owns project facts + chain orchestration; OMC owns multi-worker runtime." Rejected: the use case has no recurring runtime to coordinate. `parallel-dev` already handles in-chain sub-agent dispatch. Composition would couple to a Claude-Code-only ecosystem (breaking ADR-0001 portability), impose an OMC install on every habeebs user, and import runtime complexity that solves a problem habeebs doesn't have.

### Compose with claude-mem / memsearch for cross-session recall

Treat semantic memory as an optional add-on for "what did we decide last quarter?" recall. Rejected (also already rejected in ADR-0001): ADRs in `docs/agents/adrs/` + grep cover the same use case with no opaque vector index. claude-mem and equivalents remain optional user-side tools, never load-bearing for the chain.

### Build a native runtime substrate inside habeebs-skill

Add `.habeebs/state/` (or equivalent) with queue state, worker claims, and session envelopes — owning the runtime layer ourselves rather than composing. Rejected: out of scope. habeebs is a methodology chain plugin; building a runtime substrate would 2-3× the surface area and introduce a state directory that violates ADR-0001's "git-tracked, reviewable, portable" constraint (runtime state can't be git-tracked sensibly). Engineering primitives that have already proven themselves (worktrees for isolation, ADRs for memory, plans for resume) cover the relevant subset.

### Stay silent — let future audits decide

Don't write an ADR; let each new audit re-examine OMC composition based on then-current evidence. Rejected: the v1.5.0 audit already proposed composition; the very next audit conversation arrived at the same crossroads. Without a locked decision, this question recurs every time a new external pattern (claude-mem, MCP servers, hypothetical future runtimes) shows up. ADR-0002 is the explicit *non-decision* — same posture ADR-0001 took on the project-mode field.

## Revisit triggers

This ADR should be reopened if any of:

- The methodology gains a use case that genuinely requires persistent multi-session state — not just artifact recall (covered by ADRs/plans) but live coordination across multiple agents on a shared task that outlives the chain. Hard to predict; would be a major scope expansion.
- `parallel-dev` accumulates user-confusion reports specifically because in-chain sub-agent dispatch can't model a needed runtime pattern (e.g., suspend-resume across days for a `HITL:approval-gate` slice fleet).
- A future runtime substrate emerges that is itself multi-harness-portable (works for Codex, Cursor, OpenCode without coupling) AND is markdown-readable enough to compose without breaking ADR-0001. None known as of 2026-05-12.
- The user explicitly asks for OMC composition again on a use case that materially changes the framing (i.e., not the same audit-loop question but a real new need).

## References

- Research: prior-art-research output (in-conversation, 2026-05-12) — audit of OMC composition framing
- ADR: [`adrs/0001-environment-binding-via-system-context.md`](./0001-environment-binding-via-system-context.md) — sister ADR establishing in-repo markdown as the load-bearing protocol; ADR-0002 is the standalone corollary
- Plan: [`plans/0002-habeebs-skill-standalone.md`](../plans/0002-habeebs-skill-standalone.md) — v1.5.2 release plan implementing this ADR
- SYSTEM_CONTEXT: [`SYSTEM_CONTEXT.md`](../SYSTEM_CONTEXT.md) — Tier 0 cache
- External sources:
  - [mattpocock/skills ADR-0001 — explicit setup pointer for hard deps](https://github.com/mattpocock/skills/blob/main/docs/adr/0001-explicit-setup-pointer-only-for-hard-dependencies.md) — independent convergence on in-repo-markdown + setup-bootstrap pattern (different scope, same posture)
  - [obra/superpowers writing-plans/SKILL.md](https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md) — plan-files-as-markdown precedent; also has no runtime substrate
  - [Yeachan-Heo/oh-my-claudecode REFERENCE.md](https://github.com/Yeachan-Heo/oh-my-claudecode/blob/main/docs/REFERENCE.md) — `.omc/` runtime substrate; the alternative we're declining to compose with

---

## Changelog

- 2026-05-12 — Initial ADR, status Accepted (implementation lands in v1.5.2 per plan 0002).
