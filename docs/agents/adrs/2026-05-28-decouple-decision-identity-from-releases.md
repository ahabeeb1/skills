---
Status: Accepted
Date-Created: 2026-05-28
Last-Reviewed: 2026-05-28
Superseded-By: null
Tier: Deep
Deciders: Modie (Habeeb)
---

# ADR: Decouple decision identity from releases via dated artifact naming

**Status:** Accepted
**Date:** 2026-05-28
**Deciders:** Modie (Habeeb)
**Tier:** Deep

> This is the first ADR born under the convention it establishes — its own dated filename (`2026-05-28-decouple-decision-identity-from-releases.md`, written at creation, no release rename) is the load-bearing self-dogfood that the convention works end-to-end. It supersedes [`0020-late-binding-and-changesets`](./0020-late-binding-and-changesets.md) and is cited from there by title + link.

## Context

habeebs-skill is a Claude Code methodology plugin — markdown + JSON + shell, no runtime substrate (ADR-0002, narrowed by ADR-0019). Until now, an ADR had no stable identity until a release happened: `decision-record` wrote an unnumbered `adr-<slug>.md` placeholder and the `release` skill's Phase 3.5 assigned a sequential integer and renamed it at release-PR-creation time (the late-binding scheme of ADR-0020). That coupling is wrong for a methodology meant to work in repos that do not cut releases — "not everyone has releases" — and it leaves a window where a decision is unaddressable.

A Deep-tier research run (5 sub-problems; archive `docs/agents/research/2026-05-28-v1.23.0-dated-artifact-naming-research.md`) found the real fix is to **bind identity at creation, not at release**, and that ADR-0020's claim of "zero canonical endorsement for dated ADR naming" was overstated: log4brains defaults to dated filenames and Shopware has shipped them in production since 2020, both using the **slug as the uniqueness key** with the date for sorting. The decision is needed now because the v1.23.0 line is the natural cutover, and every subsequent ADR otherwise keeps paying the release-coupling tax.

## Decision

We will name ADRs (and specs, plans, and grill-records) with their **final dated filename at creation**: `YYYY-MM-DD-<slug>.md`, written by `decision-record` the moment the decision is made. No release step ever renames an artifact.

- **Slug is the uniqueness key**, not the bare date. Two ADRs on the same day are fine because their slugs differ; the date is for chronological sorting.
- **Halt loud on a true duplicate.** If `YYYY-MM-DD-<slug>.md` already exists, `decision-record` refuses to write — no overwrite, no suffix, no counter — and demands a more specific slug. A same-date-same-slug collision means the slug is too vague; the fix is a better name.
- **Cross-references use title + markdown link** for dated artifacts (e.g. "see the [dated-naming decision](./2026-05-28-decouple-decision-identity-from-releases.md)"). The 24 frozen integer ADRs continue to be cited as `ADR-00NN` — the integer is each one's permanent identifier. So new→new is title+link, new→old is `ADR-00NN`.
- **Full sweep.** ADRs, specs, plans, and grill-records all adopt dated naming. The release version moves out of the filename and into a frontmatter `Version:` / `Release:` field, so spec→plan→release traceability survives via frontmatter rather than the filename.
- **Freeze old, date new.** The 24 existing integer ADRs (`0001`–`0024`) keep their integer names forever — zero cross-reference edits across the ~117 files / ~1,241 `ADR-00NN` references that point at them. The directory permanently mixes the two schemes, which is shipped precedent (Rails 2.1 left old sequential migrations untouched when it switched to timestamps). The cutover is signaled by a section note at the top of `adrs/README.md`.
- **The release-driven late-binding machinery is removed.** `skills/release/scripts/assign-adr-ids.sh`, the release skill's Phase 3.5, and dogfood scenario 21 are deleted; the ADR README index is hand-maintained by `decision-record` (one row appended at write time, no script).
- **dogfood-28 carve-out.** The plugin's anti-version-archaeology lint (scenario 28) bans dated *strings in SKILL.md prose bodies* — decaying version-archaeology. A dated *filename* or a frontmatter `Date:` field is an immutable identifier (like a git SHA), categorically different, and is explicitly allowed; the lint's failure message distinguishes the two so a tripped contributor understands the carve-out.

The dated-vs-merge-number trade was considered and rejected: Rust's "number-at-merge = PR number" is the objectively cleanest decouple but needs a forge to supply the number, and this project has no CI and merges manually. Dates + slug is the better fit for a no-CI, markdown-only, parallel-session solo project; the slug carries the meaning and supersession is expressed by explicit forward-links, not numeric adjacency.

### Relationship to ADR-0020 — the Changesets half is RETAINED and IN-FORCE

