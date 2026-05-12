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

- **Anchor:** integration patterns, environment binding, greenfield-vs-brownfield adaptation, deep-skill vs shallow-skill (Ousterhout applied to skills themselves)
- **Look at:** Superpowers (obra), oh-my-claudecode (Yeachan-Heo), mattpocock/skills, Anthropic's own Skills 2.0 patterns
- **Avoid:** generic prompt-engineering advice; CI/CD setup (out of scope for this audit)
- **Last reconciliation outcome:** [pending Phase 6]
