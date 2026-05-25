# ADR-NNNN: Cut dormant methodology folders and fold grill-records into specs

**Status:** Accepted
**Date:** 2026-05-25
**Deciders:** Modie (Habeeb)
**Tier:** Balanced

> Note: This ADR is filed as `adr-methodology-folder-cuts.md` (no integer prefix) per the late-binding convention adopted by [`adr-late-binding-and-changesets.md`](./adr-late-binding-and-changesets.md). The `release` skill will assign the next sequential int + rename at v1.20.0 release time.

## Context

habeebs-skill's `docs/agents/` directory had accreted 9 declared subdirectories as the methodology grew across v1.5-v1.18. The v1.19.0 workflow audit memo (`docs/agents/research/v1.19.0-workflow-audit-research.md`, Deep tier) found that two of these subdirectories — `dispatches/` and `conflicts/` — were declared by ADRs (ADR-0004 Part 2 and ADR-0018 Part A respectively) but had **zero files written to them in real use** across the entire project history. A third subdirectory, `grill-records/`, held a single file (`2026-05-22-cross-session-conflict-detection.md`) and the corresponding mechanism had organically migrated to `specs/<name>-grill.md` naming during v1.18.0.

The audit measured this against **7 peer AI-tooling repos** (obra/superpowers, mattpocock/skills, anthropics/skills, anthropics/claude-code, Aider, Cline, Continue) and found:

