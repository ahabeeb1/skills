# habeebs-skill — Agent Instructions (Codex / generic agents)

This repository is a portable agent-skill bundle. It is consumable by **Claude Code** (as an installable plugin) and by **OpenAI Codex CLI** or any other agent that honors `AGENTS.md` plus markdown-based skills.

When you, the agent, are invoked inside a project that has installed or vendored this repo, treat the files under `skills/`, `commands/`, and `agents/` as authoritative procedures.

## The chain

```
prior-art-research → draft-spec → socratic-grill → decision-record → write-plan → tdd-loop → release
                                       ↓
                             agent-factors-check (only if the spec is an agent product)
                             devex-review        (only if the spec is a developer-facing product)
```

`write-plan` is skip-able when the slice list is trivial and ordering is obvious. `verify-output` gates each `tdd-loop` commit, and `deep-modules` runs at `tdd-loop`'s refactor step — neither is a separate sequential phase. `release` is the terminal link after `tdd-loop` goes GREEN.

Each skill produces output the next skill consumes. The handoff lines at the bottom of each skill's output (e.g. `HANDOFF: spec ready`) tell you what to do next.

Every chain run executes at a depth tier — **Quick**, **Balanced**, or **Deep** (ADR-0016; see `docs/agents/references/tier-scale.md`). `prior-art-research` picks it and every downstream skill inherits it; the tier scales effort, never decision quality.

## Triggering principles

- **Trigger `prior-art-research` aggressively.** Users almost never say "research." They say "I want to build X." Read between the lines.
- **Don't skip phases for speed — pick a lighter tier instead.** If you are tempted to jump straight to writing code, you are missing the point of this methodology.
- **Internal precedent first.** Check local repos before going external. The user's own prior art is Tier 0.
- **Engineering primitives compose.** `parallel-dev`, `deep-modules`, `tdd-loop`, `vertical-slice`, `using-worktrees`, `systematic-debugging` are not standalone — they support the chain.

## What this is NOT

- **Standalone by design (ADR-0002).** habeebs-skill has no runtime dependency on any external substrate — no shared memory store, vector store, MCP server, or session-state directory.
- Not an automatic code writer — implementation still happens through TDD
- Not a survey tool — the research phase makes opinionated recommendations
- Not for trivial CRUD — let trivial things stay trivial

## Agent skills

This repo is configured for the habeebs-skill chain. The methodology files are:

- **Domain glossary:** `docs/agents/GLOSSARY.md`
- **Issue tracker:** `docs/agents/issue-tracker.md`
- **Triage labels:** `docs/agents/triage-labels.md`
- **System context:** `docs/agents/SYSTEM_CONTEXT.md` (written by `prior-art-research` Phase 0; load-bearing per ADR-0001)
- **ADRs:** `docs/agents/adrs/` (see `README.md` for index)
- **Specs:** `docs/agents/specs/`
- **Plans:** `docs/agents/plans/`
- **Chain-shared references:** `docs/agents/references/` (cross-cutting helpers per ADR-0009: `tier-scale.md`, `grill-extension-protocol.md`, `system-context-staleness-check.md`, `run-file-format.md`, `trigger-firing-eval.md`)
- **Postmortems:** `docs/agents/postmortems/` (event-driven per ADR-0011)
- **Dispatches:** `docs/agents/dispatches/`

**Directory classification:** `docs/agents/dispatches/` and `docs/agents/conflicts/` are *runtime writer paths* (written by `parallel-dev` and `cross-session-detect` respectively), not authored methodology directories — they stay on disk with `.gitkeep` regardless of file count. The "earn existence by file count" rule applies only to authored directories (`adrs/`, `specs/`, `plans/`, `postmortems/`, `research/`, `references/`). See [ADR-0021](./docs/agents/adrs/0021-methodology-folder-cuts.md) for the distinction.

When invoking habeebs-skills in this repo, read these files first. They define how `vertical-slice` publishes issues, what labels to use, what vocabulary to apply, and where decision records live. Per ADR-0005, `GLOSSARY.md` is the human-authored half of the two-file context layout; `SYSTEM_CONTEXT.md` is the tool-authored half (written by Phase 0).

## Anti-patterns

If you find yourself doing any of these, stop and re-read the relevant skill:

- Surveying multiple options without recommending one
- Skipping the context-capture questions to "save time"
- Researching after deciding (research is upstream of decisions, not downstream)
- Recommending FAANG-scale solutions to non-FAANG-scale problems
- Letting the chain stall in research without producing a spec
- Letting a lighter tier skip a triggered quality gate (open questions still grill; one-way doors still get an ADR)

## Quote and copyright discipline

When researching:
- One quote per source maximum, under 15 words, in quotes
- Paraphrase everything else
- Never reconstruct an article's structure with detailed paraphrase
- Cite every claim that follows from a search result

## Codex-specific notes

Codex CLI does not natively understand the `/plugin` system. To use this repo from Codex:

1. Vendor the repo (clone or submodule) into your project at any path, e.g. `./vendor/habeebs-skill/`.
2. Reference `vendor/habeebs-skill/AGENTS.md` from your project's root `AGENTS.md` with an `include` line, or copy its content.
3. Skills are plain markdown — Codex can read them on demand. Invoke a skill by name in your prompt (e.g. "use the `prior-art-research` skill from habeebs-skill").
4. The slash commands under `commands/` are Claude-Code-specific shortcuts; under Codex, invoke the underlying skill by name instead.

## Map of the bundle

- `skills/<name>/SKILL.md` — the skill definition; read this first when invoked
- `skills/<name>/references/` — templates and reference material the skill cites
- `commands/<verb>.md` — Claude Code slash command shortcuts (`/research`, `/spec`, etc.)
- `agents/<role>.md` — subagent prompts dispatched by `prior-art-research` Deep mode
- `docs/` — methodology/build documentation
