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
- **Phase 7** — terminal phase of `prior-art-research` (steering flush) and of `setup-habeebs-skill` (Phase 0 trigger, added in v1.8.0 per ADR-0005).

**Synonyms to AVOID:** "pipeline" (implies orchestration; the chain is sequential by handoff, not by daemon), "workflow" (vague — be specific about which chain).

### Slice

A vertical work item that cuts through ALL integration layers end-to-end (tracer-bullet style), produced by `vertical-slice` from a spec or `write-plan` output. Tagged HITL or AFK.

**Sub-concepts:**
- **HITL slice** — human-in-the-loop required mid-slice; agent must pause and surface a decision.
- **AFK slice** — autonomous-friendly; agent can implement and merge without human gating.
- **Tracer bullet** — synonym for "vertical slice"; from *Pragmatic Programmer*.

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
