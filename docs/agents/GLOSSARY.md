# Domain Glossary

The vocabulary habeebs-skill uses. `deep-modules`, `draft-spec`, `decision-record`, and `socratic-grill` read this when proposing names, refactors, and decisions. When two terms are interchangeable in everyday English but distinct here, pick ONE and document why — inconsistency is the leading cause of confused agents.

This GLOSSARY is the human-authored half of habeebs-skill's two-file context layout (the tool-authored half is `SYSTEM_CONTEXT.md`, written by `prior-art-research` Phase 0 — see [ADR-0005](./adrs/0005-lifecycle-split-glossary-and-system-context.md)).

## Core concepts

### Skill

A self-contained markdown file under `skills/<name>/SKILL.md` with optional references in `skills/<name>/references/`. The unit of methodology habeebs-skill ships. A skill has a YAML frontmatter (name, description, optional `next-skills`) and a body that describes WHEN to trigger, the workflow phases, anti-patterns, and a "See also" footer.

**Examples in code:** `skills/prior-art-research/SKILL.md`, `skills/tdd-loop/SKILL.md`
**Synonyms to AVOID:** "command" (commands are slash-command shortcuts that invoke skills — not the same thing), "agent" (agents are subagent prompts under `agents/` — different layer)

### Chain

The ordered sequence of skills that compose into a methodology run: `prior-art-research → draft-spec → socratic-grill → decision-record → write-plan → tdd-loop`. One-time-use per feature (per [ADR-0002](./adrs/0002-habeebs-skill-standalone.md)). Each skill's HANDOFF lines tell the agent what skill to invoke next.

**Sub-concepts:**
- **Phase 0** — `prior-art-research`'s pre-Phase-1 reconnaissance pass; the single writer of `SYSTEM_CONTEXT.md` per ADR-0001.
- **Phase 2.5** — the category-completeness critic pass in `prior-art-research`, dispatched by `parallel-dev` (added in v1.7.0).
- **Phase 3** — `prior-art-research`'s tier-selection phase; sets the **tier** the whole chain run inherits (per ADR-0016).
- **Phase 7** — terminal phase of `prior-art-research` (steering flush) and of `setup-habeebs-skill` (Phase 0 trigger, added in v1.8.0 per ADR-0005).

Every chain run executes at one **tier** (see below), decided once in Phase 3.

**Synonyms to AVOID:** "pipeline" (implies orchestration; the chain is sequential by handoff, not by daemon), "workflow" (vague — be specific about which chain).

### Slice

A vertical work item that cuts through ALL integration layers end-to-end (tracer-bullet style), produced by `vertical-slice` from a spec or `write-plan` output. Tagged HITL or AFK.

**Sub-concepts:**
- **HITL slice** — human-in-the-loop required mid-slice; agent must pause and surface a decision.
- **AFK slice** — autonomous-friendly; agent can implement and merge without human gating.
- **Tracer bullet** — synonym for "vertical slice"; from *Pragmatic Programmer*.
- **Tracer slice** — the FIRST slice in a phase, deliberately chosen as the lowest-risk, lowest-coupling unit that still demonstrates end-to-end value. Surfaces format/integration/coupling problems cheaply before higher-load slices commit to the same pattern. Distinct from "tracer bullet" (which describes the *shape* of every vertical slice) — a tracer slice is the *role* a specific slice plays in a phase's ordering.

**HITL variants** (used in plan tables, scoped within HITL):
- **HITL:inline** — human reviews/decides in the chat session mid-slice; the agent halts and waits for an inline reply before continuing the same slice.
- **HITL:approval-gate** — human approves each commit out-of-band (Slack/email/PR review) before it lands; the agent drafts the commit then surfaces it for sign-off.
- **HITL:per-file** — human approves each file's diff in the slice individually; finer-grained than approval-gate. Used when the slice touches multiple skills/files and each diff has independent judgment weight.

