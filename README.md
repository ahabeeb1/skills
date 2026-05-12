# habeebs-skill

**Research-grounded engineering methodology, packaged as an installable agent-skill bundle.**

Before you build X, find how the best teams actually shipped X. Then spec it, grill it, capture the decisions, and implement it with TDD, vertical slices, and deep modules.

Works as:
- a **Claude Code plugin** (installable via `/plugin marketplace add ...`)
- a **Codex CLI** (or generic agent) skill bundle, by vendoring this repo and referencing `AGENTS.md`

Relationship to adjacent projects:
- **Uses** [Context7](https://github.com/upstash/context7) for library docs during `prior-art-research`.
- **Composes with** [oh-my-claudecode](https://github.com/yeachan-heo/oh-my-claudecode) for agent orchestration — different domain, no overlap.
- **Consolidates and re-sequences** patterns from [Superpowers](https://github.com/obra/superpowers) and [mattpocock/skills](https://github.com/mattpocock/skills) into a single methodology chain. You don't need them installed alongside — habeebs-skill absorbs their TDD, deep-module, vertical-slice, parallel-dev, worktree, and systematic-debugging patterns directly.

---

## What it does

A skill chain that grounds implementation in real production patterns rather than generic best-practices.

```
prior-art-research → draft-spec → socratic-grill → decision-record → write-plan → tdd-loop
                                       ↓
                             agent-factors-check (conditional — agent products only)
                                                              ↓
                            parallel-dev + deep-modules + vertical-slice + using-worktrees
                            + systematic-debugging (supporting primitives)
```

---

## Repository scaffolding

This repo is the plugin itself — there is no separate "source" tree. The whole repo is the deliverable.

```
habeebs-skill/
├── .claude-plugin/
│   ├── plugin.json          # Claude Code plugin manifest (name, version, deps)
│   └── marketplace.json     # Marketplace listing — enables `/plugin marketplace add`
│
├── skills/                  # The skills themselves (14 total)
│   ├── prior-art-research/
│   │   ├── SKILL.md         # Skill definition + frontmatter trigger description
│   │   └── references/      # Templates and reference material the skill cites
│   │       ├── extraction-checklist.md
│   │       ├── output-template.md
│   │       ├── source-tiers.md
│   │       ├── recon-checklist.md          # v1.1.0 — Phase 0 reconnaissance
│   │       ├── system-context-template.md  # v1.1.0 — cached repo context
│   │       └── steering-hints.md           # v1.3.0 — optional anchor/look-at/avoid
│   ├── draft-spec/          # → references/spec-template.md
│   ├── socratic-grill/      # → references/ambiguity-axes.md, grill-output-template.md
│   ├── decision-record/     # → references/adr-template.md
│   ├── write-plan/          # v1.4.0 — phased delivery doc with acceptance gates + rollback hooks
│   ├── tdd-loop/            # → references/test-seam-guide.md
│   ├── deep-modules/        # → references/LANGUAGE.md
│   ├── parallel-dev/        # → references/dispatch-record-template.md
│   ├── vertical-slice/      # → references/hitl-vs-afk.md (extended 3-label vocab in v1.4.0)
│   ├── using-worktrees/     # v1.2.0 — isolation primitive for parallel/multi-commit work
│   ├── systematic-debugging/ # v1.2.0 — reproduce → minimize → probe → fix → regression test
│   ├── agent-factors-check/ # v1.4.0 — 12-factor-agents gap-finder for agent product specs
│   ├── setup-habeebs-skill/ # → references/issue-tracker-*.md, triage-labels.md, domain.md
│   └── using-habeebs-skill/
│
├── commands/                # Claude Code slash-command shortcuts
│   ├── research.md          # /research     — invokes prior-art-research
│   ├── spec.md              # /spec         — invokes draft-spec
│   ├── grill.md             # /grill        — invokes socratic-grill
│   ├── record.md            # /record       — invokes decision-record
│   ├── plan.md              # /plan         — invokes write-plan            (v1.4.0)
│   ├── tdd.md               # /tdd          — invokes tdd-loop
│   ├── deepen.md            # /deepen       — invokes deep-modules
│   ├── parallel.md          # /parallel     — invokes parallel-dev
│   ├── slice.md             # /slice        — invokes vertical-slice
│   ├── worktree.md          # /worktree     — invokes using-worktrees       (v1.2.0)
│   ├── debug.md             # /debug        — invokes systematic-debugging  (v1.2.0)
│   ├── factor-check.md      # /factor-check — invokes agent-factors-check   (v1.4.0)
│   └── groundwork.md        # /groundwork   — invokes setup-habeebs-skill
│
├── agents/                  # Subagent prompts (used by prior-art-research Deep mode)
│   ├── source-fetcher.md    # Fetches one source, returns a structured record
│   ├── pattern-extractor.md # Identifies patterns across source records
│   └── synthesizer.md       # Produces the final convergent recommendation
│
├── docs/
│   └── BUILD-PLAN.md        # Methodology / build history
│
├── tests/
│   └── evals/               # JSON eval suites covering each phase
│       ├── prior-art-research.evals.json
│       ├── phase-2.evals.json
│       └── phase-3.evals.json
│
├── AGENTS.md                # Agent instructions for Codex / generic agents
├── CLAUDE.md                # Agent instructions for Claude Code
├── CHANGELOG.md             # Release notes
├── LICENSE                  # MIT
└── README.md                # You are here
```

### Anatomy of a skill

Every skill lives in `skills/<name>/` and follows the same contract:

- **`SKILL.md`** — required. Starts with YAML frontmatter (`name`, `description`) that the agent matches against when deciding whether to trigger. The body is the procedure the agent should execute.
- **`references/`** — optional. Templates, checklists, and reference material the `SKILL.md` cites by relative path. Loaded on demand so the main `SKILL.md` stays short.

The frontmatter `description` is the single most important field — keep it specific about when to trigger AND when not to.

### Anatomy of a slash command

Files under `commands/<verb>.md` are Claude Code slash commands. They are thin wrappers that delegate to a skill — they exist so users can type `/research` instead of "use the prior-art-research skill." Codex users invoke the skill by name directly.

### Anatomy of a subagent

Files under `agents/<role>.md` are subagent prompts with their own frontmatter (`name`, `description`, `tools`). They are dispatched in parallel by the host skill (currently only `prior-art-research` in Deep mode uses them) and return a structured record.

---

## The skills

### Core research → spec → grill → record → plan chain

| Skill | What it does | When it fires |
|---|---|---|
| `prior-art-research` | Finds 3-5 production implementations of approximately-X, extracts patterns, recommends an approach | User wants to build/implement/design any non-trivial feature |
| `draft-spec` | Turns the research recommendation into an implementation spec | After `prior-art-research` completes |
| `socratic-grill` | Drives ambiguity out of every decision through structured questioning | When a spec has open questions or implicit assumptions |
| `decision-record` | Captures chosen architecture as an ADR for future reference | After spec + grill, before implementation |
| `write-plan` | Converts ADR + sliced spec into a phased delivery doc with binary acceptance gates, dependency DAG, parallelization map, rollback hooks, and revisit triggers | After `decision-record`, when ≥3 slices or non-obvious ordering (v1.4.0) |

### Engineering primitives

| Skill | What it does | Inspired by |
|---|---|---|
| `tdd-loop` | Red-green-refactor TDD with vertical slices + two-stage review (spec compliance + code quality) | Superpowers + mattpocock |
| `deep-modules` | Ousterhout deep module check — find shallow modules, propose deepenings | mattpocock |
| `parallel-dev` | Dispatches parallel subagents into isolated worktrees, with per-subagent commit discipline | Superpowers + OMC |
| `vertical-slice` | Decomposes work into tracer-bullet vertical slices with the 3-label vocab (`AFK:full-auto` / `HITL:inline` / `HITL:approval-gate`) | mattpocock + humanlayer |
| `using-worktrees` | Isolates each feature/AFK slice in its own git worktree with verified-clean baseline; teardown via finishing-a-development-branch | Superpowers |
| `systematic-debugging` | Reproduce → minimize → hypothesis-driven probe → fix → regression test → postmortem | Superpowers + OMC trace |

### Conditional extensions

| Skill | What it does | When it fires |
|---|---|---|
| `agent-factors-check` | Pressure-tests an agent / copilot / LLM-workflow spec against the 12 factors from humanlayer/12-factor-agents. Surfaces the 6 gaps the standard 7 axes miss (tool-call schemas, state unification, pause/resume, human-as-tool, trigger surface, pre-fetch). Returns 6–13 Socratic questions interleaved into the active `socratic-grill` agenda. | Invoked from `socratic-grill` when the spec is an agent product; or directly via `/factor-check` (v1.4.0) |

### Meta

| Skill | What it does |
|---|---|
| `setup-habeebs-skill` | One-time per-repo bootstrap — issue tracker, label vocab, domain doc layout |
| `using-habeebs-skill` | Intro skill so the agent knows the chain exists |

---

## Installation

### Claude Code — via marketplace (recommended)

```bash
/plugin marketplace add ahabeeb1/skills
/plugin install habeebs-skill@habeebs-skill
```

### Claude Code — local dev

```bash
git clone https://github.com/ahabeeb1/skills.git
cd skills
claude --plugin-dir .
```

### Codex CLI (or any AGENTS.md-aware agent)

Codex does not have a plugin manager; vendor the repo instead:

```bash
# from your project root
git submodule add https://github.com/ahabeeb1/skills.git vendor/habeebs-skill
```

Then reference it from your project's root `AGENTS.md`:

```markdown
## Skills

This project uses [habeebs-skill](./vendor/habeebs-skill/AGENTS.md).
See `vendor/habeebs-skill/skills/` for the skill bundle.
```

Codex will read the vendored `SKILL.md` files on demand. Invoke a skill by name:

```
> Use the prior-art-research skill to investigate event-sourced order systems.
```

---

## Quick start

After install, just describe what you want to build:

```
> I want to build a real-time collaborative document editor for my SaaS.
```

The chain fires automatically: research → spec → grill → record → implementation primitives.

To invoke a single step (Claude Code):

```
/research "real-time collaborative editor"
/spec     # after research
/grill    # after spec
/record   # after grill
```

To invoke a single step (Codex or any agent):

```
> Run the prior-art-research skill on "real-time collaborative editor".
> Now run draft-spec on that recommendation.
> Now run socratic-grill on the spec.
> Now run decision-record on the grilled spec.
```

---

## Status

**v1.4.x — 14 skills, 13 slash commands.** See [CHANGELOG.md](./CHANGELOG.md) for the full version history.

- **Core chain (5):** `prior-art-research`, `draft-spec`, `socratic-grill`, `decision-record`, `write-plan`
- **Engineering primitives (6):** `tdd-loop`, `deep-modules`, `parallel-dev`, `vertical-slice`, `using-worktrees`, `systematic-debugging`
- **Conditional extensions (1):** `agent-factors-check`
- **Meta (2):** `setup-habeebs-skill`, `using-habeebs-skill`

Dogfood tests cover each major release. v1.4.0 added three new dogfood scenarios (write-plan rate-limiter migration, agent-factors-check support-copilot spec, HITL-labels usage-billing batch) — all PASS, with logged sharpenings tracked for v1.4.x patches.

---

## Contributing

The skill format is simple — a directory under `skills/` with `SKILL.md` and an optional `references/` folder. To add a skill:

1. Create `skills/<your-skill>/SKILL.md` with a precise frontmatter `description`.
2. Add a slash-command shortcut at `commands/<verb>.md` if you want a `/your-skill` alias.
3. Add evals under `tests/evals/` covering trigger conditions.
4. Bump version in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.

---

## License

MIT — see [LICENSE](./LICENSE).
