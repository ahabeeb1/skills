# habeebs-skill — Agent Instructions (Codex / generic agents)

This repository is a portable agent-skill bundle. It is consumable by **Claude Code** (as an installable plugin) and by **OpenAI Codex CLI** or any other agent that honors `AGENTS.md` plus markdown-based skills.

When you, the agent, are invoked inside a project that has installed or vendored this repo, treat the files under `skills/`, `commands/`, and `agents/` as authoritative procedures.

## The chain

```
prior-art-research → draft-spec → socratic-grill → decision-record → tdd-loop
```

Each skill produces output the next skill consumes. The handoff lines at the bottom of each skill's output (e.g. `HANDOFF: spec ready`) tell you what to do next.

## Triggering principles

- **Trigger `prior-art-research` aggressively.** Users almost never say "research." They say "I want to build X." Read between the lines.
- **Don't skip phases for speed.** If you are tempted to jump straight to writing code, you are missing the point of this methodology.
- **Internal precedent first.** Check local repos before going external. The user's own prior art is Tier 0.
- **Engineering primitives compose.** `parallel-dev`, `deep-modules`, `tdd-loop`, `vertical-slice` are not standalone — they support the chain.

## What this is NOT

- Not a replacement for Superpowers or oh-my-claudecode — it composes with them
- Not an automatic code writer — implementation still happens through TDD
- Not a survey tool — the research phase makes opinionated recommendations
- Not for trivial CRUD — let trivial things stay trivial

## Anti-patterns

If you find yourself doing any of these, stop and re-read the relevant skill:

- Surveying multiple options without recommending one
- Skipping the context-capture questions to "save time"
- Researching after deciding (research is upstream of decisions, not downstream)
- Recommending FAANG-scale solutions to non-FAANG-scale problems
- Letting the chain stall in research without producing a spec

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
