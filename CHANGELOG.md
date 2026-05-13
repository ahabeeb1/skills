# Changelog

All notable changes to `habeebs-skill`.

## Convention

Every entry includes a **Why** line — the reason the feature exists, not just what it is. This is so future readers (humans and agents) can judge whether a feature is still load-bearing, or has been outgrown.

Versioning is [SemVer](https://semver.org/):
- **MAJOR** — breaking change to a skill's frontmatter, output template, or handoff contract
- **MINOR** — new skill, new phase, new template, or new opt-in behavior
- **PATCH** — wording fixes, internal cleanups, doc clarifications

Each release gets a git tag `vX.Y.Z` and a GitHub release with notes mirrored from this file.

## [1.9.0] — 2026-05-13

Ecosystem alignment + chain hygiene. The 2026-05-13 audit against Anthropic Skills 2.0 + Superpowers + mattpocock/skills + OMC + claude-mem produced four new ADRs (0006-0009) and six vertical slices, shipped as a single release. Headline outcomes: skill-listing budget recovers ~700 tokens/turn (avg description trimmed 796 → 593 chars across 14 skills); unrecognized `next-skills` frontmatter removed (chain integrity now testable via 29-pair assertion script); new `verify-output` skill closes the post-impl anti-slop gap habeebs-skill had vs OMC's `ai-slop-cleaner`; `/abort-chain` convention documents the cleanup path that was previously implicit; GLOSSARY consumption widened from 2 of 14 skills to 5; SYSTEM_CONTEXT mtime-check protocol extracted from `prior-art-research` Phase 0 into `docs/agents/references/` as the first inhabitant of a new cross-cutting-helpers directory convention.

### Added (Slice 1 — description-trim)

- **`tests/dogfood/11-description-budget/check-description-budget.sh`** — automated dogfood assertion enforcing the [ADR-0007](docs/agents/adrs/0007-description-budget-policy.md) description budget: ≤1,200 chars/skill hard cap, ≤600 chars target average, "Make sure to use this skill" pushy-trigger preservation, no "Inspired by" in descriptions, three-keystone protected anti-trigger rule (`prior-art-research`, `socratic-grill`, `tdd-loop` retain ≥2 anti-trigger items). Script passes at 593-char average post-trim.
  - **Why:** Per [ADR-0007](docs/agents/adrs/0007-description-budget-policy.md), all 14 description fields live in the always-loaded skill-listing budget (Anthropic's default 1% of context window). Pre-trim total was ~11,150 chars (avg 796); post-trim is 8,315 chars (avg 593) — recovers ~700 tokens per turn. The dogfood script makes future-author drift mechanically detectable.

- **`## Origins` body sections** in 6 SKILL.md files: `parallel-dev`, `systematic-debugging`, `using-worktrees`, `vertical-slice`, `write-plan`, `deep-modules`. Captures "Inspired by X" / "Lifted from X" credits formerly embedded in frontmatter descriptions. Placed near the bottom of each SKILL.md body (after `## See also`).
  - **Why:** [ADR-0007](docs/agents/adrs/0007-description-budget-policy.md) moves acknowledgments out of the always-loaded description budget and into the lazy-loaded body. Same attribution, zero per-turn token tax.

### Changed (Slice 1 — description-trim)

- **All 14 `skills/*/SKILL.md` descriptions trimmed ~25%.** Capability-statement preservation: every description still opens with what the skill does. Pushy-trigger preservation: every description still contains "Make sure to use this skill" + enumerated trigger phrases. Anti-trigger condensation: the 11 non-keystone skills tightened "Do NOT use for X, Y, Z, A, B, C" enumerations to ≤1 line. Three keystone skills (`prior-art-research`, `socratic-grill`, `tdd-loop`) retain ≥2 anti-trigger items per the keystone protection rule.
  - **Why:** Per the 2026-05-13 ecosystem audit, descriptions ran 20-30% verbose past trigger-quality saturation. The verbose parts were "Inspired by X" credits (zero trigger value, now in `## Origins`) and over-enumerated anti-triggers (over-precision past diminishing return). Trimming preserves trigger reliability while recovering token budget for future skill additions.

### Removed (Slice 2 — `next-skills` frontmatter removal)

- **`next-skills:` frontmatter line removed from all 11 SKILL.md files that carried it.** The 29 chain-relationship pairs they encoded (e.g., `prior-art-research → draft-spec`, `tdd-loop → deep-modules`) all already surface in the SKILL.md bodies via `HANDOFF:` lines or `## See also` sections — chain-integrity script confirms 29/29 pairs found post-removal.
  - **Why:** Per [ADR-0006](docs/agents/adrs/0006-remove-next-skills-frontmatter.md), `next-skills` is not a recognized Claude Code Skills 2.0 frontmatter field — the harness silently ignored it. Removing it eliminates always-loaded metadata that carried zero behavioral signal, brings habeebs-skill into structural alignment with Anthropic/Superpowers/mattpocock/OMC peer ecosystems (none use a chain-frontmatter field), and consolidates chain-relationship discovery into the three documented body-level surfaces: `HANDOFF:`, `## See also`, prose.

### Added (Slice 2 — chain integrity tooling)

- **`tests/dogfood/11-description-budget/chain-pairs.txt`** — snapshotted (source, target) chain-relationship pairs from pre-removal `next-skills` frontmatter. 29 pairs total. Used as fixture for the chain-integrity assertion script.
- **`tests/dogfood/11-description-budget/chain-integrity.sh`** — assertion script. For each (source, target) pair, greps the source SKILL.md body for the target name in `HANDOFF` / `## See also` / prose. Exits non-zero on any unmatched pair. Currently 29/29 PASS.
- **`tests/dogfood/11-description-budget/no-next-skills.sh`** — assertion that zero SKILL.md files carry `next-skills:` frontmatter. Currently PASS.
  - **Why:** [ADR-0006](docs/agents/adrs/0006-remove-next-skills-frontmatter.md) explicitly makes chain-relationship coverage testable, where the frontmatter field carried no enforcement. The three scripts together form the slice-2 pre-merge dogfood gate.

### Added (Slice 3 — `verify-output` skill)

- **`skills/verify-output/SKILL.md`** — new post-generation anti-slop pass. Runs at `tdd-loop` Pass 5c between two-stage review (5a + 5b) and Phase 4 commit. Scans `git diff --staged` against seven slop heuristics. Returns one of four ADR-0004 statuses (`DONE`, `DONE_WITH_CONCERNS`, `BLOCKED`, `NEEDS_CONTEXT`). Default mode ANNOTATE (`BLOCKED` only on severe slop); GATE mode opt-in via `--gate` arg. Includes `--override <ref>` escape hatch for intentional stubs (override is recorded in commit message and is `git log`-auditable).
- **`skills/verify-output/references/slop-heuristics.md`** — the seven heuristics. H1-H4 lifted verbatim from `CLAUDE.md` (user-authored canon: feature creep, impossible-scenario error handling, unjustified comments, backward-compat hacks for unshipped code). H5-H7 paraphrased from OMC's `ai-slop-cleaner` / `ultraqa` (≤10 words per source per repo quote policy): repeated boilerplate (rule of 3+), defensive validation past trusted boundaries, severe slop (half-finished impl / unreachable / declared-and-unused). Each heuristic carries a positive example + a counter-example.
- **`tests/dogfood/12-verify-output/`** — three planted-diff scenarios: `12a-planted-moderate-slop.md` (H1-H6 hits, expects `DONE_WITH_CONCERNS` ANNOTATE / `BLOCKED` GATE), `12b-clean-control.md` (no slop, expects `DONE` both modes; deliberately includes H5 counter-example fixture — three parallel tests that look similar but aren't repeated boilerplate), `12c-severe-slop.md` (H7 hits, expects `BLOCKED` both modes; includes `--override` smoke test).
- **`skills/tdd-loop/SKILL.md` Phase 5 — Pass 5c (verify-output)** added between Pass 5b (deep-modules code-quality review) and Phase 4 commit. Documents the 4-status branching: `DONE` proceeds to commit, `DONE_WITH_CONCERNS` warns but proceeds in ANNOTATE mode, `BLOCKED` halts, `NEEDS_CONTEXT` surfaces ambiguity.
  - **Why:** Per [ADR-0008](docs/agents/adrs/0008-verify-output-skill-scope.md), the 2026-05-13 ecosystem audit identified post-impl slop detection as the one quality phase habeebs-skill was missing. Peer ecosystems (OMC `ai-slop-cleaner`, `ultraqa`) fill this slot; habeebs-skill did not. `deep-modules` catches interface-shape problems at the refactor step but doesn't catch code-shape slop (unjustified comments, defensive validation past boundaries, half-finished implementations). `verify-output` is the dedicated narrow-scope post-impl pass. ANNOTATE default preserves user agency; GATE opt-in serves stricter contexts.

### Added (Slice 4 — `/abort-chain` convention)

- **`skills/using-habeebs-skill/SKILL.md` § Aborting the chain** — new top-level section documenting how to abort a chain in flight. Documents 5 abort triggers (user says "abort"; new requirement invalidates spec; research surfaces blocker; work paused indefinitely; critic surfaces coverage gap), an ordered 5-step cleanup checklist (SYSTEM_CONTEXT steering flush, in-flight worktree teardown with user-confirmation, partial spec archive to `docs/agents/specs/abandoned/`, partial ADR archive to `docs/agents/adrs/abandoned/`, final summary echo), a no-destructive-git rule (no `--force` push, no branch deletion, no `git reset --hard`), and 2 handoff paths (re-research vs back-to-user).
- **`skills/using-worktrees/SKILL.md` `## See also`** — added cross-reference to the new abort section so the worktree-teardown protocol is discoverable from the abort path.
  - **Why:** Per the 2026-05-13 grill, every other peer ecosystem has cancel/abort skills (OMC `cancel`, `stopomc`) and habeebs-skill had no documented chain-abort UX. Leaving a half-flushed chain behind (stale `## Active steering`, abandoned worktrees) contaminates the next `prior-art-research` invocation's Phase 0 reconnaissance. Documenting the abort as a body section in `using-habeebs-skill` (rather than a dedicated skill) keeps the always-loaded description budget tight while making the protocol discoverable.

### Changed (Slice 5 — GLOSSARY.md consumption widened)

- **`skills/draft-spec/SKILL.md`, `skills/socratic-grill/SKILL.md`, `skills/write-plan/SKILL.md`** — Pre-flight blocks now include a one-line LINK-form GLOSSARY reference: *"If methodology terminology in this spec / grill / plan feels ambiguous (e.g., 'slice', 'phase', 'dispatch group', 'pgroup', 'HITL', 'AFK'), Read `docs/agents/GLOSSARY.md` immediately before proceeding."* These are read-on-demand pointers, not LOAD-form always-include directives — preserves token economy.
  - **Why:** Before v1.8.0, only `deep-modules` and `setup-habeebs-skill` referenced GLOSSARY.md (2 of 14 consumers). The middle-chain skills (`draft-spec`, `socratic-grill`, `write-plan`) directly manipulate methodology vocabulary (slices, HITL/AFK labels, dispatch groups) but were silent on where the canonical definitions live. The grill resolved on LINK over LOAD: trust the agent to read on ambiguity instead of always-including ~2KB of glossary content. Revisit trigger logged: if dogfood evals show >1-in-5 GLOSSARY-skip rate when needed, escalate to LOAD in v1.10.

### Added (Slice 6 — SYSTEM_CONTEXT mtime-check helper)

- **`docs/agents/references/system-context-staleness-check.md`** — the canonical SYSTEM_CONTEXT.md staleness-check protocol, extracted out of `prior-art-research` Phase 0 into a shared reference doc. Documents the mtime-vs-manifests comparison, the staleness banner format (`⚠ SYSTEM_CONTEXT.md is stale (X changed since YYYY-MM-DD). Refresh? (Y/n)`), and three explicit fallback cases: (A) git history unavailable (shallow clone, non-git context) — emit advisory, proceed; (B) file missing — emit advisory, proceed empty (except `prior-art-research` Phase 0 which writes); (C) file malformed — emit advisory, proceed empty.
- **`docs/agents/references/`** — new directory convention introduced (parallels existing `docs/agents/{adrs,specs,plans,dispatches}/`). Per [ADR-0009](docs/agents/adrs/0009-docs-agents-references-convention.md), cross-cutting helpers consumed by 3+ skills live here; skill-specific helpers stay under `skills/<name>/references/`.

### Changed (Slice 6 — 10 SKILL.md consumers retrofitted)

- **All 10 SKILL.md files that read SYSTEM_CONTEXT.md** now reference the shared staleness-check doc instead of inlining the protocol: `prior-art-research` (Phase 0 — the canonical writer; refactored to reference the doc and inherit fallbacks), `agent-factors-check`, `decision-record`, `draft-spec`, `parallel-dev`, `setup-habeebs-skill`, `socratic-grill`, `tdd-loop`, `using-habeebs-skill`, `write-plan` (Pre-flight blocks updated with the staleness-check reference + reader-only reminder).
  - **Why:** Per [ADR-0009](docs/agents/adrs/0009-docs-agents-references-convention.md), DRY refactor. Pre-slice-6, only `prior-art-research` Phase 0 enforced the staleness check; the other 9 consumers implicitly trusted the file. Centralizing the protocol + documenting fallbacks (git unavailable / file missing / malformed) means all 10 consumers behave identically and degrade gracefully when their environment can't run the mtime check. Single source of truth — future protocol edits land in one place.



The two-file context layout becomes deliberate. **ADR-0005** locks the split: `docs/agents/GLOSSARY.md` is the human-authored domain glossary; `docs/agents/SYSTEM_CONTEXT.md` is the tool-authored environment-binding recon. Different writers, different refresh cadences, different readers — and now different filenames so the one-token collision (`CONTEXT.md` vs `SYSTEM_CONTEXT.md`) that confused agents porting the plugin to fresh repos is gone. The same release closes ADR-0001's latent bug — setup-habeebs-skill never honored the ADR's stated intent that "setup defers the recon write to Phase 0 when invoked through the chain." It does now, via a new Phase 7 that invokes Phase 0 inline after writing the human-answered config. Single-writer invariant for SYSTEM_CONTEXT.md preserved by construction (setup invokes; Phase 0 writes).

### Added

- **`docs/agents/GLOSSARY.md` — the canonical name for habeebs-skill's human-authored domain glossary.** Replaces legacy `CONTEXT.md`. Written by `setup-habeebs-skill` Phase 5 from the renamed `references/domain.md` template. Read by `deep-modules` (vocabulary) and `draft-spec` (slice naming). This repo's own GLOSSARY ships with 13 concepts: skill, chain, slice, ADR, harness, runtime substrate, dispatch group, single-writer invariant, steering, halt-with-redirect, context preamble, dogfood, project mode.
  - **Why:** The original filename `CONTEXT.md` collided one-token with `SYSTEM_CONTEXT.md`. When the plugin was ported to a fresh repo, the user got `CONTEXT.md` from setup but no `SYSTEM_CONTEXT.md` because nothing in the setup flow invoked Phase 0 — and the filename collision made the two-file mental model invisible. Renaming to `GLOSSARY.md` makes the lifecycle role legible from the filename alone.

- **`setup-habeebs-skill/SKILL.md` Phase 7 — Trigger Phase 0 reconnaissance.** After Phases 5–6 write GLOSSARY + tracker + labels + adrs/README + the `## Agent skills` block, Phase 7 invokes `prior-art-research` Phase 0 inline. Phase 0 remains the sole writer of `SYSTEM_CONTEXT.md` (ADR-0001 single-writer invariant preserved). Phase 0's existing cache-check governs idempotency — re-running `/setup` on a configured repo is a no-op for SYSTEM_CONTEXT when the file is fresh. **Forked failure handling**: `[unknown]` tags in Phase 0 output pass through with a success-message count; write-failure (permission denied, disk full, sandbox restriction, git uninitialized) halts loud at end of setup with a `SETUP_INCOMPLETE` banner naming the specific error and the recovery command (existing GLOSSARY/tracker/labels writes preserved — idempotent re-run).
  - **Why:** ADR-0001 already declared this chain should exist — "setup is the bootstrap entry point but defers the actual write of the recon digest to Phase 0 when invoked through the chain." The skill never implemented it. v1.8.0 closes that latent bug. Net UX win: one invocation, fully bootstrapped repo, no surprise `SYSTEM_CONTEXT.md` appearing later, no halt on first `/research`.

- **`setup-habeebs-skill/SKILL.md` Phase 8 — Confirm** (renumbered from old Phase 7). File list now includes `docs/agents/SYSTEM_CONTEXT.md` and surfaces the `[unknown]` field count from Phase 0.

- **`deep-modules/SKILL.md` pre-flight halt block** — `SETUP REQUIRED: docs/agents/GLOSSARY.md missing. Run /setup to populate the domain glossary stub.` Two writers (setup + Phase 0) now produce two halt paths (`/setup` vs `/research`). Other chain skills' existing SYSTEM_CONTEXT halt blocks are unchanged.

- **ADR-0005: Split project context into GLOSSARY.md and SYSTEM_CONTEXT.md by writer lifecycle, and chain `setup-habeebs-skill` into Phase 0 inline** (`docs/agents/adrs/0005-lifecycle-split-glossary-and-system-context.md`). Captures the 5 locked decisions, 6 alternatives considered, 6 revisit triggers. Partially supersedes ADR-0001 (the "Notable absence" line and the undefined CONTEXT.md/SYSTEM_CONTEXT.md relationship); ADR-0001's load-bearing rule for SYSTEM_CONTEXT.md and its single-writer invariant remain in force, unchanged.

- **Spec + Grill record at `docs/agents/specs/v1.8.0-glossary-rename-and-setup-chain.md` + `-grill.md`.** Grill resolved 5 items (the 4 spec-listed open questions + 1 surfaced mid-grill: 4 file-touch sites the spec's slice 1 had missed). `agent-factors-check` fired as conditional extension and added zero net-new questions — all 6 factor gaps were already covered by existing chain contracts (ADR-0001 / ADR-0004) or the spec itself.

- **Slice 3 dogfood: `setup-habeebs-skill` ran on this canonical repo for the first time.** Produced the three previously-absent methodology files: `docs/agents/issue-tracker.md` (GitHub), `docs/agents/triage-labels.md` (canonical 5), `docs/agents/GLOSSARY.md` (13 concepts). Refreshed `docs/agents/SYSTEM_CONTEXT.md` via the new Phase 7 chain. Added `## Agent skills` blocks to `AGENTS.md` and `CLAUDE.md`. The v1.5.0 "Notable absences" list is now fully resolved.

### Changed

- **`CONTEXT.md` → `GLOSSARY.md` rename across all writers, readers, templates, and tests.** Touched: `skills/setup-habeebs-skill/SKILL.md`, `skills/setup-habeebs-skill/references/domain.md`, `skills/deep-modules/SKILL.md`, `skills/prior-art-research/references/system-context-template.md`, `skills/prior-art-research/references/recon-checklist.md`, `tests/evals/phase-3.evals.json`, `tests/dogfood/05-research-recon-and-memory.md`. CHANGELOG.md mentions are NOT rewritten (release history is immutable).

- **`tests/dogfood/05-research-recon-and-memory.md` — Pattern B description.** Previously conflated `CONTEXT.md` and `SYSTEM_CONTEXT.md` as if they were one file ("A markdown file (`docs/agents/CONTEXT.md`, `SYSTEM_CONTEXT.md`) written once and refreshed when a tracked manifest changes"). This was the literal symptom of the bug v1.8.0 fixes. Rewritten to make the lifecycle split explicit: two files, two writers, two refresh cadences.

- **`AGENTS.md` "What this is NOT" section** — removed stale "composes with Superpowers/OMC" line that contradicted ADR-0002. Replaced with the ADR-0002 standalone-by-design statement.

- **ADR-0001 status field** — annotated "partially superseded by ADR-0005" with a one-line forward link. ADR-0001's load-bearing rule for `SYSTEM_CONTEXT.md` and its single-writer invariant are unchanged; only the CONTEXT.md handling and the "Notable absence" line are superseded.

- **ADR index (`docs/agents/adrs/README.md`)** — added ADR-0005 row, marked ADR-0001 as "Accepted (partially superseded by 0005)".

### Plugin metadata

- `version`: 1.7.0 → 1.8.0 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- No new top-level directories
- No new skills (v1.8.0 is a contract clarification + filename rename, not a new capability)

### Why this is a MINOR, not a patch

New opt-in behavior — Phase 7 chain into Phase 0 is additive (skip-allowed when re-running on a configured repo via the cache-check). New file naming (`GLOSSARY.md`) is additive — Phase 0's `SYSTEM_CONTEXT.md` is unchanged, the 5 downstream chain skills' halt-if-missing blocks are unchanged, only the new `deep-modules` halt-if-missing block adds a redirect. The forked failure handling in setup Phase 7 is a new contract surface that downstream chain runs must honor.

### Why this is NOT a MAJOR

No breaking change to any skill's frontmatter, output template, or handoff contract. The rename `CONTEXT.md` → `GLOSSARY.md` affects only the artifact filename produced by setup; consumer skills (`deep-modules`, `draft-spec`) read the renamed file via the updated paths in the same release. Personal repo — no shipped consumers to migrate. ADR-0001's load-bearing rule is partially superseded but not contradicted.

### Compatibility

- Repos previously bootstrapped with v1.7.0 (which would have `CONTEXT.md`) need a one-line `git mv docs/agents/CONTEXT.md docs/agents/GLOSSARY.md`. No migrator shim ships in this release — explicitly rejected as overkill for a personal-repo plugin (ADR-0005 § Alternatives: ESLint-style and Rails-style migrators considered and cut).
- `parallel-dev`'s `context_preamble` injection (ADR-0004 Part 3) reads `SYSTEM_CONTEXT.md`, NOT `GLOSSARY.md` — unaffected.
- ADR-0002's "no runtime substrate" rule is unchanged. ADR-0005 is markdown-only, in-repo, multi-harness portable by construction.

### Self-application loop closure

This release's implementation **dogfooded itself**: research → spec → grill → record → tdd-loop, with `setup-habeebs-skill` being run on its own canonical repo as slice 3. The original symptom (the `tests/dogfood/05` Pattern B description conflating the two files) was fixed in the same slice that fixes the bug it describes — clean loop closure between bug-as-documented and bug-as-fixed.

## [1.7.0] — 2026-05-12

Parallel subagent dispatch becomes a first-class contract, governed by **ADR-0004** (4-status return, audit-log dispatch records, mandatory `SYSTEM_CONTEXT` preamble injection, idempotent re-invocation as pause/resume API). The bleeding-pain fix lands: a new `prior-art-research` Phase 2.5 dispatches a `category-completeness-critic` subagent that catches missing-category failures (the literal v1.6.0 hooks miss is reproduced and caught by `tests/dogfood/09-category-critic/09b-missing-hooks.md`). `tdd-loop` gains a Phase 0.5 that auto-dispatches pgroups of size ≥2 via `parallel-dev`, replacing the previous "labels exist, no dispatcher consumes them" gap.

### Added

- **`agents/category-completeness-critic.md`** — coverage critic subagent. Receives proposed sub-problem decomposition + Phase 1 context + `SYSTEM_CONTEXT.md` preamble. Scores against a 12-category catalog of commonly-missed blind spots (hooks, agents, observability, security, migration, …). Returns either `APPROVED` or `ADDITIONS PROPOSED` with per-addition rationale. Bounded at 1 iteration. Hard no-padding rule: every proposed addition must change Phase 4 search, or be struck (false-positive gate at scenario 09d).
  - **Why:** A single-agent Phase 2 planner reliably misses entire categories of architectural concern. The chain's bleeding pain — documented 2026-05-12 — was a research run that missed `hooks / event handlers` and `subagent-driven patterns` when researching habeebs-skill itself, and the chain blindly proceeded against the incomplete decomposition. Phase 2.5 is the coverage gate that catches this failure mode automatically. Pattern lineage: LangGraph multi-agent research critic loop + Anthropic CitationAgent.

- **`prior-art-research` Phase 2.5 — Category-completeness critic (coverage gate)** in `skills/prior-art-research/SKILL.md`. Inserts the critic between current Phase 2 (Decompose) and Phase 3 (Choose mode). Lead either accepts each proposed addition or rejects with a written reason in the report's new "Phase 2.5 outcome" section (silent rejection forbidden). Skip-allowed only when Quick mode + 1 sub-problem + "shipping speed" priority.

- **`prior-art-research/references/output-template.md` — Phase 2.5 outcome section.** Required between Sub-problems and Case studies. Captures verdict + per-addition response with written reason on rejection.

- **`tdd-loop` Phase 0.5 — Plan inspection: pgroup auto-dispatch + idempotent re-invocation** in `skills/tdd-loop/SKILL.md`. Reads the active plan, detects the next unfinished pgroup, dispatches concurrently via `parallel-dev` when size ≥ 2. Idempotent resume via `git log --grep "Dispatch-id:"` + branch inspection — completed slices skip, in-flight surface as `BLOCKED`, pending dispatch fresh. Git is the durability layer (ADR-0004 Part 4); no checkpoint file consulted. Status handling matrix per ADR-0004 Part 1. Single-slice fallthrough preserves the pre-v1.7.0 sequential path (regression-tested by `tests/dogfood/10-pgroup-dispatch/10b-no-pgroup-control.md`).
  - **Why:** `parallel-dev` was a dispatcher with no real callers pre-v1.7.0. `write-plan` Phase 4 labeled pgroups as parallelizable, then waited — no skill consumed the label. This phase is the first machine-readable consumer.

- **`write-plan` Phase 8 — `HANDOFF: pgroup-dispatch-ready` line** in `skills/write-plan/SKILL.md`. Always emitted when the plan has any pgroup of size ≥ 2 (machine-readable trigger for `tdd-loop` Phase 0.5). Coexists with the existing `parallel dispatch ready` human-readable emit for plans with 3+ AFK slices.

- **`parallel-dev` § Return contract** in `skills/parallel-dev/SKILL.md`. Locks the 4-status return contract (`DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT`) verbatim from Superpowers' `subagent-driven-development/implementer-prompt.md`. Includes per-status handling matrix and `suggested_action` enum on BLOCKED.

- **`parallel-dev` § Sub-patterns — Hypothesis probe** in `skills/parallel-dev/SKILL.md`. AlphaCode-style generate-N-filter-to-K pattern documented for future `systematic-debugging` Phase 3.5 consumption (v1.8.0+).

- **Concurrency soft-cap with opt-in per-pgroup override.** Default 5; pgroup labelers can override with `concurrency: <N>` field. Source: appxlab's empirical 5-7 ceiling for concurrent coding agents.

- **`SYSTEM_CONTEXT.md` preamble injection as subagent contract** (ADR-0004 Part 3). Dispatcher MUST read `docs/agents/SYSTEM_CONTEXT.md` and inject as `context_preamble` field in every subagent's input. Captured in `parallel-dev/SKILL.md` Phase 3 + the dispatch-record template.

- **`agents/source-fetcher.md`, `agents/pattern-extractor.md`, `agents/synthesizer.md`** rewritten to honor the 4-status return contract + the `context_preamble` requirement. Per-agent additions: source-fetcher emphasizes ≤15-word quote discipline + tier health verdict; pattern-extractor adds homogeneity-bias detection (tier-narrow / vendor-narrow / benign-convergence) + missing-pattern surfacing; synthesizer runs in fresh context to dodge lead-agent context exhaustion + surfaces contradictions in Open Questions rather than silently smoothing.

- **`docs/agents/dispatches/.gitkeep`** anchors the audit-log directory (ADR-0004 Part 2). Single-writer (`parallel-dev` only); no in-execution reads by any skill; 30-day retention candidate for v1.8.0+.

- **`skills/parallel-dev/references/dispatch-record-template.md`** rewritten as the authoritative contract reference: input JSON schema (10 fields including mandatory `context_preamble`), return JSON schema (4-status with per-status field requirements matrix), BLOCKED structured message shape with `suggested_action` enum, dispatch record file shape. The pre-v1.7.0 markdown audit shape is preserved as a legacy / PR-description format.

- **ADR-0004: Adopt the parallel subagent dispatch contract** (`docs/agents/adrs/0004-parallel-subagent-dispatch-contract.md`). Captures the four binding parts of the contract + explicit carve-out from ADR-0002 (dispatch records are write-only audit logs, not a runtime substrate). Captures 5 rejected alternatives.

- **Plan 0004: `docs/agents/plans/0004-parallel-subagent-v1.7.0.md`** — phased implementation plan for this release. 8 slices across 4 phases. Slice #8 (release) is `HITL:inline`; all others `AFK:full-auto` (but dispatched sequentially this release due to R10 chicken-and-egg: this release ships the wiring it would otherwise dispatch through).

- **Adversarial dogfood suite at `tests/dogfood/09-category-critic/`** — 3 false-negative scenarios (09a observability, 09b hooks reproducer, 09c security) + 1 false-positive control (09d no-gap). Load-bearing acceptance gate for Slice #5; 09b is the literal reproducer of the v1.6.0 hooks miss that drove this work.

- **Dogfood suite at `tests/dogfood/10-pgroup-dispatch/`** — positive scenario (10a, 3-slice plan with pgroup-1A) + regression scenario (10b, single-slice plan must no-op cleanly). 10b is the load-bearing regression test; every pre-v1.7.0 user's single-slice flow must keep working unchanged.

### Changed

- **`README.md` skills tables** — `prior-art-research` row now mentions Phase 2.5 category-completeness critic; `parallel-dev` row now mentions the 4-status contract + auto-dispatch from `tdd-loop` Phase 0.5.
- **`README.md` repo scaffolding tree** — `agents/` directory now lists 4 files (added `category-completeness-critic.md`); descriptions noted as v1.7.0 contract-compliant.
- **`skills/parallel-dev/SKILL.md` cross-refs** updated to point at the consolidated repo-root `/agents/` location (`../../agents/X.md` instead of broken `agents/X.md` which previously resolved to a non-existent `skills/parallel-dev/agents/X.md`).
- **`skills/parallel-dev/SKILL.md` Phase 3 dispatch spec** now includes mandatory `context_preamble` field per ADR-0004 Part 3.
- **`skills/parallel-dev/SKILL.md` Phase 4** now documents the concurrency cap (default 5, opt-in `concurrency: <N>` per-pgroup override).

### Plugin metadata

- `version`: 1.6.0 → 1.7.0 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- New top-level directory: `docs/agents/dispatches/` (audit log for parallel-dev runs; auto-populated by the dispatcher)

### Why this is a MINOR, not a patch

New opt-in behavior — Phase 2.5 critic, Phase 0.5 pgroup auto-dispatch, the 4-status contract, and the dispatch-record convention are all additive. Existing chains continue to work unchanged: the Phase 2.5 critic is skip-allowed for trivial scope; Phase 0.5 falls through cleanly when no pgroup ≥ 2 exists (regression-tested by 10b). Distinct from the v1.5.x patch series and the v1.6.0 hooks release.

### Compatibility

- Subagent prompts at `/agents/*.md` updated to honor the 4-status return contract. Old subagent invocations (pre-v1.7.0) that returned free-form text continue to be parseable as `DONE` for backward compatibility. New skill code MUST emit the structured contract.
- `parallel-dev` cross-reference fixes (the path-resolution bug for `agents/X.md`) are transparent: humans following the links now hit the right files; the broken link never actually resolved before.
- ADR-0002's "no runtime substrate" rule is **unchanged**. ADR-0004 explicitly carves out dispatch records as a permitted audit-log artifact (write-once, never read mid-chain) — this carve-out is documented in ADR-0004, not in ADR-0002's body.

### Self-application irony

This release's own implementation runs **sequentially** (Plan 0004 Risk R10) — by construction, you can't dispatch the wiring you're shipping through itself. The first real exercise of pgroup auto-dispatch will be the v1.8.0+ release that consumes this plan format. The plan records pgroup-1A and pgroup-2A as eligible for the next release; v1.7.0 itself walks them as a sequential list.

### Token cost amplification

Per the spec's Trade-offs: Phase 2.5 critic adds ~1 subagent call per research run (~1.2-1.4× research-mode amplification). Pgroup dispatch only fires when a pgroup ≥ 2 exists in the active plan; implementation runs without parallel pgroups see 1.0× (unchanged). Total expected amplification is workload-dependent; we'll measure on the first 3 real runs post-merge.

## [1.6.0] — 2026-05-12

First-ever Claude Code hooks land in habeebs-skill, governed by **ADR-0003** ("warn-only or block-only, multi-harness aware, never own state"). Two hooks total — no more, no less — addressing the two documented user pains from prior research: squash-merge ghost-commit divergence (warned by SessionStart) and accidental commits to the default branch (blocked by PreToolUse on Bash). Plus a manual-install fallback documented in README per [Superpowers issue #773](https://github.com/obra/superpowers/issues/773) (plugin hook auto-discovery is fragile).

### Added

- **`hooks/session-start.sh`** — SessionStart hook. Silent `git fetch origin --prune` + ahead/behind check on the default branch. If `ahead=0, behind>0` → "Local main is N commits behind origin. Run /sync to fast-forward." If `ahead>0, behind>0` → "Diverged (likely squash-merge ghost commits) — run /sync." If `ahead>0, behind=0` → "N unpushed commit(s); push or discard." Warn-only — never resets, merges, or deletes anything. Multi-harness aware via `CLAUDE_PLUGIN_ROOT` / `CURSOR_PLUGIN_ROOT` env-var detection per Superpowers pattern.
  - **Why:** v1.5.3 added the `/sync` command to handle ghost commits, but the user has to remember to run it. The SessionStart hook surfaces the same warning automatically at the moment it's most useful — when a new session opens and the local repo is out of sync with origin. Found by repeated user pain after every PR squash-merge; the v1.5.0-v1.5.4 self-audit chain confirmed hooks are the right primitive.

- **`hooks/preventing-commits-to-default.sh`** — PreToolUse hook on `Bash`. Inspects each `git commit` / `git push` command before execution. Blocks (exit 2) when the current branch IS the default branch (resolved via `origin/HEAD`). Skips when mid-rebase, mid-merge, or mid-cherry-pick (`.git/REBASE_HEAD` etc.). Per-repo opt-out via `.claude/habeebs-allowed-branches`. Emergency disable via `HABEEBS_DISABLE_HOOKS=1`.
  - **Why:** ADR-0001's never-commit-to-default rule was previously enforced only by skill text. Easy to violate during fast iteration ("just a tiny commit"). PreToolUse-on-Bash is the canonical mattpocock pattern (`git-guardrails-claude-code`); this is a single-rule scoped version focused on the most important guardrail.

- **`hooks/hooks.json`** — declares both hooks for plugin auto-discovery. Schema follows [Anthropic's `hook-development` SKILL](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/hook-development/SKILL.md): `description` + nested `hooks` object keyed by event name. Uses `${CLAUDE_PLUGIN_ROOT}` for portable paths.

- **ADR-0003: habeebs-skill hooks — warn-only or block-only, multi-harness aware, never own state** (`docs/agents/adrs/0003-hooks-scope.md`). Locks the scope so future audits don't drift into hook sprawl. Captures four explicit rejected alternatives (reject hooks entirely / adopt full hook system / per-install authorization / prompt-based hooks for v1.6.0 / auto-fix hooks).

- **Plan 0003: `docs/agents/plans/0003-hooks-v1.6.0.md`** — implementation plan for this release. 9 slices across 3 phases. Slice #9 is `HITL:inline` for tag-and-release; all others `AFK:full-auto`.

- **README "Hooks (v1.6.0+)" section** — verification (`/hooks` command), manual-install fallback (paste-into-`settings.json` snippet for issue-#773 cases), per-repo opt-out via `.claude/habeebs-allowed-branches`, emergency disable via `HABEEBS_DISABLE_HOOKS=1`.

### Changed

- **`README.md` repo scaffolding tree** — adds `hooks/` between `agents/` and `docs/` with one-line descriptions of each file. Status line updated to "14 skills, 13 slash commands, 2 hooks."

### Plugin metadata

- `version`: 1.5.4 → 1.6.0 in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- New top-level directory: `hooks/` (auto-discovered by Claude Code when the plugin loads)

### Why this is a MINOR, not a patch

New opt-in behavior — hooks fire automatically on install. Distinct from the v1.5.x patch series (those were bug fixes against shipped contracts). Backward compatible: repos that ran v1.5.x continue to work; hooks add automation on top.

### Compatibility

- **Existing v1.5.x installs**: no breaking changes. Hooks add automatic behaviors that didn't exist before; they don't replace any prior contract.
- **Multi-harness (Codex / Cursor / OpenCode)**: hooks gracefully no-op on non-Claude-Code harnesses (env-var detection). The methodology continues to work on those harnesses via skills + commands.
- **Sandboxed environments without `gh`/`jq`**: hooks degrade gracefully — `gh`-absent skips PR-merged detection; `jq`-absent falls back to `sed` regex extraction.

### Dogfood (post-release)

Per slice #9 of plan 0003, the SessionStart and PreToolUse hooks will be verified against v1.6.0's own squash-merge — opening a fresh session after the PR merges should surface the SessionStart "behind origin" warning; attempting `git commit -m "test"` on `main` should produce the BLOCKED message. Logged in plan 0003 change log after verification.

### Out of scope (deferred to v1.7.x or later, per ADR-0003)

- `UserPromptSubmit` hook for "I want to build X" detection — too easy to misclassify on first cut.
- `PostToolUse` hook on `gh pr merge` — rare event; SessionStart catches the same case on next session.
- Prompt-based hooks (Anthropic recommends them) — wait for command hooks to ship and surface their failure modes first.
- Auto-format / auto-test hooks — out of scope for a methodology plugin per ADR-0003.

Every additional hook requires a fresh ADR-grade evaluation against ADR-0003's three rules. No batch adoption.

---

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
