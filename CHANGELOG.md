# Changelog

All notable changes to `habeebs-skill`.

## Convention

Every entry includes a **Why** line — the reason the feature exists, not just what it is. This is so future readers (humans and agents) can judge whether a feature is still load-bearing, or has been outgrown.

Versioning is [SemVer](https://semver.org/):
- **MAJOR** — breaking change to a skill's frontmatter, output template, or handoff contract
- **MINOR** — new skill, new phase, new template, or new opt-in behavior
- **PATCH** — wording fixes, internal cleanups, doc clarifications

Each release gets a git tag `vX.Y.Z` and a GitHub release with notes mirrored from this file.

## [2.0.0] — 2026-06-27

Methodology 2.0 — the chain is reorganized around a plain-language **Human layer** the user reads and signs off (research → the Design → grill) and a technical **Machine layer** for the implementing agent (vertical-slice → tdd → release). "spec" is redefined as the **Design** — one cold-readable doc of what we're building and why — and a typical feature now leaves three artifacts behind instead of five. Every skill is rewritten in one house voice.

### Changed

- **Human/Machine layer split.** The chain is now `prior-art-research → draft-spec (the Design) → socratic-grill` (Human layer — plain-language, user-facing) then `vertical-slice → tdd-loop → release` (Machine layer — technical, agent-facing). **`draft-spec`** writes the **Design** — what we're building, why this approach, the key decisions and trade-offs — which the user reads cold and signs off before any code; slice decomposition moves to the Machine layer. **Why:** users reported the chain "lacked clarity — a wall of jargon with no insight into what's being built"; the split makes the human-facing half readable and defers technical detail to where only the agent reads it. See [`2026-06-26-split-human-design-and-machine-layers`](docs/agents/adrs/2026-06-26-split-human-design-and-machine-layers.md).
- **`socratic-grill` merges the grill record into the Design.** The grill walks the user through the Design, pressure-tests every aspect, writes resolved decisions back into the Design's **Decided** section (one human artifact, not a separate grill record), and earns an explicit sign-off that is the gate into the Machine layer. **Why:** two artifacts split the "why" of a feature across files; merging them keeps a single source of truth.
- **`decision-record` and `write-plan` are now conditional.** An ADR is written **only** for a one-way-door (irreversible) decision; a plan **only** for genuinely multi-phase work — so a typical feature produces three artifacts (research, the Design, the signed-off Design), not five. **Why:** most decisions are reversible and most features are single-phase, so mandatory ADRs/plans were ceremony without payoff. See [`2026-06-26-demote-adr-and-plan-to-conditional`](docs/agents/adrs/2026-06-26-demote-adr-and-plan-to-conditional.md).
- **House voice across all 18 skills.** Every skill opens with one iron law, renders its anti-pattern list as a **Thought→Reality** table, uses plain imperatives, and glosses jargon. **Why:** a consistent, punchy voice makes the rules hard to evade and easy to read on first pass. Codified in **`docs/agents/references/skill-voice.md`** and enforced by **`tests/dogfood/45-skill-voice`**. See [`2026-06-26-adopt-superpowers-house-voice`](docs/agents/adrs/2026-06-26-adopt-superpowers-house-voice.md).
- **Doc + manifest + eval sync.** **`CLAUDE.md`**, **`AGENTS.md`**, **`README.md`**, **`GLOSSARY.md`**, **`tier-scale.md`**, the plugin/marketplace descriptions, the **`check-chain-state`** hook (now flags a signed-off Design with an empty Decided section), and **`tests/evals/phase-2.evals.json`** are all updated to the new model. **Why:** a methodology that contradicts its own orchestration docs can't be followed.

### Added

- **`skills/draft-spec/references/design-template.md`** — the Design doc format (Overview, Why this approach, Key decisions and trade-offs, What we're explicitly NOT doing, Open questions, Decided, References) that `draft-spec` writes and `socratic-grill` fills in. **Why:** the Design needs a cold-readable, plain-language shape distinct from a slice list.

### Removed

- **`skills/draft-spec/references/spec-template.md`** — superseded by `design-template.md`. **Why:** "spec" is now the Design (Human layer); the slice list is a Machine-layer artifact generated after sign-off, so the slice-oriented template no longer fits.

MAJOR bump: output templates (`spec-template` → `design-template`) and inter-skill handoff contracts (e.g. `draft-spec` now emits `HANDOFF: grill ready`; `socratic-grill` emits a conditional `HANDOFF: record ready`) changed. No new runtime dependency — the ADR-0002 standalone invariant holds and the chain stays one-time-use per feature.

## [1.29.0] — 2026-06-25

- Dual-native on Claude Code AND Codex CLI — the bundle is now first-class on both harnesses, not a prose-only Codex fallback. The prior Codex story (AGENTS.md/README "Codex can only read markdown on demand") was built on an obsolete premise: Codex CLI has since grown a native **Agent Skills** system (same `SKILL.md` + `name`/`description` frontmatter, same progressive disclosure, invoked `$skill-name`), a **hooks engine** mirroring Claude's `hooks.json` schema (stable since Codex v0.124.0), and native **subagents**. **Single source of truth:** `skills/` stays canonical; the Codex discovery tree `.agents/skills/` is GENERATED by `bin/sync-codex.sh` (18 skills mirrored; `cross-session-detect`, having no `SKILL.md`, is intentionally skipped) and guarded by a CI drift-check (`tests/codex/02-skill-drift`). **Hooks:** `.codex/config.toml` registers the same five hook scripts under Codex with anchored regex matchers against Codex's reported `tool_name` (`^Bash$` for shell, `^(apply_patch|Edit|Write)$` for edits — `apply_patch` is Codex's canonical edit tool_name; `NotebookEdit` is Claude-only). The commit-block hook now emits Codex's JSON deny shape (`permissionDecision: "deny"`) in addition to Claude's `exit 2`. Version floor: edit-triggered hooks require Codex ≥ 0.123.0 — earlier Codex fired PreToolUse/PostToolUse only for Bash/shell, not `apply_patch` edits (openai/codex#16732, fixed in 0.123.0 / PR #18391, which also exposes the patch body as `tool_input.command`); the v0.124.0 engine baseline this release targets is past that floor, so all five hooks fire on both harnesses. **Portability:** a new `hooks/lib/resolve-bundle-root.sh` resolves the bundle root across harnesses (`CLAUDE_PLUGIN_ROOT` → `CURSOR_PLUGIN_ROOT` → `CODEX_PLUGIN_ROOT` → `git rev-parse --show-toplevel` → self-location), so one hook/command body runs everywhere with no harness-specific env var. **Subagents:** `parallel-dev` documents a harness-neutral dispatch guarantee (Claude Task/Agent tool AND Codex native subagents, sequential fallback where neither exists); the `agents/*.md` prompts were already runtime-neutral and ADR-0004-contract-driven, so Deep-tier research reaches full parity. **Frontmatter:** kept minimal (`name`/`description`/`disable-model-invocation`) — verified against Codex's published Agent Skills schema (name+description required, other keys inert), with `tests/codex/01-frontmatter-parity` guarding the assumption. New dated ADR `2026-06-25-dual-native-claude-codex-parity`; spec + plan under `docs/agents/`; new `tests/codex/` suite (4 scenarios) wired into `tests/run-all.sh` (48 suites green). Also fixed a pre-existing red: `hooks/*.sh` and `skills/release/scripts/*.sh` were committed non-executable, which dogfood scenarios 23/25/29 assert against. **Why:** the methodology's "Works on Codex" claim had quietly become false-by-omission — Codex users got neither hooks nor Deep-mode subagents — and the fix is now structurally durable because divergence between the two harnesses is a CI failure, not a silent runtime gap. Classed MINOR not MAJOR: every change is additive — the Claude plugin layout, install flow, and `skills/` tree are untouched, so no existing install breaks (ADR-0002 standalone invariant preserved; no new runtime dependency).

## [1.28.0] — 2026-06-13

- Audit follow-up — two decisions from the v1.27.0 audit, executed. **Removed the unwired halt-UX:** `cross-session-detect`'s `actions.sh` / `halt-ux.sh` / `trust.sh` (and their `tests/{actions,halt-ux,trust}/` suites) are deleted — ~400 lines that were specced in v1.16.0 and tested but never wired into a hook, and whose `halt-ux.sh` read operator choices via interactive `read`, which cannot run in Claude Code's non-interactive hook environment. The advisory detection layer (`sidecar` / `overlap` / `policy` / `audit`, hook-wired) is untouched; cross-session detection remains warn/annotate, never blocking. New dated ADR `2026-06-13-remove-unwired-halt-ux`. **Unified the grill extensions:** `agent-factors-check` and `devex-review` shared ~70 lines of identical procedure (pre-flight, scoring legend, question rules, triage rule, hand-back, anti-patterns); that procedure now lives once in `docs/agents/references/grill-extension-protocol.md` (per ADR-0009), and each skill keeps only its trigger test, checklist (13 factors / 6 dimensions), triage assignments, and examples. Dropped `devex-review`'s unused 4-status return contract (and its template Status section) for symmetry with `agent-factors-check` — both are grill extensions that feed questions back via `HANDOFF: grilling agenda updated`, never a standalone DONE/BLOCKED return. **Why:** the halt-UX was unreachable dead weight that couldn't work as written, and the twin-skill duplication was the exact drift trap ADR-0009 exists to prevent (the two had already diverged on their return contracts). The two other audit decisions — keep the frozen scenario-ID collisions, skip the `lib.sh` extraction — were deliberately left as-is. No new dependency (ADR-0002); all 43 suites green.

## [1.27.0] — 2026-06-13

- Full skill-base audit — a correctness-and-consistency pass across all 18 skills, the `cross-session-detect` hook library, 17 command files, 4 subagent prompts, 6 hooks, and the docs layer. **Hooks:** three of five registered hooks were silently inert under the current Claude Code hook contract — SessionStart emitted top-level `additionalContext`, the PreToolUse peer-scan read `HABEEBS_TOOL_NAME`/`HABEEBS_SESSION_ID` env vars the harness never sets, and PreToolUse/PostToolUse wrote warnings to plain stdout/stderr (debug-log-only); all now parse stdin JSON and emit `hookSpecificOutput.additionalContext`, and `hooks.json` quotes its `${CLAUDE_PLUGIN_ROOT}` paths. **Release:** the manual CHANGELOG/version-bump phases contradicted the changeset-aggregation phase (following the doc literally double-wrote); reconciled so aggregation is the mechanism and Phases 3/4 verify/enrich, and moved the description-policy audit out of the `gh pr create` heredoc (it was being posted as PR body text). **tdd-loop:** COMMIT was numbered before the review it logically follows — review is now Phase 4 (three-stage 4a/4b/4c), COMMIT is Phase 5. **Chain:** aligned one canonical drawing across AGENTS.md / CLAUDE.md / README / using-habeebs-skill / GLOSSARY / tier-scale / both manifests, disambiguated the overloaded `implementation ready` handoff token (decision-record now emits `plan ready`), and added the missing `tdd-loop → release` handoff. **Portability:** removed hardcoded personal precedent (BeanBot / salahi.app / AEGIS) from shipped skills so Tier 0 reads from the *consuming* repo. **Tests:** new `tests/run-all.sh` aggregating runner (46 suites green); fixed real `cross-session-detect` bugs (fail-safe liveness probe, honest merge-status reporting); reconciled stale counts/dates and the 7→8 ambiguity-axis drift; fixed a pre-existing red (scenario 16) that conflicted with the behavioral-only-body policy. **Why:** the plugin's runtime safety net beyond the commit-block hook was inert in production, the release skill double-wrote if followed literally, and the chain was drawn four disagreeing ways — each a correctness gap undermining the methodology's own "follow your own rules" premise. No new dependency (ADR-0002). Classed MINOR not MAJOR: the chain is one-time-use (ADR-0002) and internally consistent within the release — the renamed handoff token's only consumer (`write-plan`) was updated in lockstep, so no version-straddling consumer can break.

## [1.26.0] — 2026-06-10

- Loop harness — the chain becomes loop-capable: **`tdd-loop`** gains a failure-triage rule (transient → one fresh-context re-run; structural / same-error-twice → `systematic-debugging` auto-invoked with an evidence payload; spec-implicated → the re-grill edge; per-slice retry budget 2 as a termination guarantee) and a loop mode (`/tdd --loop` promotes Phase 0.5 to a fresh-context-per-slice driver — ceiling 2× open slices with `--max-iterations` override, exactly two terminal states `DONE` / `BLOCKED`-with-halt-report, a tiered halt policy where three confirmation gates run provisionally on green checks while decision gates park scope into structured halt reports, and `/tdd --resume <run-id>` re-enters parked slices next morning); **`parallel-dev`** gains a context-starved reviewer dispatch (diff + slice spec + bounding SHAs only, gaps-not-style, Critical hard-blocks in AFK) and a widened NEEDS_CONTEXT bound (up to 2 dispatcher-judged materially-changed re-dispatches — ADR-0004 Part 1 amended in place); a new run-file artifact class lands in `docs/agents/dispatches/` with a RUN_SUMMARY morning-read and one halt-report format (the re-grill 7 fields + cause/evidence/options), defined at **`docs/agents/references/run-file-format.md`**. **Why:** overnight loops need bounded self-correction and fail-closed human gates — the harness makes runaway waste structurally impossible (every budget is capped), keeps halt *authority* human while changing halt *handling* (park-and-continue instead of run-death, formally discharging the Grill 2.0 ADR's unattended-execution revisit trigger), and extends only existing machinery (no hooks, no substrate; the Stop-hook carve-out is explicitly deferred). New dated ADR 2026-06-10-loop-harness-fresh-context-outer-loop; dogfood 40–44; GLOSSARY +5 terms.

## [1.25.0] — 2026-06-09

- Grill 2.0 — the grill now aligns user and agent across the whole workflow: it interrogates the slice decomposition (slice-shape 8th ambiguity axis; the spec's slice table is a standing Phase 1 inventory item), verifies the user's expectations with tier-scaled mental-model probes (premortem / door-classification with undo-cost follow-up / concrete example — Quick 1 / Balanced 2 / Deep 3 — landing in a "User mental model" record section that `write-plan` and `decision-record` consume), and gains a first-class re-grill edge so implementation-revealed spec ambiguity halts into a scoped round instead of being guessed away (`tdd-loop` BLOCKED + `suggested_action: "re-grill"` with a 7-field learning payload; the blast-radius rule splits inline spec patches from ADR escalation; `parallel-dev`'s halt-scope rule pauses or salvages in-flight siblings). **Why:** the three alignment blind spots — slice defects caught by luck, mid-flight spec drift handled by improvisation, user-expectation misses surfacing as late pushback — each had documented incidents across 12 grill records. New dated ADR 2026-06-09-add-regrill-edge-and-grill-alignment-axes; dogfood 37/38/39.

## [1.24.0] — 2026-06-01

- Chain-fidelity hardening — three new corpus-tested dogfood guards (scenario 34 self-referential-archaeology lint, 35 fixture-ID late-binding rule, 36 supersession-link integrity check) plus the ADR-0003 Rule 4 amendment (hooks resolve their block predicate from the action's target, not the hook's cwd — locking the v1.23.0 fix as doctrine) and a plugin-self-dev runtime-lag note. Each guard catches a convention that previously relied on a human remembering it; all markdown/bash, no new dependency (ADR-0002). New dated ADR 2026-06-01-chain-fidelity-executable-assertions.

## [1.23.0] — 2026-05-29

- Decouple decision identity from releases — decision-record writes dated YYYY-MM-DD-<slug>.md ADRs at creation (slug is the uniqueness key, halt-loud on duplicate); the release-driven late-binding rename machinery is removed; convention extends to specs/plans/grill-records with version in frontmatter; the 24 integer ADRs stay frozen. Also fixes the commit-block hook to resolve the branch from a command's target worktree (was false-positive-blocking worktree commits).

## [1.22.0] — 2026-05-26

- methodology overhaul — plain-English plan format (TL;DR + per-phase narrative + tables limited to status block + slice list); provisional-state HITL pivot gate between research Phase 6 and Phase 6.5 archive; warn-only PostToolUse chain-state validator hook (missing-grill-when-Grilled + editing-on-default-no-worktree); markdown-only telemetry frontmatter (PascalCase Status / Date-Created / Last-Reviewed / Superseded-By + release editorial scan on minor+major); ADR-0021 in-place 2026-05-26 Clarification (runtime writer paths vs authored methodology directories); supply-chain threat-model ADR acknowledging Anthropic-plugin gap, deferring hardening to v1.23.0+. Drives the v1.22.0 methodology-overhaul research (`docs/agents/research/2026-05-26-v1.22.0-methodology-overhaul-research.md`, Deep tier, 36 sources, 7 sub-problems).

## [1.21.0] — 2026-05-26

- behavioral-only SKILL.md body convention — strip inline ADR cites + version-archaeology tags + dated incidents (58 hits across 11 files); Pattern-D empirical-claim exception for load-bearing quantitative claims; new dogfood scenarios 26/27/28 prevent regression

## [1.20.0] — 2026-05-25

Methodology overhaul — late-binding ADR IDs + Changesets-shape append-only version bumps eliminate the two largest parallel-session merge-conflict classes (ADR integer collisions + `plugin.json` / `marketplace.json` / `CHANGELOG.md` 3-way conflicts on every PR). `decision-record` writes `adr-<slug>.md` (no integer); `release` skill is the SOLE writer of numbered ADR files and assigns ints at release-PR-creation time in alphabetic slug order. Feature branches never edit version files — they drop a `.changeset/<slug>.md` carrying `bump:` + `why:`, and the new release-skill `Phase 3.25` aggregates them atomically. This release self-dogfoods the entire mechanism: the v1.20.0 bump itself + the two new ADRs (renamed to 0020 + 0021 here) shipped via the new scripts. Drives the [v1.19.0 workflow audit memo](docs/agents/research/v1.19.0-workflow-audit-research.md) findings.

### Added

- **`.changeset/`** directory at repo root with `README.md` (schema + workflow), `EXAMPLE.md` (copy-and-edit template), and `.gitkeep`. Per-PR changesets carry `bump: patch|minor|major` + `why: <single line>` frontmatter.
  - **Why:** the Changesets / release-please / Vercel / Backstage convergent pattern (Pattern A from the audit) — append-only intent files + release-time aggregation by a single coordinator. Eliminates the version-file 3-way merge-conflict class because feature branches never touch the aggregated files. Single-author scale = slug-based filenames (not random-id); revisit trigger if a 2nd author joins + ≥3 collisions in 90 days.
- **`skills/release/scripts/aggregate-changesets.sh`** (212 lines) — reads pending `.changeset/*.md`, picks highest bump (major > minor > patch), atomically bumps `plugin.json` + `marketplace.json` + prepends a `## [X.Y.Z] — YYYY-MM-DD` section to `CHANGELOG.md`, deletes consumed changesets. Temp-staging-dir + backup-and-rollback semantics; exit codes 0 success / 1 aborted clean / 2 aborted dirty. Supports `--root`, `--dry-run`, `--help`.
  - **Why:** the bot-equivalent at release time. habeebs-skill has no CI; the release skill IS the single coordinator. Aggregation runs in-PR (FIRST step of release-PR creation) so the bump commit lives on the release branch and lands via merge, not on `main` directly.
- **`skills/release/scripts/check-changeset-required.sh`** (154 lines) — path-audit matrix. REQUIRED for `skills/`, `hooks/`, `.claude-plugin/`, `plugin.json`, `marketplace.json`. OPTIONAL (INFO note) for `docs/`, `CLAUDE.md`, `AGENTS.md`, `README.md`, `CHANGELOG.md`. NEVER required for `tests/`, `.gitignore`, `.github/`, `.gitattributes`. Supports `--print-messages` to print all 5 named operator-facing error messages (used by dogfood 25).
  - **Why:** soft enforcement at PR-creation time. A PR modifying skills/ without a changeset halts the release with `"PR modifies skill files but contains no .changeset/*.md. Required path (...) needs a changeset. See .changeset/README.md..."` Hard cutover migration — no grace window — because habeebs-skill is single-author and the migration is one-time.
- **`skills/release/scripts/assign-adr-ids.sh`** (183 lines) — scans `adrs/adr-*.md`, assigns sequential integers from `max(existing NNNN-*) + 1`, renames alphabetically, regenerates `adrs/README.md` index. Slug collision (two `adr-<identical-slug>.md`) halts loud with exit 2 and the operator-facing message `"Cannot rename — two ADRs share slug ..."`. Supports `--adrs-dir`, `--extra-scan` (collision-detection across two directories, used by dogfood 21), `--dry-run`, `--help`.
  - **Why:** Backstage late-binding pattern — the only canonical-tier source (1 of 6 ADR practices surveyed in the audit) that visibly grapples with parallel-writer collisions. Preserves Nygard's sequential-monotonic-no-reuse guarantee while eliminating the branch race.
- **`docs/agents/adrs/0020-late-binding-and-changesets.md`** (new ADR, born as `adr-late-binding-and-changesets.md` and renamed at release time by `assign-adr-ids.sh` — self-dogfood) — combines the identifier-strategy + version-bump + atomicity + path-audit + error-message + migration decisions. Cross-links ADR-0002 (substrate preserved), ADR-0004, ADR-0007 (v1.19.0 release-skill audit step extended, not replaced), ADR-0018, ADR-0019.
  - **Why:** the load-bearing methodology ADR for v1.20.0. Becomes Tier 0 prior art for future research on multi-file release coordination, ADR identifier strategies, monorepo version bumps.
- **`docs/agents/adrs/0021-methodology-folder-cuts.md`** (new ADR, born as `adr-methodology-folder-cuts.md`) — documents the `grill-records/` → `specs/<name>-grill.md` fold + Pattern B applied to files-with-content + the **2026-05-25 Amendment** that reverses the originally-planned `dispatches/` and `conflicts/` deletions after runtime-writer inventory revealed both have live writers (parallel-dev Phase 7.5 + cross-session-detect/audit.sh respectively). Empty directories are NOT dormant when a runtime writer targets them on rare events.
  - **Why:** Pattern G (methodology folders earn existence by file count) needed the carve-out for runtime audit-log directories. The amendment itself is evidence the chain's "loud failure mode" works — bug caught at the latest non-destructive point (mid-Slice-4 prep, before any deletion landed).
- **`skills/release/SKILL.md`** § **Phase 3.25 (Changeset aggregation + path audit)** — new release-skill phase inserted between v1.19.0's `## Description-policy audit` and Phase 4 (version bump). Sequence: path audit → aggregation dry-run → aggregation live → ADR ID assignment (Phase 3.5) → commit + push + PR.
  - **Why:** integrates the new mechanism into the existing release flow at the right point. The release skill is now the sole coordinator for plugin.json / marketplace.json / CHANGELOG.md / ADR-int writes; feature branches own only their own slice content.
- **`skills/release/SKILL.md`** § **Phase 3.5 (ADR ID assignment)** — new phase invoking `assign-adr-ids.sh --dry-run` then live. Halts on exit 2 (slug collision).
  - **Why:** completes the late-binding mechanism. Without this phase, `adr-<slug>.md` files would pile up unnumbered.
- **`tests/dogfood/21-late-binding-adr/check-late-binding.sh`** (5 fixture cases) — happy path alphabetic ordering, slug collision halt + exact message, `--dry-run` no-op, `--help` usage, separation-of-writers (decision-record never writes `^[0-9]{4}-`).
  - **Why:** mechanical enforcement of the late-binding contract. Without this dogfood, a future author could silently regress `decision-record` back to writing numbered ADRs directly.
- **`tests/dogfood/22-changeset-schema/check-schema.sh`** — validates every real changeset's `bump:` + `why:` against the schema. Skips README/EXAMPLE/.gitkeep. Includes EXAMPLE.md as a contract-demo validation.
  - **Why:** without schema validation, malformed changesets (typo'd bump, missing why) would surface only at aggregation time. Failing earlier reduces friction.
- **`tests/dogfood/23-changeset-aggregation/check-aggregation.sh`** (5 fixture cases) — happy path 3 mixed-bumps → minor + 3 bullets, bump resolution major > minor > patch, `--dry-run` no-op, `--help`, atomic-or-rollback contract structurally present. Fixture uses the canonical `## [X.Y.Z] — YYYY-MM-DD` CHANGELOG format.
  - **Why:** caught a real bug during the Slice 7 self-dogfood — the original Slice 3 fixture used `## v1.19.0` (legacy format) and silently passed against the buggy regex; the canonical-format fixture exposed the bug at exactly the right time. Lesson: dogfood fixtures must match real data shapes.
- **`tests/dogfood/24-folder-cuts/check-grill-records-folded.sh`** — verifies `grill-records/` is absent + the moved file's git history is preserved (post-commit `git log --follow` mode 1; staged-rename mode 2 fallback for pre-commit runs) + the structural-fold ADR is present.
  - **Why:** the only mechanical confirmation that the `git mv` actually preserved file history (a `cp + delete + new commit` would silently lose authorship).
- **`tests/dogfood/25-changeset-required-check/check-path-audit.sh`** (5 fixture cases) — REQUIRED-without-changeset halts, OPTIONAL emits INFO, NEVER silent, REQUIRED-with-changeset passes, all 5 named error messages present in `--print-messages` output.
  - **Why:** locks the 5 operator-facing error messages from the ADR § Decision verbatim. Any future drift (e.g., reformatting a message) fails this scenario loud.

### Changed

- **`skills/decision-record/SKILL.md`** — Phase 2 ("Number the ADR") rewritten to "Late-binding ID (skip numbering)"; Phase 3 filename example updated from `0008-...` to `adr-<slug>.md`; Phase 6 ("Update the ADR index") rewritten to "Defer ADR index update to release". **`decision-record` is now the SOLE writer of `adr-*.md`; never writes `NNNN-*.md` directly** — enforced by dogfood scenario 21 case (e). Existing ADRs (0001-0019) NOT renamed (Pattern B / immutable path; asymmetric creation path is invisible at rest because final shape is identical).
  - **Why:** decision-record creating numbered ADRs directly was the source of the parallel-writer collision. Moving the int-assignment to release time eliminates the race; separation-of-writers makes the contract enforceable.
- **`skills/release/SKILL.md`** — gains Phase 3.25 + Phase 3.5 (additive, not replacing v1.19.0's flow). Phase 4 (version bump) remains as a fallback for any release that bypasses the changeset mechanism (e.g., a hotfix); the new aggregation script's exit-0-on-nothing-to-do behavior makes both paths coexist cleanly.
  - **Why:** integrates the new mechanism without breaking v1.19.0's still-load-bearing description-policy audit step.
- **`docs/agents/specs/v1.16.0-cross-session-conflict-detection-grill.md`** — moved (via `git mv`) from `docs/agents/grill-records/2026-05-22-cross-session-conflict-detection.md`. The old `grill-records/` directory deleted. Naming convention now aligns with the existing `<spec>-grill.md` pattern.
  - **Why:** `grill-records/` had 1 file after months; Pattern G (folders earn existence by file count) genuinely applied here (unlike `dispatches/` + `conflicts/`, which were misclassified — see ADR-0021 § 2026-05-25 Amendment). The fold reduces `docs/agents/` from 9 to 8 declared subdirectories.
- **`skills/parallel-dev/SKILL.md`** — new "Task class — read vs write" section between "Do NOT trigger on" and "Core workflow"; Phase 4 concurrency-cap text gains an 8-hard-ceiling for write-task dispatches.
  - **Why:** Cognition's "Don't build multi-agents" essay and Anthropic's multi-agent research system are not actually in conflict — they apply to different task classes. Read-task dispatches (research / extraction / audit) are Anthropic-validated at ~15× tokens with zero merge surface; write-task dispatches (artifact-producing) are Cognition-restricted to per-worktree isolation + ≤8 concurrent + Phase 2 independence verification, all mandatory. Hybrid dispatches collapse to write (stricter rule wins).
- **`skills/using-worktrees/SKILL.md`** — new "Hazards from git itself" section after Anti-patterns. Documents the `extensions.worktreeConfig` footgun (`core.worktree` / `core.bare` / `core.sparseCheckout` shared across worktrees by default; one agent's `git config` mutation leaks to all peers; recovery is `git config extensions.worktreeConfig true`), the manual-`rm -rf` stale-refs problem (recovery: `git worktree prune`), and the one-branch-one-worktree constraint (git refuses double-checkout; the constraint forces session-per-branch isolation — don't work around it).
  - **Why:** these are the most-likely cross-worktree state-hygiene bugs the audit memo flagged as the actual source of "conflicts in real use" the user reported. v1.18.0's cross-session conflict detection is downstream; using-worktrees hygiene is upstream.
- **`CLAUDE.md`** — triggering-principles list gains one bullet pointing at the new `parallel-dev` task-class section.
  - **Why:** the triggering-principles section is the right surface to flag a methodology distinction that changes which downstream phases are mandatory.

### Fixed

- **`skills/release/scripts/aggregate-changesets.sh`** — CHANGELOG section regex broadened from `/^## v/` to `/^## (\[|v[0-9])/` so it matches the canonical `## [X.Y.Z] — YYYY-MM-DD` format (was matching only legacy `## v...`). Section header itself now written in the canonical bracketed-with-date format. Post-write verification grep aligned. Dogfood scenario 23 fixture switched from `## v1.19.0` to `## [1.19.0] — 2026-05-22` to catch any future regex regression.
  - **Why:** the original Slice 3 regex matched the toy fixture but not the real CHANGELOG, so the first live run silently appended `## v1.20.0` at the bottom of the file instead of prepending it. Surfaced and fixed during Slice 7 self-dogfood — exactly the loud failure mode the audit memo's "self-dogfood release" strategy was designed for.

### Migration notes

Any open PR modifying `skills/`, `hooks/`, or `.claude-plugin/` must add a `.changeset/<branch-slug>.md` before merging. Copy `.changeset/EXAMPLE.md`, edit `bump:` and `why:`, commit alongside other changes. See `.changeset/README.md` for full schema. **Hard cutover — no grace window.** Single-author + manual release process makes the migration one-time and well-bounded.

## [1.19.0] — 2026-05-25

Auto-trigger reliability — habeebs-skill descriptions now actually fire on natural-language dev prompts. The previous "Make sure to use this skill when…" canonical phrasing read as advisory; descriptions never won the fuzzy-match contest against 135 SKILL.md files installed system-wide. v1.19.0 rewrites all 18 descriptions to a trigger-first / literal-quote / directive-imperative anatomy (650-trials empirical pattern), demotes 11 chain-internal skills via `disable-model-invocation: true` so only 7 compete for auto-invocation, and adds an explicit `## Skill routing` table to CLAUDE.md that outranks fuzzy-match. ADR-0007 amended in place (clauses A-F); original 2026-05-13 ADR body preserved for historical record.

### Changed

- **All 18 `skills/*/SKILL.md` descriptions** rewritten to the v1.19.0 anatomy: `[Capability ≤8 words]. [Imperative directive] when [literal user phrase 1], [phrase 2], or [phrase 3]. [Tight anti-trigger].` Average drops from 596 → 298 chars; ~5,400 tokens recovered per turn on the always-loaded skill-listing budget.
  - **Why:** the Seleznov 2026 650-trials study A/B-tested directive imperatives (`ALWAYS invoke when…`) at 94-100% activation vs passive `Use when…` at 37-87% (Cohen's h = 1.83, p < 0.0001). habeebs's `Make sure to use this skill when…` read as advisory and lost the fuzzy-match contest in real sessions.
- **11 chain-internal SKILL.md frontmatters** carry `disable-model-invocation: true`: `draft-spec`, `socratic-grill`, `decision-record`, `write-plan`, `tdd-loop`, `verify-output`, `release`, `vertical-slice`, `parallel-dev`, `agent-factors-check`, `devex-review`. They remain `/slash-invocable` and fire on upstream HANDOFF — only the 7 entry-point / support-meta skills compete for auto-invocation.
  - **Why:** 18 skills auto-invocable + 135 SKILL.md installed system-wide diluted entry points that should have won. Demoting chain-internals restores entry-point precedence while preserving slash-command muscle memory.
- **`CLAUDE.md`** — added a `## Skill routing` block between `## The chain` and `## Triggering principles`, mapping natural-language user signals to slash-commands for the 4 entry-point skills + chain handoffs.
  - **Why:** explicit task-type → skill mapping in always-loaded CLAUDE.md outranks fuzzy-match against 30+ competing descriptions.
- **`docs/agents/adrs/0007-description-budget-policy.md`** — amended in place with a dated `## 2026-05-24 Amendment` section. Hard cap drops 1,200 → 1,024 (matches Anthropic's actual spec); target avg drops 600 → 300; pushy-trigger preservation rule replaced with the anatomy template above. Three-keystone list updated: `prior-art-research`, `systematic-debugging`, `deep-modules` (was `prior-art-research`, `socratic-grill`, `tdd-loop` — but the latter two are now `disable-model-invocation: true` and cannot over-trigger).
  - **Why:** ADR-0007's original 1,200-char cap was based on outdated Anthropic doc claiming 1,536; the live spec is 1,024. The pushy-trigger phrasing rule was anchored on theoretical Anthropic guidance, never A/B-tested against directives.
- **`tests/dogfood/11-description-budget/check-description-budget.sh`** — `HARD_CAP=1024`, `TARGET_AVG=300`, new directive-imperative regex `(use when|always use|you must use|trigger (on|when))`, new forbidden-legacy-phrase check (`Make sure to use this skill`), new literal-quote check (≥1 `"..."` per description), new block-scalar regression guard (rejects `|`/`>` on `description:` line per research Case 7).
  - **Why:** the dogfood is the only mechanical enforcement of the amended policy; without script updates, future authors would drift back to legacy phrasing.
- **`tests/dogfood/13-trigger-precision/README.md`** — status changed to "regression baseline." The synthetic-corpus 34/34 precision was Hamel Husain's "synthetic prompts approach 100% by construction" red flag — confirmed empirically by the maintainer's real-session experience. Primary firing-rate signal now lives in `docs/agents/references/trigger-firing-eval.md`.
  - **Why:** dogfood 13 reported 100% precision while real sessions failed to fire — the synthetic auditor scored prompts it would have written, not prompts the maintainer actually types.
- **`skills/release/SKILL.md`** — new `## Description-policy audit (v1.19.0+)` section; release checklist gains a dogfood 11 line item.
- **`skills/using-habeebs-skill/SKILL.md`** — new `## Auto-invocation scope (v1.19.0+ per ADR-0007 § C)` section documenting the 7/11 split.

### Added

- **`tests/dogfood/11-description-budget/check-disabled-list.sh`** — new dogfood assertion that the 11 demoted skills carry `disable-model-invocation: true` and the 7 auto-invocable skills do not. Cross-checks total skill count = 18.
  - **Why:** without this guard, an author adding a new SKILL.md could silently land in the auto-invocation pool without an explicit decision; the script makes the classification mandatory.
- **`docs/agents/references/trigger-firing-eval.md`** — new methodology doc for the real-session transcript review that replaces dogfood 13 as the primary firing-rate signal. Cadence (quarterly + 7 days post-release), sample-set sizing, anonymization rubric, scoring (primary/secondary/tertiary signals), failure response, idempotency rule. Cites the 10pp lift threshold that gates v1.20.0.
  - **Why:** dogfood 13's synthetic corpus reports 100% precision yet real sessions fail — Hamel Husain's red flag. The transcript eval closes the synthetic-vs-real gap by measuring firing-rate on prompts the maintainer actually types.
- **`docs/agents/research/2026-05-24-auto-trigger-reliability.md`**, **`docs/agents/specs/v1.19.0-auto-trigger-reliability.md`** + **`-grill.md`**, **`docs/agents/plans/0007-description-policy-amendment-v1.19.0.md`** — full chain artifacts for the v1.19.0 work (Balanced tier, 8 case studies, 6 OQs all DECIDED, 5-phase plan).

### Success metric (load-bearing for v1.20.0 follow-up)

+30 days post-release, the transcript eval must show **>10 percentage-point lift** in (sessions with `"build"`/`"add"`/`"refactor"`/`"fix this"`/`"design"`/`"implement"` in the user prompt AND the matched entry-point skill fires within 2 turns) / (all sessions with those keywords). Below 10pp, v1.20.0 candidate uses the `You MUST use this skill when…` imperative-with-pronoun variant — NOT a revert. The metric is documented at `docs/agents/references/trigger-firing-eval.md`.

## [1.18.0] — 2026-05-24

Cross-session conflict detection. When two Claude Code sessions work on the same repo simultaneously, they can unknowingly modify the same files and produce conflicting changes that only surface at push time. v1.18.0 adds advisory detection at three trigger points — SessionStart (warn-only peer scan), pre-push (block on overlap), and PreToolUse (opt-in annotate-only) — so sessions discover conflicts early and resolve them interactively. ADR-0019's four-sub-clause guard (advisory not authoritative, defined stale-data contract, per-writer-unique artifact, read-only across writers) carves out in-flight sidecar reads from ADR-0002's standalone constraint.

### Added

- **`skills/cross-session-detect/sidecar.sh`** — per-session JSON sidecar lifecycle (write/read/list/end/prune) in `$(git rev-parse --git-common-dir)/habeebs-sessions/`. PID-based liveness probe with configurable TTL.
  - **Why:** sessions need a shared discovery mechanism that doesn't require a runtime daemon; per-file sidecars inside `.git/` are invisible to git and auto-cleaned.
- **`skills/cross-session-detect/policy.sh`** — 4-scope policy resolver (User < Project < Local < Managed) with scalar-override precedence and type validation.
  - **Why:** different repos and users need different conflict-detection behavior (e.g., PreToolUse opt-in, TTL tuning); a layered policy avoids per-repo forks.
- **`skills/cross-session-detect/overlap.sh`** — `git merge-tree` overlap probe using the pre-2.38 three-tree form for broad git compatibility.
  - **Why:** the core detection primitive — determines whether two sessions' changes actually conflict on the same files.
- **`skills/cross-session-detect/audit.sh`** — single-writer append-once JSON audit log in `docs/agents/conflicts/`.
  - **Why:** conflict events need a durable, reviewable record for postmortems and methodology improvement.
- **`skills/cross-session-detect/halt-ux.sh`** — 5-option interactive halt menu (Merge / Sequence / Transfer / Abort / Worktree-out) with SIGINT/EOF→abort default.
  - **Why:** conflicts need user-driven resolution, not automated guessing; the menu presents all viable options.
- **`skills/cross-session-detect/actions.sh`** — all 5 action handlers: abort (sidecar cleanup + audit), worktree-out (branch + worktree creation), transfer (`.transfer.md` for peer), sequence (exponential-backoff polling), merge (conflict extraction + `$EDITOR`).
  - **Why:** each halt-menu option needs a concrete implementation that leaves the repo in a clean, resumable state.
- **`skills/cross-session-detect/trust.sh`** — opt-in `git verify-commit` wrapper for signed-signal verification of peer sidecars.
  - **Why:** high-trust environments may want cryptographic proof that a peer sidecar was written by a legitimate session.
- **`hooks/session-start-peer-scan.sh`** — SessionStart hook: writes own sidecar, scans live peers, emits warn-only JSON.
  - **Why:** the earliest detection point — warns immediately when a session starts and peers are already active.
- **`hooks/pre-push.sh`** — pre-push hook: blocks push (exit 1) when any live peer's stash overlaps with the current branch.
  - **Why:** the highest-stakes trigger — prevents conflicting pushes before they create remote merge conflicts.
- **`hooks/pretool-use-peer-scan.sh`** — PreToolUse hook (Edit/Write/NotebookEdit only): annotates when peer overlap detected on the target file, gated by `pretool_use: true` in policy.
  - **Why:** per-edit awareness for teams that want continuous conflict visibility without blocking.
- **`tests/`** — 11 test suites, 170 assertions across sidecar lifecycle, policy resolver, SessionStart hook, overlap probe, pre-push hook, audit writer, halt UX, action handlers, PreToolUse hook, trust mode, and 6 end-to-end scenarios.
  - **Why:** TDD — every slice was RED→GREEN before implementation was considered complete.

### Changed

- **`hooks/hooks.json`** — added `session-start-peer-scan.sh` to SessionStart array and `pretool-use-peer-scan.sh` to PreToolUse array with `Edit|Write|NotebookEdit` matcher.
  - **Why:** hooks must be registered to fire.
- **`docs/agents/adrs/0002-habeebs-skill-standalone.md`** — status updated to `Accepted (amended by 0018)` with forward link to the carve-out ADR.
  - **Why:** ADR-0002 is the load-bearing standalone constraint; the amendment must be visible from the original.

### Notes

- **git 2.36.1 compatibility.** The overlap probe uses the pre-2.38 `git merge-tree` three-tree form (base_tree, our_tree, peer_tree) rather than `--write-tree`, ensuring compatibility with git versions shipping on Windows and older Linux.
- **No runtime daemon.** Despite adding per-session state, the implementation is fully stateless from the hook's perspective — sidecars are plain JSON files inside `.git/`, probed on-demand, never watched. ADR-0002's standalone constraint holds.

## [1.17.0] — 2026-05-23

Dormant artifact-recording contracts go live (ADR-0018). Two declared-but-unused docs directories — `docs/agents/dispatches/` (declared by ADR-0004 Part 2 in v1.7.0) and `docs/agents/research/` (informally used once in v1.10.0) — both finally have writer skills. `parallel-dev` gains Phase 7.5 (always-on: writes a JSON dispatch record after every verified parallel run). `prior-art-research` gains Phase 6.5 (tier-conditional per ADR-0016: required on Deep, optional on Balanced, skipped on Quick — archives the Phase 6 synthesis to `<slug>-research.md`). Both writes degrade gracefully on failure (one-line warn, work proceeds) — audit/archive cost must never poison successful chain results. Ships alongside a mechanical docs-folder cleanup that removes the v1.0-era `docs/BUILD-PLAN.md` (6+ months stale; "Decisions deferred" questions all resolved by ADR-0007/0009/0014/0016) and collapses the single-file `docs/agents/templates/` directory into the consuming skill's `references/` per ADR-0009's 3-consumer threshold.

### Added

- **`docs/agents/adrs/0018-implement-dormant-artifact-recording-contracts.md`** — ADR-0018: Part A commits `parallel-dev` Phase 7.5 (writes `docs/agents/dispatches/<id>.json` per the schema in `dispatch-record-template.md` § Section 4 — independence verification, per-subagent records, aggregate timing, re-dispatches; always-on). Part B commits `prior-art-research` Phase 6.5 (archives the Phase 6 report verbatim to `docs/agents/research/<slug>-research.md`; tier-conditional). Both markdown/JSON only; ADR-0002 unaffected. ADR-0004 status field extended with "Part 2 writer implemented by 0018."
  - **Why:** every Deep-tier research run since v1.7.0 discarded its evidence base after synthesis; every parallel dispatch since v1.7.0 ran with no audit log. The contracts were declared but never honored. Future research and parallel runs now have durable artifacts for the chain-postmortem skill (ADR-0011) to grade against.
- **`skills/parallel-dev/SKILL.md`** Phase 7.5 — pre-existing Phase 7 sentence "Note this in the dispatch record for future calibration" now actually points at a write step instead of a missing convention. Dispatcher (single-writer) writes the record after verification verdict is known. Single-writer invariant preserved; forensic readers grep after the fact.
  - **Why:** without Phase 7.5, ADR-0004 Part 2's audit contract had no implementation surface. Calibration-via-postmortem cannot grade a directory that's been empty for 6 months.
- **`skills/prior-art-research/SKILL.md`** Phase 6.5 — tier-conditional archive between Phase 6 Synthesize and Phase 7 Hand off. Slug follows the downstream spec convention (`vX.Y.Z-<feature-name>`). HANDOFF lines in Phase 7 name the archive path so downstream skills read the durable file instead of relying on conversation context (honors `using-habeebs-skill`'s full-doc-read contract).
  - **Why:** Deep-tier research had no durable surface — only the spec's "Concrete picks" table and SYSTEM_CONTEXT's "Last reconciliation outcome" preserved compressed traces. The full evidence base was lost between releases, making it impossible to grade the chain's research quality cross-cycle.

### Changed

- **`docs/agents/SYSTEM_CONTEXT.md`** — ADR count 16 → 18; latest-ADR + recent-batch lines updated for 0017 + 0018; two new lines under § Methodology / agent setup document the dispatch-record and research-archive directories now that both are write-implemented; session-summary-template path updated to its new home under `using-habeebs-skill/references/`. Last refreshed advanced to 2026-05-22.
  - **Why:** SYSTEM_CONTEXT is the cross-session ground truth for what's load-bearing in the methodology. Adding two new write-active directories without surfacing them here would defeat the per-ADR-0005 single-writer contract.
- **`docs/agents/adrs/README.md`** — index rows 17 + 18 added; ADR-0004 status extended.
  - **Why:** the ADR index is the discovery surface for prior-art-research's Tier 0 internal-precedent lookup.
- **`skills/using-habeebs-skill/references/session-summary-template.md`** (moved from `docs/agents/templates/`) — same content, new location per ADR-0009's 3-consumer threshold (one consumer = the skill's own `references/`, not top-level).
  - **Why:** the template was misplaced at top-level since v1.10.0. ADR-0009 was the existing rule; the move closes the inconsistency without adding new convention.
- **`docs/agents/adrs/0012-compress-at-overflow-protocol.md`** — in-place amendment + changelog entry updating the template path reference.
- **`skills/tdd-loop/SKILL.md`**, **`skills/using-habeebs-skill/SKILL.md`** — see-also and prose references updated to the new template path.
- **`README.md`** — `docs/` block rewritten from the misleading single-BUILD-PLAN listing to an accurate 11-item enumeration of `docs/agents/` artifacts.
  - **Why:** the README's `docs/` block never mentioned `docs/agents/`, the entire methodology substrate. A reader who only read the README would not learn the methodology exists.
- **`tests/dogfood/16-session-summary-template/`** — both scripts (`check-session-summary-template.sh`, `check-using-habeebs-section.sh`) updated to the new path; README updated.
  - **Why:** dogfood scripts must reflect current paths, not historical ones.

### Removed

- **`docs/BUILD-PLAN.md`** (100 lines) — the v1.0-era build tracker. Last touched at 6cdec0e (v1.0.0). Phases 1-5 describe completed work; phases 5-7 reference workflows that have since shipped in other forms (`CHANGELOG.md`, marketplace publish via `release` skill). The "Decisions deferred" section asked 4 questions that ADR-0007 / ADR-0009 / ADR-0014 / ADR-0016 have since resolved.
  - **Why:** zero downstream readers besides the README's directory tree. Stale documentation is worse than missing documentation — it teaches the wrong mental model of where the project is.
- **`docs/agents/templates/`** directory — collapsed to empty after the session-summary template moved; removed.
  - **Why:** ADR-0009 governs `references/` placement; a top-level `templates/` directory holding a single-consumer file violated the threshold.

### Notes

- **No frontmatter or handoff-contract change.** Phase 7.5 (parallel-dev) is additive between Phase 7 and the Return contract section; Phase 6.5 (prior-art-research) is additive between Phase 6 and Phase 7. Neither renames an existing phase or alters a HANDOFF line semantically. Existing chain consumers see only new optional outputs.
- **No retroactive backfill.** Past releases' dispatch records and research archives are not reconstructed — only future runs produce them.
- **Retention/pruning policy not yet specified.** ADR-0018's revisit triggers fire at 1000 dispatch records and ~50 research files; until then both directories grow unbounded.
- **`verify-output` archive↔descended-artifact consistency check** is flagged as a future revisit trigger but not implemented in this release.
- **Hook scope memory amended.** The release-tag-hook-misfire memory was updated post-v1.16.0: ADR-0015 fixed tag-pushes from main but `git branch -D` / `git push origin --delete` remain blocked. The two-step workaround (switch off main first) is documented but no hook change ships in v1.17.0.

## [1.16.0] — 2026-05-22

Semantic-repo-discovery as a conditional Phase 4 Tier 2 technique. `prior-art-research`'s Phase 4 Tier 2 previously routed every repo-discovery query through `gh search repos` or `WebSearch site:github.com` — both keyword-shaped — which returned tutorials and SEO chum for NL-rich feature descriptions ("local AI assistant that remembers screen activity"). v1.16.0 adds a fire-rule-gated NL→ranked-GitHub-repos loop (query-expand → search → skim → LLM-rerank → return) ported from [reposeek.ai](https://docs.reposeek.ai/)'s idea but native to the chain — no API key, no SaaS, no runtime substrate (ADR-0002 unamended). The fire-rule is load-bearing under ADR-0010's prune test: the loop fires only when at least one of three NL-shape tests trips, biasing toward firing because false-skip is a correctness cost while false-fire is only a token cost. Ships alongside three quality-of-life refinements: a pre-dispatch goal-clarity gate in `parallel-dev`, trade-off-rationale notes in `setup-habeebs-skill`, and a Phase 1 editorial-priming fix that was teaching the LLM to defend its question count before asking it.

### Added

- **`docs/agents/adrs/0017-semantic-repo-discovery-port.md`** — ADR-0017: port reposeek.ai's NL→repo idea as a conditional Tier 2 technique. Three-test fire-rule (skip only when ALL three fail: no recognized tech, no quoted API, ≤6 words). Tier-gated: Quick skipped unconditionally; Balanced fires for NL-framed only; Deep fires per-subagent in Phase 4 fan-out. Degradation ladder: `gh search repos` → `WebSearch site:github.com` → skip-and-report-the-gap. Extends ADR-0014's markdown-idea-port pattern to a 4th capability.
  - **Why:** without the loop, NL-rich queries silently degrade to keyword noise; without the fire-rule, the loop fails ADR-0010's prune test for keyword-rich queries. The fire-rule is what makes the technique earn its slot.
- **`skills/prior-art-research/references/semantic-repo-discovery.md`** — the 5-step loop (expand / search / skim / rerank / return), the 0-7 rerank rubric weighting description-match over star count, the degradation ladder, the mandatory fire-decision audit-log lines.
  - **Why:** the agent is the semantic engine and `gh search repos` + WebSearch are the corpus — Phase 1 already loads the LLM with feature description, stack, scale, constraints, and priorities, which is stronger query context than any hosted service gets cold.
- **`skills/prior-art-research/references/source-tiers.md`** Tier 2 — pointer to the new technique doc.
  - **Why:** Tier 2 lookups now have one canonical loop to follow instead of ad-hoc keyword-search-shaped queries.
- **`tests/dogfood/20-semantic-repo-discovery/`** — 4 calibration scenarios (20a NL-rich fires, 20b keyword-rich skips, 20c gh-unavailable WebSearch fallback, 20d both-unavailable report-the-gap) + README.
  - **Why:** the fire-rule's three-test threshold is calibrated theoretically until it runs against labelled cases. The 20b SKIP case is load-bearing — without it the loop is always-on and fails the prune test.
- **`skills/parallel-dev/SKILL.md`** Phase 3 — pre-dispatch goal-clarity gate. Two yes/no checks the dispatcher must answer with a concrete name (not a yes/no): (1) is success unambiguous — what's the deliverable's exact file path or return field; (2) is verification one-turn resolvable — what's the single inspection step. `NEEDS_CONTEXT` returns are now framed as a missed gate, not a subagent failure.
  - **Why:** vague subagent specs previously surfaced as `NEEDS_CONTEXT` returns in Phase 5 — after dispatch had already burned tokens. Catching them in Phase 3 is cheaper and converts the gate from cosmetic self-evaluation to a mechanical name-the-deliverable check.
- **`skills/setup-habeebs-skill/SKILL.md`** Phases 2–4 — three "When the default isn't right" trade-off notes, placed inside the user-visible blockquote before the "Press Enter" prompt: Linear/Jira beats GitHub when the backlog spans multiple repos; local markdown beats both when solo or pre-product; mapping a conflicting label vocab beats fighting it; type the existing ADR-directory path because a second canon is harder to retire than to never create.
  - **Why:** the previous prompts presented a default and asked for accept, but never surfaced the *trade-off that drives a non-default choice* — so a user who pressed Enter took the default without seeing the cases where it's wrong.

### Changed

- **`skills/prior-art-research/SKILL.md`** Phase 4 Tier 2 bullet — conditionally invokes the new semantic-repo-discovery loop on Balanced/Deep tiers when the fire-rule trips; Quick skips it unconditionally.
  - **Why:** the loop only earns its slot under the fire-rule; the SKILL.md wiring is what makes Tier 2 actually use the new technique.
- **`skills/prior-art-research/SKILL.md`** Phase 1 — replaced the "frame asks as gap-filling, not cold interrogation" priming + first-person `"I see ... Two open questions:"` example + "before search burns budget" tail + the "(Echo for confirmation; will weight Phase 4 queries.)" parenthetical with: *"Ask questions plainly. Do not preface them with explanations of why you're asking, why there are this many, or what you already know. State the questions and stop."*
  - **Why:** the prior priming taught the LLM to editorialize about its own questions before asking them — producing output like *"Two questions before I move to Phase 2 — both genuinely ambiguous, not ceremony."* The editorial preamble was a Phase 1 anti-pattern, not a polish layer.
- **`skills/systematic-debugging/SKILL.md`** — hypothesis-statement template changed from first-person `"I believe the failure is caused by X."` to declarative `"Hypothesis: the failure is caused by X."`.
  - **Why:** the first-person framing modelled the same editorial pattern Phase 1 had — defending the statement before stating it. Declarative form ties the statement to its falsifiable probe instead of to the agent's confidence.
- **27 skill / doc / command files** stripped of third-party attribution — Origins sections, "Inspired by" lines, "Source:" headers, "Ported from" credits, author/repo URLs, person-name references all removed from user-facing skill content. Concept names retained (deep modules, 13 factors, deletion test, HITL/AFK, vocabulary). Touched skills: `agent-factors-check`, `deep-modules`, `security-audit`, `devex-review`, `write-plan`, `parallel-dev`, `systematic-debugging`, `using-worktrees`, `vertical-slice`, `setup-habeebs-skill`, `release`, `decision-record`, `prior-art-research`, `using-habeebs-skill`, plus `README.md`, `AGENTS.md`, `CLAUDE.md`, `commands/factor-check.md`, `commands/deepen.md`, `docs/BUILD-PLAN.md`. ADRs, CHANGELOG, specs, plans, postmortems, and dogfood fixtures left intact as historical record.
  - **Why:** the user-facing prose surface should describe the methodology, not litigate its provenance. Attribution belongs in commit history and ADRs (where it's audit-grade and dated), not at the top of every SKILL.md (where it implies the methodology is a derivative work rather than a thing in its own right).
- **`docs/agents/adrs/README.md`** — index row 27 added for ADR-0017.
  - **Why:** the ADR index is the discovery surface for prior-art-research's Tier 0 internal-precedent lookup.

### Notes

- **No frontmatter or handoff-contract change.** The new semantic-repo-discovery loop is purely additive within Phase 4 Tier 2; existing `/research` invocations on keyword-rich queries are unaffected. The pre-dispatch gate in `parallel-dev` is additive Phase 3 discipline, not a return-contract change. No skills were renamed, removed, or had their description budgets exceeded.
- **PR #19 (SYSTEM_CONTEXT.md refresh) and PR #20 (parallel-dev + setup-habeebs-skill principle bake) both landed on main during the v1.15.0 → v1.16.0 window and are included in this release.**
- **Fire-rule calibration is theoretical until the dogfood scenarios run against labelled cases.** ADR-0017 records the threshold as accepted-with-revisit-trigger; two false-fire postmortems would trigger threshold tuning.

## [1.15.0] — 2026-05-19

Chain-wide depth tiers. `prior-art-research` had a binary Quick/Deep *mode* that governed only its own research depth — the rest of the chain applied uniform spec / grill / ADR / plan ceremony regardless of how much the feature warranted. v1.15.0 generalizes that binary into a graded, chain-wide **tier** (Quick / Balanced / Deep), decided once by `prior-art-research` Phase 3 and inherited by every downstream skill via a `Tier:` artifact-header field. ADR-0016 records the decision; it extends ADR-0013's adaptive-gate reasoning from one phase to the whole chain. Two invariants are load-bearing: the tier scales *effort*, never *decision quality* (a real open question always reaches `socratic-grill`; a one-way-door decision always gets an ADR — even under a `--quick` override), and tier-related user-facing output stays task-focused (no token/cost/time rationale).

### Added

- **`docs/agents/adrs/0016-chain-wide-depth-tier.md`** — the decision: the chain runs at a tier, carried in artifact headers (not runtime state, not the HANDOFF string). Extends ADR-0013.
  - **Why:** the binary mode was research-only; trivial features still paid full downstream ceremony. A graded chain-wide scale lets simple work reach a plan fast while ambitious work keeps the full treatment.
- **`docs/agents/references/tier-scale.md`** — canonical tier table, the three-signal auto-detect rule (residual ambiguity + sub-problem count + constraint complexity), and the two invariants. All six chain skills link here per ADR-0009.
  - **Why:** single source of truth — skills reference the scale instead of each restating it and drifting.
- **`tests/dogfood/20-depth-tier/`** — tier-detection eval: a labelled calibration set of borderline task prompts, scored on whether Phase 3 auto-routes the expected tier, plus the invariant checks. Methodology follows Anthropic's skill-creator eval guidance (baseline-style, grade the outcome not the path).
  - **Why:** the feature's core risk is mis-tiering; an eval over borderline cases is the primary regression signal.

### Changed

- **`prior-art-research/SKILL.md`** — Phase 3 "Choose mode" rewritten to "Choose tier": three tiers, the scored auto-detect rule with an ambiguity floor (a high-ambiguity task never auto-routes to Quick), and `--quick`/`--balanced`/`--deep` overrides. Phase 1 / Phase 2.5 / examples updated from "mode" to "tier".
  - **Why:** Phase 3 is the single point where the chain-wide tier is decided.
- **Output / artifact templates** — `prior-art-research` output-template `Mode: Quick | Deep` → `Tier: Quick | Balanced | Deep`; spec, grill-record, ADR, and plan templates gain an inherited `Tier:` header field.
  - **Why:** the tier propagates through the headers downstream skills already read in full — the same mechanism as `Slug`/`Status`. This is an additive output-template change; all consumers are updated in the same release.
- **`draft-spec`, `socratic-grill`, `decision-record`, `write-plan`, `tdd-loop`** — each reads the inherited `Tier:`, echoes it into its own header, and scales its work to the tier. `socratic-grill` always runs on a non-empty open-questions inventory regardless of tier; `decision-record` always records a one-way-door decision; `tdd-loop` always runs in full and now treats a missing plan as the expected Quick state.
  - **Why:** the tier is only useful if the whole chain honors it — and only safe if the quality gates hold at every tier (invariant 1).
- **Vocabulary swap** — "Quick/Deep **mode**" → "Quick/Balanced/Deep **tier**" across `parallel-dev`, `using-habeebs-skill`, `source-fetcher`, `pattern-extractor`, `CLAUDE.md`, and `GLOSSARY.md` (new "Tier" core concept; "mode" retired). Behavior of the Deep tier is unchanged — only the word.
  - **Why:** "mode" was a research-only binary; "tier" is chain-wide and graded. One consistent word prevents confused agents (GLOSSARY discipline).

### Notes

- **No frontmatter or handoff-contract change.** Quick and Deep keep their existing meaning, so no existing `/research` invocation breaks; Balanced is purely additive. The only format change is the `Mode:`→`Tier:` template-header rename, applied in lockstep across all chain templates and their consuming skills in this release.
- **The v1.11.0 trigger-precision corpus-growth item is not in this release.** That remains open; v1.15.0's new corpus is the tier-detection calibration set, a separate eval surface.

## [1.14.0] — 2026-05-18

gstack capability adoption. A `prior-art-research` run evaluated [garrytan/gstack](https://github.com/garrytan/gstack) — a 31-skill Claude Code "software factory" — and selectively adopted three substrate-free capabilities, re-implemented as pure-markdown skills (Pattern A: idea-port, not skill-port). gstack's runtime-coupled half (browser engine, GBrain memory, `/qa`, `/canary`, `/codex`) was rejected; ADR-0002 stands unamended, recorded as an explicit finding. The spec's D6 decision staggered this into a v1.13.0 + v1.14.0 plan; implementation ran all three slices together, so the bundle ships once as v1.14.0 — **v1.13.0 is intentionally skipped.**

### Added

- **`skills/security-audit/`** — a standalone `/security-audit` skill: static OWASP Top 10 + STRIDE-per-component audit, secrets archaeology over git history, confidence-gated findings, markdown report. Idea-ported from gstack `/cso`.
  - **Why:** habeebs-skill had no security review — `verify-output` explicitly disclaims it. This closes the single clearest capability gap the gstack evaluation surfaced.
- **`skills/release/`** — a terminal chain link after `tdd-loop`: version bump, CHANGELOG entry, clean-history review, PR body, doc-sync coverage audit, tag-push. Idea-ported from gstack `/ship` + `/document-release`. No deploy/canary/benchmark.
  - **Why:** the chain ended at `tdd-loop`; release was fully manual. This closes the chain at the shipping end.
- **`skills/devex-review/`** — a conditional `socratic-grill` extension for developer-facing specs (CLI/SDK/library/plugin/framework): surfaces 6 developer-experience gap dimensions as Socratic questions. Idea-ported from gstack `/plan-devex-review`; mirrors `agent-factors-check`.
  - **Why:** habeebs-skill is itself a developer-facing product but had no DX review lens.
- **`docs/agents/adrs/0014-adopt-gstack-capabilities-markdown-idea-port.md`** — ADR-0014: adopt the three capabilities; reject the runtime-coupled half; ADR-0002 stands as an explicit finding.
- **`docs/agents/adrs/0015-hook-allow-tag-pushes-on-default.md`** — ADR-0015: amend the commit-block hook to allow tag-only pushes on the default branch.
  - **Why:** the hook blocked release tag-pushes on `main` — a documented recurring pain. The carve-out resolves it permanently.

### Changed

- **`hooks/preventing-commits-to-default.sh`** — the PreToolUse block predicate is narrowed: unambiguous tag-only pushes (`git push origin refs/tags/<tag>`, `git push --tags`, `git push <remote> tag <name>`) are now allowed on the default branch; bare branch pushes and `git commit` stay blocked, with a guard arm that declines the carve-out for any command also containing `git commit`.
  - **Why:** a release tag-push is an append-only pointer, not a branch commit; blocking it was an over-broad matcher. See ADR-0015.
- **`docs/agents/adrs/0003-hooks-scope.md`** — amended in place to document the tag-push carve-out.
  - **Why:** ADR-0003 is the canonical hook-scope record; the narrowed block predicate must be traceable from it.

## [1.12.0] — 2026-05-17

Context-gate adaptivity release. A review of the `/research` command surfaced a contradiction between `commands/research.md` (hard-blocked on 5 context questions — "Do not proceed without them") and `prior-art-research/SKILL.md` Phase 1 (accepts partial answers, proceeds with unknowns flagged). v1.12.0 resolves it in favor of the skill: the Phase 1 gate stays questions-first but scales the asking to the anticipated mode and never hard-blocks. The decision is recorded as ADR-0013.

### Changed

- **`skills/prior-art-research/SKILL.md`** — Phase 1 gains a "Scale the asking to the anticipated mode" paragraph: an obviously-Quick scope collapses to the 2 foundational questions (or a single confirmation line when Phase 0 + the prompt already cover them); the full staged 2-then-3 is reserved for Deep-mode scopes.
  - **Why:** the gate was binary — full 5 questions regardless of scope. For an obviously-Quick run the two question round-trips can cost more than the research itself. Adaptive asking removes that fixed tax while keeping questions-first as the canonical gate.

- **`commands/research.md`** — the Phase 1 instruction is rewritten from "Ask the user the 5 context questions. Wait for answers. Do not proceed without them." to match SKILL.md Phase 1: staged questions, skip anything Phase 0 or the prompt already answered, accept partial / "I don't know" answers (flagged `[assumed]`/`[unknown]`), and block only the Phase 4 search — not the whole run — until context is captured or explicitly waived.
  - **Why:** the command is read after the skill, so its absolute hard block silently overrode the skill's accept-partial rule. The skill is the single source of truth for gate behavior; the command must not contradict it.

### Added

- **`docs/agents/adrs/0013-research-context-gate.md`** — ADR-0013: the `prior-art-research` Phase 1 context gate is adaptive, not a hard block. Records why questions-first is kept (research is convergent and expensive; context weights Phase 4 source tiering and is the only thing preventing the skill's own "FAANG-scale solutions for non-FAANG-scale problems" anti-pattern).
  - **Why:** the review was a question about whether the *existing* gate is shaped right, not a proposal to add one — capturing the answer as Tier-0 prior art stops the same review recurring.

## [1.11.0] — 2026-05-14

Trigger-precision tuning release. The v1.10.0 audit ([`audit-report-2026-05-13.md`](tests/dogfood/13-trigger-precision/audit-report-2026-05-13.md)) flagged 4 skills with precision or recall below the 0.80 threshold across a 30-prompt corpus. v1.11.0 applies the audit's suggested tunings (4 surgical edits to SKILL.md `description:` fields, ≤100 chars each), expands the corpus by 4 Cat-3 adversarial prompts per the audit's recommendation #3, and re-runs the audit. New audit ([`audit-report-2026-05-14.md`](tests/dogfood/13-trigger-precision/audit-report-2026-05-14.md)) reports 34/34 (100%) with 0 skills flagged.

### Changed (description tunings)

- **`prior-art-research/SKILL.md`** — added anti-trigger: `Do NOT use when the user's intent is too vague to commit to a feature — ask a clarifying question instead.`
  - **Why:** v1.10.0 P16 false positive on "I want to add something useful to this codebase." The existing "trivial CRUD" anti-trigger didn't disqualify content-free intent; "add" + "vague idea" trigger language combined to over-trigger. Precision 0.80 → 1.00.

- **`socratic-grill/SKILL.md`** — added positive triggers: `"verify this design"` and `"pressure-test this approach" before implementation`.
  - **Why:** v1.10.0 P22 false negative — the auditor expected socratic-grill to fire on "I need to verify this design before we commit to it" but no description language matched. Recall 0.50 → 1.00.

- **`parallel-dev/SKILL.md`** — added anti-trigger: `Do NOT use for debugging existing parallel dispatches — that's systematic-debugging.`
  - **Why:** v1.10.0 P27 false positive on "Debug why my parallel subagents are returning conflicting results." The "parallel subagents" keyword pulled parallel-dev's trigger above systematic-debugging's "Debug" / "behavior is unexpected" trigger. Precision 0.50 → 1.00.

- **`verify-output/SKILL.md`** — sharpened positive triggers from "verify this" / "check this for slop" to "verify this **code**" / "check this **diff** for slop"; hoisted anti-trigger `Do NOT use for pre-implementation review of designs, plans, or specs (that's socratic-grill)` to first position; added explicit scope clause "Post-generation anti-slop pass on a staged code diff (post-implementation, pre-commit)".
  - **Why:** v1.10.0 P22 false positive (coupled with the socratic-grill miss above) on "I need to verify this design before we commit to it." The word "verify" + "before commit" matched verify-output verbatim; the existing "Pre-implementation review" anti-trigger was buried at line 4 of 4. The pair fix was treated as one tuning per the v1.10.0 audit's coupled-fault note. Precision 0.50 → 1.00.

### Added (corpus expansion)

- **`tests/dogfood/13-trigger-precision/corpus.md`** — 4 new Cat-3 (multi-skill-applicable) prompts. P31 + P32 specifically probe the v1.11.0 tunings; P33 + P34 probe Cat-3 boundaries not exercised by v1.10.0 (write-plan vs explicit user opt-out; prior-art-research vs vertical-slice when PRD exists but no ADR).
  - **Why:** v1.10.0 audit recommendation #3 — "Add 3-5 new adversarial prompts to the corpus before re-running, biased toward category 3 (multi-skill) since that's where this audit was weakest (3/4 = 75%)." 4 chosen as the mid-point of the recommended range.

- **`tests/dogfood/13-trigger-precision/audit-report-2026-05-14.md`** — v1.11.0 re-audit report. Cross-references the v1.10.0 baseline; documents per-prompt resolution for P16, P22, P27; notes Hamel's "100% red flag" caveat applies because the curated re-audit corpus is verification, not discovery.

### Notes

- **No skill behavior change beyond trigger surfaces.** No new skills, no new phases, no contract changes. Net description-size delta is *negative* — the 4 trigger/anti-trigger additions are paired with filler trims in the same 4 descriptions, so the avg-chars-per-description metric drops from 626 (post-additions, pre-trim) to 594 (post-trim), comfortably under the [ADR-0007](docs/agents/adrs/0007-description-budget-policy.md) target of 600. Items trimmed: prior-art-research dropped the redundant "Convergent research, not divergent brainstorming" tagline + the "vague idea" trigger now superseded by the new anti-trigger; socratic-grill dropped the long "until each decision exits..." clause; verify-output dropped the redundant parentheticals "(post-implementation, pre-commit)", "(all tests passing)", and the inline status-name enumeration (the ADR reference still names them); parallel-dev dropped the "used internally by..." context-line (belongs in body, not description).
- **Hamel's "100% pass rate is a red flag" caveat acknowledged.** The 100% rate reflects that the new corpus prompts were curated *after* the v1.10.0 failure modes were already known. v1.12.0 must grow the corpus toward genuinely-unknown failure modes (target: 5–8 new prompts from real transcripts) for the audit to retain diagnostic value.

## [1.10.0] — 2026-05-13

Context-engineering alignment release. The 2026-05-13 audit (second-pass, broader than the morning v1.9.0 audit) pulled Anthropic Skills 2.0 + Claude Code best-practices + Effective harnesses for long-running agents, Hamel Husain + Shreya Shankar evals FAQ, Cognition AI "Don't Build Multi-Agents", OpenAI Agents SDK, Google ADK Workflow Agents, and LangChain Context Engineering for Agents (8 case studies total). Three new ADRs (0010 / 0011 / 0012) plus an in-place amendment to ADR-0004. Five recommendations (R1–R5) shipped as 6 vertical slices. Headline outcomes: SYSTEM_CONTEXT.md narrows to non-re-derivable cross-session state (~40% size reduction); HANDOFF semantics formalized as navigation pointers with full-doc-read contract; chain-postmortem cadence introduced as section in `using-habeebs-skill` with `verify-output` and postmortems classified as complementary (static-pre-commit vs. dynamic-post-incident); description trigger precision measured at 90% across 30-prompt corpus (4 skills flagged for v1.11.0 tuning); Compress-at-overflow protocol added with 7-section session-summary template — fills LangChain's missing 4th context-engineering move (Write/Select/Compress/Isolate).

### Added (Slice #3 — error-analysis cadence)

- **`docs/agents/postmortems/`** — new directory with `README.md` template documenting the 8-section transition-failure-matrix structure (Hamel + Shreya). One retrospective entry committed for the 2026-05-12 missed-architectural-categories incident that drove Phase 2.5 critic adoption in v1.6.0.
  - **Why:** Per [ADR-0011](docs/agents/adrs/0011-error-analysis-cadence.md), error-analysis-before-infrastructure is the load-bearing principle from Hamel's evals FAQ. The chain had a static evaluator (`verify-output`) but no dynamic feedback loop on real chain runs. Synthetic dogfood approaches 100% pass rate by construction (Hamel's red flag). Postmortems generate the rules that `verify-output` enforces; postmortems find the rules `verify-output` missed.

- **`tests/dogfood/15-postmortem-structure/`** — dogfood assertion that every postmortem file contains the 8 required sections + the README template documents them.

### Added (Slice #4 — trigger-precision audit)

- **`tests/dogfood/13-trigger-precision/`** — one-time R4 audit. 30-prompt corpus (15 happy-path + 15 adversarial across 4 categories: vague / wrong-skill-bait / multi-skill-applicable / edge cases). Manual reading exercise; audit report `audit-report-2026-05-13.md` records 27/30 correct (90% — below Hamel's 100% red-flag threshold by design). Four skills flagged for v1.11.0 description tuning: `prior-art-research` (precision 0.80 on vague-intent FP), `socratic-grill` (recall 0.50 on "verify this design" FN), `parallel-dev` (precision 0.50 on debug-of-subagents FP), `verify-output` (precision 0.50 on "verify this design" FP — coupled with the socratic-grill miss).
  - **Why:** Per Anthropic's Claude Code best-practices, description quality is **the** correctness axis for skills. v1.9.0 trimmed all 14 descriptions for budget compliance ([ADR-0007](docs/agents/adrs/0007-description-budget-policy.md)) but did not measure whether the trimmed descriptions still trigger correctly. This audit fills that gap.

### Added (Slice #5 — Compress-at-overflow)

- **`docs/agents/templates/session-summary-template.md`** — 7-section summary template per [ADR-0012](docs/agents/adrs/0012-compress-at-overflow-protocol.md): Active artifacts / Current slice / Last successful action / What's blocking / Open grill Qs / Recent test state / Branch / worktree pointer. New section in `using-habeebs-skill/SKILL.md` documents the summary-and-flush protocol for sessions approaching context-window pressure. `tdd-loop/SKILL.md` gains a cross-reference (most likely overflow site).
  - **Why:** Per [LangChain's "Context Engineering for Agents"](https://blog.langchain.com/context-engineering-for-agents/) framework, agents have 4 context-engineering moves: Write / Select / Compress / Isolate. habeebs-skill covered Write (SYSTEM_CONTEXT, ADRs), Select (prior-art-research fetches), Isolate (parallel-dev dispatch), and Compress-at-ingest (extraction-checklist ≤15-word quote rule) — but had no Compress-at-overflow move for long sessions. ADR-0012 closes the gap with a markdown-only passive-doc protocol (ADR-0002 preserved).

- **`tests/dogfood/16-session-summary-template/`** — dogfood assertion that the template has the 7 required sections and the `using-habeebs-skill` section references ADR-0012 + template path + v1.11.0 promotion criterion.

### Added (Slice #1 — SYSTEM_CONTEXT contents prune)

- **`tests/dogfood/14-system-context-schema/`** — dogfood assertion that `docs/agents/SYSTEM_CONTEXT.md` matches the new ADR-0010 schema (retained sections present, dropped sections absent) and the template documents the new schema with a "DO NOT persist" guidance block.

### Changed (Slice #1 — SYSTEM_CONTEXT contents prune)

- **`skills/prior-art-research/references/system-context-template.md`** rewritten with new schema. Retained sections: Scale envelope, Methodology / agent setup, Notable absences, Project mode, Active steering, Last reconciliation outcome. Dropped sections: Stack, Persistence, Deployment shape, External services, Recent hot files, Open / unknown, Tracked manifests — all re-derivable by Claude from `package.json` + `git log` + imports on fresh invocation (per Anthropic's [Claude Code best-practices](https://code.claude.com/docs/en/best-practices) ❌ Exclude rule: *"Anything Claude can figure out by reading code"*).
- **`docs/agents/SYSTEM_CONTEXT.md`** migrated to the new schema (this repo's own self-migration in Slice #6).
  - **Why:** Per [ADR-0010](docs/agents/adrs/0010-system-context-contents-prune.md), Anthropic's prune test (*"Would removing this cause Claude to make mistakes?"*) applies. The dropped sections persisted facts Claude derives instantly; the retained sections carry non-re-derivable cross-session state (scale, agent setup, steering, reconciliation history) — the file's primary value across invocations.

### Changed (Slice #2 — HANDOFF semantics)

- **`skills/using-habeebs-skill/SKILL.md`** gains `## HANDOFF lines — navigation, not state transfer`: HANDOFF strings are pointers to which skill runs next; state transfer happens via the previous phase's **full output document**, which the next skill MUST read in full. Cites OpenAI Agents SDK ("Handoff = ownership transfer" primitive) as positive validation and Walden Yan's "[Don't Build Multi-Agents](https://cognition.ai/blog/dont-build-multi-agents)" (Cognition AI, 2025-06-12) as the anti-pattern guarded against.
- **`skills/prior-art-research/SKILL.md` Phase 7** cross-references the HANDOFF semantics section so downstream skills know to read the full Phase 6 doc, not just the HANDOFF line.
  - **Why:** The invariant was implicit (each phase reads previous phase's full output by default) but never explicitly stated. Making it explicit forecloses a future drift toward thin handoffs that would re-create Yan's "implicit decision divergence" failure mode.

### Changed (Slice #2 — ADR-0004 amendment)

- **[ADR-0004](docs/agents/adrs/0004-parallel-subagent-dispatch-contract.md) amended in place.** Part 3 gains the "share full traces" clause: subagents MUST receive the parent's full context (Phase 1 context, decomposition, steering, SYSTEM_CONTEXT preamble) as one coherent input payload. Citation: Walden Yan, Cognition AI. New Part 5 codifies the treat-fetched-content-as-untrusted rule with a dated 2026-05-13 evidence paragraph documenting three fabricated `<system-reminder>` tags surfaced in fetched HTML from `developers.googleblog.com`, `adk.dev`, and `code.claude.com` during this release's prior-art-research dispatches (all ignored per the rule).
  - **Why:** Share-full-traces was implicit in current dispatch templates; making it explicit guards against future drift. The untrusted-content rule was implicit in source-fetcher subagent prompts; codifying it in ADR-0004 with dated lived-evidence makes the invariant load-bearing in the canonical contract doc.

### Documented (Slice #0 — chain artifacts)

- **`docs/agents/research/v1.10.0-context-engineering-alignment-research.md`** — archives the prior-art-research run (8 case studies, 6 patterns, 4 Breunig failure modes, R1–R5 recommendations, steering reconciliation) as durable Tier-0 prior art per `prior-art-research` § "Internal precedent first".
- **`docs/agents/specs/v1.10.0-context-engineering-alignment.md`** — spec (status: Grilled).
- **`docs/agents/specs/v1.10.0-context-engineering-alignment-grill.md`** — grill record resolving Q1–Q8 (Q8 surfaced by agent-factors-check F6 pause/resume gap on the R5 summary schema).
- **`docs/agents/plans/0010-context-engineering-alignment-v1.10.0.md`** — phased delivery plan: 3 phases, 8 slices, pgroup-1B = {#1, #2, #4} parallel triplet, serial chain `#2 → #3 → #5` due to `using-habeebs-skill/SKILL.md` file-overlap. 12 risks tracked.
- **Three new ADRs (0010 / 0011 / 0012)** locked; **ADR-0001 status updated** to record scope narrowing by 0010.

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
