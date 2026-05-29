# ADR-0020: Adopt late-binding ADR IDs and Changesets-shape version bumps with the release skill as single coordinator

**Status:** Superseded by the [decouple-decision-identity-from-releases decision](./2026-05-28-decouple-decision-identity-from-releases.md) (ADR-ID half only)
**Date:** 2026-05-25
**Deciders:** Modie (Habeeb)
**Tier:** Balanced

> **Superseded (partial) 2026-05-28.** The **late-binding ADR-integer-ID half** of this ADR is superseded by the [dated-artifact-naming decision](./2026-05-28-decouple-decision-identity-from-releases.md): ADRs are now named `YYYY-MM-DD-<slug>.md` at creation, and the release-time rename machinery (Phase 3.5 + `assign-adr-ids.sh`) is removed. **The Changesets-shape version-bump half of this ADR (append-only `.changeset/*.md` intent files aggregated by the release skill) is NOT superseded — it continues unchanged and remains in force under the new ADR.**
>
> Historical note: this ADR was itself filed as `adr-late-binding-and-changesets.md` and renamed to `0020-` at v1.20.0 release time, dogfooding the (now-superseded) late-binding scheme.

## Context

habeebs-skill is a Claude Code plugin shipped as markdown + JSON with no runtime substrate (ADR-0002, narrowed by ADR-0019). Two file classes have been generating real merge conflicts under the user's working pattern of running multiple parallel Claude Code sessions:

1. **ADR identifier collisions.** ADRs use sequential 4-digit integer prefixes (`0001-` through `0019-`). When two parallel sessions each `decision-record` a new ADR, both attempt `0020-<slug>.md`. The current Phase 0 peer-scan mechanism (v1.18.0) predicts the collision but does not eliminate it — the user still has to manually rename one ADR after the second session lands.

2. **Version-file bump collisions.** Every PR currently edits `plugin.json`, `.claude-plugin/marketplace.json`, and `CHANGELOG.md` for its release. Two parallel branches each bumping `version: "1.19.0" → "1.20.0"` produces a guaranteed merge conflict in three files plus a CHANGELOG entry whose ordering depends on merge order.

The v1.19.0 workflow audit memo (`docs/agents/research/v1.19.0-workflow-audit-research.md`, Deep tier, 6 source-fetchers across 30 distinct upstream sources) found one universally-convergent pattern for parallel-write safety: **append-only intent files + release-time aggregation by a single coordinator** (Pattern A). Evidence: Changesets, release-please, Vercel Academy, and Backstage all solve this the same way, across different tiers and vendors. Backstage additionally provides the canonical-tier answer for ADR-specific parallel-writer collisions via **late-binding** — the integer is assigned at merge time, not at file creation. ~17% of canonical ADR sources (1 of 6 surveyed) address the parallel-writer problem at all; Backstage is that source.

habeebs-skill's existing `release` skill (v1.19.0) already runs as a single human-invoked coordinator at release time — it bumps versions, runs the description-policy audit (ADR-0007 § A-F), drafts the PR body, and pushes the release tag. It is the natural locus for the new aggregation step; we extend it rather than build new infrastructure.

The decision is needed NOW because the v1.20.0 release line is the natural cutover point: ship the new mechanism in v1.20.0, self-dogfood it during this very release, and eliminate both collision classes for v1.21.0+. Deferring would mean every subsequent ADR continues to require manual renumbering and every release continues to require version-file conflict resolution.

## Decision

We will adopt **append-only intent files** for version bumps and **late-binding** for ADR identifiers, with the existing `release` skill as the single coordinator that consumes both at release time.

Specifically:

