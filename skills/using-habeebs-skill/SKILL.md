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
         ↓
release               → version bump, CHANGELOG, PR body, tag-push — terminal chain link
```

## HANDOFF lines — navigation, not state transfer

Each chain skill ends its output with one or more `HANDOFF: <name> ready` lines pointing at the next skill to invoke. **These lines are navigation pointers, not state payloads.** State transfer between phases happens via the previous phase's **full output document** — the spec file written by `draft-spec`, the grill record written by `socratic-grill`, the ADR written by `decision-record`, the plan written by `write-plan`. When a downstream skill runs, it MUST read the full upstream document, not just the HANDOFF line.

Worked example: `socratic-grill` finishes a session by writing `docs/agents/specs/<slug>-grill.md` (the full record) and emitting `HANDOFF: record ready — invoke decision-record to capture as ADRs`. When `decision-record` runs, it reads the grill record IN FULL — every resolved item, every axes-grilled rationale, every revisit trigger. The HANDOFF line tells you which skill runs next; the grill record tells you *what to put in the ADR*. If `decision-record` ever proceeded from the HANDOFF line alone, it would lose the context it needs.

This shape positively matches [OpenAI's Agents SDK](https://openai.github.io/openai-agents-python/multi_agent/) "Handoff = ownership transfer" primitive — handoffs at the markdown layer carry full state via the file the next skill reads, not via the pointer string. It also guards against the failure mode documented in Walden Yan's ["Don't Build Multi-Agents"](https://cognition.ai/blog/dont-build-multi-agents) (Cognition AI, 2025-06-12): subagents on degraded context (handoff strings without the parent's full trace) silently encode conflicting interpretations of the parent task. The full-doc-read contract is what keeps habeebs-skill's chain on the right side of Yan's line. Same invariant applies to `parallel-dev` subagent dispatches per [ADR-0004 § Part 3](../../docs/agents/adrs/0004-parallel-subagent-dispatch-contract.md): subagents receive the parent's full context (Phase 1 context, decomposition, steering, SYSTEM_CONTEXT preamble) as one coherent payload, not a thin task summary.

If you're a downstream skill author: when you encounter a `HANDOFF: X ready` line, your first action is to READ the file it points to (the spec, the grill, the ADR). Don't infer what the previous phase decided from the HANDOFF text alone.

## Supporting primitives (used inside the chain)

- **parallel-dev** — the Deep tier of `prior-art-research` uses this to dispatch subagents per sub-problem. Also consumes `write-plan`'s `pgroup-N` parallelization map to dispatch AFK:full-auto slices concurrently.
- **vertical-slice** — `draft-spec` uses this to decompose the spec into tracer-bullet issues. Labels each slice `AFK:full-auto`, `HITL:inline`, or `HITL:approval-gate`.
- **deep-modules** — `decision-record` references the deep-module principles; `tdd-loop` invokes deepening checks at refactor steps.
- **using-worktrees** — isolates each non-trivial slice in its own branch + worktree with a verified-clean test baseline. Invoked from `tdd-loop` Phase 0 and `parallel-dev` Phase 4.
- **systematic-debugging** — reproduce → minimize → probe → fix → regression-test. Invoked when a bug surfaces during or after a slice.

## Standalone skills (invoked on demand, outside the chain)

- **security-audit** — a static security audit: attack-surface census, secrets archaeology over git history, OWASP Top 10, STRIDE per-component, confidence-gated findings. Invoked via `/security-audit` on demand — it is not chain-triggered and does not require habeebs-skill setup or `SYSTEM_CONTEXT.md`.

## When chain runs go wrong — postmortem cadence

Per [ADR-0011](../../docs/agents/adrs/0011-error-analysis-cadence.md), the chain has two complementary quality loops: `verify-output` (static, pre-commit, KNOWN slop classes) and chain-postmortems (dynamic, post-incident, NEW failure categories). Postmortems are where error analysis happens on real chain runs — Hamel Husain + Shreya Shankar's "[error analysis before infrastructure](https://hamel.dev/blog/posts/evals-faq/)" thesis applied to a markdown-only chain.

**Trigger conditions** — write a postmortem when:
- A chain run produced a wrong-shaped output (spec missed a sub-problem; grill missed a question; ADR locked something that's wrong in retrospect)
- A slice landed but with concerns (`verify-output` returned `DONE_WITH_CONCERNS`; behavior diverged from spec)
- A dispatched subagent BLOCKED unexpectedly
- The user says "that didn't work" / "this chain went sideways"
- A previously-passing dogfood scenario started failing

**Artifact:** one markdown file at `docs/agents/postmortems/YYYY-MM-DD-<slug>.md` per incident. Template structure (transition-failure-matrix per Hamel + Shreya): see [`docs/agents/postmortems/README.md`](../../docs/agents/postmortems/README.md).

**What postmortems produce:** named failure categories that feed back into `verify-output`'s ruleset (new static rules), into a SKILL.md's anti-pattern list, or into a new ADR. The output is durable rule-derivation, not narrative.

**v1.11.0 promotion criterion** (per ADR-0011): if 10+ real postmortems land in 90 days OR the user explicitly requests a `/postmortem` slash-command → promote this section to a standalone `chain-postmortem` skill with description tuned to failure-shaped trigger phrases.

## Cross-session learnings — no separate ledger (by design)

habeebs-skill deliberately has no learnings ledger or memory file. Cross-session knowledge lives in three existing artifacts: **ADRs** capture decisions and their rationale, **`docs/agents/postmortems/`** captures incident and error analysis, and **`SYSTEM_CONTEXT.md`'s "Last reconciliation outcome"** log captures research learnings. A separate curated ledger was evaluated and rejected (see ADR-0014 grill, 2026-05-18): it duplicates these artifacts, decays without the automated pruning ADR-0002 forbids, and reverses ADR-0010's doc-weight reduction. If you want a "learnings file", write an ADR or a postmortem instead.

## Conditional extensions

- **agent-factors-check** — invoked *from* `socratic-grill` Phase 1 when the spec is for an agent product. Runs the 13 agent quality factors and adds 6–13 Socratic questions to the active grilling agenda. Skipped for non-agent specs (CRUD, web, mobile, infra).
- **devex-review** — invoked *from* `socratic-grill` Phase 1 when the spec is a developer-facing product (CLI, SDK, library API, plugin, framework). Surfaces 6 developer-experience gap dimensions as Socratic questions for the grilling agenda. Skipped for non-developer-facing specs. Both conditional extensions can fire on the same spec.

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

habeebs-skill is **one-time-use per feature, with no runtime dependencies.** The chain runs once for a given feature, produces durable in-repo artifacts (`docs/agents/SYSTEM_CONTEXT.md`, ADRs, plans, code, tests), and ends. It does not depend on any external runtime substrate — no shared memory store, vector store, MCP server, or session-state directory. `parallel-dev` is the only in-chain parallelism primitive — it dispatches sub-agents within a single chain run via git worktrees, not a persistent worker pool.

If a feature being built by the chain has long-running runtime concerns (queues, workers, sessions, dispatch), those are properties of the product spec — the chain captures them in the spec / ADR / plan and hands off to whatever production runtime the product chooses. They are NOT properties of habeebs-skill itself.

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

## When sessions grow long — summary-and-flush

Per [ADR-0012](../../docs/agents/adrs/0012-compress-at-overflow-protocol.md), the chain's 4th context-engineering move ("Compress-at-overflow") is a markdown-only summary-and-flush protocol for sessions that approach context-window pressure. The other three moves (Write, Select, Isolate per [LangChain's framework](https://blog.langchain.com/context-engineering-for-agents/)) are already covered by SYSTEM_CONTEXT writes, prior-art-research fetches, parallel-dev dispatch isolation. This section closes the Compress gap.

**Trigger signals** (agent notices these; no runtime detection):

- Conversation length approaching the prompt-cache TTL boundary (rough heuristic: > 100 tool-call turns)
- Tool feedback accumulating past obvious-relevance (the agent has re-read the same file 3+ times)
- A long `tdd-loop` running 20+ slices in one conversation
- User explicitly says "this session is getting long" / "context feels heavy"

**Action: summary-and-flush.** Write a markdown summary to `.scratch/session-summary-<timestamp>.md` using the 7-section template at [`references/session-summary-template.md`](./references/session-summary-template.md). Then signal to the user that a fresh sub-session should start loading the summary + the active artifacts (current spec, ADRs in flight, current slice file, recent commits). The fresh sub-session inherits enough context to continue work mid-chain without a Phase 1 cold start.

**7-section template** (copy from the template file when flushing):

1. **Active artifacts** — file paths for current spec, ADRs being authored, current slice file, current grill record (if any), current postmortem (if any)
2. **Current slice** — slice number + name + acceptance-criteria status (which boxes checked, which open, which the agent was working on at flush time)
3. **Last successful action** — commit SHA + message, OR "test X passed" with path, OR "file Y written" with path
4. **What's blocking** — immediate next action + any blocker (missing input, failing test, open grill question)
5. **Open grill Qs from this session** — Q-IDs from grill records that drove current decisions
6. **Recent test state** — last dogfood / test run outcome + any red commits since
7. **Branch / worktree pointer** — current branch name, worktree path (if relevant), commit SHA at flush time

`.scratch/` is gitignored by user convention (not enforced by ADR — these are ephemeral working-set files, not durable artifacts). Cleanup is manual or per-user-environment policy. Per ADR-0002, no runtime substrate manages the lifecycle.

**v1.11.0 promotion criterion** (per ADR-0012): 3+ postmortems in `docs/agents/postmortems/` showing Context Distraction OR Context Confusion as the failure mode → promote this passive doc to an active skill (`chain-overflow-flush` or similar) with richer detection heuristics.

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
