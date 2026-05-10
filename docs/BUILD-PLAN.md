# habeebs-skill — Build Plan

Tracking the multi-phase build. Each phase is a chunk that should fit in one focused conversation turn.

## Phase 1 — Skeleton + foundation skill ✅ (DONE)

- [x] Plugin directory structure
- [x] `.claude-plugin/plugin.json` manifest
- [x] `README.md`
- [x] `CLAUDE.md` (agent-facing instructions)
- [x] `skills/prior-art-research/SKILL.md` (the foundational skill — complete)
- [x] `skills/prior-art-research/references/source-tiers.md`
- [x] `skills/prior-art-research/references/output-template.md`
- [x] `skills/prior-art-research/references/extraction-checklist.md`
- [x] `skills/using-habeebs-skill/SKILL.md` (the intro)
- [x] Placeholders for remaining 8 skills
- [x] `tests/evals/prior-art-research.evals.json` (8 complex test prompts with assertions)
- [x] `commands/research.md` + `commands/groundwork.md`

## Phase 2 — Core chain skills ✅ (DONE)

- [x] `skills/draft-spec/SKILL.md` — full content
- [x] `skills/draft-spec/references/spec-template.md`
- [x] `skills/socratic-grill/SKILL.md` — full content
- [x] `skills/socratic-grill/references/ambiguity-axes.md`
- [x] `skills/socratic-grill/references/grill-output-template.md`
- [x] `skills/decision-record/SKILL.md` — full content
- [x] `skills/decision-record/references/adr-template.md`
- [x] `commands/spec.md`, `commands/grill.md`, `commands/record.md`
- [x] Eval prompts for each of the three skills (`tests/evals/phase-2.evals.json`)
- [x] Phase 2 chain test executed end-to-end: 29/29 = 100% pass rate

## Phase 3 — Engineering primitives ✅ (DONE)

- [x] `skills/tdd-loop/SKILL.md` — full content (red-green-refactor with vertical-slice integration)
- [x] `skills/tdd-loop/references/test-seam-guide.md`
- [x] `skills/deep-modules/SKILL.md` — full content (Ousterhout principles + deletion test)
- [x] `skills/deep-modules/references/LANGUAGE.md` — architectural vocabulary
- [x] `skills/parallel-dev/SKILL.md` — full content (independence verification + dispatch)
- [x] `skills/parallel-dev/references/dispatch-record-template.md`
- [x] `skills/vertical-slice/SKILL.md` — full content (HITL/AFK decomposition)
- [x] `skills/vertical-slice/references/hitl-vs-afk.md`
- [x] Commands: `/tdd`, `/deepen`, `/parallel`, `/slice`
- [ ] Eval prompts for each (deferred — could test integration with the chain in Phase 5)
- [ ] `agents/source-fetcher.md` (subagent prompt for research fetching) — deferred
- [ ] `agents/pattern-extractor.md` — deferred
- [ ] `agents/synthesizer.md` — deferred

## Phase 4 — Meta + setup ✅ (DONE)

- [x] `skills/setup-habeebs-skill/SKILL.md` — full content
- [x] `skills/setup-habeebs-skill/references/issue-tracker-github.md`
- [x] `skills/setup-habeebs-skill/references/issue-tracker-linear.md`
- [x] `skills/setup-habeebs-skill/references/issue-tracker-local.md`
- [x] `skills/setup-habeebs-skill/references/triage-labels.md`
- [x] `skills/setup-habeebs-skill/references/domain.md`
- [x] `agents/source-fetcher.md`
- [x] `agents/pattern-extractor.md`
- [x] `agents/synthesizer.md`
- [x] Phase 4 test executed: 7/7 = 100%

## Phase 5 — v1.0 finalization ✅ (DONE)

- [x] plugin.json bumped to v1.0.0
- [x] CHANGELOG.md written
- [x] README.md updated to v1.0 status
- [x] Final bundle

## Phase 5 — Eval harness execution

- [ ] Run `prior-art-research` against all 8 eval prompts (in this sandbox)
- [ ] Grade outputs against assertions
- [ ] Identify failure patterns
- [ ] Iterate on skill prose
- [ ] Repeat until eval pass rate >80%
- [ ] Do the same for spec / grill / record once they're written
- [ ] Document eval results in `docs/eval-results.md`

## Phase 6 — Package + deliver

- [ ] Final pass on README and CLAUDE.md
- [ ] Validate plugin.json
- [ ] Optional: write `scripts/package_plugin.py` (similar to skill-creator's)
- [ ] Bundle as .skill or zip
- [ ] Present to user

## Optional Phase 7 — Publish

- [ ] Create marketplace.json
- [ ] Push to a GitHub repo
- [ ] Test install via `/plugin marketplace add` + `/plugin install`

---

## Decisions deferred

- Whether `parallel-dev` should integrate with OMC's `/team` or Superpowers' `subagent-driven-development` natively, vs. just dispatch independently
- Whether `decision-record` writes to a fixed path or asks the user where ADRs live (probably the latter — handled by `setup-habeebs-skill`)
- Whether to support `--quick` and `--deep` flags on the command interface, or only via natural-language hints
- Whether `setup-habeebs-skill` should attempt to auto-detect existing CONTEXT.md or always re-bootstrap