- **No peer repo ships empty/dormant subdirectories.** Every declared directory in every peer has at least one file.
- **Modal peer shape is "no methodology folders at all."** anthropics/skills and anthropics/claude-code (Anthropic's own dogfooding) ship zero methodology folders — README + skills/agents/commands tree only.
- **The dormant-directory pattern is uniquely habeebs-skill.** Zero peer adoption across the surveyed set.

This converged into **Pattern G** in the audit: "methodology folders earn existence by file count, not by declaration." Industry threshold: 3+ files AND search-cost reduction over flat layout.

The audit also surfaced **Pattern B** (tombstone + forward-pointer + immutable PATH for retired artifacts) as the universally-convergent retirement pattern across MADR, Fowler, Backstage, and Rust RFCs. Backstage explicit: "Records are never deleted." Pattern B applies to files-with-content: the file stays at its original path, the Status field flips to point at the superseder, and inbound links remain valid.

The decision is needed NOW because the v1.20.0 release line is the natural cutover point. Deferring would mean every subsequent ADR continues to declare `dispatches/` and `conflicts/` as load-bearing, every cross-reference in CLAUDE.md / AGENTS.md / SKILL.md files continues to point at empty directories, and every new contributor reading the codebase wastes search-attention on directories that earn nothing.

Two reconciliations the audit memo applied during synthesis must be documented here so future readers don't re-litigate them:

1. The audit originally recommended folding `research/` into `specs/`. **Reversed during reconciliation** after v1.19.0 PR #42 promoted `research/` across the file-count threshold (4 files: 2 pre-existing + the v1.19.0 auto-trigger research + the audit memo itself). Pattern G's 3+ file threshold is met; `references/trigger-firing-eval.md` cross-references `research/` as the eval-input source.
2. The audit originally recommended consolidating `issue-tracker.md` + `triage-labels.md` into one `tracker-config.md`. **Reversed during reconciliation** when actual consumer counts surfaced (6 consumers and 8 consumers respectively, both clearing ADR-0009's 3-consumer threshold). The two files do different jobs — `issue-tracker.md` answers "which tracker" (with three reference docs for github/linear/local), `triage-labels.md` answers "which labels" (single canonical-5 mapping). Merging would entangle choice-axis with convention-axis. Pattern G applies to folders, not root files.

## Decision

We will retire three methodology subdirectories from `docs/agents/` and amend the ADRs that declared them in place.

Specifically:

- **Delete `docs/agents/dispatches/`** (0 files, declared by ADR-0004 Part 2). No stub README. ADR-0004 amended in place per Pattern B with a `Status: Accepted (Part 2 partially superseded by ADR-NNNN — dispatches directory retired)` line and a dated `## 2026-05-25 Amendment` section.
- **Delete `docs/agents/conflicts/`** (0 files, declared by ADR-0018 Part A). No stub README. ADR-0018 amended in place identically.
- **Fold `docs/agents/grill-records/` into `docs/agents/specs/<name>-grill.md`** naming. The single existing file (`2026-05-22-cross-session-conflict-detection.md`) is `git mv`'d to `specs/v1.16.0-cross-session-conflict-detection-grill.md` (preserves history); the directory is then deleted.
- **No stub README in deleted directories.** Pattern B's "immutable path" applies to FILES-with-content, not to declared-but-empty directories. A README in a deleted directory would itself constitute a non-empty directory, defeating the deletion. The in-place ADR amendments ARE the tombstones for empty-directory contracts; inbound references to the directories from skill files / CLAUDE.md / AGENTS.md are updated to either remove the reference or point at the amended ADR.
- **Cross-reference cleanup is in-scope of Slices 4 + 5** (not deferred). Each slice's acceptance criteria includes an exhaustive checklist of files to update: `CLAUDE.md` (line 84 lists `dispatches/`), `AGENTS.md`, `skills/parallel-dev/SKILL.md`, `skills/cross-session-detect/SKILL.md`. The grep step verifies no stale references remain except in (a) the amended ADRs themselves, (b) this ADR, (c) historical specs/grills/research (immutable per Pattern B).
- **SYSTEM_CONTEXT.md updates are DEFERRED** to the next `prior-art-research` Phase 0 invocation, per ADR-0005's single-writer invariant. Slices 4 + 5 list the needed SYSTEM_CONTEXT updates as comments in their commit messages; the next Phase 0 picks them up. This preserves the "SYSTEM_CONTEXT is written exclusively by prior-art-research Phase 0" contract — Slices 4 + 5 are not Phase 0 invocations.
- **`socratic-grill` SKILL.md edit is DEFERRED to v1.21.0** with a revisit trigger. The current grill record for v1.20.0 (`docs/agents/specs/v1.20.0-methodology-overhaul-grill.md`) already lives at the new convention path naturally, demonstrating the pattern works without a SKILL.md edit. Premature codification risk: changing the SKILL.md text now would force the convention before evidence accumulates. Trigger: after 2+ grills land in `specs/<name>-grill.md` naturally, OR a grill invocation accidentally writes to the now-nonexistent `grill-records/`.
- **Final `docs/agents/` shape: 7 declared surfaces** — `adrs/`, `specs/`, `plans/`, `references/`, `postmortems/`, `research/`, root files (`GLOSSARY.md`, `SYSTEM_CONTEXT.md`, `issue-tracker.md`, `triage-labels.md`). Down from 9.

The two retained patterns from the audit reconciliation:

- **`research/` is KEPT.** v1.19.0 PR #42 added two files (the auto-trigger-reliability research + this audit memo itself; further files since), pushing the directory across Pattern G's 3+ file threshold. Cross-referenced by `references/trigger-firing-eval.md` as the eval-input source. Folding into `specs/` would break those references.
- **`issue-tracker.md` + `triage-labels.md` stay separate.** 6 + 8 consumers respectively, both clearing ADR-0009's 3-consumer threshold. The two files separate the choice-axis (which tracker) from the convention-axis (which labels) — `setup-habeebs-skill` has three tracker-specific reference docs that all share one labels file. Merging would force entanglement.

## Consequences

### Positive

- **Reduces docs/agents/ surface from 9 to 7 declared subdirs.** Specifically matches Pattern G threshold (3+ files per subdir) for every remaining subdir.
- **Eliminates dormant-contract pattern.** No declared-but-empty directory remains in `docs/agents/`. Brings habeebs-skill into alignment with peer practice (zero of 7 surveyed peers ship empty/dormant subdirs).
- **Cross-references stay valid via in-place ADR amendments.** Pattern B preserved for the ADR files themselves (ADR-0004, ADR-0018 amended at their original paths with forward-pointer Status lines).
- **`grill-records/` content history preserved** via `git mv` (not delete + recreate).
- **Reconciliations documented prevent future re-litigation.** The reasoning for keeping `research/` and for keeping `issue-tracker.md` + `triage-labels.md` separate is captured here; the next audit doesn't re-investigate either.
- **Becomes Tier 0 prior art for folder-shape decisions.** Future `prior-art-research` runs that ask "should we add a new methodology folder?" check this ADR first (the file-count threshold + earn-existence rule).
- **Three deferrals are explicit, not implicit.** v1.21.0 socratic-grill SKILL.md edit, SYSTEM_CONTEXT.md updates, future `research/` re-evaluation — all flagged with revisit triggers.

### Negative / Accepted trade-offs

- **The deletion of `dispatches/` removes a contract that ADR-0004 Part 2 codified.** Anyone reading ADR-0004 in isolation would see the contract; the amendment forwards them to this ADR. Acceptable because the contract had zero adoption — superseding it is more honest than leaving a fiction in place.
- **Same for `conflicts/` and ADR-0018 Part A.** v1.18.0 cross-session conflict detection was implemented (sidecars + peer-scan + pre-push gate per ADR-0019), so the `conflicts/` directory's purpose was already obsolete before this ADR ships.
- **In-place ADR amendments make ADR-0004 and ADR-0018 longer.** Each grows by ~1 paragraph (date-stamped Amendment section). Acceptable — v1.19.0's ADR-0007 amendment is the in-repo precedent for this approach, and reading an amended ADR end-to-end is still less work than reading two ADRs in sequence to understand the same decision.
- **Reader has to know "deleted dir = check the ADR amendment for why."** No stub README to bread-crumb the reader. Mitigation: cross-references in active code (skill files, CLAUDE.md) point at the amended ADR, not at the deleted directory.
- **`socratic-grill` SKILL.md still says "write to grill-records/" until v1.21.0.** Acceptable risk because (a) the skill text already describes outputs going to `references/grill-output-template.md` (template, not directory), (b) the v1.20.0 grill record proves the convention works without a SKILL.md edit, (c) the deferral has an explicit revisit trigger. The deferral catches real future drift if it happens, instead of preemptively codifying based on one data point.
- **SYSTEM_CONTEXT.md will be transiently stale after Slices 4 + 5 land** (still mentioning `dispatches/` and `conflicts/`) until the next `prior-art-research` Phase 0 invocation reconciles it. Accepted because (a) ADR-0005's single-writer invariant is non-negotiable, (b) the next chain run picks up the staleness as part of normal Phase 0 staleness check, (c) the slices' commit messages list the needed SYSTEM_CONTEXT updates so the reconciliation is unambiguous.

### Operational impact

- **Slices 4 + 5 are AFK** (autonomous-friendly) — mechanical file deletions + ADR amendments + grep-driven cleanup.
- **Slice 6 is HITL** — the structural-fold ADR (this file) and the `grill-records/` `git mv` need human review for the historical record.
- **Cross-reference cleanup is exhaustive.** `grep -rn "dispatches/" --include="*.md"` and same for `conflicts/` must return only the amended-ADR + this-ADR + historical-spec hits after Slices 4 + 5. Dogfood scenario 24 (`tests/dogfood/24-folder-cuts/`) asserts this for each cut directory.
- **No CI dependency added.** All checks are local-only via dogfood scripts.
- **5 baseline dogfood tests must continue to pass post-implementation** (description-budget, disabled-list, chain-integrity, no-next-skills, system-context-schema). Slice 7 acceptance criterion enforces this.

## Alternatives considered

### Keep dormant directories with explanatory README stubs

Add a `README.md` in each deleted directory explaining "this directory was speculative; see ADR-NNNN." Preserves discoverability if someone navigates to the directory directly.

**Rejected** because (a) a directory with a README is non-empty by definition, defeating the purpose of the deletion, (b) Pattern B's "immutable PATH" applies to files with semantic content, not to directories the ADRs declared, (c) the in-place ADR amendments are already the forward-pointer — adding a README at the directory path would create two tombstones for one contract.

### Hard delete + drop the ADR amendments

Delete the directories AND delete the ADR clauses that declared them (or mark the entire ADRs as Superseded).

**Rejected** because the ADRs (0004 and 0018) contain other clauses that remain load-bearing — ADR-0004's parallel-subagent dispatch contract is still authoritative for `parallel-dev`; ADR-0018's other artifact-recording contracts remain in scope. Pattern B's "Records are never deleted" applies — partial supersession via in-place amendment is the right shape.

### Move `grill-records/` content to `postmortems/` instead of `specs/`

The grill record is retrospective in shape; postmortems are too.

**Rejected** because grill records are upstream of implementation (drive ambiguity out BEFORE the slice runs), while postmortems are downstream of incidents. ADR-0011 governs postmortem cadence as event-driven; folding grill records there would dilute the meaning of `postmortems/` as a directory and orphan the grill-record contract from its actual consumers (`socratic-grill` skill writes grills; `tdd-loop` reads them as one source of slice acceptance criteria).

### Cut all three subdirs + ALSO fold `research/` into `specs/`

The original audit recommendation. Maximally aggressive — collapse to 6 declared subdirs.

**Rejected** after v1.19.0 PR #42 promoted `research/` across the file-count threshold (4 files now; was 2 at audit time). Reconciliation documented above. The audit reversal is the right call — Pattern G is "earn existence by file count," and `research/` now earns it.

### Cut all three subdirs + ALSO consolidate `issue-tracker.md` + `triage-labels.md`

The original audit recommendation. Maximally aggressive — collapse root file count too.

**Rejected** because the actual consumer count surfaced during reconciliation contradicts the audit's "two files with one consumer each" premise. Real counts: 6 and 8 consumers respectively, both clearing ADR-0009's 3-consumer threshold. The two files do orthogonal jobs (choice vs convention); merging entangles them. Reconciliation documented above.

## Revisit triggers

This ADR should be reopened if any of:

- **The user discovers a fourth (or later) methodology folder is dormant.** Apply the same Pattern G threshold + amend-in-place tombstone pattern; do not re-spec the meta-decision. This ADR is the precedent.
- **After 2+ grills land in `specs/<name>-grill.md` naturally** (v1.20.0's own grill counts as the first), OR a grill invocation accidentally writes to the now-nonexistent `grill-records/`. Update `socratic-grill` SKILL.md to specify the new write path in v1.21.0.
- **`research/` file count drops below 3** (e.g., archive policy deletes old research files). Re-evaluate the keep-decision; fold into `specs/` if the directory falls below threshold.
- **A new contract emerges that wants its own subdirectory** (e.g., `evaluations/`, `benchmarks/`, `audit-trails/`). Apply Pattern G's "earn existence" rule before declaring — wait for 3+ files in a flat-layout precedent before creating the directory.
- **Anthropic ships a first-party docs/agents/ convention for Claude Code plugins.** Currently no published guidance. If they do, audit against this ADR's choices and migrate the cuts/keeps if needed.
- **Cross-reference link rot is observed** (e.g., a stale "see docs/agents/dispatches/" comment surfaces in a future commit). Add a CI-equivalent grep check; until then, dogfood scenario 24 is the protection.
- **An in-place ADR amendment becomes too long to read in one sitting** (rough threshold: amendment section grows past ~3 paragraphs OR cumulative amendments exceed the original ADR length). Consider Superseded-by-new-ADR pattern instead of further in-place amendment for that ADR.

## References

- Research: [`docs/agents/research/v1.19.0-workflow-audit-research.md`](../research/v1.19.0-workflow-audit-research.md) — Deep-tier audit, Pattern B + Pattern G derivations
- Spec: [`docs/agents/specs/v1.20.0-methodology-overhaul.md`](../specs/v1.20.0-methodology-overhaul.md) — Slices 4, 5, 6 implement this ADR
- Grill: [`docs/agents/specs/v1.20.0-methodology-overhaul-grill.md`](../specs/v1.20.0-methodology-overhaul-grill.md) — Items PT-3, PT-5 resolve the empty-dir tombstone question + `socratic-grill` SKILL.md deferral
- External sources:
  - [adr.github.io/madr](https://adr.github.io/madr/) — Status-field supersession convention; Pattern B canonical source
  - [martinfowler.com/architecture/](https://martinfowler.com/architecture/) — Fowler's ADR canon; reinforces MADR on retirement protocol
  - [Backstage architecture-decisions docs](https://backstage.io/docs/architecture-decisions/) — "Records are never deleted"; Pattern B production endorsement
  - [Rust RFC process](https://rust-lang.github.io/rfcs/introduction.html) — amendment-in-place + Postponed status; Pattern B variant
  - [ESLint rule deprecation](https://eslint.org/docs/latest/extend/rule-deprecation) — structured deprecation metadata (`since/until/replacedBy`); Pattern F for machine-readable retirement (cited but not adopted here — prose forward-pointer sufficient at habeebs-skill scale)
  - [anthropics/skills](https://github.com/anthropics/skills) — zero methodology folders; Pattern G canonical floor
- Related ADRs:
  - [ADR-0004](./0004-parallel-subagent-dispatch-contract.md) — Part 2 partially superseded by this ADR (in-place amendment by Slice 4)
  - [ADR-0009](./0009-docs-agents-references-convention.md) — 3-consumer threshold preserved; informs the `issue-tracker.md` + `triage-labels.md` keep-decision
  - [ADR-0011](./0011-error-analysis-cadence.md) — postmortems/ cadence-as-contract preserves the directory despite 1-file count; reasoning informs why `grill-records/` was folded (no cadence contract there)
  - [ADR-0018](./0018-implement-dormant-artifact-recording-contracts.md) — Part A partially superseded by this ADR (in-place amendment by Slice 5); the "dormant artifact-recording contracts" framing is itself partially superseded — Pattern G says contracts must earn existence, not be declared in advance
  - [ADR-0019](./0019-amend-adr-0002-for-advisory-in-flight-reads.md) — orthogonal; substrate carve-out unaffected by folder cuts
  - [`adr-late-binding-and-changesets`](./adr-late-binding-and-changesets.md) — companion v1.20.0 ADR; both ADRs share this release line + this audit memo as their source

### Reference implementations cited

- **Tombstone + forward-pointer + immutable PATH:** [MADR template](https://adr.github.io/madr/) and [Backstage](https://backstage.io/docs/architecture-decisions/) — Pattern B canonical implementations.
- **Earn-existence-by-file-count:** [anthropics/skills](https://github.com/anthropics/skills) and [anthropics/claude-code](https://github.com/anthropics/claude-code) — Pattern G zero-methodology-folder baseline. The audit measured habeebs-skill against this baseline and identified the 3-folder reduction.

---

## Changelog

- 2026-05-25 — Initial ADR, status Accepted (locked by v1.20.0 grill resolution; slated for implementation in Slices 4, 5, and 6 of `docs/agents/specs/v1.20.0-methodology-overhaul.md`)
