---
Status: Accepted
Date-Created: 2026-05-26
Last-Reviewed: 2026-05-26
Superseded-By: null
Tier: Deep
Deciders: Modie (Habeeb)
---

# ADR: Plain-English plan format + provisional-state HITL pivot + PostToolUse chain-state validator + markdown-only telemetry frontmatter

**Status:** Accepted
**Date:** 2026-05-26
**Deciders:** Modie (Habeeb)
**Tier:** Deep

> Note: This ADR is filed as `adr-methodology-bundle-v1.22.md` (no integer prefix) per the late-binding convention adopted by [ADR-0020](./0020-late-binding-and-changesets.md). The `release` skill assigns the next sequential integer + renames at v1.22.0 release time. This ADR also dogfoods the v1.22.0 Piece 5 telemetry frontmatter (the PascalCase `Status:` / `Date-Created:` / `Last-Reviewed:` / `Superseded-By:` block above) from day 1.

## Context

After six self-dogfood release cycles (v1.16.0 through v1.21.0), habeebs-skill has accumulated four interlocking methodology frictions. The user (Modie, the sole maintainer) surfaced all four on 2026-05-26 in plain language: "the language of the plans and the way they are structured its not human readable and hard to comprehend"; "the hooks, are these good or no, should there be hooks about stop context ensuring we are in worktrees"; "before plans get implemented human in the loop things should be fleshed out, not midway during plans"; "there have been folders that are deprecated but we havent deleted them."

A Deep-tier prior-art-research run (archived at [`docs/agents/research/2026-05-26-v1.22.0-methodology-overhaul-research.md`](../research/2026-05-26-v1.22.0-methodology-overhaul-research.md)) decomposed these four pains into seven sub-problems (Phase 2.5 category-completeness-critic added three: mid-flight branch survival, plugin supply-chain, markdown-only telemetry), fanned out one source-fetcher per sub-problem in parallel, and synthesized 36 peer sources spanning Anthropic canonical docs, obra/superpowers, mattpocock/skills, Backstage BEPs, Kubernetes KEPs, Python PEPs, Rust RFCs, ThoughtWorks Tech Radar, MADR, Changesets, Conventional Commits, Keep-a-Changelog, OWASP CICD-SEC-8, and the Palo Alto Unit 42 Shai-Hulud npm-worm report.

The research recommendation (§ 4) was a 5-piece bundle plus 1 deferred-hardening ADR. The HITL pivot gate this ADR codifies was itself **dogfooded** on that research run — the gate fired between Phase 6 (synthesize) and Phase 6.5 (archive); Modie accepted with one OQ deferral; the gate caught the right grain. The grill record (`docs/agents/specs/v1.22.0-methodology-overhaul-grill.md`) resolved five open questions and surfaced one (OQ-6) that re-scoped Piece 4 — that re-scope is captured separately in the [ADR-0021 in-place 2026-05-26 Clarification](./0021-methodology-folder-cuts.md), not in this ADR. Piece 6 (plugin supply-chain) is captured in [`adr-plugin-supply-chain-threat-model.md`](./adr-plugin-supply-chain-threat-model.md).

This ADR covers FOUR of the original six pieces — Pieces 1, 2, 3, and 5 — because they are bundled in one release and cohere as one methodology change: the chain becomes more human-readable (Piece 1), the pivot opportunity moves earlier (Piece 2), the discipline becomes self-enforcing through advisory tooling (Piece 3), and the durable observability of decisions becomes a frontmatter convention (Piece 5). One ADR per bundled release matches the precedent set by v1.20.0 (ADR-0020) and v1.21.0 (ADR-0022).

The decision must be made now because v1.22.0 is the natural cutover — every future chain run inherits these conventions from the moment they ship. Deferring would mean every subsequent `/research` run uses the old gate placement, every plan written uses the old Jira-export aesthetic, and every new ADR written ships without telemetry observability that catches the dormancy class the research surfaced.

## Decision

We will land four coordinated methodology changes as habeebs-skill v1.22.0, all conforming to ADR-0002 markdown-only standalone-by-design:

### Piece 1 — Plain-English plan format

