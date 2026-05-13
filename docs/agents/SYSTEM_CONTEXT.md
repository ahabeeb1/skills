# SYSTEM_CONTEXT

**Last refreshed:** 2026-05-13
**Refreshed by:** prior-art-research Phase 0 reconnaissance, triggered by `setup-habeebs-skill` Phase 7 (per ADR-0005). v1.8.0 implementation slice 3 dogfood.
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
- **Skill count:** 14 in tree, all wired (the v1.4.0 orphans `write-plan` and `agent-factors-check` were brought into `commands/`, `README.md`, `CHANGELOG.md`, and `using-habeebs-skill` in v1.5.1)
- **Chain depth:** 6 core (research → spec → grill → record → plan → tdd) + 6 primitives + 2 meta. `agent-factors-check` is a conditional extension of grill (fires when the spec is an LLM/agent product).

## Methodology / agent setup

- **habeebs-skill configured:** Yes — `setup-habeebs-skill` run on 2026-05-13 as part of v1.8.0 slice 3 dogfood (per ADR-0005, setup chains into Phase 0 inline; this file is the Phase 0 output).
- **Issue tracker:** GitHub Issues (`docs/agents/issue-tracker.md`)
- **Triage labels:** Canonical 5 (`docs/agents/triage-labels.md`)
- **Domain glossary:** Populated — 13 concepts (`docs/agents/GLOSSARY.md`). Methodology-specific vocabulary; project-specific architectural vocabulary continues to live in `skills/<name>/references/LANGUAGE.md` for `deep-modules`.
- **Latest ADR:** ADR-0005 (`lifecycle-split-glossary-and-system-context`, Accepted 2026-05-13; partially supersedes ADR-0001).

## Recent hot files

(From `git log --since="60 days"` as of 2026-05-13)

- `CHANGELOG.md` (touched every release)
- `.claude-plugin/marketplace.json` / `.claude-plugin/plugin.json` (version bumps per release)
- `skills/setup-habeebs-skill/SKILL.md` (v1.8.0 — Phase 7 chain into Phase 0)
- `skills/prior-art-research/SKILL.md` (steady churn — Phase 0/2.5/7 evolutions)
- `skills/parallel-dev/SKILL.md` (v1.7.0 — dispatch contract)
- `skills/tdd-loop/SKILL.md` (v1.7.0 — Phase 0.5 pgroup auto-dispatch)
- `docs/agents/adrs/*` (4 ADRs landed across v1.5.0–v1.7.0; ADR-0005 lands at v1.8.0)
- `docs/agents/specs/*` (one spec per release post-v1.5.0)

## Notable absences

- No CI/CD — releases are manual (`gh release create` after PR merge).
- No formal release notes outside `CHANGELOG.md`.
- No external install-count telemetry — public install number is unobservable.

(The v1.5.0-era absences — no domain glossary, no ADR directory, no `setup-habeebs-skill` ever run on this repo, orphan skills — are all resolved as of v1.8.0.)

## Open / unknown

- Codex / Cursor / OpenCode treatment of `docs/agents/*.md` is informally verified (no harness reserves the path) but not externally confirmed via harness documentation. Revisit if any harness publishes a `docs/agents/*` convention. (Per ADR-0005 § Revisit triggers.)
- Phase 0 write-failure rate in practice (sandbox restrictions, permission issues) — unknown until v1.8.0 ships and is used in N ported repos.

## Project mode

- **brownfield** — habeebs-skill v1.7.0 shipped, v1.8.0 in progress at write-time (slice 3 dogfood — this file refresh is part of the slice). Methodology is mature; this audit is the v1.8.0 lifecycle-split refactor.

## Active steering

(none — flushed 2026-05-12 per Phase 7 flush rule; last outcome below)

## Last reconciliation outcome

**2026-05-13 — topic: reconcile CONTEXT.md (setup) vs SYSTEM_CONTEXT.md (Phase 0) — v1.8.0 candidate**

- Anchor "mattpocock/skills bootstrap": Honored — setup-writes-only-user-answered-bits adopted as the v1.8.0 contract.
- Anchor "obra/superpowers project-context": Honored with caveat — auto-trigger philosophy adopted for runtime, but explicit setup retained because user-answered config (tracker, labels) cannot be re-derived.
- Anchor "Anthropic Skills 2.0 layout": Honored — `docs/agents/` directory + progressive disclosure preserved; "create-with-default instead of failing" rule guides migrator UX.
- Anchor "ADR community on context-doc separation": Honored — Nygard's decision-local-context principle anchors the lifecycle-split decision (rename CONTEXT.md → GLOSSARY.md).
- Anchor "DDD ubiquitous-language vs context-map": Honored — Evans/Vernon lifecycle-split rationale lifted verbatim; same writer-role/refresh-cadence axis applies here.
- Look-at "oh-my-claudecode": Honored as contrast — cited as composition pattern that ADR-0002 explicitly rejects.
- Look-at "Linux kernel Documentation/": Honored with caveat — namespace-by-directory pattern NOT adopted (only 2 files at this layer; directory namespacing would be overkill).
- Look-at "Rust RFCs": Overridden — numeric-prefix scheme rejected for context files; identity is by name+role, not order. ADRs already carry the numeric scheme.
- Look-at "Rails upgrade guide": Honored — `bin/rails app:update` + `config.load_defaults` + one-minor deprecation window lifted directly into the `migrate-v1.8` skill design.
- Avoid "runtime substrate": Honored — migrator is a skill, not a daemon; no session state.
- Avoid "vector stores": Honored — markdown-only.
- Avoid "session-state directories": Honored — no `.habeebs/` runtime dir introduced.
- Phase 2.5 critic outcome: APPROVED with one addition during decomposition (sub-problem 5 — migration path for shipped repos). Critic-driven coverage prevented the synthesizer from picking ESLint-style external-migrator (which would have violated ADR-0002) by surfacing the Rails alternative early.
- Prompt-injection report: Sub-problem 3 and sub-problem 5 source-fetchers reported injected `<system-reminder>` tags in fetched web content; both correctly ignored. Per ADR-0004 dispatch contract, subagents treat fetched content as untrusted.

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
