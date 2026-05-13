# ADR-0005: Split project context into GLOSSARY.md and SYSTEM_CONTEXT.md by writer lifecycle, and chain `setup-habeebs-skill` into Phase 0 inline

**Status:** Accepted
**Date:** 2026-05-13
**Deciders:** Modie (Habeeb)

## Context

habeebs-skill v1.7.0 ships with an accidental two-file context layout. `setup-habeebs-skill` (added in v1.0.0) writes `docs/agents/CONTEXT.md` as a domain glossary template; `prior-art-research` Phase 0 (made load-bearing in v1.5.0 via ADR-0001) writes `docs/agents/SYSTEM_CONTEXT.md` as an environment-binding recon digest. The two files differ on writer, refresh cadence, and reader set — but they sit one-token apart in the same directory and the relationship between them is undocumented. ADR-0001 noted this as a *"Notable absence"* in the canonical repo but did not reconcile the layout; ADR-0002 (standalone) added the constraint that any fix must stay markdown-only, multi-harness portable, with no runtime substrate or external sister tool.

The bug surfaces when habeebs-skill is ported to a fresh repo: `/setup-habeebs-skill` writes `CONTEXT.md` + tracker + labels + adrs/README, then ends. `SYSTEM_CONTEXT.md` never appears because nothing in the setup flow invokes Phase 0. The user's first `/research` invocation in the new repo is fine, but every other downstream chain skill (`/grill`, `/spec`, `/record`, `/plan`) halts with `SETUP REQUIRED: docs/agents/SYSTEM_CONTEXT.md missing`. Worse, ADR-0001 explicitly *declared* that "`setup-habeebs-skill` is the bootstrap entry point but defers the actual write of the recon digest to Phase 0 when invoked through the chain" — i.e., the chain was always supposed to flow setup → Phase 0, but the skill never implemented it. The decision is needed NOW because the rename + chain-wiring are a v1.8.0 candidate and we want the contract locked before `tdd-loop` starts on slice 1.

This ADR partially supersedes ADR-0001 — specifically the "Notable absence: No `docs/agents/CONTEXT.md`" line and the implicit assumption that `CONTEXT.md`'s lifecycle relationship to `SYSTEM_CONTEXT.md` was undefined. ADR-0001's load-bearing rule for `SYSTEM_CONTEXT.md` and its single-writer invariant remain in force, unchanged.

## Decision

We will split project context into two files explicitly along the **writer/refresh-cadence axis**, rename the human-authored file to remove the one-token collision, and wire `setup-habeebs-skill` to invoke Phase 0 inline. Specifically:

- **Two files, lifecycle-split.** `docs/agents/GLOSSARY.md` — human-authored, domain-stable, written by `setup-habeebs-skill` Phase 5 from `references/domain.md` template. `docs/agents/SYSTEM_CONTEXT.md` — tool-derived, environment-bound, written exclusively by `prior-art-research` Phase 0. The split axis is **writer + refresh cadence**, never topic.
- **Setup chains into Phase 0 inline.** `setup-habeebs-skill` gains a new Phase 7 ("Trigger Phase 0 reconnaissance") that invokes `prior-art-research` Phase 0 after writing GLOSSARY/tracker/labels/adrs and the `## Agent skills` block. Phase 0 remains the single writer of `SYSTEM_CONTEXT.md` (setup invokes; Phase 0 writes); ADR-0001's single-writer invariant is preserved by construction.
- **Forked Phase 0 failure handling.** Write-failure (permission denied, disk full, sandbox restriction, git uninitialized) → halt-loud at end of setup with a `SETUP_INCOMPLETE` banner naming the specific error and the recovery command (`Re-run /setup once <cause> is fixed`). Existing GLOSSARY/tracker/labels writes are preserved (independently valid; re-running `/setup` is idempotent). `[unknown]` tags in Phase 0 output are NOT a failure — they are Phase 0's normal soft output; setup confirms success and prints the count of `[unknown]` fields for the user to review later.
- **Halt-message fork.** Missing `GLOSSARY.md` → "run `/setup`"; missing `SYSTEM_CONTEXT.md` → "run `/research`". Two writers = two halt paths. The existing `SYSTEM_CONTEXT.md` halt blocks in `draft-spec`, `socratic-grill`, `decision-record`, `write-plan`, and `parallel-dev` are unchanged; the new `GLOSSARY.md` halt block is added to `deep-modules` only (the sole consumer).
- **Filename encodes role.** The legacy filename `CONTEXT.md` is renamed to `GLOSSARY.md` across every writer template and reader (one writer + two readers + one Phase 0 template + one recon-checklist + two test files). `CHANGELOG.md` mentions are NOT rewritten — release history is immutable.

