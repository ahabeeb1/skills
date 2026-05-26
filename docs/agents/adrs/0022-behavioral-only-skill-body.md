# ADR-NNNN: Behavioral-only SKILL.md body with Pattern-D empirical-claim exception

**Status:** Accepted
**Date:** 2026-05-26
**Deciders:** Modie (project lead)
**Tier:** Balanced

## Context

SKILL.md files are the runtime instruction surface for habeebs-skill. Each skill body is read every time the skill triggers — by agents, by contributors, by future-Modie. Over ~20 ADR cycles + ~19 releases, the bodies accreted three cruft categories: inline ADR-NNNN citations (worst offender 13 hits in one file), inline version-history tags ("Added in v1.7.0", "v1.8.0+ candidate"), and dated incident references ("documented 2026-05-12"). 12 of 18 SKILL.md files carried this cruft — 58+ hits total enumerated by hand audit.

A Balanced-tier `prior-art-research` run (`docs/agents/research/2026-05-25-skill-md-body-shape.md`) sampled 27 instruction files across 3 independent populations (peer Claude Code plugins, Anthropic canon, outside-Claude-Code rule ecosystems) plus 7 authoring/spec docs. The convergence was exceptional: 27/27 had zero inline ADR citations, 27/27 had zero version-archaeology tags, 26/27 had zero dated incidents. Anthropic's published best-practices doc states the rule directly: "Don't include information that will become outdated." Habeebs-skill was the outlier against the entire surveyed industry. This ADR adopts the convergent convention and codifies the small carve-outs the convention permits.

## Decision

We will treat SKILL.md body content as behavioral-only — present-tense imperative instructions for the agent executing the skill. The rule has three prohibitions and three carve-outs.

### Prohibited in skill body prose

- Inline `ADR-NNNN` citations ("per ADR-0004 Part 2", "consistent with ADR-0013"). Provenance lives in the ADR index, not the skill body.
- Inline version-archaeology tags ("Added in v1.7.0", "Phase 0.5 (added v1.7.0)", "v1.8.0+ candidate", "planned for v1.8.0+", section headings carrying `(vX.Y.Z+)` parentheticals). CHANGELOG.md is the canonical version log; `git blame` + tags reconstruct introduction history for any line.
- Dated incident references ("documented 2026-05-12", "the chain's bleeding pain was…"). Postmortems live in `docs/agents/postmortems/`; the surviving rule restates in body without the date.

### Permitted carve-outs

