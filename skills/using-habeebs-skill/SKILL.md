---
name: using-habeebs-skill
description: Introduction to the habeebs-skill methodology. Auto-loads when any habeebs-skill is referenced. Tells the agent how the skill chain composes — prior-art-research → draft-spec → socratic-grill → decision-record → write-plan → tdd-loop — and which engineering primitives (parallel-dev, deep-modules, vertical-slice, using-worktrees, systematic-debugging) support each phase. Documents how to abort the chain cleanly. Make sure to use this skill whenever any habeebs-skill triggers, so you know what's coming next in the chain and how to recover if work needs to halt.
---

# Using habeebs-skill

A research-grounded engineering methodology. The skills compose into a chain. Don't run them in isolation.

## The chain at a glance

```
[User says "I want to build X"]
         ↓
prior-art-research    → finds production patterns, recommends an approach
         ↓
draft-spec            → turns recommendation into an implementation spec
         ↓
socratic-grill        → drives ambiguity out of decisions
         │   ↳ agent-factors-check (conditional — only if the spec is an agent/copilot/LLM-workflow product)
         ↓
decision-record       → captures the result as an ADR
         ↓
write-plan            → phased delivery doc with acceptance gates + rollback hooks (skip if trivial)
         ↓
tdd-loop              → implements with red-green-refactor over vertical slices
         ↓
deep-modules          → refactor pass to deepen modules and remove shallow layers
```

## Supporting primitives (used inside the chain)

- **parallel-dev** — Deep mode of `prior-art-research` uses this to dispatch subagents per sub-problem. Also consumes `write-plan`'s `pgroup-N` parallelization map to dispatch AFK:full-auto slices concurrently.
- **vertical-slice** — `draft-spec` uses this to decompose the spec into tracer-bullet issues. Labels each slice `AFK:full-auto`, `HITL:inline`, or `HITL:approval-gate`.
- **deep-modules** — `decision-record` references the deep-module principles; `tdd-loop` invokes deepening checks at refactor steps.
- **using-worktrees** — isolates each non-trivial slice in its own branch + worktree with a verified-clean test baseline. Invoked from `tdd-loop` Phase 0 and `parallel-dev` Phase 4.
- **systematic-debugging** — reproduce → minimize → probe → fix → regression-test. Invoked when a bug surfaces during or after a slice.

## Conditional extensions

- **agent-factors-check** — invoked *from* `socratic-grill` Phase 1 when the spec is for an agent product. Runs the 13 factors from humanlayer/12-factor-agents and adds 6–13 Socratic questions to the active grilling agenda. Skipped for non-agent specs (CRUD, web, mobile, infra).

## Why this methodology

Three things kill AI-assisted development:

1. **Ungrounded design.** The agent recommends what it has seen most often, which is generic best-practices, which often don't match the user's actual scale or stack.
2. **Ambiguous decisions.** Implicit assumptions in the spec become bugs in the code.
3. **Software entropy.** Agents can write code faster than humans can review architecture. Codebases turn into balls of mud quickly.

habeebs-skill addresses each:

1. **Research grounds design.** Real teams' real architectures are stronger evidence than tutorials.
2. **Socratic grilling surfaces assumptions.** Every ambiguous decision becomes explicit before code is written.
3. **Deep modules + vertical slices preserve architecture.** Each slice cuts through all layers end-to-end. Each refactor pass deepens modules.

## Standalone by design (ADR-0002)

habeebs-skill is **one-time-use per feature, with no runtime dependencies.** The chain runs once for a given feature, produces durable in-repo artifacts (`docs/agents/SYSTEM_CONTEXT.md`, ADRs, plans, code, tests), and ends. It does not depend on oh-my-claudecode, claude-mem, memsearch, vector stores, MCP servers, or any external runtime substrate. `parallel-dev` is the only in-chain parallelism primitive — it dispatches sub-agents within a single chain run via git worktrees, not a persistent worker pool.

If a feature being built by the chain has long-running runtime concerns (queues, workers, sessions, dispatch), those are properties of the product spec — the chain captures them in the spec / ADR / plan and hands off to whatever production runtime the product chooses. They are NOT properties of habeebs-skill itself.

Users who also run OMC, claude-mem, Superpowers, etc. can do so. Those tools are orthogonal — they don't coordinate with habeebs-skill and habeebs-skill doesn't read or write their state.

See [`docs/agents/adrs/0002-habeebs-skill-standalone.md`](../../docs/agents/adrs/0002-habeebs-skill-standalone.md).

## Aborting the chain