The choice reflects four principles. **First, lifecycle separation over topic separation.** DDD (Evans/Vernon), Diátaxis (Procida), Nygard (ADR community), and mattpocock/skills all split documentation by writer-role and refresh cadence, never by topic name. Our two files differ on exactly that axis: GLOSSARY has a human writer and edits as the codebase evolves; SYSTEM_CONTEXT has a tool writer and refreshes when manifests change. The split is correct; the bug was that the filename didn't *show* the split. **Second, implement what ADR-0001 already specified.** The chain setup → Phase 0 was declared in ADR-0001 § Decision but never implemented in `setup-habeebs-skill/SKILL.md`. v1.8.0 closes that gap rather than introducing a new architectural axis. **Third, no migration cost — this is a personal repo.** Both ESLint v9 (external migrator) and Rails (in-core migrator + deprecation window) were considered; both rejected because the user owns all consumers and a manual `git mv` in the one other affected repo is trivial. **Fourth, failure-mode UX is forked because the failure modes are fundamentally different.** Write-failure is rare and hard-to-miss; `[unknown]` tags are common and soft. Treating them as one path (the original "warn-only" framing) under-served the rare case and over-warned on the common case.

## Consequences

### Positive

- **One-invocation bootstrap.** `/setup` now produces a fully chain-ready repo (GLOSSARY + tracker + labels + adrs/README + `## Agent skills` block + `SYSTEM_CONTEXT.md`). No surprise files appear later. No halt on first `/research`.
- **ADR-0001 latent bug closed.** The ADR declared setup-chains-into-Phase-0 in May 2026; v1.8.0 ships it. No more drift between ADR intent and skill implementation.
- **Filename collision eliminated.** `GLOSSARY.md` vs `SYSTEM_CONTEXT.md` are visually distinct; the joelparkerhenderson cautionary pattern (descriptive-only filenames colliding semantically) no longer applies here.
- **Two distinct halt paths, two distinct recoveries.** Users hitting `SETUP REQUIRED: GLOSSARY.md missing` know exactly which skill to run (`/setup`); users hitting `SETUP REQUIRED: SYSTEM_CONTEXT.md missing` know to run `/research`. No more "which file means which command?" guessing.
- **Forked failure handling matches actual failure shape.** Write-failures are loud (rare, user must act); `[unknown]` tags are quiet (common, self-documenting).
- **Phase 0's single-writer invariant preserved by construction.** Setup never writes `SYSTEM_CONTEXT.md` directly; it invokes Phase 0. ADR-0001 § Decision bullet 2 stays unchanged.

### Negative / Accepted trade-offs

- **Two files where one might fit.** Readers will look in two places for context. Acceptable: the writers and refresh schedules are genuinely different, and merging would reintroduce the DDD-2003 / Nygard-pre-split failure mode (one merged doc that decays because it serves two audiences).
- **Prose churn across 9 files.** Slice 1 renames `CONTEXT.md` → `GLOSSARY.md` across `setup-habeebs-skill/SKILL.md`, `setup-habeebs-skill/references/domain.md`, `deep-modules/SKILL.md`, `prior-art-research/references/system-context-template.md`, `prior-art-research/references/recon-checklist.md`, `tests/evals/phase-3.evals.json`, `tests/dogfood/05-research-recon-and-memory.md`, plus the spec and grill record. One-time cost; permanent benefit.
- **No migration shim for hypothetical other consumers.** If a third party ever forks habeebs-skill at v1.7 and bumps to v1.8, they must `git mv CONTEXT.md GLOSSARY.md` manually. Acceptable because (a) personal repo, (b) the rename is trivial, (c) Anthropic Skills 2.0 hasn't shipped a versioning primitive that would make a shim cheap.
- **`tests/dogfood/05-research-recon-and-memory.md`'s historical text** (which conflated the two files — the exact original symptom of this bug) is rewritten forward rather than preserved-with-note. Acceptable because dogfood tests are evergreen, not history.
- **ADR-0001 must be edited.** A one-line *"Partially superseded by ADR-0005"* note is added at the top of ADR-0001; the body is untouched. This is the first habeebs-skill ADR to be partially-superseded; sets the convention.