- **Changesets-shape `.changeset/<slug>.md` intent files** carry minimal YAML frontmatter — `bump: patch|minor|major` + `why: <single line>`. Feature branches NEVER edit `plugin.json`, `.claude-plugin/marketplace.json`, or `CHANGELOG.md`. The release skill aggregates pending changesets, computes the highest bump, writes the single bump + CHANGELOG entry, and deletes consumed changesets in one atomic commit.
- **Late-binding ADR identifiers.** `decision-record` writes new ADRs as `docs/agents/adrs/adr-<slug>.md` (no integer). The `release` skill scans for `adr-*.md` files at release time, assigns the next sequential int from `adrs/README.md`, renames each file in alphabetic slug order, and regenerates the README index.
- **Separation-of-writers.** `decision-record` is the ONLY writer of `adr-*.md`; `release` is the ONLY writer of `NNNN-*.md`. Enforced by dogfood scenario 21 (`tests/dogfood/21-late-binding-adr/check-late-binding.sh`).
- **In-PR aggregation, FIRST step of release PR creation.** Sequence: read `.changeset/*.md` → compute version → write `plugin.json` + `marketplace.json` + `CHANGELOG.md` → delete consumed changesets → commit atomic → assign ADR ints → push branch → open PR. Tag-push (post-merge `git push origin refs/tags/<version>`) remains unchanged from v1.19.0.
- **Atomicity guarantee.** Aggregation script (`skills/release/scripts/aggregate-changesets.sh`) stages all mutations in a temp directory, then moves atomically. Exit codes: 0 success + commit ready, 1 aborted clean (no state change), 2 aborted dirty (manual intervention; should never happen given temp-dir approach but documented for safety). Rollback path: `git checkout -- .changeset/ plugin.json marketplace.json CHANGELOG.md`.
- **Two-PR race acceptance.** Two simultaneous release PRs targeting the same version slot are not pre-empted by a CI lock. The second merge fails loudly on `CHANGELOG.md` + `plugin.json` conflict; the operator closes the second PR, re-runs aggregation against post-first-merge state, and the changesets that targeted vN.M.0 in the second PR now correctly target vN.(M+1).0. Per the audit's Pattern D (conflicts pushed to merge-time, handed to human) — substrate-free design accepts merge-time conflict resolution over coordinator infrastructure.
- **ADR slug-collision halt-loud.** If two `adr-<identical-slug>.md` files exist at release time, the rename script halts with exit 2 and an operator-facing message: "Two ADRs with identical slug `<slug>` cannot be assigned distinct IDs. Rename one before retrying." Alphabetic slug order is the deterministic tiebreak for distinct-slug ordering only — identical slugs never silently merge or overwrite.
- **Path-audit matrix at PR-creation time.** The release skill reads `git diff --name-only main...HEAD` and applies:
  - **Changeset REQUIRED if PR modifies any of:** `skills/`, `hooks/`, `.claude-plugin/`, `plugin.json`, `marketplace.json`
  - **Changeset OPTIONAL (emits INFO note, does not block):** `docs/`, `CLAUDE.md`, `AGENTS.md`, `README.md`, `CHANGELOG.md`
  - **Changeset NEVER required:** `tests/`, `.gitignore`, `.github/`, `.gitattributes`

  Required-path-without-changeset halts the audit with a clear error.

- **Changeset naming: slug-based.** Filename is `<branch-slug>.md` (e.g., `v1.20.0-methodology-overhaul.md`). Slug-based wins over random-id (the upstream Changesets default) because habeebs-skill is single-author: branch-slug is already unique per branch, and human-readable filenames beat random word-pairs when reviewing changesets in a PR. Random-id remains the fallback if a second author joins and collisions emerge (see Revisit triggers).
- **Changeset schema: minimal.** `bump` + `why` only. Richer fields (`breaking`, `migration`, `affects-skills`) deferred to v1.21.0+ if usage reveals need. YAGNI — two fields are the entire mechanism.
- **Substrate-free contributor affordance.** No CLI scaffolder (would violate ADR-0002 by introducing a Node dependency). `.changeset/EXAMPLE.md` (uppercase to avoid mistake-as-real-changeset) ships a fully-populated minimal example. Contributors run `cp .changeset/EXAMPLE.md .changeset/<your-slug>.md` and edit. The release skill audits frontmatter at PR-creation time so malformed changesets fail loud.
- **Helper-script ergonomics.** Both helper scripts (`assign-adr-ids.sh`, `aggregate-changesets.sh`, `check-changeset-required.sh`) support `--dry-run` and `--help`. Scripts are safe to invoke standalone (no global state mutation; everything happens via git commit which is reversible).
- **Five named error messages with exact format** (asserted by dogfood scenario 25):
  - Missing `bump`: "Changeset `.changeset/<file>.md` missing required `bump` frontmatter field. Expected one of: patch, minor, major. See .changeset/EXAMPLE.md."
  - Invalid `bump` value: "Changeset `.changeset/<file>.md` has invalid `bump: <value>`. Must be one of: patch, minor, major."
  - Empty `why`: "Changeset `.changeset/<file>.md` missing `why:` line. Add a one-sentence explanation."
  - Two identical-slug ADRs: "Cannot rename — two ADRs share slug `<slug>`: `<file1>`, `<file2>`. Pick distinct slugs."
  - Required path without changeset: "PR modifies skill files but contains no `.changeset/*.md`. Required path (`<path>`) needs a changeset. See `.changeset/README.md` for instructions."
