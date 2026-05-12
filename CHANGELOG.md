# Changelog

All notable changes to `habeebs-skill`.

## Convention

Every entry includes a **Why** line — the reason the feature exists, not just what it is. This is so future readers (humans and agents) can judge whether a feature is still load-bearing, or has been outgrown.

Versioning is [SemVer](https://semver.org/):
- **MAJOR** — breaking change to a skill's frontmatter, output template, or handoff contract
- **MINOR** — new skill, new phase, new template, or new opt-in behavior
- **PATCH** — wording fixes, internal cleanups, doc clarifications

Each release gets a git tag `vX.Y.Z` and a GitHub release with notes mirrored from this file.

## [1.5.4] — 2026-05-12

Two patches: (1) Phase 6.5 step 3 now covers the `ahead=0, behind>0` simple-fast-forward case — the most common post-merge state, missed in v1.5.3 and caught by the live dogfood run on v1.5.3's own merge. (2) Plugin install was failing with `agents: Invalid input` because `plugin.json` declared `commands: ["./commands/"]` and `agents: ["./agents/"]` — both directories are auto-discovered per the [Claude Code plugin reference](https://code.claude.com/docs/en/plugins-reference), so the explicit declarations were redundant and the validator rejected the directory-path form for `agents`. Both fields removed; auto-discovery handles them as it does for Superpowers and other reference plugins.

### Fixed

- **`using-worktrees` Phase 6.5 step 3** — added the `ahead=0, behind>0` fast-forward case. Behavior: `git merge --ff-only origin/<default>` then continue to step 6 (cleanup). Previously this case fell through to the `ahead=0` "already in sync" path and silently left local main behind origin.
  - **Why:** Caught by the live dogfood run of `/sync` against v1.5.3's own squash-merge. Local main was 1 commit behind origin (the v1.5.3 squash); the ghost-commit detection in step 4 only triggers when `ahead>0 AND behind>0`. Without the explicit FF case, the most common post-merge state was unhandled. Found-by-dogfood is the strongest test signal.
- **`/sync` slash-command description** — now lists all four `ahead/behind` cases explicitly so the discovery surface matches the SKILL.md.
- **`.claude-plugin/plugin.json`** — removed `commands` and `agents` fields. Both directories are auto-discovered when the plugin loads. The `agents: ["./agents/"]` declaration was the immediate cause of the user's `Failed to install: ... agents: Invalid input` error; `commands: ["./commands/"]` happened to validate but was equally redundant. Removing both follows Superpowers' convention and the [Anthropic plugins reference](https://code.claude.com/docs/en/plugins-reference).
  - **Why:** Validator in current Claude Code rejects directory-path strings in the `agents` array (it expects individual `.md` file paths). Auto-discovery sidesteps the schema question entirely and is forward-compatible — new agents/commands register without manifest edits.

### Plugin metadata

- `version`: 1.5.3 → 1.5.4 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- `plugin.json` is now 4 lines shorter: no `commands` field, no `agents` field

### Why this is a patch, not a minor

Both changes are bug fixes against v1.5.3's stated contract. Phase 6.5 was supposed to handle "post-merge sync" — the FF case was an omission, not a new feature. Manifest fix restores install-time validity. No new skills, no contract changes.

### Compatibility

- **Phase 6.5 FF case**: any repo that previously had local-main-behind-origin and ran `/sync` saw no action; now it gets a clean fast-forward. Pure improvement.
- **Manifest**: existing installs of v1.5.3 (where the agents field validator was lenient) continue to work; new installs no longer fail with the validation error. Auto-discovery means the `agents/` and `commands/` directories continue to register correctly.

### Dogfood

The Phase 6.5 fix was caught by running `/sync` on v1.5.3's own squash-merge — the test ran the new skill against the very state it was designed to handle, and surfaced the missing case immediately. This is the third release in a row produced by the chain dogfooding itself (v1.5.0 → v1.5.2 → v1.5.4).

---

## [1.5.3] — 2026-05-12

Closes the squash-merge ghost-commit gap. After every PR squash-merge, local default-branch carries the original feature commits whose content is now duplicated by origin's squash, so `git pull origin <default>` conflicts on every release. v1.5.3 adds `using-worktrees` Phase 6.5 + `/sync` slash command that detects the case via tree-equivalence and auto-resolves with `git reset --hard origin/<default>` when it's unambiguously a ghost-commit case. Genuine local-only work always halts. Additive only — no contract changes.

### Added

- **`using-worktrees` Phase 6.5 — Post-merge sync.** Detects ghost-commit divergence after a squash-merge and reconciles local default-branch with origin. Triggers: end of Phase 6 (after the PR is merged), start of any subsequent chain run when divergence is detected, or direct invocation via `/sync`. Ghost-commit detection compares tree SHAs between local-ahead commits and the recent origin window (default 10 commits, configurable via `/sync --squash-window=N`). Safe-reset only fires when **every** local-ahead commit has a tree-match in origin; otherwise halts and asks the user. Also auto-cleans merged feature branches via `gh pr list --state merged` (or `git branch --merged` fallback), removing the worktree first.
  - **Why:** User raised this on 2026-05-12 — "I am constantly seeing merge conflicts with squashing and pushing; our skill should auto-resolve things like that." Prior-art-research confirmed the gap is unowned: Superpowers' `finishing-a-development-branch` handles pre-merge cleanup (4 options + worktree removal) but doesn't address post-squash-merge ghost commits; their `using-git-worktrees` is pre-work setup only; their TDD skill doesn't specify commit conventions. mattpocock/skills doesn't touch this either. v1.5.3 is the first plugin to solve it natively.

- **`/sync` slash command.** Stand-alone entry point that jumps directly to Phase 6.5. Use after any PR merge from any session, even if you didn't run the chain to produce the merge. Halt conditions documented inline so failures are diagnostic, not destructive.
  - **Why:** Phase 6.5 fires across sessions (the merge typically happens at end-of-PR, the next pull is on a later session), so a dedicated entry point matters. Mirrors the cadence of `/research`, `/spec`, `/grill` etc. — discoverable via slash menu.

### Changed

- **`using-worktrees` Lifecycle diagram** updated to show Phase 6.5 as the final stage after the merge actually lands on origin. The diagram now distinguishes "PR merge happens on GitHub" from "local repo reconciles with the new origin state."
- **`using-worktrees` Anti-patterns** gain two entries: "Manually fighting squash-merge ghost commits" (run Phase 6.5 instead of resolving by hand) and "Auto-resetting on `ahead>0, behind=0`" (signals real local work; Phase 6.5 halts by design).
- **`docs/agents/SYSTEM_CONTEXT.md`** — first use of the v1.5.2 steering-flush rule. The v1.5.0-era `Active steering` block (environment binding / greenfield / look-at OMC etc.) is now under `Last reconciliation outcome` along with today's post-merge-cleanup outcome. Active steering reads `(none — flushed YYYY-MM-DD)` until the next research run captures new anchors.

### Plugin metadata

- `version`: 1.5.2 → 1.5.3 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- New slash command: `/sync`

### Why this is a patch, not a minor

No new skills (Phase 6.5 lives inside the existing `using-worktrees` skill), no breaking contract changes, no required setup. The flush of `SYSTEM_CONTEXT.md`'s `Active steering` block is a documentation-format dogfood of the v1.5.2 rule, not a contract change. Repos with active steering they want to preserve can copy it back manually before the next chain run (per the v1.5.2 opt-in-persistence rule).

### Compatibility

Fully backward compatible with v1.5.x. Repos that haven't experienced the squash-merge pain see no change — Phase 6.5 simply runs through with `ahead=0` and reports a one-line "already in sync." Repos with stale ghost commits get auto-resolved on next `/sync` invocation.

### Dogfood

This release was itself produced by the chain: `prior-art-research` (Quick mode, targeted at Superpowers' commit/PR automation, steered against pretending OMC composition could help) → recommendation skipping `draft-spec` and `socratic-grill` (the slice batch was small and unambiguous) → implementation. The research output is preserved in conversation; the steering reconciliation outcome lands in `SYSTEM_CONTEXT.md`'s `Last reconciliation outcome` section per v1.5.2.

---

## [1.5.2] — 2026-05-12

Locks the "habeebs-skill is standalone" rule across every discovery surface, and stops `Active steering` from bleeding across unrelated chain runs. Both gaps surfaced from a v1.5.0-style self-audit on the OMC→habeebs-skill transition — the audit recommended OMC composition and the user rejected it. ADR-0002 captures the rejection so future audits don't re-litigate.

### Added

- **ADR-0002: habeebs-skill is standalone — no runtime-substrate composition** (`docs/agents/adrs/0002-habeebs-skill-standalone.md`). The repo's second ADR. Documents the rejection of OMC composition (and by extension claude-mem, memsearch, vector stores, MCP-as-state, native runtime substrates). The "Alternatives considered" section captures all four paths considered, including the verbatim v1.5.0-audit recommendation as the rejected primary alternative.
  - **Why:** The OMC composition question recurs every audit. ADR-0001 already established in-repo markdown as load-bearing; ADR-0002 is the corollary that locks "no external runtime, period." Together they form a stable posture: project facts live in `docs/agents/`, the chain has no runtime concerns of its own, multi-harness portability is preserved by construction.

- **Plan 0002: `docs/agents/plans/0002-habeebs-skill-standalone.md`** — first plan ever produced under `write-plan`'s convention (`<NNNN-slug>.md`, ADR-paired). 9 slices across 3 phases (lock rule → add steering-flush → wire and release). Slice #9 is `HITL:inline` for the tag-and-release gate; all others are `AFK:full-auto`.

- **Steering flush at Phase 7.** `skills/prior-art-research/references/steering-hints.md` gains a "Flush at end of chain" section; `skills/prior-art-research/SKILL.md` Phase 7 references it. Default: move `## Active steering` → `## Last reconciliation outcome` after handoff lines fire. Persistence across a multi-chain campaign is opt-in.
  - **Why:** v1.3.0 added optional steering anchors and made them inheritable through the chain via `SYSTEM_CONTEXT.md`. The inheritance worked, but the lack of a flush rule meant anchors persisted across topic switches — the next unrelated `prior-art-research` run silently inherited stale weighting. The 2026-05-12 self-audit caught its own steering biasing the search; closing the loop.

### Changed

- **`CLAUDE.md`** — "What this plugin is NOT" first bullet rewritten. The v1.5.1 wording ("Not a replacement for oh-my-claudecode — it composes with OMC's orchestration") contradicted ADR-0002 and was the root cause of the audit-loop. New wording leads with **Standalone by design (ADR-0002)** and is explicit about orthogonality (other tools can coexist) vs coupling (no dependency).
- **`skills/using-habeebs-skill/SKILL.md`** — new "Standalone by design (ADR-0002)" section above "When to skip the chain." Auto-loads with every chain invocation, so every agent sees the rule.

### Plugin metadata

- `version`: 1.5.1 → 1.5.2 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`

### Why this is a patch, not a minor

No new skills, no new behavior in existing skills (the steering-flush rule is documentation-only — Phase 7 already fired handoff lines; the flush is a new instruction inside Phase 7, not a new contract surface for downstream skills). Pure clarification + locked decision. Backward compatible with v1.5.x — the flush only affects `SYSTEM_CONTEXT.md` files that have `## Active steering` content, and the move-to-`Last reconciliation outcome` is non-destructive.

### Compatibility

Fully backward compatible with v1.5.1. Repos that have `SYSTEM_CONTEXT.md` with active steering get the flush behavior on the next `prior-art-research` Phase 7. Repos without steering see no change. No version bump required in any downstream config.

### Out of scope (deferred to v1.6.0)

- **Self-bootstrap of this repo.** The audit surfaced that `setup-habeebs-skill` has never been run here — `docs/agents/CONTEXT.md`, `triage-labels.md`, `issue-tracker.md`, and the `## Agent skills` block in `AGENTS.md`/`CLAUDE.md` don't exist. Tracked as v1.6.0 candidate; substantial enough to warrant its own release.
- **Plan-file naming convention final pick.** v1.5.2 establishes `<NNNN-slug>.md` (ADR-paired) by writing the first plan that way; the question of whether to also support `YYYY-MM-DD-<slug>.md` (Superpowers-style date prefix) is deferred. Not blocking; current naming is precedent now.

---

## [1.5.1] — 2026-05-11

Wiring catch-up for the v1.4.0 skills (`write-plan`, `agent-factors-check`). These were committed in v1.4.0 with SKILL.md + references + dogfood tests, but the surrounding discovery surfaces — slash commands, README skill tables, CLAUDE.md chain diagram, `using-habeebs-skill` chain diagram, `plugin.json` keyword sync — weren't included. Originally planned as v1.4.1 but the wiring PR was open while v1.5.0 merged first, so this becomes v1.5.1 to preserve semver order.

### Added

- **`commands/plan.md`** — `/plan` slash command that delegates to `write-plan`. Halt-on-missing-input contract documented in the command body so the user sees the requirement up front (ADR, sliced spec, grill record, `SYSTEM_CONTEXT.md`).
- **`commands/factor-check.md`** — `/factor-check` slash command that delegates to `agent-factors-check`. Documents the trigger-test honor rule so direct invocation on non-agent specs halts with `SKIP` rather than producing noise.

### Changed

- **`README.md`** — chain diagram now shows the v1.4.0 shape (`decision-record → write-plan → tdd-loop` with `agent-factors-check` as a conditional sibling of `socratic-grill`); skill count updated to 14; new `Conditional extensions` table row for `agent-factors-check`; `write-plan` row added to the core chain table; `vertical-slice` row updated with the 3-label vocab; command list updated with `/plan` and `/factor-check`; Status section rewritten to reflect the v1.4.x+v1.5.x reality.
- **`CLAUDE.md`** — chain diagram updated to include `write-plan` and the conditional `agent-factors-check` branch; engineering-primitives line extended to include `using-worktrees` and `systematic-debugging`.
- **`skills/using-habeebs-skill/SKILL.md`** — chain-at-a-glance diagram updated to show `write-plan` between `decision-record` and `tdd-loop` and the `agent-factors-check` sibling branch under `socratic-grill`; supporting-primitives section extended with `using-worktrees` and `systematic-debugging`; new `Conditional extensions` section describes `agent-factors-check` as an opt-in extension that fires only on agent products.
- **`.claude-plugin/plugin.json`** — keywords list synced to include `plan`, `agent-factors`, `12-factor-agents`, `human-in-the-loop` (these were already in `marketplace.json` v1.4.0 but missed in `plugin.json`); description updated to reflect the v1.4.0 chain shape.

### Plugin metadata

- `version`: 1.5.0 → 1.5.1 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`

### Why this is a patch, not a minor

No new skills, no new behavior, no new contracts. Pure documentation + command-binding catch-up so the v1.4.0 skills are discoverable through every surface (README, CLAUDE.md, `using-habeebs-skill`, and slash commands) — which is what made them surface in the v1.5.0 self-audit as "orphans" in the first place.

### Compatibility

Fully backward compatible with v1.5.0 — only adds discovery surfaces; no existing skill bodies, references, halt contracts, or handoffs changed.

---

## [1.5.0] — 2026-05-11

Makes `docs/agents/SYSTEM_CONTEXT.md` load-bearing. The file was already written by `prior-art-research` Phase 0 (since v1.1.0) and read by downstream skills, but no skill *required* it — so silent-defaults masked unconfigured repos. v1.5.0 closes that gap with a halt-if-missing rule on 5 chain skills, a small UX polish to keep the new mandatory bootstrap painless, and the repo's first ADR documenting the choice.

### Added

- **Pre-flight environment check on 5 chain skills.** `draft-spec`, `socratic-grill`, `decision-record`, `write-plan`, and `tdd-loop` each gain a "Pre-flight — Environment check" block before Phase 1. If `docs/agents/SYSTEM_CONTEXT.md` is missing, halt with `SETUP REQUIRED: ... Run /groundwork (preferred) or /research (writes the file via Phase 0 reconnaissance) first.` `prior-art-research` is exempt — its Phase 0 IS the writer.
  - **Why:** Before v1.5.0, missing the file meant chain skills silent-defaulted on triage labels / issue tracker / domain glossary. Most users never ran `setup-habeebs-skill` because nothing required it, and SYSTEM_CONTEXT.md was advertised as the chain's shared memory primitive but was decorative in practice. The halt-redirect makes bootstrap mandatory without making it painful (one-keystroke defaults — see UX polish below). Engineering primitives (`parallel-dev`, `deep-modules`, `vertical-slice`, `using-worktrees`, `systematic-debugging`) are NOT gated — they run from inside the chain (already covered) or standalone (debugging — halting hurts more than helps).

- **ADR-0001: Make SYSTEM_CONTEXT.md the load-bearing environment-binding protocol** (`docs/agents/adrs/0001-environment-binding-via-system-context.md`). The repo's first ADR. Documents the choice of in-repo markdown over alternatives (tmux session state, vector-backed memory, hierarchical AGENTS.md, declarative project-mode field), the halt-if-missing contract, and the explicit *non-decision* to add a project-mode field — preventing the next audit from re-litigating.
  - **Why:** The methodology dogfoods itself. This is the first time a habeebs-skill ADR records a habeebs-skill design choice. The "Alternatives considered" section is the most load-bearing content in the file — it captures the audit's evidence so future readers can judge whether the rejections still hold.

- **`docs/agents/adrs/README.md`** index file for ADRs, with conventions (Nygard format, zero-padded monotonic numbering, status lifecycle, never-delete rule) and a table of contents.

- **`docs/agents/specs/v1.5.0-environment-binding.md`** — the spec produced by `draft-spec` for this release. Kept as a reference for future-similar work and to demonstrate the chain dogfooding itself end-to-end.

### Changed

- **`setup-habeebs-skill`** — each of the three setup sections (issue tracker, triage labels, domain doc layout) now shows the default value and a one-keystroke Enter-accept hint. Keeps the new mandatory bootstrap from feeling like friction.
  - **Why:** Making bootstrap mandatory raises the first-install bar. If the user just wants defaults, they should be able to clear all three sections with three Enter presses. Friction proportional to value: zero, since defaults are sensible for most repos.

- **`parallel-dev`** — adds a "Single-writer invariant for SYSTEM_CONTEXT.md" note before Phase 5. Documents the existing invariant explicitly: parent's `prior-art-research` Phase 0 is the sole writer; subagents are read-only. No behavior change.
  - **Why:** Concurrent subagents reading SYSTEM_CONTEXT.md mid-write would corrupt their view. The chain already orders Phase 0 before any parallel dispatch, so the race can't happen — but the invariant was implicit. Documenting makes it explicit for future maintainers.

### Plugin metadata

- `version`: 1.4.1 → 1.5.0 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`

### Why this is a minor, not a patch

New required pre-flight phase on 5 skills, new mandatory artifact (`SYSTEM_CONTEXT.md`), and a contract change (chain halts on missing file where it used to silent-default). Backward compatible *in spirit* — running `/groundwork --defaults` once unblocks any pre-v1.5.0 repo — but the chain's behavior on a fresh repo is materially different. MINOR per semver.

### Dogfood

This release was itself produced by the chain: `prior-art-research` (audit on env integration / greenfield-brownfield / redundancy) → `draft-spec` (initial 7-slice plan) → `socratic-grill` (cut to 2 slices via Q1–Q7 resolution + post-grill scope cut that removed the project-mode field) → `decision-record` (ADR-0001) → implementation. The spec, the grill record (in-conversation), and the ADR are all in-repo artifacts.

### Compatibility

- Repos that already have `docs/agents/SYSTEM_CONTEXT.md` from v1.4.x: no schema change; new field-free format works as-is.
- Repos without the file: first chain invocation halts with the redirect message. `/groundwork --defaults` (or `/research` for users who want recon before bootstrap) clears the halt.

---

## [1.4.0] — 2026-05-11

Adds the definitive-plan step the chain was missing, the agent-product gap-finder, and a richer HITL vocabulary. Three features bundled because they share an audience (anyone running the chain on a non-trivial slice batch) and they reinforce each other (the plan writes labels; agent-factors-check feeds questions back into grill before plan; HITL:approval-gate slices appear in the plan's slice table).

### Added

- **New skill: `write-plan`.** Sits between `decision-record` and `tdd-loop`. Converts a locked ADR + sliced spec into `docs/agents/plans/<slug>.md` — phased delivery story with binary acceptance gates, dependency DAG, parallelization map, per-phase rollback hooks (or explicit one-way-door declarations), risk register, and revisit triggers. Status field lifecycle: Proposed → Active → Done → Superseded. Update mode bumps `Last updated` and appends a Change log entry; never re-writes a passed phase.
  - **Why:** The chain went straight from "decision locked" to "implement one slice at a time" with no orchestration artifact tying slices together. Every major skill ecosystem we surveyed has this step — Superpowers' `writing-plans`, OMC's `ralplan`, mattpocock's implicit slice ordering, Claude Code's built-in Plan mode. Without it, `parallel-dev` had no contract for which batches were dispatchable; `tdd-loop` had no authoritative slice order; phase boundaries went undeclared, which meant rollback paths were silent (worst case: a one-way door no one declared, blowing up in production).
  - Positioned after `decision-record` (not before — planning multiple approaches is waste; planning the chosen one is the value). Distinguished from `vertical-slice` (which *decomposes*) — `write-plan` *sequences and gates* the decomposition.
  - New references: `skills/write-plan/references/plan-template.md` (the strict format), `skills/write-plan/references/phase-gate-examples.md` (good vs. bad gates by phase shape, with the "two tests" — binary in production AND user/system-observable).
  - Wired upstream: `decision-record` HANDOFF now offers `write-plan` as the next step (with a fallback to skip directly to `tdd-loop` for trivial slice counts). `tdd-loop` upstream section now reads the plan for authoritative slice order.

- **New skill: `agent-factors-check`.** Conditional domain extension invoked *from* `socratic-grill` (not a new chain phase) when the spec is for an agent / copilot / chatbot / LLM workflow / RAG system / function-calling product. Runs the spec against the 12 factors from [humanlayer/12-factor-agents](https://github.com/humanlayer/12-factor-agents) and surfaces the 6 gaps the chain's standard 7 axes don't cover — tool-call schemas (F1/F4), state unification (F5), pause/resume API (F6), human-as-tool (F7), trigger surface (F11), and pre-fetch context (F13). Returns 6–13 Socratic questions interleaved into the active grilling agenda; triages them into Must-grill / Should-grill / Nice-to-grill.
  - **Why:** habeebs-skill's 7 ambiguity axes (performance, failure modes, scale, concurrency, migration, reversibility, observability) are domain-agnostic — they catch production-readiness gaps but not agent-shape gaps. For agent products, "what's the tool-call schema?" and "how does the agent pause when a human approval is needed?" are make-or-break, and the standard axes leave them implicit. Folding into `socratic-grill` instead of adding a chain phase keeps the main chain lean (80%+ of specs aren't agent products and don't need this overhead). The conditional trigger ("does this orchestrate multiple LLM calls OR use tool/function calls?") fires precisely.
  - New references: `skills/agent-factors-check/references/factor-check-template.md` (output format), `skills/agent-factors-check/references/factor-questions-bank.md` (concrete question templates per factor — used as starting points, not pasted verbatim).
  - Cites humanlayer/12-factor-agents as the canonical factor source; cites [humanlayer](https://github.com/humanlayer/humanlayer) (the SDK) as the F7 reference implementation.

- **Extended HITL/AFK vocabulary — three labels instead of two.** Bare `HITL` and `AFK` are replaced with `HITL:inline`, `HITL:approval-gate`, and `AFK:full-auto`. The new vocabulary distinguishes *where* a human gates a slice:
  - `AFK:full-auto` — no human in the loop; eligible for `parallel-dev` autonomous dispatch.
  - `HITL:inline` — human in the active chat session answers a question mid-slice (e.g., domain naming, deferred architectural choice). Cheap, conversational pause.
  - `HITL:approval-gate` — human approves out-of-band (Slack / email / queue / humanlayer). Use for production data migrations, billing decisions, compliance sign-off, external coordination, or whenever a paper trail is required.
  - **Why:** Bare HITL conflated two fundamentally different runtime shapes. An "in the chat, answer my question" pause is sub-second; an out-of-band approval can take hours. Treating them as one label forced `parallel-dev` to be conservative on every HITL slice (excluding even cheap inline ones from the dispatch eligibility check), and meant `tdd-loop` had no instruction on how to *wait* for an out-of-band approval. The three-label system lets `parallel-dev` correctly accept only `AFK:full-auto`, lets `tdd-loop` distinguish "ask in chat" from "suspend until external approval", and lets the plan's slice table show the runtime shape per row.
  - Updated reference: `skills/vertical-slice/references/hitl-vs-afk.md` — full decision tree, tiebreaker hierarchy (paper trail > org-chart approval > async timing > chat presence), mid-slice discovery rule (an `AFK` slice that surfaces an approval need at runtime re-labels itself), and end-of-slice-review-is-NOT-HITL clarification.
  - Updated `skills/vertical-slice/SKILL.md` Phase 4 to apply the new vocabulary and require gate-detail naming (specific role + specific channel; rejects "the team" / "anyone" / "whoever's around").
  - Updated `skills/parallel-dev/SKILL.md` to exclude both HITL variants from dispatch eligibility.
  - Updated `skills/decision-record/references/adr-template.md` with a "Reference implementations cited" subsection — humanlayer named there as the canonical impl for `HITL:approval-gate` slices.

### Changed

- **`decision-record` HANDOFF** now offers `write-plan` as the next step before `tdd-loop`. The hand-off includes a one-line decision rule for when to invoke (3+ slices, non-obvious ordering, or before parallel-dev) vs. when to skip directly to `tdd-loop`.
- **`tdd-loop` integration section** updated: when a plan exists, it is the authoritative slice order, superseding raw spec order. Phase-gate evaluation happens when all slices in a phase are Done.
- **`socratic-grill` Phase 1** gained a domain-extension hook: if the spec is for an agent product, invoke `agent-factors-check` before Phase 2 to augment the grilling agenda.

### Dogfood tests (`tests/dogfood/`)

Three new tests with criterion-by-criterion rubrics, multiple adversarial cases, and **honest surfacing of weaknesses** (not pass-the-test rubrics):

- `06-write-plan.md` — rate-limiter migration scenario, 12/12 happy-path criteria, 5 adversarial cases (circular dep, all-parallelizable, bad gate, no rollback, update mode). 5 v1.4.1 follow-up improvements logged from the adversarial cases. PASS.
- `07-agent-factors-check.md` — customer-support copilot spec, 10/10 happy-path criteria, 5 adversarial cases including a non-agent SKIP test, a borderline LLM-as-feature test, a faked-Addressed-on-F7 test, and a multi-agent shape test. 2 in-flight v1.4.0 edits + 1 known limitation logged for v1.5.0 (multi-agent extension). PASS.
- `08-hitl-labels.md` — usage-based-billing batch with 8 mixed-shape slices, 9/9 happy-path criteria, 5 adversarial cases including mislabel cleanup, mid-slice approval discovery, vague approver rejection, and pre-v1.4.0 label migration. 4 in-flight v1.4.0 edits applied. PASS.

### Edits applied from dogfood findings (before merge)

- `agent-factors-check/SKILL.md` — Phase 1 trigger phrasing extended to catch single-turn tool-using products; Phase 2 N/A score given explicit legitimacy (and explicit exclusion of "I don't know" as a valid N/A reason).
- `vertical-slice/references/hitl-vs-afk.md` — added tiebreaker hierarchy for conflicting signals, mid-slice approval-discovery runtime rule, and "end-of-slice review is NOT HITL" clarification.
- `vertical-slice/SKILL.md` Phase 4 quality checklist — added gate-detail validation rule rejecting vague approver names.

### Plugin metadata

- `version`: 1.3.0 → 1.4.0 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- Skill count: 12 → 14 (added `write-plan`, `agent-factors-check`)

### Compatibility

- Old `HITL` and `AFK` bare labels remain readable in completed work — `hitl-vs-afk.md` migration note covers re-labeling on next touch. No bulk renames required.
- `write-plan` is optional in the chain — `decision-record` HANDOFF allows skipping directly to `tdd-loop` for trivial slice counts.
- `agent-factors-check` is conditional — fires only when the spec is for an agent product. Generic CRUD specs never see it.
- All `next-skills` frontmatter updates are additive.

### Known limitations

- **Multi-agent shape coverage** — the 12 factors are written for single-agent shapes. `agent-factors-check` inherits that blind spot. Logged for v1.5.0 as either a sub-section of `agent-factors-check` or a sibling `multi-agent-shape-check` skill. Surfaced explicitly in `07-agent-factors-check.md` A4.

---

## [1.3.0] — 2026-05-10

### Added

- **`prior-art-research` Phase 1 — Optional steering hints.** The user can now (optionally) supply three free-text slots alongside scale/priorities: `Anchor:` (terms or techniques to bias queries toward), `Look at:` (specific projects/teams/architectures to fetch first), and `Avoid:` (out-of-scope terms or anti-patterns). Steering is purely additive — Phase 2 decomposition still runs autonomously; anchors weight Phase 4 query construction and Phase 5 source ranking. Phase 2 echoes the captured steering line so the user can confirm before search burns budget.
  - **Why:** Anthropic's prompt-engineering canon endorses precision when the user has it ("reference specific files, mention constraints, point to example patterns"), but `prior-art-research` had no surface to receive that precision — the user had to either type it into the open prompt and hope, or accept the agent's autonomous decomposition wholesale. Steering closes the gap *without* mandating direction (still works for vague-idea flows). The pattern is borrowed from OMC's `deep-interview` mode-flag prompt injection and extended to free-text anchors. The user dogfooded it on the meta-question that drove this release: their prompt asking the agent to "search Claude repos and guides" was textbook steering.
  - New reference: `skills/prior-art-research/references/steering-hints.md` — the three slots, when steering is appropriate, the override rule, and worked examples (rate limiter / background jobs / no-steering default).

- **`prior-art-research` Phase 6 — Steering reconciliation sub-section** (only rendered when steering was captured). For each anchor, the report must state one of: `Honored`, `Honored with caveat`, or `Overridden` (with citation). Anchors silently ignored are a bug.
  - **Why:** Without forced reconciliation, anchors quietly become anchoring bias — the agent honors a bad hint because the user supplied it, not because the evidence supports it. Reconciliation makes overrides loud and auditable. This preserves the "be opinionated, don't survey" discipline that the rest of the skill is built on.

### Changed

- **`prior-art-research/references/system-context-template.md` gained an `Active steering` section.** Steering anchors and the latest reconciliation outcome are written here so downstream chain skills (`draft-spec`, `socratic-grill`, `decision-record`) inherit the same hints and don't re-ask. Updated in place when the user revises.
  - **Why:** Without inheritance, the user would have to re-type anchors into every chain skill, or watch `draft-spec` propose specs that contradict an anchor `prior-art-research` already honored. SYSTEM_CONTEXT was already the chain's shared memory primitive; steering belongs there.

- **`prior-art-research/references/output-template.md`** now contains the `Steering reconciliation` table slot between Recommendation and Decisions-to-make-next. Rendered only when steering exists; omitted entirely otherwise.

- **`using-worktrees` now ships an explicit Branching strategy section.** Hard rules: never commit to the default branch; one worktree per branch (1:1); never nest worktrees; safe-delete by default (`-d`, not `-D`); push before removing worktree. Branch naming: `feature/`, `fix/`, `chore/`, `docs/`, `spike/`, `slice-<N>/` prefixes with hyphenated slugs ≤6 words. Linear history policy: rebase onto default-branch during the feature, never merge into the feature branch; squash-and-merge or rebase-and-merge on the PR side, never a merge commit on the default branch. Full lifecycle from create → push → PR → squash → cleanup laid out as a single ASCII pipeline.
  - **Why:** v1.2.0 added the mechanics of worktrees but left the *policy* on top of them implicit. Reviewing Superpowers' `using-git-worktrees` showed the same gap there — they cover worktree mechanics but not branch naming, never-commit-to-main, or rebase-vs-merge. Without an explicit policy, the skill auto-creates worktrees but agents still produce inconsistent branch names, occasionally try to commit to `main`, and create merge commits on the default branch. The explicit policy section closes those gaps. The skill also now adapts to the repo's existing branch conventions if they deviate from the default — `git branch --list` is checked first.
  - Added mandatory **nesting check** to Phase 2 (`git rev-parse --git-dir` vs `--git-common-dir`) — never create a worktree inside another.

### Process

- **First release shipped through the new branching policy.** This v1.3.0 lands on `chore/v1.3.0-release` → PR → merge, not direct-to-main. Direct push to `main` is blocked by the permission rule the user just added, matching the policy we just shipped.

### Plugin metadata

- `version`: 1.2.1 → 1.3.0 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`

### Compatibility

- Steering is fully opt-in — runs that don't supply it behave exactly as in v1.2.1 (no echoed steering line in Phase 2, no reconciliation sub-section in Phase 6).
- Existing `SYSTEM_CONTEXT.md` files are forward-compatible — the `Active steering` section is appended on next refresh, never required.

---

## [1.2.1] — 2026-05-10

### Changed

- **`tdd-loop` gained Phase 0 — Decide whether to run in a worktree.** A small decision matrix runs BEFORE RED: auto-invoke `using-worktrees` for multi-commit slices, parallel-dev batches, work on the default branch, infra/migration touches, or when the source checkout has unrelated uncommitted changes. Stay in the current tree for single-commit trivial work, spikes, or when the user opted out.
  - **Why:** v1.2.0 added the `using-worktrees` skill and wired it into `parallel-dev` Phase 4, but `tdd-loop` only listed it under `next-skills:`. That meant a user invoking `/tdd` directly never got automatic worktree isolation, even for multi-commit features. v1.2.1 closes that gap with an explicit decision step — automatic *when it makes sense*, skipped when it doesn't.
  - The decision is logged in one line at the start of the loop so the user always sees what was chosen and why.

### Plugin metadata

- `version`: 1.2.0 → 1.2.1 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`

---

## [1.2.0] — 2026-05-10

Aligns the chain with the two proven methodologies this plugin builds on — Superpowers (obra) and oh-my-claudecode (Yeachan-Heo) — by importing the patterns they shipped and that we lacked.

### Added

- **`skills/using-worktrees/`** — Each non-trivial feature or AFK slice runs in its own git worktree on its own branch with a verified-clean test baseline before work starts. Phase 6 includes the `finishing-a-development-branch` teardown (rebase → push → PR → remove worktree).
  - **Why:** Without this, concurrent `parallel-dev` subagents race on the same working tree, and a TDD session in progress gets polluted by mid-stream merges. Superpowers proved this pattern is load-bearing; OMC's `team` mode uses tmux + worktrees for the same reason. Worktrees are the right primitive: cheap, native to git, and portable across Claude Code / Codex / generic agents.
  - New slash command: `/worktree`.

- **`skills/systematic-debugging/`** — Six-phase debugging method: reproduce → minimize → hypothesis-driven probe → fix → regression-test → postmortem (for non-trivial bugs).
  - **Why:** The chain had no canonical destination for bug-fix work. The `tdd-loop` RED step is great when the failure mode is expected; when it isn't, you need a hypothesis-driven probe procedure, not a guess-fix loop. Superpowers' `systematic-debugging` is the proven pattern; OMC's `trace` lane is adjacent in spirit. Posting fixes without a reproduction is the canonical anti-vibe failure mode; this skill prevents it.
  - New slash command: `/debug`.

- **`next-skills:` frontmatter on all chain skills.** Declares each skill's downstream handoffs in machine-parseable form alongside the existing `HANDOFF:` text lines.
  - **Why:** OMC Skills 2.0 formalized chain coupling via `pipeline:` / `next-skill:` frontmatter. Our `HANDOFF:` text lines worked but weren't parseable by tooling/IDE integrations. Adding `next-skills:` is additive — text handoffs still drive runtime behavior; frontmatter unlocks tooling that wants to visualize or validate the chain.

### Changed

- **`tdd-loop` Phase 5 now requires two-stage review** before commit:
  - **Pass 5a — Spec-compliance review:** map every acceptance criterion in the slice to a line of code or test that satisfies it. If any criterion is unmappable, return to GREEN or revise the spec.
  - **Pass 5b — Code-quality review:** explicit `deep-modules` check as a final gate before commit.
  - Phase 6 (formerly Phase 5) is now "Check in and advance" and adds an explicit handoff to `systematic-debugging` when an unexpected failure mode surfaced during RED.
  - **Why:** Superpowers' subagent-driven-development showed that a one-pass review confuses spec compliance with code quality — they get different answers from different probes. Splitting them makes both auditable. The fix WITHOUT this discipline tends to pass tests but drift from the spec.

- **`parallel-dev` Phase 4 now invokes `using-worktrees` once per artifact-producing subagent.** Each subagent runs in `cwd=<worktree-path>`; research subagents that return structured records (not files) are exempt.
  - **Why:** Two concurrent subagents writing to the same working tree was always going to lose one of their commits or corrupt the index. The worktree primitive eliminates this category of failure entirely.

### Plugin metadata

- `version`: 1.1.0 → 1.2.0 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- Skill count: 10 → 12 (added `using-worktrees`, `systematic-debugging`)
- Slash commands: 9 → 11 (added `/worktree`, `/debug`)

### Compatibility

- All `next-skills` additions are additive; v1.1.0 consumers continue to work
- Worktree dispatch in `parallel-dev` falls back to single-tree mode if the runtime can't create worktrees (sandboxed environments)
- Two-stage review adds time per slice; for trivial slices, both passes complete in ~1 minute

---

## [1.1.0] — 2026-05-10

### Added

- **`prior-art-research` Phase 0 — Reconnaissance.** A pre-question pass that probes manifests (package.json, schema files, Dockerfile, CI config, recent git activity) and writes/loads `docs/agents/SYSTEM_CONTEXT.md`. Subsequent chain skills (`draft-spec`, `socratic-grill`, `decision-record`) inherit the cache for free.
  - **Why:** Phase 1 was asking the user for things `package.json` already said. Cold-asking is both rude and weak — the user only tells you what they remember. Phase 0 forces the discipline of *looking first*, and the in-repo cache file makes the reconnaissance reusable across chain runs without introducing a vector store or MCP dependency. Decided against `claude-mem` / `graphify` integration because in-repo markdown is versioned, reviewable, and human-correctable; opaque vector stores aren't.
  - New reference: `skills/prior-art-research/references/recon-checklist.md`
  - New reference: `skills/prior-art-research/references/system-context-template.md`
  - Staleness detection via `git log --since "<file_mtime>" -- <manifest_paths>`; user-confirmed refresh, never silent overwrite.

- **`parallel-dev` — Mandatory commit discipline for artifact-producing subagents.** Each subagent that writes to the repo now commits its own work with a structured commit message containing `Dispatched-by`, `Dispatch-id`, `Subagent`, and `Parent-task` trailers. Dispatcher captures returned SHAs in the dispatch record.
  - **Why:** v1.0.0 captured timing and tokens but not commit SHAs, which meant a parallel run was not replayable from `git log` alone. Subagents returning text blobs the parent had to interpret-and-write was lossy and broke `git blame`. Forcing per-subagent commits gives full audit trail (`git log --grep="Dispatch-id: <id>"`) and lets partial successes survive a re-dispatch without rework. Research subagents that return structured records (not files) remain exempt — the parent commits the synthesized output once.

### Changed

- **`prior-art-research` Phase 1 reframed from cold-asking to gap-filling.** Where v1.0 led with five generic context questions, v1.1 leads with: *"I see X, Y, Z; two open questions remain: A and B."* Phase 0's recon output drives this.
  - **Why:** Same root cause as the Phase 0 addition. The new framing is materially cheaper for the user (fewer questions) AND higher-signal (questions are scoped to genuine unknowns).

### Plugin metadata

- `version`: 1.0.0 → 1.1.0 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`

### Dogfood test

- `tests/dogfood/05-research-recon-and-memory.md` — the chain run on the meta-question that drove this release. Demonstrates Phase 0's value by example.

---

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
