# SYSTEM_CONTEXT

**Last refreshed:** 2026-05-25
**Refreshed by:** prior-art-research Phase 0 + Phase 7 (v1.18.0 workflow audit run). ADR count corrected 18→20 (0019 was missed by the prior v1.17.0 refresh). Steering reconciliation appended below. Canonical writer per ADR-0005 single-writer invariant.
**Schema:** per ADR-0010 — non-re-derivable cross-session state only. Dropped sections (Stack / Persistence / Deployment shape / External services / Recent hot files / Open / unknown / Tracked manifests) are re-derivable from `package.json`, git, and imports on fresh invocation per Anthropic's Claude Code best-practices ❌ Exclude rule.

## Scale envelope

- **Users (MAU / DAU):** [unknown — public OSS, install count untracked]
- **Skill count:** 18 in tree (15 pre-v1.14.0; v1.14.0 added `security-audit`, `release`, `devex-review` per ADR-0014).
- **Chain depth:** 8 core (research → spec → grill → record → plan → tdd → verify-output → release). `agent-factors-check` and `devex-review` are conditional extensions of grill. `security-audit` is a standalone slash-invokable skill (ADR-0014). 5 primitives (parallel-dev, deep-modules, vertical-slice, using-worktrees, systematic-debugging) + 2 meta (using-habeebs-skill, setup-habeebs-skill). Every chain run executes at a depth tier — Quick / Balanced / Deep (ADR-0016; canonical reference `docs/agents/references/tier-scale.md`). `chain-postmortem` is a section in `using-habeebs-skill` (post-incident error-analysis, complementary to verify-output's pre-commit static check, per ADR-0011).
- **ADR count:** 20 (0001-0019 + README). ADR-0001 amended by 0006 + scope-narrowed by 0010. ADR-0002 amended by 0019 (advisory in-flight reads carve-out for cross-session conflict detection). ADR-0003 amended by 0015 (tag-only-push carve-out). ADR-0004 amended in place 2026-05-13 (Part 3 share-full-traces clause + Part 5 untrusted-content rule); Part 2 writer implemented by ADR-0018. ADR-0013 (research-context-gate) extended by ADR-0016 (chain-wide depth tier). ADR-0012 amended in place 2026-05-22 (template path relocation).
- **Current release:** v1.18.0 (cross-session conflict detection — 16 slices, 170 test assertions). New tracked directory: `docs/agents/conflicts/` (audit logs). New runtime directory: `$(git rev-parse --git-common-dir)/habeebs-sessions/` (session sidecars, auto-gitignored inside `.git/`).

## Methodology / agent setup

- **habeebs-skill configured:** Yes — `setup-habeebs-skill` run on 2026-05-13 (v1.8.0 slice 3 dogfood); v1.10.0 release self-dogfooded.
- **Issue tracker:** GitHub Issues (`docs/agents/issue-tracker.md`)
- **Triage labels:** Canonical 5 (`docs/agents/triage-labels.md`)
- **Domain glossary:** Populated — 13 concepts (`docs/agents/GLOSSARY.md`). Methodology-specific vocabulary.
- **Latest ADR:** ADR-0018 (`implement-dormant-artifact-recording-contracts`, Accepted 2026-05-22). Recent batch — ADR-0017 (`semantic-repo-discovery-port`, Accepted 2026-05-22, shipped v1.16.0); ADR-0016 (`chain-wide-depth-tier`, Accepted 2026-05-19, shipped v1.15.0); ADR-0014 (gstack capability adoption) + ADR-0015 (hook tag-push carve-out) Accepted 2026-05-18, shipped v1.14.0.
- **Postmortem directory:** `docs/agents/postmortems/` (new in v1.10.0 per ADR-0011). One retrospective entry to date (2026-05-12 missed-architectural-categories).
- **Dispatch record directory:** `docs/agents/dispatches/` (location declared by ADR-0004 Part 2 in v1.7.0; writer implemented by ADR-0018 Part A — `parallel-dev` Phase 7.5). Schema: `skills/parallel-dev/references/dispatch-record-template.md` § Section 4.
- **Research archive directory:** `docs/agents/research/` (Deep-tier convention established by ADR-0018 Part B — `prior-art-research` Phase 6.5 writes the Phase 6 report verbatim; tier-conditional per ADR-0016).
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

- **brownfield** — habeebs-skill v1.15.0 is current on `main`. Release line since v1.12.0: v1.14.0 (gstack capability adoption — `security-audit` / `release` / `devex-review` skills, ADR-0014/0015) and v1.15.0 (chain-wide depth tiers, ADR-0016), both shipped 2026-05-18/19. The v1.13.0 number is intentionally skipped (gstack spec staggered v1.13.0+v1.14.0 but shipped all slices as v1.14.0). Methodology is mature.

## Active steering

(none — flushed 2026-05-13 per `prior-art-research` Phase 7 flush rule at end of v1.10.0 research run; last outcome below)

## Last reconciliation outcome

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