`skills/write-plan/SKILL.md` and `skills/write-plan/references/plan-template.md` are rewritten to enforce:

1. **TL;DR at top** — 3-5 plain-English sentences before any table or status block. Reader picks up the plan cold and knows what's happening.
2. **Per-phase narrative intro** — every phase opens with 1-3 sentences of "why this phase exists / what we accomplish here" BEFORE acceptance gates, risks, or tables.
3. **Tables collapse to two uses only** — (a) Status block at top (Plan ID / ADR / Tier / Status / Owner — five rows max), (b) Slice list. Acceptance gates become numbered prose lists. Risks become prose paragraphs with embedded "Mitigation:" lines, not nested bullets.
4. **Jargon discipline** — first use of `pgroup`, `pre-flight verification`, `HITL:approval-gate`, etc. is inline-defined if used ≤3 times in the doc, OR linked to a GLOSSARY.md entry if used more. GLOSSARY.md gains seven new entries (per grill OQ-4 resolution): `pgroup`, `pre-flight verification`, `HITL:approval-gate`, `HITL:per-file`, `HITL:inline`, `AFK:full-auto`, `tracer slice`.
5. **Dropped surface** — rollback-hook columns, Jira-style blocked-by tables, three-level-nested risk hierarchies. These cluttered every prior plan and surfaced in zero of five peer plan-shape sources.

The convention dogfoods itself: v1.22.0's own delivery plan (next phase) uses the new format on its own plan, providing the first evidence that the convention is followable.

### Piece 2 — Provisional-state HITL pivot

`skills/prior-art-research/SKILL.md` inserts a new HITL gate between Phase 6 (synthesize) and Phase 6.5 (archive). The gate emits a `## Phase 6 ready for HITL review — pivot point` block at the end of Phase 6 output with three response options:

- **(a) Approve as-is** — proceed to Phase 6.5 archive write unchanged.
- **(b) Approve with pivots** — free-text edits applied to the in-conversation Phase 6 report BEFORE Phase 6.5 commits to the archive file. Once Phase 6.5 writes the file, it IS the source of truth.
- **(c) Reject + re-research** — return to Phase 2 (re-decomposition) with new scope.

Format is yes/no + iteration, NOT menu-of-options. Zero of five peer methodologies used menus; four of five used yes/no + iteration or state-transition. Solo-author cadence (Modie) favors the simpler shape; state-transition adds ceremony without value here.

The gate is the KEP `provisional` shape (a stub document exists in conversation; approval moves it to archive). It is NOT the PEP pre-RFC issue gate (no document exists yet) — Python's pre-spec discussion gate would require a separate artifact habeebs-skill doesn't currently produce, and the report itself already exists by Phase 6.

### Piece 3 — PostToolUse chain-state validator hook

A new shell hook `hooks/check-chain-state.sh` is wired to `PostToolUse[Edit|Write|NotebookEdit]` in `hooks/hooks.json`. The hook is **warn-only**, exits 0 always, prints warnings to stderr, and honors `HABEEBS_DISABLE_HOOKS=1` per existing pattern.

**Scope** (locked by grill OQ-1 — the kill-switch did NOT fire; the hook is justified):

- **(b) Missing grill record when spec `Status: Grilled`** — the hook reads `docs/agents/specs/*.md` frontmatter (file-existence-as-state per ADR-0003 stricter statelessness bar) and warns when a spec marked `Status: Grilled` has no corresponding `<slug>-grill.md` file. Drift class: spec advanced through the chain without the grill record being committed.
- **(c) Editing skills/ | hooks/ | .claude-plugin/ on default branch with uncommitted changes** — three stateless signals composed (`git symbolic-ref refs/remotes/origin/HEAD`, path match, `git status --porcelain`). Complements the existing `preventing-commits-to-default.sh` PreToolUse Bash hook: that one blocks at commit time, this one warns at edit time — earlier surface, more recovery options.

**Rejected scopes** (grill OQ-1 reasoning preserved here for revisit triggers):