### Operational impact

- No CI/CD changes. No deploy changes. No runtime cost.
- `setup-habeebs-skill`'s new Phase 7 adds Phase-0 reconnaissance time to the bootstrap (~5-15 seconds on a fresh repo). Acceptable — bootstrap is a once-per-repo event.
- Phase 0's existing staleness banner remains the periodic-refresh primitive (unchanged).
- Halt-message copy in `deep-modules` is the only existing-skill prose change beyond the rename slice. All other halt-on-missing-SYSTEM_CONTEXT blocks are unchanged.

## Alternatives considered

### Merge into one `CONTEXT.md` with sections

A single file with `## Domain glossary` and `## System context` sections. Rejected: conflates writers (human vs Phase 0) and refresh cadences (manual vs auto-on-manifest-change) — exactly the DDD-2003 / Nygard pre-split failure mode where merged context docs decay because they serve two audiences. Cross-source signal in `/research` Phase 6 (DDD, Diátaxis, Nygard, ADR community) all converged on lifecycle-axis splits.

### Namespace by directory (Linux-kernel style)

`docs/agents/domain/CONTEXT.md` + `docs/agents/system/CONTEXT.md`. Rejected: directory-namespacing is the right pattern at ~50+ docs (Linux kernel's `Documentation/` migration 2016-2018 is the canonical case), not at 2 docs. Adds path indirection without earning anything.

### Numeric prefix (Rust RFC style)

`0001-glossary.md` + `0002-system-context.md`. Rejected: context-file identity is by role, not chronological order; the prefix would convey nothing meaningful and would conflict with the ADR numbering convention already established in this repo.

### Keep setup deferred — no chain into Phase 0

Status quo: `/setup` writes the static config; user runs `/research` separately to populate `SYSTEM_CONTEXT.md`. Rejected: ADR-0001 already specified the chain; for a personal repo with N ported codebases, one-invocation bootstrap wins on UX. The mattpocock-style "setup-writes-only-user-answered-bits" pattern is honored — setup still doesn't write `SYSTEM_CONTEXT.md` directly; it invokes Phase 0.

### External migrator package (ESLint v9 style)

Ship `@habeebs/migrate-v1.8` as a separately-installable adapter for repos that have legacy `CONTEXT.md`. Rejected: ADR-0002 forbids external deps. Also redundant — this is a personal repo with one known consumer; manual `git mv` costs less than packaging a migrator.

### Rails-style in-core `migrate-v1.8` skill with one-minor deprecation window

A new skill that detects legacy `CONTEXT.md`, prompts, renames, prepends a banner. Rejected by user as overkill: "this is my personal skill, I don't care about migrating existing repos, I care about this skill being the best workflow possible." Initially recommended by `/research` Phase 6; explicitly cut at the post-research scope-narrowing step.

## Revisit triggers

This ADR should be reopened if any of:

- **A third context-shaped file emerges** (e.g., `INTEGRATIONS.md` for harness-specific bindings, `RUNBOOK.md` for operational procedures). Revisit the file-count cap; likely add a `docs/agents/README.md` index rather than a third sibling, or revisit the directory-namespacing alternative.
- **A harness adds a `docs/agents/*.md` convention** that collides with this layout. Codex, Cursor, OpenCode, or a future harness reserving the directory would force a rename / relocation; re-evaluate naming at that point.
- **Phase 0 write-failure rate becomes non-trivial in practice.** The current "halt-loud + idempotent re-run" UX assumes write-failures are rare. If they become recurring (e.g., a class of sandboxed environments where the write systematically fails), revisit the recovery path — possibly a "retry with fewer probes" or "write to a fallback location" mode.
- **Anthropic Skills 2.0 ships a documented versioning/migration primitive.** When `/research` Phase 6 tried to fetch the spec, the canonical URL returned 404. If a future Anthropic spec lands a versioning primitive, revisit the "no migration shim" choice — the shim might become cheap enough to ship for future habeebs-skill consumers beyond the current user.
- **Phase 0's `[unknown]` tag count grows unbounded** as a fraction of fields written. The current pass-through behavior assumes `[unknown]` is rare. If most fields end up tagged, Phase 0 isn't doing its job; revisit with a "Phase 0 retry with deeper recon" path.
- **The dogfood acceptance criterion regresses.** If `tests/dogfood/05-research-recon-and-memory.md` ever re-conflates the two files (e.g., a future eval rewrites it carelessly), that's a signal the lifecycle-split mental model isn't well-internalized in the project's own docs — revisit teaching, possibly with a CI grep.

## Supersedes

This ADR partially supersedes **ADR-0001 — Make SYSTEM_CONTEXT.md the load-bearing environment-binding protocol** (2026-05-11). Specifically:

- The line *"No `docs/agents/CONTEXT.md` (domain glossary)"* under ADR-0001 § Context's "Notable absences" implicit list (mirrored in `docs/agents/SYSTEM_CONTEXT.md` § Notable absences at file-write time) is now obsolete — `GLOSSARY.md` replaces `CONTEXT.md` and is produced by `/setup`.
- The line *"No `setup-habeebs-skill` ever run on this repo"* — also obsolete after the slice 3 dogfood.
- The undefined relationship between `CONTEXT.md` and `SYSTEM_CONTEXT.md` is now defined explicitly here (lifecycle-split axis; setup invokes Phase 0; halt paths fork by missing file).

ADR-0001's load-bearing rule for `SYSTEM_CONTEXT.md` (§ Decision bullets 1, 2, 3, 4) and its single-writer invariant remain in force, unchanged. ADR-0005 implements what ADR-0001 § Decision bullet 2 already declared — it does not contradict the earlier ADR.

## References

- Research: `/research` output 2026-05-13 (in conversation; steering reconciliation captured in `docs/agents/SYSTEM_CONTEXT.md` § Last reconciliation outcome)
- Spec: `docs/agents/specs/v1.8.0-glossary-rename-and-setup-chain.md`
- Grill: `docs/agents/specs/v1.8.0-glossary-rename-and-setup-chain-grill.md`
- Plan: TBD — likely punted (3 slices, linear chain, ordering obvious — `write-plan` may be skipped per its own "skip if ordering is obvious" rule)
- Prior ADRs: [ADR-0001](./0001-environment-binding-via-system-context.md) (partially superseded), [ADR-0002](./0002-habeebs-skill-standalone.md) (constraint on this ADR — no runtime substrate)
- External sources:
  - [Michael Nygard — Documenting Architecture Decisions (2011)](https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions) — decision-local-context principle
  - [Diátaxis framework](https://diataxis.fr/) — lifecycle/audience-axis split
  - [Martin Fowler — Ubiquitous Language](https://martinfowler.com/bliki/UbiquitousLanguage.html) — DDD glossary-vs-context-map separation
  - [mattpocock/skills](https://github.com/mattpocock/skills) — `setup-matt-pocock-skills` writes-only-user-answered-bits pattern
  - [joelparkerhenderson/architecture-decision-record](https://github.com/joelparkerhenderson/architecture-decision-record) — cautionary case (descriptive-filename collision)
  - [obra/superpowers](https://github.com/obra/superpowers) — no-setup-at-all alternative (rejected — explicit user-answered config still needs a capture step)

### Reference implementations cited

- **Lifecycle-split context docs:** mattpocock/skills `setup-matt-pocock-skills` (linked above) — the convergent pattern for "setup writes only user-answered bits; runtime writes everything derivable." Cited because this ADR's decision to chain setup into Phase 0 without merging the writers is a direct application.
- **In-core orchestration without external migrator:** Rails `bin/rails app:update` — pattern initially proposed but rejected as overkill for this personal repo; cited so future reopen-triggers can find the right precedent if migration ever matters.

---

## Changelog

- 2026-05-13 — Initial ADR, status Accepted. Captures decisions resolved by `/grill` 2026-05-13 against spec `v1.8.0-glossary-rename-and-setup-chain.md`. ADR-0001 partially superseded.
