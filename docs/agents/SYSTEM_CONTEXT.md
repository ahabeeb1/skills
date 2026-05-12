# SYSTEM_CONTEXT

**Last refreshed:** 2026-05-11
**Refreshed by:** prior-art-research Phase 0 reconnaissance (self-meta)
**Tracked manifests:**

```
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
README.md
CHANGELOG.md
CLAUDE.md
skills/*/SKILL.md
```

## Stack

- **Runtime:** None (markdown + JSON manifests; no executable code)
- **Framework:** Claude Code plugin format + Codex-compatible AGENTS.md
- **Test runner:** JSON eval suites under `tests/evals/`; dogfood scenarios under `tests/dogfood/`
- **Type-checker / linter:** JSON-schema for plugin manifests; no markdown linter wired

## Persistence

- **Primary datastore:** git (the repo IS the deliverable)
- **ORM / driver:** N/A
- **Migrations location:** N/A
- **Other datastores:** none

## Deployment shape

- **Topology:** Distributed via `/plugin marketplace add ahabeeb1/skills` (Claude Code) or `git submodule` (Codex/generic agents)
- **Regions:** N/A — static repo
- **CI/CD:** None currently (no `.github/workflows/`)
- **Observability:** None — outcomes are evals + dogfood runs

## External services

- None — the plugin is self-contained markdown + JSON

## Scale envelope

- **Users (MAU / DAU):** [unknown — public OSS, install count untracked]
- **Skill count:** 14 in tree (12 of which are wired; 2 — `write-plan`, `agent-factors-check` — are untracked orphans as of this audit)
- **Chain depth:** 5 core (research → spec → grill → record → tdd) + 6 primitives + 2 meta

## Methodology / agent setup

- **habeebs-skill configured:** Self-application — irony noted. `docs/agents/` did not exist until this file was written.
- **Issue tracker:** GitHub Issues (assumed from `gh` availability)
- **Triage labels:** Not configured for this repo
- **Domain glossary:** Not yet populated; project-specific terms live in `skills/<name>/references/LANGUAGE.md` (deep-modules)
- **Latest ADR:** No ADRs yet

## Recent hot files

(From `git log --since="60 days"` and project memory hot-paths)

- `CHANGELOG.md` (touched every release)
- `.claude-plugin/marketplace.json`
- `.claude-plugin/plugin.json`
- `skills/prior-art-research/SKILL.md`
- `skills/using-worktrees/SKILL.md`
- `skills/tdd-loop/SKILL.md`

## Notable absences

- No `docs/agents/CONTEXT.md` (domain glossary)
- No `docs/agents/adrs/` (the methodology has never produced an ADR about itself)
- No CI/CD — releases are manual
- No `setup-habeebs-skill` ever run on this repo
- `write-plan` and `agent-factors-check` are not in `commands/`, `README.md`, `CHANGELOG.md`, or `using-habeebs-skill` chain diagram

## Open / unknown

- Whether the orphan skills are intended for v1.4.0 or experimental
- Whether `tests/dogfood/06-write-plan.md` (referenced in grep) is part of the v1.4.0 plan

## Project mode

- **brownfield** — habeebs-skill v1.3.0 published, methodology established, this audit is a refactor/integration pass on existing system

## Active steering

(none — flushed 2026-05-12 per Phase 7 flush rule; last outcome below)

## Last reconciliation outcome

**2026-05-12 — topic: parallel subagent processing across the chain (v1.6.0 candidate)**

- Anchor "Superpowers subagent-driven-development": Honored — 4-status return contract (`DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT`) and controller-implementer-reviewer triad both adopted in recommendations 9 + 12.
- Anchor "mattpocock parallel-dev": Honored with caveat — no explicit `parallel-dev` skill found in mattpocock/skills via subagent search; pattern shape covered by Superpowers + OMC equivalents.
- Anchor "OMC team/ralph": Honored — persistence loop wrapping parallel `Task()` calls informs recommendations 8 (write-plan→tdd-loop dispatch wiring) and 12 (durable dispatch state file).
- Anchor "Anthropic multi-agent research system": Honored — lead-agent + N-subagent fan-out, role specs, `CitationAgent`, scaling rules (1 / 3-5 / 10+) are foundational across recommendations 2, 3, 12.
- Avoid "(none — runtime substrate constraint explicitly relaxed)": Honored — blackboard and Temporal still rejected, but on cost/benefit grounds (concurrent writers + daemon overhead), NOT on ADR-0002 grounds. ADR-0002 may need amendment if recommendation 8 ships (durable dispatch state file at `docs/agents/dispatches/<dispatch-id>.json` is borderline — in-repo artifact, not runtime daemon).
- Coverage-failure framing: validated — the user's pain ("we missed hooks, missed subagent-driven patterns") maps cleanly to LangGraph's "LLM synthesizer fills gaps with plausible text" failure mode. Phase 2 category-completeness critic (recommendation 1) is the single highest-leverage fix.

**2026-05-12 — topic: post-merge cleanup / squash-merge ghost-commit pain (v1.5.3)**

- Anchor "auto-commit per change": Honored with caveat — framing was aspirational, not actual Superpowers contract; not imported.
- Anchor "auto-PR per change": Honored — already covered by `using-worktrees` Phase 6.
- Anchor "squash-merge recovery": Honored (with new rule) — gap in both Superpowers and habeebs-skill; filled by `using-worktrees` Phase 6.5 + `/sync` command.
- Anchor "post-merge cleanup": Honored — same as squash-merge recovery anchor.
- Look-at "obra/superpowers": Honored with caveat — pattern shape correct (`finishing-a-development-branch`), but Superpowers does NOT solve the post-squash-merge ghost-commit case either.
- Look-at "mattpocock/skills": Honored — no additional precedent on this specific gap.
- Avoid "runtime substrate": Honored — Phase 6.5 is markdown + git commands only, no daemon / hook / watcher.

**2026-05-11 — topic: environment binding / greenfield-vs-brownfield (v1.5.0 + v1.5.2)**

- Anchor "state persistence shape": Honored — in-repo markdown is the convergent pattern; ADR-0001.
- Anchor "multi-runtime portability": Honored — SYSTEM_CONTEXT.md is harness-agnostic markdown.
- Anchor "halt-vs-silent-default": Honored — mattpocock's hard-dep pattern converges with habeebs's halt-with-redirect.
- Look-at "Superpowers (obra)": Honored — plan-files-as-markdown precedent matches.
- Look-at "oh-my-claudecode (Yeachan-Heo)": Overridden — wrong layer; runtime substrate, not project-fact substrate; ADR-0002 locks the rejection of composition.
- Look-at "mattpocock/skills": Honored — independent convergence on in-repo markdown + setup-bootstrap pattern.
- Look-at "Anthropic Skills 2.0 patterns": Honored with caveat — no state-persistence guidance from Anthropic; both habeebs and OMC fill the gap differently.
- Avoid "generic prompt-engineering advice": Honored.
- Avoid "CI/CD setup": Honored — deferred.
