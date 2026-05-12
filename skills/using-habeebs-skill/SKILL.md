---
name: using-habeebs-skill
description: Introduction to the habeebs-skill methodology. Auto-loads when any habeebs-skill is referenced. Tells the agent how the skill chain composes — prior-art-research → draft-spec → socratic-grill → decision-record → tdd-loop — and which engineering primitives (parallel-dev, deep-modules, vertical-slice) support each phase. Read this first whenever any habeebs-skill triggers, so you know what's coming next in the chain.
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

## When to skip the chain

The chain is overkill for:

- Trivial fixes with known causes
- Adding a single field to a model
- Calling an API the user already knows how to call
- Bug fixes where the bug is already understood

For these, just answer directly or invoke `tdd-loop` only.

## Naming and namespacing

Plugin commands appear as `/habeebs-skill:<command>` in Claude Code. The auto-triggered skills don't need explicit invocation — they fire when the user describes a buildable feature.

## The implicit promise

When the chain runs, the user should never be surprised by an implementation choice. Every decision should be traceable back to a research case study, a graded trade-off in the spec, or an ADR. If a choice can't be traced, it shouldn't be in the code.