- **Hard-cutover migration.** Post-v1.20.0, any in-flight branch modifying `skills/`, `hooks/`, or `.claude-plugin/` must add a `.changeset/<slug>.md` before merging. No grace window — single-author scale + manual release process makes the migration one-time and well-bounded. The v1.20.0 CHANGELOG entry carries the migration note.

The decision reuses the existing v1.19.0 `release`-skill infrastructure (description-policy audit step) rather than building parallel machinery. The `release` skill IS the bot-equivalent at release time; this ADR extends its responsibilities to include changeset aggregation + ADR-int assignment as the first phase of release PR creation.

## Consequences

### Positive

- **Eliminates the two largest classes of parallel-session merge conflicts.** ADR integer collisions and version-file collisions both disappear — feature branches never touch the contested files. Single most-leverage change identified by the audit (Pattern A convergence across 5 of 5 reference implementations).
- **Substrate-free.** All mechanisms are markdown + JSON + shell scripts. No daemon, no MCP server, no Node CLI dependency, no IPC. Preserves ADR-0002 + ADR-0019.
- **Self-dogfooding.** This very ADR + the companion `adr-methodology-folder-cuts.md` ship with `adr-<slug>.md` filenames (no integer); the v1.20.0 release run will rename them to integers + update README, demonstrating the mechanism works end-to-end. The v1.20.0 changeset (`.changeset/v1.20.0-methodology-overhaul.md`) self-dogfoods the aggregation step.
- **Backwards-compatible with existing ADRs.** ADRs 0001-0019 are NOT renamed; the asymmetric creation path is invisible at rest because the final file shape (`NNNN-<slug>.md`) is identical. Readers cannot tell which ADRs were born numbered vs. born unnumbered. Pattern B (immutable path) from the audit is preserved for existing files.
- **Loud failures, no silent merges.** Slug collisions halt with exit 2 + specific operator message. Required-path-without-changeset halts the audit with specific path + remediation pointer. Atomicity is enforced at the script level.
- **Tracer-bullet TDD path.** Slice 1 of v1.20.0 proves the late-binding mechanism on the smallest end-to-end surface (rename + README regenerate) before the changeset aggregation lands. Slice 2 + Slice 3 build the changeset side independently in parallel.
- **Becomes Tier 0 prior art.** Future `prior-art-research` runs on adjacent problems (multi-file release coordination, ADR identifier strategies, monorepo version bumps) check this ADR first.

### Negative / Accepted trade-offs

- **Two-phase release workflow shifts contributor discipline.** Every release-worthy PR must include a `.changeset/<slug>.md`. The mitigation is the release-skill path audit at PR-creation time (failing loud, not silently); the cost is a one-line discipline change for the user.
- **Bot-equivalent at merge time is the user.** habeebs-skill has no CI; the "release skill" runs locally when the user invokes it. If the user merges a PR without running release skill afterward, changesets pile up. Accepted because (a) the very next release picks them up, (b) the release skill already runs the dogfood audit step that fails loud if state is wrong, (c) this matches the existing v1.19.0 manual-release pattern.
- **`decision-record` writes lose chronological sortability until rename runs.** During the window between `decision-record` writing `adr-<slug>.md` and `release` renaming to `NNNN-<slug>.md`, ADRs are not sortable by integer. Mitigated by short-lived branches (rename happens at release-PR-creation, typically same day) and by git history providing chronology unambiguously.
- **Asymmetric ADR creation path.** Old ADRs (0001-0019) were born numbered; new ADRs (0020+) are born unnumbered and renamed. The asymmetry is only in the creation path — at rest, all ADRs have identical shape. Mitigated by the separation-of-writers contract (`decision-record` writes one shape, `release` writes the other; never crosses).
- **Two-PR version-slot race accepted.** Two simultaneous release PRs bumping the same version slot collide at git merge time, not before. Single-author scale makes this hypothetical; substrate-free design rejects a CI lock as out-of-bounds per ADR-0002. The failure mode is loud (git merge conflict), not silent (data loss). Per audit Pattern D.
- **Three new helper scripts and two new dogfood scenarios add maintenance surface.** Scripts at `skills/release/scripts/*.sh`; dogfood scenarios at `tests/dogfood/21-late-binding-adr/` (5 fixture cases) and `tests/dogfood/25-changeset-required-check/` (3 path classes + 5 error-message asserts). Accepted because each script + scenario protects a specific load-bearing contract surfaced in the grill (PT-1, OQ-2, OQ-4, OQ-5, DX-4).

