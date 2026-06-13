# SYSTEM_CONTEXT

**Last refreshed:** 2026-06-13
**Refreshed by:** full-repo audit pass (hand reconciliation per the template's "edit by hand whenever it's wrong" rule; not a Phase 0 run — the next `prior-art-research` Phase 0 remains the canonical automated writer per ADR-0005). Counts reconciled to disk: 19 skills, 28 ADRs (24 integer + 4 dated), v1.26.0 current, 6 hooks, 23 glossary concepts, 4 dispatch records.
**Schema:** per ADR-0010 — non-re-derivable cross-session state only. Re-derivable sections (Stack / Deployment / Hot files / Tracked manifests) excluded.

## Scale envelope

- **Users (MAU / DAU):** [unknown — public OSS, install count untracked]
- **Skill count:** 19 in tree (v1.14.0 added `security-audit`, `release`, `devex-review`; v1.18.0 added `cross-session-detect`).
- **Chain depth:** 7 core links (research → spec → grill → record → plan → tdd → release); `verify-output` gates each tdd-loop commit (not a separate link). `agent-factors-check` and `devex-review` are conditional extensions of grill. `security-audit` is a standalone slash-invokable skill. 5 primitives (parallel-dev, deep-modules, vertical-slice, using-worktrees, systematic-debugging) + 2 meta (using-habeebs-skill, setup-habeebs-skill) + cross-session-detect. Every chain run executes at a depth tier — Quick / Balanced / Deep (ADR-0016).
- **ADR count:** 28 — two-era naming scheme LIVE: 24 frozen integer ADRs (0001-0024) + 4 dated ADRs (`2026-05-28-decouple-decision-identity-from-releases.md` shipped v1.23.0; `2026-06-01-chain-fidelity-executable-assertions.md` shipped v1.24.0; `2026-06-09-add-regrill-edge-and-grill-alignment-axes.md` shipped v1.25.0; `2026-06-10-loop-harness-fresh-context-outer-loop.md` shipped v1.26.0). New ADRs are dated `YYYY-MM-DD-<slug>.md` at creation; old integers frozen, never renamed; new↔old cross-refs by title+markdown-link. Recent batch: ADR-0022 (behavioral-only SKILL.md body, shipped v1.21.0), ADR-0023 (v1.22.0 methodology bundle), ADR-0024 (plugin supply-chain threat model — deferred hardening), 2026-05-28-decouple-decision-identity (dated artifact naming; FULLY supersedes ADR-0020's late-binding-ID half, RE-STATES its Changesets half as in-force, shipped v1.23.0), 2026-06-01-chain-fidelity-executable-assertions (SP2 archaeology lint + SP3 fixture-ID rule + SP4 supersession check, shipped v1.24.0) + ADR-0003 Rule 4 in-place amendment (resolve-from-target hook predicate, v1.24.0).
- **Current release:** v1.26.0 (loop harness — fresh-context-per-slice outer loop with failure-triage and tiered halt policy; ADR `2026-06-10-loop-harness-fresh-context-outer-loop`). Preceded by v1.25.0 (Grill 2.0 — slice-shape 8th ambiguity axis + first-class re-grill edge + mental-model probes; ADR `2026-06-09-add-regrill-edge-and-grill-alignment-axes`) and v1.24.0 (chain-fidelity hardening — scenarios 34-36 executable assertions + ADR-0003 Rule 4 amendment).
- **Dogfood scenario count:** ~44 (baselines 01-08 + suites 09-44; v1.25.0 added 37-39, v1.26.0 added 40-44). NOTE: scenario-number collisions exist (two `19-*`, two `20-*`) — flagged for renumbering. The v1.22.0 chain-state-validator (scenario 29) and the cross-session peer-scan hooks were repaired in the 2026-06-13 audit to emit `hookSpecificOutput.additionalContext` (prior versions emitted output the harness silently dropped); their suites now pass.
- **Hook count:** 6 .sh on disk: session-start.sh (ghost-commit-detect), session-start-peer-scan.sh, preventing-commits-to-default.sh (PreToolUse[Bash] block-only; v1.23.0 resolves branch from command target dir, not hook cwd), pretool-use-peer-scan.sh (PreToolUse[Edit|Write|NotebookEdit]), check-chain-state.sh (PostToolUse warn-only validator, v1.22.0), pre-push.sh (dormant). All conform to ADR-0003 (warn-only or block-only, stateless, multi-harness aware).

## Methodology / agent setup

- **habeebs-skill configured:** Yes — `setup-habeebs-skill` run on 2026-05-13 (v1.8.0 slice 3 dogfood); v1.10.0 release self-dogfooded.
- **Issue tracker:** GitHub Issues (`docs/agents/issue-tracker.md`)
- **Triage labels:** Canonical 5 (`docs/agents/triage-labels.md`)
- **Domain glossary:** Populated — 23 concepts (`docs/agents/GLOSSARY.md`). Methodology-specific vocabulary.
- **Latest ADR:** `2026-06-10-loop-harness-fresh-context-outer-loop` (shipped v1.26.0). Recent dated ADRs: `2026-06-09-add-regrill-edge-and-grill-alignment-axes` (v1.25.0); `2026-06-01-chain-fidelity-executable-assertions` (v1.24.0); `2026-05-28-decouple-decision-identity-from-releases` (v1.23.0). Last integer ADR: ADR-0024 (plugin supply-chain threat model, deferred hardening). See `docs/agents/adrs/README.md` for the full index.
- **Postmortem directory:** `docs/agents/postmortems/` (per ADR-0011). One retrospective: 2026-05-12 missed-architectural-categories.
- **Dispatch record directory:** `docs/agents/dispatches/` — 4 records (`disp-v1230-2a`, `disp-v1240-1a`, `disp-v1260-1a`, `disp-v1260-2a`). The dormant-carve-out from ADR-0021 is now populated by `parallel-dev` Phase 7.5; this is a runtime writer path, not an authored dir.
- **Conflicts directory:** `docs/agents/conflicts/` — EMPTY (0 files) as of 2026-05-26. Same dormant-carve-out status as dispatches/.
- **Research archive directory:** `docs/agents/research/` — 5 files (2 v1.X.Y named + 3 dated YYYY-MM-DD-slug). Per ADR-0018 Part B / ADR-0016 tier-conditional fire rule: Deep REQUIRED, Balanced OPTIONAL, Quick SKIPPED.
- **Session-summary template:** `skills/using-habeebs-skill/references/session-summary-template.md` (introduced in v1.10.0 per ADR-0012; relocated 2026-05-22 from `docs/agents/templates/` per ADR-0009's 3-consumer threshold). Used by the Compress-at-overflow protocol documented in `using-habeebs-skill` § "When sessions grow long".

## Notable absences

(Things you'd expect but didn't find. Inferential — often more valuable than what's there.)

- No CI/CD — releases are manual (`gh release create` after PR merge).
- No formal release notes outside `CHANGELOG.md`.
- No external install-count telemetry — public install number is unobservable.
- No active runtime substrate — ADR-0002 forbids MCP / daemons / observation logs / session-state directories.
- No automated postmortem cadence — postmortems are an event-driven manual convention (per ADR-0011 Q1 hybrid resolution); v1.11.0 promotion candidate.
- No active Compress-at-overflow skill — passive doc only (per ADR-0012 Q4 resolution); v1.11.0 promotion candidate if 3+ postmortems show context-distraction failure mode.
- Codex / Cursor / OpenCode treatment of `docs/agents/*.md` is informally verified (no harness reserves the path) but not externally confirmed via harness documentation.

## Project mode

- **brownfield, methodology-mature** — habeebs-skill v1.26.0 is current on `main`. Recent release line: v1.22.0 (methodology overhaul — plain-English plans, HITL pivot, PostToolUse validator); v1.23.0 (dated artifact naming); v1.24.0 (chain-fidelity executable assertions); v1.25.0 (Grill 2.0 — slice-shape axis + re-grill edge + mental-model probes); v1.26.0 (loop harness — fresh-context outer loop). v1.13.0 intentionally skipped (gstack spec staggered, shipped as v1.14.0). Self-dogfooded every cycle.

## Active steering

(none — flushed 2026-05-26 per `prior-art-research` Phase 7 flush rule at end of v1.22.0 methodology-overhaul research run; last outcome below)

## Last reconciliation outcome

**2026-06-09 — topic: Grill 2.0 full-workflow alignment upgrade (v1.25.0 candidate) — Balanced-tier, 5 sub-problems**

- Anchor "peer methodology gates": Honored — KEP (no-backward-edge negative example, issue #2960), Rust RFC amendment cap, superpowers executing-plans halt rule, Shape Up betting table all load-bearing.
- Anchor "requirements-elicitation / shared-mental-model": Honored — Example Mapping + premortem (Klein/HBR) + one-way/two-way doors are the SP3 backbone.
- Anchor "agentic re-plan loops": Honored with override — anchor implies autonomous re-planning; convergent evidence (superpowers hard prohibition, Anthropic fresh-context-restart rule) says halt-to-human with structured re-grill instead.
- Look-at internal grill records: Honored — 12 records mined (not the 5 estimated at invocation); 9/12 contain ad-hoc slice-shape grilling; v1.20.0 PT-4 is the proof-case; all 3 mental-model misses were caught late by user pushback.
- Avoid "runtime substrate": Honored — all three amendments are markdown + existing 4-status vocabulary.
- Phase 2.5 critic: ADDITIONS PROPOSED (3) — accepted SP4 (risk-proportional ceremony scaling) + SP5 (concurrent-slice halt semantics); rejected SP6 (template-contract evolution) with reason (grill records are write-once, never re-parsed; consumers ship same release).
- Phase 6 HITL pivot OUTCOME: Modie approved as-is → `/spec`. Sub-decisions (axis-vs-phase placement, suggested_action-vs-5th-status, amendment boundary, sibling-halt default, probe record section, extension re-fire) deferred to `/grill`.
- Verdict: three markdown-only amendments — slice-shape 8th ambiguity axis; first-class re-grill edge (`suggested_action: "re-grill"` on BLOCKED, forward-step in fresh context, dated back-linked grill record, fail-fast sibling scope rule with salvage); three indirect mental-model probes tier-scaled in count (Quick 1 / Balanced 2 / Deep 3). Archive: `docs/agents/research/2026-06-09-grill-2.0-alignment-research.md`.

**2026-06-01 — topic: habeebs-skill self-enhancement (v1.24.0 chain-fidelity hardening) — Balanced-tier, 5 sub-problems, no steering**

- No steering anchors supplied (scope locked via Phase 1 questions: all six candidates researched, one tight v1.24.0 cut requested).
- Phase 2.5 critic: ADDITIONS PROPOSED (2) — false-positive blast radius + gate-interaction-vs-36-scenario-suite; both accepted, folded into one SP5 ("gate hardening = corpus-test-before-block discipline, not a feature"). Agent-product category declined by critic with reason (owned downstream by agent-factors-check/devex-review).
- 6 candidates → 5 sub-problems: SP1 resolve-from-target hooks (#2+#4), SP2 archaeology-prose lint (#5), SP3 live-tree fixture-ID confirmation (#3), SP4 supersession-link integrity (#6+#1), SP5 gate-hardening discipline.
- Key external findings: claude-code #36556 (WorktreeCreate `worktree_path` vs `cwd` conflation — first-party confirmation the cwd-vs-target bug is a recognized class; closed not-planned) + pre-commit #808 + mise #4853 = Pattern A "resolve-from-target." Vale/GitLab = tense-linting prior art for SP2 but runtime tool (ADR-0002 keeps us bash-only). Semgrep `pattern-not` + corpus-test-before-enable = SP5 discipline. log4brains/adr-tools = supersession is "link but don't validate" → SP4 integrity check is an ecosystem gap (mildly novel).
- Tier note: auto-detect scored 2 (Balanced); shipping-speed-drop-to-Quick guard NOT applied because 5 sub-problems exceed Quick's single-sub-problem ceiling — held at Balanced (heuristic-not-hard-gate).
- Phase 6 HITL pivot OUTCOME: Modie approved as-is → `/spec`. Sub-decisions (exact SP2 regex + warn-vs-block, SP4 scope, SP1 amend-in-place-vs-new-ADR, whether one dated ADR covers the bundle) deferred to `/grill`.
- Verdict: v1.24.0 = SP2+SP3+SP4 executable-assertion bundle (each extends an existing ADR: 0022 body-lint family / spec-plan conventions / release doc-sync) + one-paragraph ADR-0003 "Rule 4 resolve-from-target" amendment (code already shipped v1.23.0 at `349bba4`). SP5 ships as discipline; #1 runtime-lag demotes to README line + tdd-loop Phase 0 note. Rejected: general Vale/CI prose linter (ADR-0002). Archive: `docs/agents/research/2026-06-01-v1.24.0-chain-fidelity-hardening-research.md`.

**2026-05-28 — topic: dated artifact naming vs. release-driven late-binding integers (v1.23.0 candidate) — Deep-tier, 5 sub-problems**

- Look-at "obra/superpowers": Honored — dates plans/specs (`YYYY-MM-DD-<slug>.md`, mandated verbatim) but keeps ZERO ADRs; informs the spec/plan half, not a dated-ADR precedent.
- Look-at "AWS Kiro": Honored with override — investigated as requested, found to be a COUNTER-example (slug dirs `.kiro/specs/<slug>/{requirements,design,tasks}.md`, no dates, no ADRs). Recommendation does not follow Kiro; reported plainly.
- Look-at "similar methodologies": Honored — github/spec-kit (sequential `001-`), log4brains + Shopware (production dated ADRs), Rust RFCs (number-at-merge=PR#) all surfaced.
- Anchor "dated / YYYY-MM-DD": Honored with caveat — adopted, but evidence forced the refinement that the SLUG (not the bare date) is the collision-uniqueness key; bare `YYYY-MM-DD` is provably collision-prone under parallel sessions (MADR #28 verbatim).
- Avoid "re-introduce parallel-session collisions": Honored — hence `date+slug`; flagged same-day rule for grill.
- Avoid "runtime substrate": Honored — all changes markdown + script DELETIONS; nothing added.
- **Key finding: ADR-0020's "zero canonical endorsement for date-prefix ADR naming" is OVERSTATED.** log4brains defaults to dated ADR filenames and documents the exact merge-collision rationale ADR-0020 dismissed. Prior research missed this counterexample.
- Phase 2.5 critic: ADDITIONS PROPOSED (2), both accepted — #1 machinery-teardown → SP5; #2 dogfood-28 self-consistency → folded into SP4.
- Machinery disposition (SP5): mechanism #1 (ADR late-binding) separates CLEANLY from mechanism #2 (Changesets version bumps) — share the release coordinator but no code/state. DELETE assign-adr-ids.sh + release Phase 3.5 + dogfood 21; EDIT decision-record + dogfood 28; changeset machinery (aggregate-changesets.sh, dogfood 22/23/25, .changeset/*) UNTOUCHED.
- Phase 6 HITL pivot OUTCOME: Modie approved as-is → `/spec`. Sub-decisions (same-day rule, cross-ref style, version-in-frontmatter traceability) deferred to `/grill`.
- Verdict: write ADRs/specs/plans/grill-records as `YYYY-MM-DD-<slug>.md` AT CREATION (slug = uniqueness key); kill release-rename; freeze 24 existing integer ADRs (zero broken cross-refs across ~117 files). New ADR partially supersedes ADR-0020 (late-binding-ID half only). Archive: `docs/agents/research/2026-05-28-v1.23.0-dated-artifact-naming-research.md`.

**2026-05-26 — topic: habeebs-skill v1.22.0 methodology overhaul — 7-strand Deep-tier research dogfooding the early-HITL-pivot pattern**

- Anchor "spec-driven development": Honored — KEP `provisional` state + superpowers design sign-off + PEP pre-spec gate all surfaced; Piece 2 (HITL pivot between Phase 6 synthesize and 6.5 archive) lands the canonical pattern.
- Anchor "RFC process": Honored — Rust RFC, Python PEP, Kubernetes KEP, Backstage BEP all in SP3 source set; 4 of 5 peer methodologies gate BEFORE spec is written, validating Modie's stated pain.
- Anchor "design-doc patterns": Honored with caveat — Increment + Pragmatic Engineer were the design-doc industry sources; thin compared to language-RFC sources. Re-research with internal-tooling-spec dominant set is a future trigger.
- Anchor "claude-code hooks": Honored — Anthropic docs + 4 peer plugins + 1 community defensive bundle (slavaspitsyn). SP2 + SP6 both anchored here.
- Anchor "agent chain enforcement": Honored with override — anchor implies *prescriptive* enforcement; evidence shows *advisory* enforcement is peer norm (Cursor `.cursorrules` empirical test: caught 0 violations against 6 sneaky prompts). Piece 3 (warn-only PostToolUse validator) follows evidence over anchor.
- Look-at "obra/superpowers": Honored — primary peer; informed SP1 (plans), SP2 (hooks), SP3 (HITL), SP5 (in-flight branch survival).
- Look-at "mattpocock/skills": Honored with caveat — ships zero plans, zero hooks; useful as canonical floor, not as positive pattern.
- Look-at "anthropics/skills + anthropics/claude-code-plugins": Honored — canonical floor (zero plans, no threat-model docs). The absence IS the finding for SP6.
- Look-at "Backstage ADRs": Honored — BEPs (Backstage's RFC equivalent) were the closest structural peer to habeebs-skill's plan format AND hit the exact same in-flight-branch problem (solved via manual reclassification gate, adopted as Piece 5 (SP5)).
- Avoid "marketing posts": Honored — Anthropic plugins blog flagged marketing-tone-high, used only for absence-of-security-framing finding.
- Avoid "substrate-coupled tools": Honored — all 5 pieces are markdown-only; no MCP/daemon adoption.
- Phase 2.5 critic outcome: ADDITIONS PROPOSED, 3 of 3 accepted (SP5 mid-flight branch survival, SP6 plugin supply-chain, SP7 markdown-only telemetry). One open-set rejection with reason (rollback granularity — folded into SP3 HITL placement). One brief-candidate modify (session-state hygiene → folded into SP5).
- Pattern-extractor returned DONE with 8 converging patterns, 6 competing-pattern picks resolved with reasons, 6 silent contradictions surfaced + resolved, 6 homogeneity-bias flags acknowledged (notably git-hooks ecosystem absent from SP2; solo-author OSS precedent absent from SP3; Markdown-graph dormancy absent from SP4).
- Phase 6 HITL pivot OUTCOME: Modie accepted as-is (5-piece bundle + Piece 6 deferred-hardening ADR), validated gate placement, picked in-place re-amendment for ADR-0021, deferred Piece 3 validator scope to `/grill`. Gate caught one real ambiguity AND validated three convergent picks — net evidence the gate fires at the right grain.
- Verdict: v1.22.0 bundle (Piece 1 plain-English plans + Piece 2 HITL pivot + Piece 3 PostToolUse validator + Piece 4 delete dormant dirs / re-amend ADR-0021 + Piece 5 markdown-only telemetry frontmatter) + Piece 6 deferred-hardening supply-chain ADR. Archive: `docs/agents/research/2026-05-26-v1.22.0-methodology-overhaul-research.md`.

**2026-05-25 — topic: habeebs-skill v1.18.0 workflow audit vs Anthropic + AI startups + canonical ADR + parallel-agent tooling (audit-only, no code changes)**

- Anchor "Anthropic Skills best-practices": Honored with caveat — anthropics/skills has zero methodology folders; audit recommends shrinking habeebs-skill from 9 to 6 subdirs (not to 0); habeebs-skill is methodology-as-product, different category.
- Anchor "Skills 2.0 conventions": Honored — skill file shapes match; no recommended changes beyond parallel-dev bifurcation by task class.
- Anchor "Cognition don't-build-multi-agents": Honored — bifurcating parallel-dev (read-OK at 15× tokens per Anthropic; write-RESTRICTED per Cognition) is the compatible compromise; pure adherence (delete parallel-dev) rejected because read-task usage is Anthropic-validated.
- Anchor "Nygard ADR canon": Honored — tombstone + immutable path + forward-pointer adopted from Nygard via MADR + Fowler; Backstage late-binding ID is a Nygard-compatible extension.
- Look-at "Claude Code parallel features": Honored — Claude Code issue #25768 (EBUSY on global `~/.claude.json`) validates v1.18.0 per-repo sidecar choice; KEEP AS-IS verdict on v1.18.0.
- Look-at "Cursor, Devin, Aider, Cline": Honored — Cursor's 8-cap + JSON sidecar is the closest peer to v1.18.0 (validates the shape; habeebs-skill's pre-tool peer-scan + pre-push gate is novel beyond Cursor's visibility-only sidecar).
- Look-at "Spotify ADR, GitHub ADR": Honored — Backstage (Spotify) is the primary case study and the only canonical source with explicit parallel-writer guidance. joelparkerhenderson (GitHub) named as slug-only alternative.
- Look-at "Vercel/Replit": Honored with caveat — Vercel cited via Changesets adoption; Replit not separately sampled (no public ADR/conflict material). Not material because Changesets and Backstage cover the same pattern shape.
- Avoid "runtime substrate": Honored — all recommendations are markdown/JSON only (append-only intent files, tombstone ADRs, folder pruning, skill-content edits).
- Avoid "re-litigating chain shape": Honored — audit accepts the chain (prior-art-research → spec → grill → record → plan → tdd); recommendations are scoped to taxonomy + identifier-strategy + skill-positioning.
- Phase 2.5 critic outcome: ADDITIONS PROPOSED, 3 of 3 accepted (chain-usage telemetry → SP2; cost ceilings → SP3 with scope-narrowing; deprecation patterns → SP2). One open-set rejection with reason (skill-catalog discoverability — search would re-fetch same SP3 sources).
- Pattern-extractor returned DONE_WITH_CONCERNS with 2 tier-narrow flags (dormancy detection, cost ceilings); both resolved without re-fan-out because enterprise contract-testing requires runtime substrate ADR-0002 forbids and FinOps tools control dollar-spend not chain-ceremony cost (already covered by ADR-0016).
- Verdict: v1.18.0 cross-session detection is canonically correct and KEEP AS-IS; single highest-leverage change is adopting Changesets-shape append-only intent files for version bumps + Backstage late-binding for ADR IDs; recommend deleting dormant `dispatches/` + `conflicts/` and folding `grill-records/` + `research/` into `specs/` (3 tombstone ADRs needed). Archive: `docs/agents/research/v1.19.0-workflow-audit-research.md`. NO auto-trigger to draft-spec per user request — research-only run.
- Prompt-injection report: None detected across 6 source-fetcher dispatches.
- **Audit finding NOT in main report:** SYSTEM_CONTEXT.md said "ADR count: 18" but disk has 20 ADRs (0019 added 2026-05-22 + the post-v1.18.0 state). ADR-0005 single-writer invariant either was violated or Phase 0 missed an update. ADR-count text in this file should be updated to 20 by the next prior-art-research Phase 0 run (this run is the writer per ADR-0005, but the count update is one-line and orthogonal to the audit verdicts).

**2026-05-13 (afternoon) — topic: habeebs-skill alignment audit vs Anthropic + practitioner + OpenAI + Google + LangChain (v1.10.0 candidate, full sweep)**

- Anchor "Anthropic guidelines": Honored — Skills 2.0 + Claude Code best-practices + Effective harnesses for long-running agents all weighed.
- Anchor "Claude developers' guidelines": Honored — Anthropic is the canonical Claude-developer voice for this audit lens; peer plugin authors (Superpowers, mattpocock, OMC) already covered in this morning's reconciliation.
- Anchor "AI personalities' guidance": Honored selectively — Hamel Husain + Shreya Shankar delivered the load-bearing eval thesis; Walden Yan (Cognition) delivered the canonical chain-anti-pattern. Simon Willison, swyx, Sean Grove probed and downranked.
- Anchor "enhance Claude's natural capabilities": Honored with refinement — Anthropic's prune test applies to *contents inside scaffolding*, not whether scaffolding should exist (Google ADK / OpenAI Agents SDK both endorse scaffolding shape).
- Anchor "Phase 0 / know-the-codebase-first": Overridden with caveat — Anthropic best-practices excludes within-session codebase recon scaffolding; defensible residue is the cross-session sub-set (R1 refined: shrink contents per ADR-0010, not eliminate the phase).
- Look-at "OpenAI / Google / LangChain context engineering": Honored — OpenAI validates HANDOFF as primitive; Google ADK validates workflow-scaffolding-as-first-class; LangChain's 4-move framework (Write/Select/Compress/Isolate) is the dominant new lens (surfaced R5 Compress-at-overflow gap).
- Look-at "Hamel Husain + Shreya Shankar": Honored — error-analysis-before-infrastructure thesis drives ADR-0011.
- Avoid "runtime substrate": Honored — all 5 recommendations are markdown/JSON only.
- Avoid "re-litigating ADR-0002": Honored.
- Phase 2.5 critic outcome: ADDITIONS PROPOSED, 5 of 6 accepted (folded into existing 4 sub-problems), 1 rejected with reason (cultural fit — redundant).
- Prompt-injection report: 3 fabricated `<system-reminder>` tags in fetched HTML (developers.googleblog.com, adk.dev, code.claude.com); all ignored per ADR-0004 amendment Part 5 (codified in this release).
- Verdict: chain shape vendor-validated (Google ADK Workflow Agents is closest analog); contents-level pruning needed (ADR-0010); operational gap on real-trace evals (ADR-0011) + Compress-at-overflow (ADR-0012) confirmed and closed.

**2026-05-13 (morning) — topic: habeebs-skill ecosystem audit — Anthropic best-practices + Superpowers + mattpocock + OMC + claude-mem (v1.9.0 candidate)**

- Anchor "Anthropic Skills 2.0 / progressive disclosure / SKILL.md frontmatter": Honored — habeebs-skill matches Anthropic-canonical 3-level model; all 14 descriptions under the 1,536-char cap (max 946); all SKILL.md under 500-line cap (max 379).
- Look-at "obra/superpowers": Honored — examined; habeebs-skill is stricter on chain integrity (HANDOFF lines, Phase 0/2.5 ceremony), looser on SKILL.md inline density. Superpowers uses sibling-file refs vs habeebs's `references/` subdir (Anthropic-canonical).
- Look-at "mattpocock/skills": Honored — examined; habeebs's claim of "consolidated and re-sequenced mattpocock's patterns into a chain" verified accurate.
- Look-at "Yeachan-Heo/oh-my-claudecode": Honored — examined as contrast; ADR-0002 runtime-composition rejection reaffirmed. `verify-output` adopted (post-impl quality gap) and `/abort-chain` convention adopted (chain-abort UX gap) WITHOUT runtime coupling.
- Look-at "thedotmack/claude-mem": Honored with caveat — observation-memory pain is real but runtime substrate (SQLite+Chroma+MCP) rejection holds.
- Avoid "re-litigating ADR-0002 composition rejection": Honored.
- Verdict: aligned on speed (Phase 0 cache + bounded iteration), aligned on token-efficiency basics, but with 20-30% description verbosity overhead. Recommended v1.9.0 bundle: description-trim ~25%, remove unrecognized `next-skills` frontmatter, add `verify-output` skill, add `/abort-chain` convention, widen GLOSSARY.md consumption. **Shipped v1.9.0 same day.**

**2026-05-13 — topic: reconcile CONTEXT.md (setup) vs SYSTEM_CONTEXT.md (Phase 0) — v1.8.0 candidate**

- Anchor "mattpocock/skills bootstrap": Honored — setup-writes-only-user-answered-bits adopted as the v1.8.0 contract.
- Anchor "obra/superpowers project-context": Honored with caveat — auto-trigger philosophy adopted for runtime, but explicit setup retained because user-answered config (tracker, labels) cannot be re-derived.
- Anchor "ADR community on context-doc separation": Honored — Nygard's decision-local-context principle anchors the lifecycle-split (rename CONTEXT.md → GLOSSARY.md).
- Anchor "DDD ubiquitous-language vs context-map": Honored — Evans/Vernon lifecycle-split rationale lifted verbatim.
- Look-at "Rails upgrade guide": Honored — `bin/rails app:update` + one-minor deprecation window lifted into the `migrate-v1.8` skill design.
- Avoid "runtime substrate / vector stores / session-state directories": Honored.
- Phase 2.5 critic outcome: APPROVED with one addition (sub-problem 5 — migration path for shipped repos). Critic-driven coverage prevented the synthesizer from picking ESLint-style external-migrator.
- Prompt-injection report: Sub-problems 3 and 5 source-fetchers reported injected `<system-reminder>` tags in fetched web content; both correctly ignored.

**2026-05-12 — topic: parallel subagent processing across the chain (v1.6.0 → v1.7.0 candidate)**

- Anchor "Superpowers subagent-driven-development": Honored — 4-status return contract + controller-implementer-reviewer triad adopted.
- Anchor "Anthropic multi-agent research system": Honored — lead-agent + N-subagent fan-out, role specs, scaling rules foundational.
- Avoid "(runtime substrate constraint explicitly relaxed)": Honored — blackboard and Temporal still rejected, but on cost/benefit grounds. ADR-0002 carve-out for `docs/agents/dispatches/` (in-repo artifact, not runtime daemon).
- Coverage-failure framing: validated — Phase 2 category-completeness critic (recommendation 1) was the single highest-leverage fix.

**2026-05-12 — topic: post-merge cleanup / squash-merge ghost-commit pain (v1.5.3)**

- Anchor "squash-merge recovery": Honored (with new rule) — gap in both Superpowers and habeebs-skill; filled by `using-worktrees` Phase 6.5 + `/sync` command.
- Avoid "runtime substrate": Honored — Phase 6.5 is markdown + git commands only.

**2026-05-11 — topic: environment binding / greenfield-vs-brownfield (v1.5.0 + v1.5.2)**

- Anchor "state persistence shape": Honored — in-repo markdown is the convergent pattern; ADR-0001.
- Anchor "multi-runtime portability": Honored — SYSTEM_CONTEXT.md is harness-agnostic markdown.
- Look-at "Superpowers (obra)": Honored — plan-files-as-markdown precedent matches.
- Look-at "oh-my-claudecode (Yeachan-Heo)": Overridden — wrong layer; runtime substrate, not project-fact substrate; ADR-0002 locks the rejection of composition.
- Look-at "mattpocock/skills": Honored — independent convergence on in-repo markdown + setup-bootstrap pattern.
