# Changelog

All notable changes to `habeebs-skill`.

## Convention

Every entry includes a **Why** line — the reason the feature exists, not just what it is. This is so future readers (humans and agents) can judge whether a feature is still load-bearing, or has been outgrown.

Versioning is [SemVer](https://semver.org/):
- **MAJOR** — breaking change to a skill's frontmatter, output template, or handoff contract
- **MINOR** — new skill, new phase, new template, or new opt-in behavior
- **PATCH** — wording fixes, internal cleanups, doc clarifications

Each release gets a git tag `vX.Y.Z` and a GitHub release with notes mirrored from this file.

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