Sometimes a chain in flight needs to stop before reaching `tdd-loop` — a new requirement invalidates the active spec, research surfaces an ADR-0002 blocker, the user explicitly says "stop / abort / cancel", or the work needs to be paused indefinitely. Abort is rare but high-stakes: leaving a half-flushed chain behind contaminates the next `prior-art-research` invocation's Phase 0 reconnaissance and confuses the next user picking up the work.

This is a documented convention, not a separate skill. Invoke it inline when needed: write "I'm aborting the chain — reason: <one line>" in the conversation, then execute the cleanup checklist below.

### When to abort

- **User says** "abort", "cancel", "stop the chain", "let's drop this", or equivalent
- **New requirement invalidates the active spec** (scope shift; the current draft-spec or grill record no longer maps to reality)
- **Research surfaces a blocker** — e.g., the chosen architecture violates [ADR-0002](../../docs/agents/adrs/0002-habeebs-skill-standalone.md) and the alternatives all violate it too
- **Work is paused indefinitely** — the user wants to come back to this later; in-flight artifacts shouldn't pollute the next chain run
- **A critic surfaces a coverage gap so large** that proceeding would ship the very class of bug the chain exists to prevent

### Cleanup checklist (in order)

1. **Flush `docs/agents/SYSTEM_CONTEXT.md` `## Active steering` block.** Copy any content under that heading to `## Last reconciliation outcome` with a `(chain aborted YYYY-MM-DD — reason: <one line>)` header. Then leave `## Active steering` empty with the `(none — flushed YYYY-MM-DD)` placeholder. Stale steering anchors leak into the next chain run if you skip this step.
2. **List in-flight worktrees** via `git worktree list`. For each worktree whose branch matches the active chain's feature pattern (e.g., `v1.X.Y-*`, `feature/*`, the slug from `using-worktrees` Phase 1), prompt the user: *"Abandon worktree X? (y/n)"*. On `y`, run [`using-worktrees`](../using-worktrees/SKILL.md) Phase 6 teardown — `git worktree remove <path>`. Use `--force` ONLY on a second explicit confirmation.
3. **Archive any partial spec.** If `docs/agents/specs/` contains a spec file with mtime after the chain's start that hasn't been promoted past `Draft` or `Grilled` status, move it to `docs/agents/specs/abandoned/<original-name>.md` and prepend a `**ABANDONED:** YYYY-MM-DD — <reason>` header line.
4. **Archive any partial ADR.** If `docs/agents/adrs/` contains an ADR with `**Status:** Proposed` (not Accepted) that was created during the aborted chain, move it to `docs/agents/adrs/abandoned/<original-name>.md` with the same header prepended.
5. **Echo a final summary** listing exactly what was flushed, abandoned, and preserved. The user should be able to read the summary and know the repo is in a clean state.

### No-destructive-git rule

Cleanup performs NO destructive git operations beyond user-confirmed worktree removal. Specifically:
- **No** `git push --force` of any kind
- **No** `git branch -D` to delete branches (abandoned worktrees' branches stay around; user can delete manually later if desired)
- **No** `git reset --hard` to discard committed work
- **No** force-deletion of any spec, ADR, or doc that was committed to `main`

If cleanup discovers state that would require a destructive op to fully clean up (e.g., a feature branch with committed work that the user wants gone), surface the situation to the user and stop. Do not act on the destruction without an explicit second confirmation.

### Handoff after abort

After cleanup completes, choose one of two handoffs:

- **HANDOFF: re-research needed** — invoke `prior-art-research` with the new constraint or revised feature definition. The chain restarts from Phase 1.
- **HANDOFF: back to user** — the work is genuinely paused and we are not currently working on a next step. Echo this explicitly so future-you knows the abort was not in service of a pivot.

## When to skip the chain

The chain is overkill for:

- Trivial fixes with known causes
- Adding a single field to a model
- Calling an API the user already knows how to call
- Bug fixes where the bug is already understood

For these, just answer directly or invoke `tdd-loop` only.

## Naming and namespacing

Plugin commands appear as `/habeebs-skill:<command>` in Claude Code. The auto-triggered skills don't need explicit invocation — they fire when the user describes a buildable feature.

## Shared chain protocols

Chain skills consume `docs/agents/SYSTEM_CONTEXT.md` as their environment-binding cache. The canonical freshness/staleness protocol is documented once and consumed by all 10 chain skills that read the file: [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md). Per ADR-0005, only `prior-art-research` Phase 0 writes SYSTEM_CONTEXT.md (single-writer invariant); all other skills only read.

## The implicit promise

When the chain runs, the user should never be surprised by an implementation choice. Every decision should be traceable back to a research case study, a graded trade-off in the spec, or an ADR. If a choice can't be traced, it shouldn't be in the code.
