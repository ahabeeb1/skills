# habeebs-skill — Agent Instructions

This plugin gives Claude a research-grounded engineering methodology. When the user asks to build something non-trivial, the skills in this plugin trigger in a chain. Don't bypass them.

## The chain

```
prior-art-research → draft-spec → socratic-grill → decision-record → write-plan → tdd-loop
                                       ↓
                             agent-factors-check (only if the spec is an agent product)
```

Each skill produces output that the next skill consumes. The handoff lines at the bottom of each skill's output (e.g. `HANDOFF: spec ready`) tell you what to do next.

`write-plan` is skip-able when the slice list is trivial and ordering is obvious; otherwise it runs after `decision-record` to produce the phased delivery doc that `tdd-loop` and `parallel-dev` consume. `agent-factors-check` is a conditional extension of `socratic-grill` — it only fires when the spec is for an agent / copilot / LLM workflow / RAG / function-calling product.

## Triggering principles

- **Trigger `prior-art-research` aggressively.** The user almost never says "research." They say "I want to build X." Read between the lines.
- **Don't skip phases for speed.** If you're tempted to jump straight to writing code, you're missing the point of this plugin. The whole methodology is about NOT vibe-coding.
- **Internal precedent first.** For Modie's repos (BeanBot, salahi.app, BOL automation), check local repos before going external. The user's own prior art is Tier 0.
- **Engineering primitives compose.** `parallel-dev`, `deep-modules`, `tdd-loop`, `vertical-slice`, `using-worktrees`, `systematic-debugging` are not standalone — they support the chain. `parallel-dev` is used by `prior-art-research` in Deep mode AND consumes `write-plan`'s parallelization groups. `tdd-loop` is invoked during implementation. `deep-modules` is invoked during refactor passes. `using-worktrees` isolates non-trivial slices. `systematic-debugging` handles bugs that surface during or after a slice.

## What this plugin is NOT

- **Standalone by design (ADR-0002).** habeebs-skill has no runtime dependency on oh-my-claudecode, claude-mem, memsearch, vector stores, MCP servers, session-state directories, or any other runtime substrate. The chain is one-time-use per feature: it runs once (`research → spec → grill → record → plan → tdd`), produces durable in-repo artifacts (`docs/agents/SYSTEM_CONTEXT.md`, ADRs, plans, code + tests), then ends. Users who *also* run OMC, claude-mem, or Superpowers can — those tools are orthogonal, not coupled. Don't import them.
- Not a complement to Superpowers or mattpocock/skills — it consolidates and re-sequences their TDD, deep-module, vertical-slice, parallel-dev, worktree, and systematic-debugging patterns into the chain; you don't need them installed alongside
- Not a replacement for Context7 — it uses Context7 as a documentation source during `prior-art-research`
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

## When the user pushes back

The user (Modie) prefers:
- Bullet points and structured output
- Precise metrics over vague claims
- Direct tone — no hedging, no excessive caveats
- Citations with links
- Concrete recommendations, not "it depends"

If you find yourself hedging, stop and commit to a recommendation. The chain has `socratic-grill` to challenge it later — you don't need to pre-empt criticism in the research phase.
