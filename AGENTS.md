# habeebs-skill — Agent Instructions (Codex / generic agents)

This repository is a **dual-native** agent-skill bundle. It is first-class on **Claude Code** (as an installable plugin) and on **OpenAI Codex CLI** (as native Agent Skills + hooks), and consumable by any other agent that honors `AGENTS.md` plus markdown-based skills. Both harnesses run the same canonical skills from one source — see the [dual-native parity decision](./docs/agents/adrs/2026-06-25-dual-native-claude-codex-parity.md).

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

Codex CLI has a native **Agent Skills** system, a **hooks engine** that mirrors Claude's `hooks.json` schema, and native **subagents** — so this bundle runs first-class under Codex, not as a prose-only fallback. To set it up:

1. Vendor the repo (clone or submodule) into your project, e.g. `./vendor/habeebs-skill/`, or copy the generated `.agents/skills/` and `.codex/` trees into your project root.
2. **Skills:** Codex discovers skills at `$REPO_ROOT/.agents/skills/<name>/SKILL.md`. This tree is GENERATED from the canonical `skills/` source by `bin/sync-codex.sh` (single source of truth — never hand-edit `.agents/skills/`; a CI drift-check enforces this). Invoke a skill by name: `$prior-art-research`. Auto-activation is by the skill's `description` (progressive disclosure — only `name`+`description` load at startup), the same contract Claude uses.
3. **Hooks:** `.codex/config.toml` registers the same six hook scripts as the Claude plugin (default-branch commit block, peer scan, chain-state validator). Merge it into your project's `.codex/config.toml`, or set `CODEX_PLUGIN_ROOT` if the bundle is vendored at a subpath. Hooks honor `HABEEBS_DISABLE_HOOKS=1` and `HABEEBS_SKIP=<hook>` identically.
4. **Subagents:** Deep-tier research and `parallel-dev` dispatch the `agents/*.md` prompts via Codex's native subagents under the same 4-status contract (ADR-0004). No degradation versus Claude.
5. **Commands:** the slash commands under `commands/` are Claude-Code shortcuts. Under Codex, invoke the skill directly with `$<skill-name>` (Codex custom prompts are deprecated in favor of skills).

Path portability: every hook/command body resolves its bundle root via `hooks/lib/resolve-bundle-root.sh` (`CLAUDE_PLUGIN_ROOT` → `CURSOR_PLUGIN_ROOT` → `CODEX_PLUGIN_ROOT` → `git rev-parse --show-toplevel` → self-location), so no harness-specific env var is required.

## Map of the bundle

- `skills/<name>/SKILL.md` — the canonical skill definition; read this first when invoked
- `skills/<name>/references/` — templates and reference material the skill cites
- `.agents/skills/` — **generated** Codex discovery tree (mirror of `skills/`; built by `bin/sync-codex.sh`)
- `.codex/config.toml` — Codex hook registration (mirror of `hooks/hooks.json`)
- `bin/sync-codex.sh` — regenerates `.agents/skills/`; `--check` is the CI drift gate
- `hooks/lib/resolve-bundle-root.sh` — harness-agnostic bundle-root resolver
- `commands/<verb>.md` — Claude Code slash command shortcuts (`/research`, `/spec`, etc.)
- `agents/<role>.md` — subagent prompts dispatched by `prior-art-research` Deep mode (both harnesses)
- `docs/` — methodology/build documentation