### Operational impact

- **Release workflow change.** The `release` skill SKILL.md gains two new phases (Changeset aggregation + Path audit). v1.19.0's `## Description-policy audit (v1.19.0+)` section is EXTENDED, not duplicated — the same audit step now runs three sub-checks (description budget + disabled list + changeset presence).
- **Contributor docs.** `.changeset/README.md` (Slice 2) documents the schema + workflow; `.changeset/EXAMPLE.md` ships the copy-and-edit skeleton.
- **In-flight branch migration is one-time.** The v1.20.0 release carries a CHANGELOG migration note. Any branch in flight when v1.20.0 ships adds a changeset before merging.
- **Cross-session conflict detection (v1.18.0 sidecars + peer-scan + pre-push gate) is unaffected.** Orthogonal mechanism; preserves all v1.18.0 guarantees per ADR-0019. The sidecar's contested-file detection STILL fires for files inside `.changeset/` and `adrs/adr-*.md` (peer sessions writing different changesets / different adr-slugs do not contest the same file by design, so the peer-scan now reports zero contest where v1.18.0 reported "yes contest").
- **No CI dependency added.** All enforcement is local-only via shell scripts + git hooks (existing).
- **5 baseline dogfood tests must continue to pass post-implementation.** description-budget, disabled-list, chain-integrity, no-next-skills, system-context-schema. Slice 7 acceptance criterion enforces this.

## Alternatives considered

### Sequential ADR integers + manual renumbering at merge

Keep the current `decision-record` writing `NNNN-<slug>.md` directly; rely on Phase 0 peer-scan + manual rename to resolve collisions.

**Rejected** because (a) the audit found this pattern unsolved across the entire ADR canonical literature (5 of 6 sources silent on parallel-writer collisions), (b) the user's reported pain is exactly the manual-renumbering tax, (c) Backstage's late-binding is the canonical-tier proven alternative — no need to invent.

### Slug-only ADR filenames (joelparkerhenderson approach)

Drop ADR numbering entirely; use `adr-<slug>.md` permanently with no rename. The most-starred ADR reference repo on GitHub took this path.

**Rejected** because integer prefixes carry chronological sortability that has load-bearing value when reading the ADR index (see "ADR-0001 amended by 0006 + scope-narrowed by 0010" patterns in SYSTEM_CONTEXT.md). Slugs alone lose this. Late-binding preserves the integer benefit while solving the collision problem.

### Date-prefix ADR filenames (`YYYY-MM-DD-<slug>.md`)

Use date prefixes instead of integers; collision becomes mathematically near-impossible.

**Rejected** because date-prefix has **zero canonical endorsement** in the surveyed ADR literature (Nygard, MADR, ThoughtWorks/adr-tools, Backstage, joelparkerhenderson — none recommend it). Adopting it would be inventing a pattern the canonical tier hasn't validated, against the audit's anti-pattern of "FAANG-scale solutions for non-FAANG-scale problems" applied in reverse (novel solutions for solved problems).

### CI-mediated version bumps (release-please bot pattern in full)

Adopt release-please as a GitHub Action that opens a long-lived Release PR and bumps versions automatically based on Conventional Commits.

