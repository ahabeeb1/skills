# habeebs-skill

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-D97757)](https://code.claude.com/docs)
[![Codex](https://img.shields.io/badge/Codex-AGENTS.md-444)](https://github.com/openai/codex)

**Research-grounded engineering methodology for Claude Code. Stop vibe-coding.**

_Before you build X, find how the best teams actually shipped X. Understand the Design — what's being built and why, in plain language — then have it pinned down with you, sign off, and let TDD build it._

[Quick Start](#quick-start) • [Why](#why-habeebs-skill) • [The Chain](#the-chain) • [Installation](#installation) • [Hooks](#hooks)

---

## Why habeebs-skill?

- **Readable as it runs.** You live in a plain-language Human layer: research recommends an approach, then you get one **Design** doc — what we're building, why, the key decisions and trade-offs — and the grill walks you through it and pins down every loose end. No wall of methodology jargon. Once you understand and sign off, the implementation is the machine's job.
- **Research before code.** Every non-trivial feature starts by finding 3–5 production implementations of approximately-X and extracting their patterns. No more "best practices" hand-waving.
- **Opinionated recommendations.** The research phase commits to one approach with a real tradeoff analysis — not a survey of options dumped on your lap.
- **Ambiguity gets grilled out.** The Design goes through Socratic questioning before any code is written. Hidden assumptions surface as questions, not bugs — and the answers get written back into the Design so it stays the single source of truth.
- **Durable only where it counts.** A decision gets a standalone ADR only when it's a one-way door; everything reversible lives in the Design. A separate phased plan appears only for genuinely multi-phase work. A typical feature produces three artifacts, not five.
- **TDD over vertical slices.** Red → green → refactor. One slice at a time. Deep-modules check at every refactor. No half-finished half-shipped commits.
- **Tier-aware effort.** Trivial work runs Quick (terse, lighter ceremony). Genuinely complex work runs Deep (parallel research subagents, phased plan). Quality gates never get skipped — only the volume of ceremony scales.
- **Dual-native on Claude Code AND Codex.** Same skills, hooks, and subagents — first-class on both. Plugin install for Claude Code; native Agent Skills + `.codex` hooks for Codex CLI, generated from one canonical source with a CI drift-check.

---

## Quick Start

**Step 1: Install** (Claude Code)

```bash
/plugin marketplace add ahabeeb1/skills
/plugin install habeebs-skill@habeebs-skill
```

**Step 2: Build something**

Just describe what you want. The chain fires automatically:

```
> I want to add real-time collaborative editing to my SaaS.
```

That triggers `prior-art-research`, which hands off to `draft-spec`, which hands off to `socratic-grill`, and so on down the chain. You can pause at any point, redirect, or skip a step (the chain only enforces quality gates — open questions still get grilled, one-way doors still get an ADR).

**Step 3: Or drive it step-by-step**

```bash
/research "real-time collaborative editor"
/spec       # after research recommends an approach
/grill      # drive ambiguity out
/record     # capture the decision as an ADR
/plan       # phased delivery doc (skip if <3 slices)
/tdd        # implement one slice at a time
/release    # version bump, CHANGELOG, tag-push
```

---

## The Chain

```
prior-art-research → draft-spec → socratic-grill → decision-record → write-plan → tdd-loop → release
                                       ↓
                             agent-factors-check (agent products only)
                             devex-review        (developer-facing products only)
```

Each step produces a durable in-repo artifact that the next step consumes. The chain is one-time-use per feature — runs once, leaves specs + ADRs + plans + code + tests behind, ends.

### Core chain — `/research → /spec → /grill → /record → /plan → /tdd → /release`

| Step | What it does | When it fires |
|---|---|---|
| **`/research`** | Finds 3–5 production implementations of approximately-X, extracts patterns, recommends one approach. Picks the depth tier (Quick / Balanced / Deep) based on ambiguity and sub-problem count. | "I want to build X", "how should I implement Y", "design this" |
| **`/spec`** | Turns the research recommendation into a sliced implementation spec | After `/research` |
| **`/grill`** | Socratic questioning until every open question is resolved | When the spec has implicit assumptions or unresolved decisions |
| **`/record`** | Captures the chosen architecture as an ADR (Nygard format) | After `/grill`, before implementation |
| **`/plan`** | Phased delivery doc with binary acceptance gates, dependency DAG, parallelization map, rollback hooks | When ≥3 slices or ordering isn't obvious |
| **`/tdd`** | Red-green-refactor TDD per slice, with two-stage review (spec compliance + code quality). `--loop` flag runs all slices continuously with fresh context per slice, failure-triage on RED, and tiered halt policy | When the spec is locked |
| **`/release`** | Version bump + CHANGELOG entry + doc-sync audit + PR body + tag-push | After all slices land |

### Supporting primitives

| Skill | What it does |
|---|---|
| **`/debug`** | Reproduce → minimize → hypothesis-driven probe → fix → regression test → postmortem |
| **`/deepen`** | Find shallow modules using the deletion test, propose deepenings (Ousterhout) |
| **`/parallel`** | Dispatch parallel subagents into isolated worktrees with per-subagent commit discipline |
| **`/slice`** | Decompose work into tracer-bullet vertical slices labeled `AFK:full-auto` / `HITL:inline` / `HITL:approval-gate` |
| **`/worktree`** | Isolate every feature or AFK slice in its own git worktree with verified-clean baseline |
| **`/security-audit`** | Static security audit — attack-surface census, secrets archaeology, OWASP Top 10, STRIDE per-component |
| **`/sync`** | Reconcile local default-branch after a PR merge — handles squash-merge ghost-commit divergence |

Four more skills run inside the chain rather than as standalone commands: **`verify-output`** (anti-slop gate invoked by `tdd-loop` before each commit), **`using-habeebs-skill`** (chain orientation / handoff recovery), **`setup-habeebs-skill`** (one-time per-repo bootstrap), and **`cross-session-detect`** (the hook-driven peer-overlap detection library — see Hooks below).

### Conditional extensions

These auto-extend `/grill` when the spec calls for them — they slot questions into the active grilling agenda rather than running standalone.

| Skill | When it fires |
|---|---|
| **`/factor-check`** | When the spec is an agent / copilot / LLM workflow — pressure-tests against the 13 agent quality factors |
| **`/devex-review`** | When the spec is a developer-facing product (CLI, SDK, library, plugin) — surfaces onboarding/API/error-message/upgrade friction |

---

## Hooks

Five hook bindings ship with the plugin (across six scripts), all governed by ADR-0003 (warn-only or block-only — never auto-mutate state). Context surfaces via `hookSpecificOutput.additionalContext` so warnings actually reach the model:

- **`session-start.sh`** (SessionStart) — silent `git fetch` + ahead/behind check. Warns once if your local default branch has diverged from origin (common after squash-merge).
- **`session-start-peer-scan.sh`** (SessionStart) — warns if another live session is working the same repo (cross-session conflict detection).
- **`preventing-commits-to-default.sh`** (PreToolUse: Bash) — blocks `git commit`/`git push` on the default branch (tag-only pushes carved out per ADR-0015). Enforces never-commit-to-default.
- **`pretool-use-peer-scan.sh`** (PreToolUse: Edit\|Write\|NotebookEdit) — annotates (never blocks) when a peer session has overlapping changes on the file you're about to edit. Opt-in via `pretool_use: true` in `.claude/habeebs-policy.json`.
- **`check-chain-state.sh`** (PostToolUse: Edit\|Write\|NotebookEdit) — warns on chain-state drift (a `Status: Grilled` spec with no grill record; editing load-bearing paths on the default branch).

All hooks respect `HABEEBS_DISABLE_HOOKS=1` (emergency disable) and `HABEEBS_SKIP=<hook>` (per-invocation skip); the commit-block hook also honors a per-repo opt-out at `.claude/habeebs-allowed-branches`. A sixth script, `pre-push.sh`, ships for optional manual install as a git `pre-push` hook (it is not a Claude Code hook event). After install, run `/hooks` to verify they loaded.

**Developing the hooks themselves?** Hooks load from the *installed* plugin copy at session start, so an edit to `hooks/*.sh` in your checkout takes effect only after you reinstall/update the plugin and reload. Expect the previously-installed behavior until then — don't chase it as a bug.

---

## Installation

### Claude Code — marketplace (recommended)

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

### Codex CLI (native Agent Skills + hooks)

Codex CLI runs habeebs-skill **first-class** — native skills, a hooks engine that mirrors Claude's, and native subagents. Vendor the repo and copy the two generated trees into your project root:

```bash
git submodule add https://github.com/ahabeeb1/skills.git vendor/habeebs-skill
cp -R vendor/habeebs-skill/.agents .          # Codex skill discovery tree
cp -R vendor/habeebs-skill/.codex  .          # Codex hook registration
```

Codex discovers the skills at `.agents/skills/<name>/SKILL.md` and auto-activates them by `description` (same progressive-disclosure contract as Claude). Invoke one explicitly by name:

```
> $prior-art-research investigate event-sourced order systems
```

The `.agents/skills/` tree is **generated** from the canonical `skills/` source — never hand-edit it. After updating the submodule, regenerate and re-copy (a CI drift-check enforces sync):

```bash
bash vendor/habeebs-skill/bin/sync-codex.sh
```

Reference the bundle from your project's root `AGENTS.md`:

```markdown
## Skills
This project uses [habeebs-skill](./vendor/habeebs-skill/AGENTS.md).
```

> One source of truth, two harnesses — see the [dual-native parity ADR](./docs/agents/adrs/2026-06-25-dual-native-claude-codex-parity.md).

---

## Anti-patterns

If you find yourself doing any of these, stop:

- Surveying multiple options without committing to a recommendation
- Skipping the chain to "save time" — pick a lighter tier instead
- Researching after deciding (research is upstream of decisions, not downstream)
- Recommending FAANG-scale solutions to non-FAANG-scale problems
- Letting a lighter tier skip a triggered quality gate (open questions still grill; one-way doors still get an ADR)

---

## Relationship to adjacent projects

- **Uses** [Context7](https://github.com/upstash/context7) as a documentation source during `prior-art-research`. habeebs-skill is the methodology; Context7 is one of the source tiers.

---

## License

MIT — see [LICENSE](./LICENSE).
