# Changelog

All notable changes to `habeebs-skill`.

## Convention

Every entry includes a **Why** line — the reason the feature exists, not just what it is. This is so future readers (humans and agents) can judge whether a feature is still load-bearing, or has been outgrown.

Versioning is [SemVer](https://semver.org/):
- **MAJOR** — breaking change to a skill's frontmatter, output template, or handoff contract
- **MINOR** — new skill, new phase, new template, or new opt-in behavior
- **PATCH** — wording fixes, internal cleanups, doc clarifications

Each release gets a git tag `vX.Y.Z` and a GitHub release with notes mirrored from this file.

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
