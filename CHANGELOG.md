# Changelog

All notable changes to `habeebs-skill`.

## [1.0.0] — 2026-05-10

First stable release. All 10 skills fully fleshed out, all 4 phases tested.

### Skills (10 total)

**Research chain (Phase 1-2):**
- `prior-art-research` — convergent research; finds production patterns
- `using-habeebs-skill` — chain intro
- `draft-spec` — recommendation → vertical-slice implementation spec
- `socratic-grill` — drives ambiguity out across 7 axes
- `decision-record` — locks chosen architecture as ADR

**Engineering primitives (Phase 3):**
- `tdd-loop` — red-green-refactor per vertical slice
- `deep-modules` — Ousterhout deletion test for refactoring
- `parallel-dev` — independence-verified parallel subagent dispatch
- `vertical-slice` — tracer-bullet decomposition with HITL/AFK labels

**Meta (Phase 4):**
- `setup-habeebs-skill` — per-repo bootstrap of issue tracker + labels + domain doc layout

### Commands

`/research`, `/spec`, `/grill`, `/record`, `/tdd`, `/deepen`, `/parallel`, `/slice`, `/groundwork`

### Agent prompts

`source-fetcher`, `pattern-extractor`, `synthesizer` — used by `prior-art-research` Deep mode through `parallel-dev`

### Test results

- Phase 1 (prior-art-research): 15/15 = 100%
- Phase 2 (chain: spec → grill → record): 29/29 = 100%
- Phase 3 (engineering primitives): 32/32 = 100%
- Phase 4 (setup): 7/7 = 100%
- **Cumulative: 83/83 = 100% across 12 test scenarios**

### Inspirations

- [Superpowers](https://github.com/obra/superpowers) — methodology framing, TDD loop, subagent-driven dev
- [oh-my-claudecode](https://github.com/yeachan-heo/oh-my-claudecode) — plugin structure, orchestration primitives
- [mattpocock/skills](https://github.com/mattpocock/skills) — vertical slices (to-issues), deep-modules, setup pattern, ambiguity-grill philosophy
- [Ousterhout, *A Philosophy of Software Design*](https://www.amazon.com/Philosophy-Software-Design-John-Ousterhout/dp/1732102201) — deep modules, deletion test, strategic vs tactical

### Known limitations

- Test results are self-tests (same Claude instance wrote skills and outputs). Real-world validation requires installing in Claude Code and running against actual codebases.
- The Deep mode of `prior-art-research` relies on subagent runtime — verify your Claude Code version supports parallel subagent dispatch.
- Source-tiers.md will drift over time; needs periodic refresh.