ADR-0020 bundled two independent mechanisms behind one release coordinator: (1) **late-binding ADR integer IDs** and (2) **Changesets-shape version bumps** (append-only `.changeset/*.md` intent files aggregated by the release skill at release time). This ADR **fully supersedes ADR-0020**, but supersedes only mechanism (1). **Mechanism (2) — the Changesets-shape version-bump half — is explicitly retained and remains in force, unchanged.** The research §5 disposition confirmed the two share the release skill as coordinator but no code or state: release Phase 3.5 was the only ADR-coupled phase; changeset aggregation (Phases 2–3, `aggregate-changesets.sh`, `check-changeset-required.sh`, dogfood 22/23/25, `.changeset/*`) is ADR-independent and was left untouched throughout v1.23.0. The wholesale supersession of ADR-0020 must NOT be read as retiring changesets.

## Consequences

### Positive

- A decision gets a stable, human-legible, release-independent identifier at creation. Repos with no release cadence are first-class.
- Eliminates the manual-renumbering tax and the parallel-session ADR-integer collision class (two sessions can each write a dated ADR without racing for the next integer).
- Self-dogfooding: this ADR is the first dated artifact, proving the convention end-to-end on a real decision.
- Backwards-compatible: the 24 integer ADRs and every `ADR-00NN` reference to them stay valid; nothing is renamed.

### Negative / Accepted trade-offs

- **Causal ordering degrades.** A monotonic integer said "came after" for free; a date is fuzzy (same-day = no intrinsic order) and the slug says nothing. Supersession now leans entirely on explicit forward-links. This is the one genuine regression (grill OQ-7, deferred with a revisit trigger: adopt a hybrid dated-filename + monotonic `seq:` frontmatter field if decision order is ever misattributed).
- **Mixed-scheme directory under plain `ls`.** Integers `0001-0024` sort lexically before `2026-*`, so dated files cluster after the legacy integers — chronologically slightly off but acceptable in a markdown repo with no sorting tooling.
- **No forge-number option** (no CI; manual merges) — hand-copying PR numbers would be worse than dates+slug.

### Migration

- **Freeze old / date new** — the 24 integer ADRs are not renamed; everything from 2026-05-28 onward is dated.
- **In-flight branches.** Any branch that created an `adr-<slug>.md` under the old late-binding scheme before this shipped must rename it to `YYYY-MM-DD-<slug>.md` before merge (`decision-record` no longer produces the unnumbered form). One-time, well-bounded (single author, short-lived branches), mirroring ADR-0020's own in-flight-branch note.
- The GLOSSARY "late-binding" entry is narrowed to apply to the Changesets/version-coordination mechanism only, not ADR IDs.

## Alternatives considered

- **Keep late-binding integers (ADR-0020 status quo).** Rejected — it is the pain being fixed; identity stays release-coupled.
- **Slug-only filenames, date in frontmatter (joelparkerhenderson).** Rejected — loses chronological sortability under `ls`.
- **Number-at-merge = PR number (Rust RFCs / Backstage).** Rejected — needs a forge to supply the number; this project has no CI and merges manually.
- **Bare `YYYY-MM-DD` without slug-as-key.** Rejected — provably collision-prone under the parallel-session usage that motivated dating (MADR #28).

## Revisit triggers

- A same-day same-slug collision actually occurs and halt-loud proves awkward in practice → reconsider a sub-day `HHMMSS` suffix.
- Decision causal-ordering is ever misattributed because dated filenames lack monotonicity → adopt the hybrid dated-filename + monotonic `seq:` frontmatter field (OQ-7 deferral).
- A second author joins, raising parallel-session collision pressure → re-confirm slug-as-key, or adopt forge-number-at-merge once CI exists.
- Anthropic ships a first-party ADR convention for Claude Code → audit dated naming against it.
- The retained Changesets-shape version-bump machinery (ADR-0020 half #2) is itself revised → re-check that this ADR's teardown left it whole.

## References

- Research: [`research/2026-05-28-v1.23.0-dated-artifact-naming-research`](../research/2026-05-28-v1.23.0-dated-artifact-naming-research.md) — Deep-tier, 5 sub-problems
- Spec: [`specs/v1.23.0-dated-artifact-naming`](../specs/v1.23.0-dated-artifact-naming.md)
- Grill: [`specs/v1.23.0-dated-artifact-naming-grill`](../specs/v1.23.0-dated-artifact-naming-grill.md) — 7 OQs resolved
- Plan: [`plans/v1.23.0-dated-artifact-naming`](../plans/v1.23.0-dated-artifact-naming.md)
- Superseded: [`0020-late-binding-and-changesets`](./0020-late-binding-and-changesets.md) — ADR-ID half superseded here; Changesets-shape version-bump half retained and in-force
- External: [log4brains](https://github.com/thomvaill/log4brains) (dated ADR default, slug-as-ID), [Shopware ADRs](https://developer.shopware.com/docs/resources/references/adr/) (production dated ADRs), [Rails migrations](https://guides.rubyonrails.org/active_record_migrations.html) (sequential→timestamp, old files untouched), [MADR #28](https://github.com/adr/madr/issues/28) (same-day collision)

---

## Changelog

- 2026-05-28 — Initial ADR, status Accepted (first dated artifact; supersedes ADR-0020's late-binding-ID half, retains its Changesets half). Implemented across v1.23.0 Slices 1–6.