1. **Pattern D forward-only footer.** A `## See also` block at the end of a SKILL.md is permitted IFF every entry forward-points to a bundled asset — a sibling skill, a `references/` doc inside the skill directory, or an external authoritative source. Never backward-cites an internal ADR, postmortem, audit memo, or in-repo document. Skill-body content that needs to point at an ADR's content should point at the operational artifact the ADR governs (e.g., the postmortems directory itself rather than ADR-0011).
2. **Pattern-D empirical-claim exception (new in this ADR).** A `## Sources for this section:` footer is permitted when the body contains a load-bearing quantitative claim (a specific number, percentage, or rate) that an operator might need to defend. Each footer entry MUST be a forward link to an external authoritative source (peer-reviewed paper, vendor engineering blog, canonical man page). Internal artifacts (ADRs, postmortems, audit memos) never qualify. Today this applies to two skills: `parallel-dev` (90% lift / 15× token-cost claim from Anthropic's multi-agent research) and `using-worktrees` (git-worktree man page sourcing its hazard notes).
3. **Pattern F inline cross-skill handles.** Lightweight inline references via `/skill-name`, `@sibling.md`, or `[link](sibling.md)` are permitted in body prose for cross-skill coupling. Numbered ADR citations are never substituted for these.

### Mechanical rules

- HTML-commented attribution lines (`<!-- Inspired by ... -->`) are permitted in skill bodies. Dogfood scenarios 26/27/28 must exclude HTML-commented regions from their regex scope.
- Section-heading version tags get stripped wholesale.
- Body length ceiling: ≤500 lines per SKILL.md. If a skill exceeds, split content into `skills/<name>/references/*.md` and forward-point via Pattern D.

### Why this shape

Three things converge to make the rule defensible. First, the empirical floor: 27/27 cross-population convergence is exceptional and the most-authoritative single source (Anthropic's `skill-creator` meta-skill, the skill that teaches others how to write skills) exhibits the convention itself. Second, habeebs-skill already ships the parallel substrates the convention assumes — `CHANGELOG.md` for versions, `docs/agents/adrs/README.md` with `## Affects:` back-references for ADR provenance, `docs/agents/postmortems/` for incidents, git history for everything else. Third, the carve-outs are tight enough to preserve operational defensibility (the empirical-claim exception keeps `parallel-dev`'s "~90% lift" number anchored to its source paper) without re-introducing the cruft category the rule targets.

## Consequences

### Positive

- SKILL.md bodies stop decaying with each release cycle. The body says what to do *now*; the rule survives version bumps without rewrites.
- Convergence with Anthropic's published authoring guidance, which is the canonical floor for the Claude Code plugin ecosystem.
- The user-visible cruft Modie correctly identified gets cleaned up across 11 affected files (58 hits) in one mechanical pass.
- Dogfood scenarios 26/27/28 (added by Slice 6 of v1.21.0) prevent regression mechanically — every future PR that re-introduces an inline ADR cite, version tag, or dated incident fails CI.
- The Pattern-D empirical-claim carve-out gives future skills a principled path for citing load-bearing numbers without re-opening the cruft door.

### Negative / Accepted trade-offs

- In-file "why does this rule exist" provenance is lost from skill bodies. Recovery path: `git blame skills/<name>/SKILL.md` to find the introducing commit + the ADR index at `docs/agents/adrs/README.md` to find the governing ADR. Two clicks, not zero.
- Discoverability of ADRs from the skill that implements them is reduced. Mitigation: ADRs list their affected skills in their `## Affects:` section, so the reverse-lookup (ADR → skills) is preserved at the ADR index. The forward-lookup (skill → governing ADR) requires one ADR-index read.
- Per-skill version-introduced metadata at the rule level disappears from bodies. Mitigation: `CHANGELOG.md` carries per-version skill deltas; the `git tag` ↔ `commit-hash` chain reconstructs introduction date for any rule.
- Restated rules require manual fidelity verification when the cleanup applies — the audit at `docs/agents/specs/v1.21.0-body-cleanup-audit.md` provides a per-line semantic-fidelity column for this pass, but future restatements need the same discipline.

### Operational impact

- The cleanup itself is one v1.21.0 release: 1 audit-report PR (already produced) + ~3 cleanup-batch PRs grouped by hit-count tier + 1 release PR via the v1.20.0 changeset mechanism.
- Three new dogfood scenarios (26/27/28) join the baseline regression suite. Each must exclude SKILL.md frontmatter (everything before the second `---`) and HTML-commented regions.
- A pre-Slice-2 verification step confirms `docs/agents/adrs/README.md` has up-to-date `## Affects:` back-references for ADRs 0001-0021. Without this, the cleanup creates a discoverability gap (DX-2 from the grill record).
- No runtime substrate change. This ADR is markdown-only by construction; the cleanup mechanism is mechanical text edits + dogfood greps.

## Alternatives considered

### Status quo — keep inline ADR/version/date cruft

Reject without action. Rationale: violates the 27/27 cross-population convention; SKILL.md bodies continue accreting cruft with each release cycle; Anthropic's published best-practices doc explicitly counsels against time-sensitive info in skill bodies. The status quo is the position research scored as the outlier against the entire surveyed industry.

### Move attribution to a centralized `docs/agents/skill-origins.md` registry

The audit's original OQ-A1 recommendation: rather than delete `verify-output`'s `## Origins` section, migrate its attribution to a new `docs/agents/skill-origins.md` registry. Rejected during grilling. Rationale: zero peer precedent for centralized origins registries across the 27-file research sample; a 1-entry registry (oh-my-claudecode → verify-output is the only genuine external attribution today) fails the ADR-0009 3-consumer threshold; the CLAUDE.md + self-reference entries in the current Origins block are redundant attribution that doesn't justify a new file. Attribution is preserved in the v1.21.0 commit message (`git log --all --grep="oh-my-claudecode"` returns it forever) and in an optional HTML-commented `<!-- Inspired by ... -->` line in the skill body. A registry becomes the right answer if ≥3 skills accumulate genuine external attribution — captured as a revisit trigger.

### Adopt Anthropic's `<details>` "Old patterns" disclosure-fence as a general escape valve

Anthropic's best-practices doc prescribes the `<details>` fold pattern for the rare case when legacy info must remain visible to the agent during a migration window. Rejected as a default. Rationale: Anthropic prescribes it as last-resort, not as a general permission to keep cruft; no current habeebs-skill case requires it; adopting it as default re-opens the cruft door this ADR explicitly closes. Kept available for any future genuine migration window via a revisit trigger.

### Keep ADR-backward-citing `See also` footers with descriptive prose

Multiple skills carry `See also` entries shaped `[ADR-NNNN](path) — when X happens, look here.` The descriptions contain useful operational guidance; the link targets are backward citations. Rejected via the grill OQ-A4 conversion table — convert each entry to point forward at the most operationally-useful artifact (the postmortems directory for ADR-0011's content, the dogfood test for ADR-0007's audit, the parallel-dev SKILL.md for ADR-0004's contract) while preserving the description prose. The ADR index continues to provide the canonical reverse-lookup; skill body See-also entries are operational, not provenance.

## Revisit triggers

This ADR should be reopened if any of:

- habeebs-skill is distributed into a regulated/compliance substrate (SOC2 / HIPAA / FDA / aviation / finance) where inline "(per CR-12345, effective 2026-Q2)" stamps function as audit evidence rather than cruft. Re-research the body convention against a regulated-population sample.
- 3+ skills accumulate genuine external attribution (excluding self-references and CLAUDE.md). Promote attribution from per-skill HTML comments to a `docs/agents/skill-origins.md` registry then.
- A future ADR introduces a SKILL.md migration where the `<details>` "Old patterns" disclosure-fence escape valve becomes load-bearing for keeping deprecated guidance visible to the agent during a migration window.
- Any SKILL.md exceeds 500 lines as a category. Today every habeebs-skill SKILL.md is under the ceiling; if a future skill needs more depth, split via Pattern D `references/` sibling files rather than fattening the body.
- Dogfood scenarios 26/27/28 begin producing false positives that require systematic regex changes (>1 false positive per release cycle). Re-evaluate the detection mechanism — either the regex needs refinement or a legitimate new content shape needs codification as a new carve-out.

## References

- Research: [`docs/agents/research/2026-05-25-skill-md-body-shape.md`](../research/2026-05-25-skill-md-body-shape.md)
- Spec: [`docs/agents/specs/v1.21.0-body-cleanup.md`](../specs/v1.21.0-body-cleanup.md)
- Audit (per-file line-by-line): [`docs/agents/specs/v1.21.0-body-cleanup-audit.md`](../specs/v1.21.0-body-cleanup-audit.md)
- Grill: [`docs/agents/specs/v1.21.0-body-cleanup-grill.md`](../specs/v1.21.0-body-cleanup-grill.md)
- ADR-0002 — habeebs-skill standalone-by-design (substrate constraint): [`0002-habeebs-skill-standalone.md`](0002-habeebs-skill-standalone.md). This ADR is markdown-only by construction; the cleanup mechanism uses no runtime substrate.
- ADR-0005 — lifecycle split between GLOSSARY and SYSTEM_CONTEXT (single-writer pattern this ADR doesn't change): [`0005-lifecycle-split-glossary-and-system-context.md`](0005-lifecycle-split-glossary-and-system-context.md).
- ADR-0007 — description-budget policy (frontmatter governance — this ADR is the BODY analogue to ADR-0007's FRONTMATTER policy): [`0007-description-budget-policy.md`](0007-description-budget-policy.md).
- ADR-0009 — docs/agents/references convention (3-consumer threshold cited in the registry-rejection alternative): [`0009-docs-agents-references-convention.md`](0009-docs-agents-references-convention.md).
- ADR-0018 — dormant artifact-recording contracts (research-archive convention this run followed): [`0018-implement-dormant-artifact-recording-contracts.md`](0018-implement-dormant-artifact-recording-contracts.md).
- ADR-0020 — late-binding and changesets (this ADR uses late-binding — no integer prefix until v1.21.0 release): [`0020-late-binding-and-changesets.md`](0020-late-binding-and-changesets.md).

### External sources

- [Anthropic — Agent skills best practices](https://platform.claude.com/docs/en/claude-code/skills/best-practices) — load-bearing prescription "Don't include information that will become outdated."
- [Anthropic — Agent skills overview](https://platform.claude.com/docs/en/claude-code/skills) — body length norm (≤500 lines / ≤5000 tokens).
- [agentskills.io specification](https://agentskills.io/specification) — confirms "There are no format restrictions" while observing the convention by absence.
- [anthropics/skills — skill-creator](https://github.com/anthropics/skills/blob/main/skill-creator/SKILL.md) — the meta-skill exemplar exhibiting the convention.
- [anthropics/claude-code — skill-development](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/skill-development/SKILL.md) — first-party prescription to plugin authors.

---

## Changelog

- 2026-05-26 — Initial ADR, status Accepted. Late-binding integer assignment deferred to v1.21.0 release per ADR-0020.