**AFK variants:**
- **AFK:full-auto** — the AFK extreme: no human gating at all between dispatch and merge. The agent implements, tests, and (per the plan's authorization) merges without checking in.

**Synonyms to AVOID:** "task" (ambiguous — tasks live in the TaskCreate tool, slices live in specs), "ticket" (tickets are the issue-tracker representation of a slice, not the slice itself), "horizontal slice" (forbidden — that's the anti-pattern `vertical-slice` exists to prevent).

### ADR

Architectural Decision Record. A numbered immutable markdown file under `docs/agents/adrs/NNNN-<slug>.md` capturing a non-trivial architectural decision (Nygard format). Written by `decision-record`. Read by `prior-art-research` as Tier-0 internal precedent.

**Sub-concepts:**
- **Load-bearing** — an ADR or artifact that downstream skills MUST honor (they halt if it's missing or contradicted). ADR-0001 is load-bearing for `SYSTEM_CONTEXT.md`.
- **Supersede** — when a newer ADR replaces (partially or fully) an older one. ADR-0005 partially supersedes ADR-0001. Always forward-link from the older ADR's status field.

**Synonyms to AVOID:** "RFC" (RFCs are pre-decision; ADRs are post-decision), "design doc" (design docs are typically larger and pre-decision), "decision log" (the *collection* of ADRs is a decision log; one ADR is not).

### Harness

The runtime that loads and executes Claude Code-compatible skills. The four habeebs-skill targets: **Claude Code** (uses `.claude-plugin/`, `CLAUDE.md`, `commands/`), **Codex** (uses `AGENTS.md` at repo root), **Cursor** (uses `.cursor/rules/` + `.cursorrules`), **OpenCode** (uses `.opencode/`). habeebs-skill must remain portable across all four — markdown + JSON only per ADR-0002.

**Synonyms to AVOID:** "client" (too generic), "runtime" (collides with "runtime substrate" below), "IDE" (Cursor is an IDE, but Codex is a CLI and Claude Code spans both — "harness" is the umbrella term).

### Runtime substrate

A long-running execution layer (daemon, worker pool, session-state directory, vector DB) outside the repo that the chain would depend on. **Rejected** by ADR-0002 — habeebs-skill is standalone, no runtime substrate. Examples of substrates that are explicitly NOT composed with: `.omc/state/` (oh-my-claudecode), claude-mem vector store, MCP servers, Temporal-style orchestrators.

**Synonyms to AVOID:** "memory store" (claude-mem is a runtime substrate; in-repo markdown is NOT), "state machine" (the chain is stateless by design — state lives in the repo artifacts).

### Dispatch group

A set of subagents `parallel-dev` launches concurrently for independent work. Each subagent returns a 4-status record (`DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT`) per ADR-0004. The dispatcher injects the `SYSTEM_CONTEXT.md` content as the `context_preamble` field in every subagent's input.

**Sub-concepts (the named subagent roles):**
- **source-fetcher** — fetches one external source per sub-problem (used by `prior-art-research` Deep mode).
- **pattern-extractor** — identifies common patterns across source-fetcher records.
- **synthesizer** — produces the final convergent recommendation from sources + patterns.
- **category-completeness-critic** — reviews a Phase 2 decomposition for missing categories before Phase 4-5 burns budget.

**Synonyms to AVOID:** "swarm" (implies emergent behavior; dispatch groups are explicit and bounded), "team" (collides with OMC `/team`; habeebs-skill doesn't use that orchestration).

### pgroup

Short for *parallelization group*. A set of slices in the same phase of a plan with no inter-slice dependencies — they touch disjoint files, share no state, contend on no resources, and have no ordering requirement between them. Plans declare pgroups (`pgroup-1A`, `pgroup-2B`, etc.); `parallel-dev` consumes them as the dispatch contract; `tdd-loop` Phase 0.5 auto-dispatches any pgroup of size ≥ 2.

Naming convention: `pgroup-<phase-number><letter>`. Phase 1 has `pgroup-1A`, `pgroup-1B`, etc. (sequential within a phase, parallel within each group). Letters within a phase do NOT imply ordering — `pgroup-1A` and `pgroup-1B` are sequential because one blocks the other; if they were truly parallel they'd be one pgroup. A single-slice pgroup (e.g., `pgroup-2A = {#3}`) is legal — it marks "no parallel sibling at this position" without implying single-slice work is sub-optimal.

Independence is sanity-checked against `parallel-dev`'s Phase 2 checklist (file overlap, state dependency, resource contention, ordering, implicit shared state) before two slices are co-labeled. The 20% rule applies: if more than 80% of a plan's slices are tagged parallelizable, the slicing is wrong — real features have ordering dependencies.

**Synonyms to AVOID:** "batch" (implies homogeneous work; pgroup members can be heterogeneous), "wave" (implies temporal cadence; pgroups are about dependency-shape, not timing).

### Pre-flight verification

A read-only check performed before a slice's RED phase to confirm the slice's preconditions hold. Distinct from a slice's own acceptance criteria (which fire AFTER the slice's GREEN). Common pre-flight checks include: "does `docs/agents/SYSTEM_CONTEXT.md` exist?", "is the source baseline test suite passing?", "are the upstream chain artifacts (ADR, spec, grill record) present and consistent?". Pre-flight produces a binary "ready / not ready" verdict; on not-ready the slice halts with a `SETUP REQUIRED` banner per the halt-with-redirect contract.

The term also appears in plans as a phase-level gate. A phase's pre-flight is the small set of checks (typically 1-3) that MUST pass before the phase's first slice starts. Phase pre-flight differs from acceptance gate: pre-flight is the input contract; acceptance gate is the output contract.

**Synonyms to AVOID:** "precheck" (too vague — could mean linter, type-check, format), "smoke test" (smoke tests run AFTER implementation; pre-flight runs BEFORE), "sanity check" (too informal — pre-flight has a defined output contract).

### Single-writer invariant

The rule that a load-bearing artifact has exactly ONE skill authorized to write it. `SYSTEM_CONTEXT.md` is written only by `prior-art-research` Phase 0 (per ADR-0001). `setup-habeebs-skill` may *invoke* Phase 0 (per ADR-0005), but it does not write `SYSTEM_CONTEXT.md` directly. Subagents in a dispatch group treat `SYSTEM_CONTEXT.md` as read-only (per `parallel-dev` SKILL.md § Single-writer invariant).

**Synonyms to AVOID:** "ownership" (ambiguous — many things have "ownership"; this is specifically about write permission).

### Steering

Optional user-supplied biasing for `prior-art-research` Phase 4-5 source ranking. Three slots, all free-text and all optional. Echoed back in Phase 2 for confirmation. Reconciled in Phase 6 (Honored / Honored with caveat / Overridden). Flushed in Phase 7 to `SYSTEM_CONTEXT.md`'s `## Last reconciliation outcome` section.

**Sub-concepts:**
- **Anchor** — terms or techniques to bias queries toward.
- **Look at** — specific projects or teams to fetch first.
- **Avoid** — out-of-scope terms or anti-patterns.

**Synonyms to AVOID:** "hint" (too soft — steering MUST be reconciled in Phase 6, not silently ignored), "constraint" (constraints are hard; steering is soft and overridable on evidence).

### Halt-with-redirect

The failure-mode contract pattern habeebs-skill uses when a required artifact is missing. Example: every load-bearing chain skill (`draft-spec`, `socratic-grill`, `decision-record`, `write-plan`, `parallel-dev`) halts on missing `SYSTEM_CONTEXT.md` with `SETUP REQUIRED: ... Run /groundwork or /research first.` `deep-modules` halts on missing `GLOSSARY.md` with redirect to `/setup` (added v1.8.0 per ADR-0005).

**Sub-concept:**
- **SETUP_INCOMPLETE banner** — the specific halt-loud variant emitted by `setup-habeebs-skill` Phase 7 when Phase 0 write-fails after Phases 5-6 already succeeded.

**Synonyms to AVOID:** "fail-soft" (the halt is hard; the redirect is the recovery hint), "silent default" (forbidden — silent defaults are the failure mode this pattern exists to prevent).

### Context preamble

The full content of `docs/agents/SYSTEM_CONTEXT.md` injected as a required field in every subagent's input by `parallel-dev`'s dispatcher (per ADR-0004 Part 3). Prevents subagents from re-running Phase 0 reconnaissance and burning tokens.

**Synonyms to AVOID:** "context window" (generic LLM term; context preamble is specifically the SYSTEM_CONTEXT injection), "system prompt" (subagents have their own system prompts; the preamble is an input field within them).

### Dogfood

The practice of running habeebs-skill on its own repo to validate that the chain works. Slice 3 of v1.8.0 is the dogfood for ADR-0005. `tests/dogfood/` contains frozen dogfood scenarios for evals.

**Synonyms to AVOID:** "self-test" (too generic), "self-host" (means something different — running your own infrastructure).

### Project mode

A binary classification habeebs-skill uses to shape research and spec depth. **Brownfield** — existing code, prior ADRs, established conventions; `prior-art-research` consults internal precedent first; `draft-spec` slices respect existing seams. **Greenfield** — no existing code in the area; research drives more architectural decisions; spec slices establish new seams. Detected imperatively by Phase 0 (presence of ADRs, code, tests), NOT declared upfront (per ADR-0001 § "Declarative project-mode field" alternative-considered).

**Synonyms to AVOID:** "legacy" (loaded term — brownfield ≠ legacy; brownfield can be 6 weeks old), "scratch" (greenfield is more specific than "from scratch").

### Tier

The chain-wide effort scale: **Quick**, **Balanced**, or **Deep**. It governs how much of every chain step runs — research depth, whether the Phase 2.5 critic runs, spec verbosity, whether `socratic-grill` and `write-plan` run, ADR depth. `tdd-loop` always runs in full; the tier scales *design*, not implementation. Decided once by `prior-art-research` Phase 3 (auto-detect from ambiguity + sub-problem count + constraints, or a `--quick`/`--balanced`/`--deep` override), written into the research report header as `**Tier:**`, and inherited by every downstream skill. Two invariants hold: tiers scale effort and never decision quality, and tier-related user-facing output stays task-focused (no token/cost rationale). Established by [ADR-0016](./adrs/0016-chain-wide-depth-tier.md); full table and auto-detect rule in [`references/tier-scale.md`](./references/tier-scale.md).

**Sub-concepts:**
- **Quick** — single sub-problem, low ambiguity; terse spec, optional ceremony skipped.
- **Balanced** — moderate complexity; full spec, grill, and ADR.
- **Deep** — ambitious or ambiguous scope; parallel research, multi-round grill, phased plan.

Not to be confused with `prior-art-research`'s **source tiers** (the numbered T1-T5 ranking of engineering-blog / GitHub / RFC sources in Phase 4) — depth tiers are always named (Quick / Balanced / Deep), source tiers are always numbered.

**Synonyms to AVOID:** "mode" (the pre-ADR-0016 binary was "Quick/Deep mode" and was research-only; "tier" is chain-wide and graded — never call it a mode), "level" (collides with the load-bearing/severity vocabulary).

## Aggregates and bounded contexts

Two bounded contexts in habeebs-skill:

1. **Methodology context** — the chain, the skills, the engineering primitives (`parallel-dev`, `deep-modules`, `vertical-slice`, `using-worktrees`, `systematic-debugging`). All artifacts live in `skills/` and `agents/`.
2. **Project-facts context** — the per-repo artifacts the chain produces and consumes: `docs/agents/GLOSSARY.md`, `docs/agents/SYSTEM_CONTEXT.md`, `docs/agents/adrs/`, `docs/agents/specs/`, `docs/agents/plans/`, `docs/agents/dispatches/`, `docs/agents/issue-tracker.md`, `docs/agents/triage-labels.md`.

The contexts share `setup-habeebs-skill` as the bootstrap (which lives in methodology but writes into project-facts).

## Common operations

- We **invoke** a skill; we never "call," "execute," or "run" a skill (those imply imperative function-call semantics; skills are triggered by the agent's judgment).
- We **dispatch** subagents (specifically the named roles above); we never "spawn" them (spawn implies process-fork — wrong layer).
- We **handoff** between skills via HANDOFF lines; we never "chain into" mechanically (the handoff is advisory; the agent decides).
- We **flush** steering at chain end; we never "clear" or "reset" it (flush implies the named ritual in Phase 7).
- We **supersede** ADRs; we never "deprecate" them in habeebs context unless the entire decision is obsolete (partial supersede is the common case — see ADR-0005 / ADR-0001).

## Vocabulary that has CHANGED

- `CONTEXT.md` → **`GLOSSARY.md`** (v1.8.0 per ADR-0005). The old name lives on in CHANGELOG.md historical entries; everywhere else, GLOSSARY.md is canonical.
- "Composes with OMC / Superpowers / claude-mem" → **standalone, no composition** (v1.5.2 per ADR-0002). Earlier README/AGENTS prose using "composes with" language is stale; ADR-0002 is the authority.
- `prior-art-research` "Quick / Deep **mode**" (research-only binary) → chain-wide "Quick / Balanced / Deep **tier**" (v1.15.0 per ADR-0016). The old "mode" word and the two-value binary are retired; "tier" is canonical and graded. CHANGELOG entries before v1.15.0 retain the historical "mode" wording.