- **(a) Missing spec when editing skills/ on a feature branch** — rejected for false-positive-on-chore-PRs (e.g., chore PR #47 — plan-status flip) and absent branch-naming convention (would need to map `feature/<slug>` to `specs/<slug>.md`).
- **(d) Stale plan Status fields >2 releases** — rejected for redundancy with Piece 5's release-time editorial scan and excessive per-edit firing frequency.

Hook is stateless under both Anthropic's "no in-memory state" definition and habeebs-skill's stricter ADR-0003 "no session-state directories" bar (silent-contradiction-3 resolution from pattern-extractor). Dogfood scenario 29 ships with the hook (four fixture cases: two warning scopes × two-each positive-trigger + negative-no-trigger control).

### Piece 5 — Markdown-only chain telemetry frontmatter

ADR and plan frontmatter conventions gain four new fields (PascalCase to match existing `Status:` / `Date:` / `Deciders:` / `Tier:` convention; grill OQ-2 resolution):

```yaml
---
Status: <Proposed | Accepted | Active | Done | Deprecated | Superseded by ADR-N>
Date-Created: 2026-05-26    # never changes after initial write
Last-Reviewed: 2026-05-26   # deliberate-review timestamp; NOT auto-bumped on commit
Superseded-By: null         # path to replacement ADR/plan; null until superseded
---
```

`Last-Reviewed` has **deliberate-review semantics** — it changes only when a human says "I reviewed this and confirm Status remains correct." Auto-bumping on every commit would defeat the dormancy signal (every ADR would look fresh after every release).

`skills/release/SKILL.md` Phase 10 gains an editorial-scan step: on minor+major releases only (patches skipped — low value, redundant with most-recent minor scan), walk `docs/agents/adrs/*.md` and `docs/agents/plans/*.md`; flag any with `Status: Proposed` or `Status: Active` and `Last-Reviewed` older than `max(3 minor releases ago, 6 months ago)`. Print as warning; do not block release. Modie reads the warning and decides whether to land an update PR (same shape as chore PR #47 today). No script required — instruction text + suggested grep command.

Rollout is **new ADRs/plans only starting v1.22.0+** (per spec Concrete pick #11). This ADR itself ships with the new convention; the supply-chain ADR ships with it; future ADRs follow. Existing 22 ADRs are not retrofitted in v1.22.0 — back-fill is a v1.23.0+ candidate if dormancy signal proves valuable.

### Why these four cohere as one ADR

All four pieces share the same root principle: **make the methodology's load-bearing decisions visible and addressable at the right grain**. Piece 1 makes plans readable so decisions surface in plain English. Piece 2 surfaces the pivot opportunity before downstream tokens are spent. Piece 3 surfaces chain-state drift at edit time. Piece 5 surfaces dormancy at release time. Each handles a different grain (in-doc, mid-chain, edit-time, release-time) but the principle is one.

One ADR per bundled release also matches habeebs-skill precedent: v1.20.0 (ADR-0020) bundled late-binding-ADRs + Changesets-shape-version-bumps + grill-records-fold into one ADR; v1.21.0 (ADR-0022) bundled three SKILL.md body conventions + Pattern-D exception. v1.22.0 follows the same shape.

## Consequences

### Positive

- **Methodology shrinks net surface.** Drops table-dominant plan structure (zero peer precedent), late-stage HITL gates (HITL fires earlier so per-slice approval becomes lighter), and seven undocumented jargon terms. Plans become readable to a cold reader.
- **HITL pivot prevents wasted downstream token spend.** Every `/research` run halts before Phase 6.5 archive; if the recommendation is in the wrong direction, the pivot costs one user message instead of a full `/spec` + `/grill` + `/record` + `/plan` re-do.
- **Hook surfaces drift at edit time, not commit time.** The PostToolUse validator catches "spec marked Grilled with no grill record" and "editing on main without a worktree" before the commit hook fires — more recovery options.
- **Telemetry creates a release-time dormancy signal.** ADRs and plans that drift across releases without deliberate review get flagged on every minor+major release. Modie reads the warning and decides.
- **Convergence with peer practice.** 0/5 peer plan sources used tables as primary structure; 4/5 peer methodologies gate before full spec; 0/3 peer Claude Code plugins use stateful hooks (we don't either); MADR's single-`date` overwrite anti-pattern avoided via distinct `Last-Reviewed`.
- **Dogfooded on the run that produced it.** The HITL pivot fired on the research run; one OQ was deferred to grill; gate caught the right grain. Evidence the pattern works before it ships.

### Negative / Accepted trade-offs

- **Methodology shrinks rather than grows.** Removes plan-template structure that some readers may have found familiar (the Jira-export aesthetic). New format breaks template-consistency with v1.21.0 and earlier plans; no migration of existing plans (they stay in old shape per Backstage's "manual reclassification" pattern — only new plans use the new template).
- **Warn-only hook accepts some warn-fatigue risk.** Mitigated by tight scope (only two warning conditions; (a) + (d) rejected with reasons). Modie can ignore warnings; the cost is signal lost, not work blocked.
- **Telemetry deferral leaves 22 existing ADRs without `Last-Reviewed`.** Editorial scans only catch new ADRs in `Proposed`/`Active` status. Existing ADRs' staleness remains invisible until v1.23.0+ back-fill ships. Acceptable because existing ADRs already have `Date:` and the cost of mass-rename outweighs the immediate dormancy-signal value.
- **HITL pivot adds one round-trip per `/research` run.** Cost: one halt + one user message. Benefit: prevents spec/grill/record/plan re-do. Net positive but the per-research overhead is real.
- **Cross-plan-format inconsistency.** Until existing plans are rewritten (out of v1.22.0 scope), users see two formats in the repo. Acceptable; the dogfood scenarios + new template carry the convention forward.

### Operational impact

- **No CI changes.** All checks are local-only via dogfood scenarios (existing pattern). New scenario 29 ships with the hook (file lives at `tests/dogfood/29-chain-state-validator/check-validator.sh`).
- **No deployment changes.** habeebs-skill has no deploy — releases are manual `gh release create` after PR merge.
- **Hook execution adds ~10-50ms latency per Edit/Write/NotebookEdit.** Negligible at single-author cadence; bounded by the 10-second timeout in `hooks.json`.
- **Plan-format rewrite affects every future plan.** The first plan to use it is v1.22.0's own delivery plan (Phase 12 in this chain run).
- **Release-time editorial scan adds ~5 seconds to minor+major releases.** Walks `docs/agents/adrs/*.md` + `docs/agents/plans/*.md`, ~30 files total at current scale. Acceptable.

## Alternatives considered

### Survey-style plans with heavy tables (current state)

Keep the v1.21.0 plan-format conventions (heavy tables, stacked AND-clause acceptance gates, nested risks). Rejected because zero of five peer plan sources (obra/superpowers, Backstage BEP 0001 + 0013, Increment "Planning with RFCs," anthropics/skills [zero plans shipped — canonical floor]) used tables as primary structural elements. Modie's stated pain ("I can barely comprehend what this plan is saying") aligns directly with the divergence from peer norm. Tables collapse to a 5-row status block + slice list only.

### State-transition gate format for HITL pivot

Use the full KEP `provisional → implementable → implemented` state machine for the HITL pivot, with explicit state transitions tracked in the research-archive frontmatter. Rejected for solo-author cadence — Backstage already proves the state-transition shape works for committee-driven processes (BEPs ship with `implementable / implemented / deferred / rejected / replaced` states), but the auditability benefit doesn't apply when there's one author. Yes/no + iteration is simpler, recoverable, and matches Modie's stated pivot need ("see the recommendation, redirect if needed"). The `Status:` field in Piece 5's telemetry frontmatter captures the lifecycle without inventing a parallel state machine.

### PreToolUse[Edit|Write] block instead of PostToolUse validator

Block edits when chain state is invalid (e.g., refuse to write to `skills/` without a spec). Rejected for friction on every Edit/Write call (multi-second hook overhead × every edit) and because blocking requires state-owning ("am I in /tdd right now?") which violates ADR-0003 statelessness. PostToolUse validator composes with the stateless contract naturally: file existence IS the state; warn after the fact rather than block before. disler/claude-code-hooks-mastery's "validator confirms artifact exists after subagent finishes" pattern is the precedent.

### MADR single-`date` field for telemetry

Adopt MADR's frontmatter convention as-is (`status` enum + single `date` field that's overwritten on update). Rejected because MADR's `date` overwrites on every edit — every ADR would look fresh after every commit, defeating the dormancy signal Modie needs. Distinct `Date-Created` + `Last-Reviewed` is the explicit fix (research § SP7 pattern-extractor's "adoption gap from MADR" — go beyond MADR, don't adopt as-is).

### `Stop` / `SubagentStop` hook for chain-completion verification

The brief proposed a Stop/SubagentStop hook checking whether all chain artifacts exist after a run completes. Rejected because the closest precedent (disler/claude-code-hooks-mastery) uses `SubagentStop` for TTS announcements only, not chain verification. PostToolUse fires at the right grain (per-edit, near-real-time) — Stop would batch the same checks at session end, by which time the edits are already committed. Validation belongs to PostToolUse per the silent-contradiction-3 resolution.

## Revisit triggers

This ADR should be reopened if any of:

- **Plan format adoption stalls.** If three or more contributors find the new format opaque AND no one finds the old Jira-export format clearer → re-research plan-format (next minor).
- **HITL pivot drop-out rate is too high.** If 50%+ of `/research` runs hit the gate and the user accepts as-is unchanged, the gate is overhead → demote to opt-in (`--pivot` flag).
- **PostToolUse validator warn-fatigue.** If Modie ignores ≥3 warnings in a row without acting on any of them → re-grill OQ-1 scope OR demote the hook to opt-in.
- **Telemetry back-fill becomes load-bearing.** If 5+ existing ADRs go > 6 months without `Date:` updates AND the new `Last-Reviewed` field starts showing dormancy → ship the v1.23.0+ back-fill slice for the 22 retroactive ADRs.
- **Plan-format breaks contributor onboarding.** If a new contributor (not Modie) reads the new format and gets confused → consider three-stage deprecation per superpowers pattern (disabled → deprecated → removed across 2 minors) to introduce the format more gradually.
- **GLOSSARY.md surpasses 50 entries.** If the seven new entries balloon to 50+ via per-release additions, fragmenting into multiple glossaries (or per-skill glossaries) may earn existence under ADR-0009's 3-consumer threshold.
- **Plugin-supply-chain incident hits Claude Code marketplace.** If the deferred-hardening ADR (`adr-plugin-supply-chain-threat-model.md`) trigger fires, Piece 3 hook gains a 6th potential warning class (e.g., "untrusted hook script signature mismatch") and this ADR reopens for hook-threat-model integration.
- **Anthropic ships a chain-completion-verification hook event.** If Anthropic adds a new hook event explicitly for chain-state verification (e.g., `ChainComplete`), this ADR's PostToolUse-only choice gets re-evaluated.

## References

- Research: [`docs/agents/research/2026-05-26-v1.22.0-methodology-overhaul-research.md`](../research/2026-05-26-v1.22.0-methodology-overhaul-research.md) — Deep tier, 36 sources, 7 sub-problems including 3 critic-added; recommendation § 4 is the source of all four pieces.
- Spec: [`docs/agents/specs/v1.22.0-methodology-overhaul.md`](../specs/v1.22.0-methodology-overhaul.md) — Status: Grilled; 12 Concrete picks + 11-item 2026-05-26 Amendment.
- Grill: [`docs/agents/specs/v1.22.0-methodology-overhaul-grill.md`](../specs/v1.22.0-methodology-overhaul-grill.md) — 5 OQs decided + OQ-6 surfaced; agent-factors-check + devex-review domain extensions fired.
- ADR-0002: [`0002-habeebs-skill-standalone.md`](./0002-habeebs-skill-standalone.md) — all four pieces are markdown-only; no runtime substrate.
- ADR-0003: [`0003-hooks-scope.md`](./0003-hooks-scope.md) — Piece 3 follows warn-only, stateless, multi-harness aware.
- ADR-0004: [`0004-parallel-subagent-dispatch-contract.md`](./0004-parallel-subagent-dispatch-contract.md) — Part 5 untrusted-content rule inherited by Piece 3 hook.
- ADR-0005: [`0005-lifecycle-split-glossary-and-system-context.md`](./0005-lifecycle-split-glossary-and-system-context.md) — Piece 1 GLOSSARY extension respects the human-authored single-writer invariant.
- ADR-0007: [`0007-description-budget-policy.md`](./0007-description-budget-policy.md) — orthogonal; Piece 1 doesn't touch frontmatter (Piece 5 touches frontmatter but additively).
- ADR-0009: [`0009-docs-agents-references-convention.md`](./0009-docs-agents-references-convention.md) — Piece 1 jargon glossary defers to GLOSSARY.md (existing surface) rather than fragmenting.
- ADR-0010: [`0010-system-context-contents-prune.md`](./0010-system-context-contents-prune.md) — Piece 5 telemetry doesn't change SYSTEM_CONTEXT.md shape.
- ADR-0016: [`0016-chain-wide-depth-tier.md`](./0016-chain-wide-depth-tier.md) — Piece 2 HITL pivot inherits tier from the research report header.
- ADR-0018: [`0018-implement-dormant-artifact-recording-contracts.md`](./0018-implement-dormant-artifact-recording-contracts.md) — Part B research-archive convention is what Piece 2's gate fires between (Phase 6 produces; Phase 6.5 archives; the pivot lands in the gap).
- ADR-0020: [`0020-late-binding-and-changesets.md`](./0020-late-binding-and-changesets.md) — this ADR uses `adr-*.md` filename per late-binding.
- ADR-0021: [`0021-methodology-folder-cuts.md`](./0021-methodology-folder-cuts.md) — clarified in-place by this run's 2026-05-26 Clarification block (writer-path vs authored-methodology distinction).
- Sibling ADR (this release): [`adr-plugin-supply-chain-threat-model.md`](./adr-plugin-supply-chain-threat-model.md) — Piece 6, deferred-hardening for Piece 3 hook expansion (and other hooks).

### External sources cited

- [obra/superpowers writing-plans SKILL.md](https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md) — Piece 1 plan-format (Goal/Architecture/Tech Stack header; prose+code-blocks dominant; zero tables) + Piece 2 design-sign-off precedent (section-by-section confirmation during writing).
- [Backstage BEP 0001](https://github.com/backstage/backstage/blob/master/beps/0001-notifications-system/README.md) — Piece 1 `## Summary` always first; 85-95% prose ratio.
- [Kubernetes KEP-0000](https://github.com/kubernetes/enhancements/blob/master/keps/sig-architecture/0000-kep-process/README.md) — Piece 2 `provisional` state shape that the HITL pivot most closely matches.
- [Python PEP 1](https://peps.python.org/pep-0001/) — Piece 2 explicit cost-of-writing justification: "vetting publicly before going as far as writing a PEP is meant to save author time."
- [Anthropic Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) — Piece 3 hook events catalog (31 events; we use 3 in v1.22.0: SessionStart + PreToolUse + PostToolUse).
- [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) — Piece 3 PostToolUse-validator precedent for "ensure artifact exists" after a planning subagent.
- [Cursor `.cursorrules` empirical test (DEV.to)](https://dev.to/jedrzejdocs/when-cursorrules-fails-why-ai-ignores-your-rules-and-how-to-fix-it-1hk8) — Piece 3 empirical justification: "6 sneaky prompts caught zero violations" validates hooks-over-prose for enforcement.
- [Changesets detailed-explanation](https://github.com/changesets/changesets/blob/main/docs/detailed-explanation.md) — Piece 5 Queue+GC pattern (habeebs-skill already adopted half in v1.20.0).
- [ThoughtWorks Technology Radar FAQ](https://www.thoughtworks.com/radar/faq) — Piece 5 cadence-driven editorial review precedent.
- [MADR](https://adr.github.io/madr/) — Piece 5 single-`date` overwrite anti-pattern that we explicitly improve on via distinct `Last-Reviewed`.

---

## Changelog

- 2026-05-26 — Initial ADR, status Accepted (decisions locked via grill at `docs/agents/specs/v1.22.0-methodology-overhaul-grill.md` § OQ-1 + OQ-2 + OQ-3 + OQ-4). Will be renamed to `NNNN-methodology-bundle-v1.22.md` at v1.22.0 release time by `skills/release/scripts/assign-adr-ids.sh` per ADR-0020 late-binding convention.