**Rejected** because (a) habeebs-skill has no CI by design (per the v1.19.0 audit's "no CI/CD — releases are manual" finding, intentional per ADR-0002), (b) release-please requires GitHub Actions runtime which is a substrate dependency, (c) the bot would need write access to plugin.json + marketplace.json which the user prefers to keep human-mediated, (d) the path-audit + aggregation-script approach gives us the same parallel-write safety with zero net new infrastructure.

### Random-id Changesets-style naming (`wise-frogs-jump.md`)

Use the upstream Changesets default — random word-pair filenames per PR. Solves any conceivable filename collision.

**Rejected** for v1.20.0 because habeebs-skill is single-author and branch-slug is already unique per branch. Random-id solves a problem we don't have at current scale. Kept as a revisit trigger (see below) for the multi-author + collision scenario.

## Revisit triggers

This ADR should be reopened if any of:

- **A second author joins the project AND the project sees ≥3 changeset filename collisions in any 90-day window.** Switch the changeset-scaffold step from slug-based to random-id naming (Changesets-original default).
- **Changeset count per release grows past ~10.** Aggregation-output CHANGELOG entries become noisy bullet lists; revisit grouping mechanism (Changesets-original has changeset categories for this).
- **Anthropic ships a first-party ADR convention for Claude Code.** Currently no published guidance (anthropics/claude-code issue #13853 confirms). If Anthropic publishes, audit against our late-binding choice and migrate if needed.
- **The release skill grows past ~3 distinct audit phases** (currently: description-policy + changeset-presence + path-audit). Consider splitting into a dedicated `release-audit` skill at that point.
- **`extensions.worktreeConfig` becomes git default OR a successor pattern emerges.** The aggregation script's git-config invariants would need re-evaluation. Cross-link to ADR-0019's substrate carve-out for the broader cross-worktree state-hygiene concern.
- **Empirical evidence shows the asymmetric ADR creation path confuses readers.** If new contributors regularly mistake `adr-<slug>.md` files for "abandoned drafts," reconsider — but the mitigation is documentation (`adrs/README.md` explains the convention), not a rewrite.
- **A second writer accidentally writes `NNNN-<slug>.md` directly** (bypassing the late-binding workflow). Dogfood scenario 21 catches this in CI-equivalent checks; if it slips through, revisit the separation-of-writers contract.

## References

- Research: [`docs/agents/research/v1.19.0-workflow-audit-research.md`](../research/v1.19.0-workflow-audit-research.md) — Deep-tier audit, 6 source-fetchers across 30 distinct upstream sources
- Spec: [`docs/agents/specs/v1.20.0-methodology-overhaul.md`](../specs/v1.20.0-methodology-overhaul.md)
- Grill: [`docs/agents/specs/v1.20.0-methodology-overhaul-grill.md`](../specs/v1.20.0-methodology-overhaul-grill.md) — 14 items resolved (13 decided, 1 deferred); devex-review fired
- External sources:
  - [Changesets common-questions](https://github.com/changesets/changesets/blob/main/docs/common-questions.md) — append-only intent files for version bumps; Pattern A canonical example
  - [release-please (googleapis)](https://github.com/googleapis/release-please) — release-PR-bot pattern; alternative aggregation flavor
  - [Vercel Academy — Changesets for Versioning](https://vercel.com/academy/production-monorepos/changesets-versioning) — Pattern A endorsement
  - [Backstage architecture-decisions docs](https://backstage.io/docs/architecture-decisions/) — late-binding sequential ADR IDs; primary case study (Spotify-originated)
  - [adr.github.io/madr](https://adr.github.io/madr/) — zero-padded sequential int convention; competing pattern
  - [joelparkerhenderson/architecture-decision-record](https://github.com/joelparkerhenderson/architecture-decision-record) — slug-only alternative
  - [Michael Nygard — Documenting Architecture Decisions (2011)](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) — original sequential-monotonic-no-reuse prescription
- Related ADRs:
  - [ADR-0002](./0002-habeebs-skill-standalone.md) — substrate constraint preserved (all mechanisms are markdown + JSON + shell)
  - [ADR-0004](./0004-parallel-subagent-dispatch-contract.md) — separately amended in-place by Slice 4 of v1.20.0 (dispatches/ directory cut)
  - [ADR-0007](./0007-description-budget-policy.md) — v1.19.0 release-skill audit step which this ADR extends, not replaces
  - [ADR-0009](./0009-docs-agents-references-convention.md) — 3-consumer threshold not violated (`.changeset/` is a runtime artifact directory, not a methodology reference)
  - [ADR-0018](./0018-implement-dormant-artifact-recording-contracts.md) — separately amended in-place by Slice 5 of v1.20.0 (conflicts/ directory cut)
  - [ADR-0019](./0019-amend-adr-0002-for-advisory-in-flight-reads.md) — advisory-in-flight-reads still applies for v1.18.0 sidecar mechanism (orthogonal; this ADR adds no in-flight-read pattern)

### Reference implementations cited

- **Append-only intent files + release-time aggregation:** [Changesets](https://github.com/changesets/changesets) and [release-please](https://github.com/googleapis/release-please) — Pattern A canonical implementations. Used by Astro, Storybook, Vercel internal tooling, and Google client libraries respectively.
- **Late-binding ADR identifiers:** [Backstage](https://backstage.io/docs/architecture-decisions/) — Spotify-originated production OSS; the only canonical-tier source that visibly grapples with parallel-writer ADR collisions.

---

## Changelog

- 2026-05-25 — Initial ADR, status Accepted (locked by v1.20.0 grill resolution; slated for implementation in Slices 1, 2, 3, and 7 of `docs/agents/specs/v1.20.0-methodology-overhaul.md`)
