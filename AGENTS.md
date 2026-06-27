# habeebs-skill — Agent Instructions (Codex / generic agents)

This repository is a **dual-native** agent-skill bundle. It is first-class on **Claude Code** (as an installable plugin) and on **OpenAI Codex CLI** (as native Agent Skills + hooks), and consumable by any other agent that honors `AGENTS.md` plus markdown-based skills. Both harnesses run the same canonical skills from one source — see the [dual-native parity decision](./docs/agents/adrs/2026-06-25-dual-native-claude-codex-parity.md).

When you, the agent, are invoked inside a project that has installed or vendored this repo, treat the files under `skills/`, `commands/`, and `agents/` as authoritative procedures.

## The chain — a Human layer and a Machine layer

```
HUMAN LAYER — plain language, the user reads these:
  prior-art-research → draft-spec (writes the Design) → socratic-grill (walks + grills + sign-off)

MACHINE LAYER — technical, written for the implementing subagent:
  vertical-slice (slice list) → tdd-loop → release

CONDITIONAL: decision-record — only a one-way-door decision  ·  write-plan — only multi-phase work
```

The user lives in the Human layer: research recommends an approach, `draft-spec` turns it into the **Design** (one plain-language doc — what we're building, why, the key decisions and trade-offs), and `socratic-grill` walks the user through it, pressure-tests every aspect, writes the resolved decisions back into the Design, and earns sign-off. Only after sign-off does the Machine layer begin: `vertical-slice` decomposes the signed-off Design into slices, `tdd-loop` implements them, `release` ships. The user does not read the Machine-layer artifacts.

**Two artifacts are conditional (don't write them by default):** `decision-record` writes an ADR **only** when the Design has a one-way-door (irreversible) decision — reversible decisions live in the Design's Decided section. `write-plan` runs **only** for genuinely multi-phase / staged-rollout work. A typical feature produces three artifacts: research, the Design, the grilled-and-signed-off Design. `verify-output` gates each `tdd-loop` commit, and `deep-modules` runs at `tdd-loop`'s refactor step — neither is a separate sequential phase. `agent-factors-check` (agent products) and `devex-review` (developer-facing products) are conditional extensions of `socratic-grill`. `release` is terminal after `tdd-loop` goes GREEN.

Each skill produces output the next skill consumes. The handoff lines at the bottom of each skill's output (e.g. `HANDOFF: grill ready`) tell you what to do next. Every skill is written in the house voice — see [`docs/agents/references/skill-voice.md`](./docs/agents/references/skill-voice.md).

Every chain run executes at a depth tier — **Quick**, **Balanced**, or **Deep** (ADR-0016; see `docs/agents/references/tier-scale.md`). `prior-art-research` picks it and every downstream skill inherits it; the tier scales effort, never decision quality.

## Triggering principles

- **Trigger `prior-art-research` aggressively.** Users almost never say "research." They say "I want to build X." Read between the lines.
- **Keep the Human layer plain; keep the Machine layer technical.** The user reads research → Design → grill, so write those in plain English and gloss any non-GLOSSARY jargon on first use. The slice list, plan, and tdd-loop are for the implementing subagent — keep them technical. Every skill opens with one iron law and turns its anti-patterns into a Thought→Reality table (canonical voice reference: `docs/agents/references/skill-voice.md`).
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
- Letting the chain stall in research without producing a Design
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
3. **Hooks:** `.codex/config.toml` registers the same five event-hook scripts as the Claude plugin (default-branch commit block, peer scan, chain-state validator). Merge it into your project's `.codex/config.toml`, or set `CODEX_PLUGIN_ROOT` if the bundle is vendored at a subpath. Hooks honor `HABEEBS_DISABLE_HOOKS=1` and `HABEEBS_SKIP=<hook>` identically. Two harness-dialect notes: the commit-block hook emits Codex's JSON deny shape (`hookSpecificOutput.permissionDecision: "deny"`) as well as Claude's `exit 2`; and edit matchers use Codex's canonical `tool_name` (`^(apply_patch|Edit|Write)$`). **Version floor:** edit-triggered hooks require **Codex ≥ 0.123.0** — earlier Codex emitted PreToolUse/PostToolUse only for Bash/shell, not `apply_patch` edits (openai/codex#16732, fixed in 0.123.0 / PR #18391, which also exposes the patch body as `tool_input.command`). The v0.124.0 engine baseline this bundle targets is past that floor, so all five hooks fire on both harnesses. (Residual: on a Codex `apply_patch` event the two edit hooks receive the patch body in `tool_input.command` rather than a `file_path` field, so their file-targeting is best-effort there until a live smoke confirms it.)
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
