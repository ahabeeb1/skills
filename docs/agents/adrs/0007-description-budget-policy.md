# ADR-0007: Adopt a description budget policy — 1,200-char hard cap, 600-char target, three-keystone protected anti-triggers, `## Origins` body convention for credits

**Status:** Accepted (amended 2026-05-24 — see "## 2026-05-24 Amendment" below for the v1.18.0 anatomy + auto-invocation-scope rules that supersede specific clauses of the original Decision)
**Date:** 2026-05-13
**Deciders:** ahabeeb1
**Tier:** Balanced (amendment grilled at Balanced; original ADR predates the tier convention)

## Context

The Claude Code Skills 2.0 spec imposes a **1,536-character hard cap** on each skill's `description` (combined with `when_to_use`) in the always-loaded skill-listing budget. Beyond the cap, descriptions are truncated mid-string, stripping the trigger keywords that typically appear later in habeebs-skill's "Make sure to use this skill when…" pattern. The skill-listing budget defaults to **1% of the context window**, so all 14 skill descriptions live in the prompt on every turn.

The 2026-05-13 ecosystem alignment audit measured habeebs-skill description lengths: max 946 chars (`prior-art-research`), avg 785 chars across 14 skills, ~11,000 chars total per skill listing. All descriptions are under the 1,536-char hard cap — but the audit identified ~20-30% verbosity that adds no trigger value:

- "Inspired by Superpowers/OMC/mattpocock" credits embedded in descriptions (acknowledgments, not triggers)
- Verbose "Do NOT use for X, Y, Z, A, B, C" anti-trigger enumerations beyond the 2-3 highest-precision cases
- Restatements of the capability already covered by the opening capability statement

At the same time, **Anthropic's own guidance explicitly recommends "pushy" descriptions** to combat undertriggering — capability statement followed by enumerated "Use when X, Y, or Z" patterns, plus anti-trigger clauses. The audit also surfaced that three habeebs-skill skills — `prior-art-research`, `socratic-grill`, `tdd-loop` — have the widest catchment (they trigger on common user phrases like "I want to build" / hedging language / "let's start coding") and would *over-trigger* without robust anti-trigger lists.

This ADR establishes the description-budget policy that balances pushy-triggering against per-turn token economy, and codifies it for all future skill authoring.

## Decision

We will adopt the following description budget policy across all habeebs-skill SKILL.md files (existing 14 and any future skills):

- **Hard ceiling:** ≤1,200 characters per `description` field. (Well below Anthropic's 1,536-char cap to leave headroom for any future framing additions.)
- **Target average:** ≤600 characters across all skills in the plugin. (Currently 785; trim recovers ~500-800 tokens per turn.)
- **Pushy-trigger preservation:** Every description must contain the phrase "Make sure to use this skill" (or equivalent imperative) followed by enumerated trigger phrases. Anthropic's guidance on combating undertriggering is honored as canonical.
- **Three keystone skills retain ≥2 anti-trigger bullets:** `prior-art-research`, `socratic-grill`, `tdd-loop`. These have the widest catchment and the highest cost of over-triggering. The 11 other skills condense anti-triggers to ≤1 line or remove if redundant with the capability statement.
- **`## Origins` body convention for credits:** Acknowledgments ("Inspired by X" / "Lifted from X") move out of frontmatter descriptions and into a `## Origins` section near the bottom of the SKILL.md body, after `## See also` and before any final `HANDOFF` block. Phrasing distinguishes "Inspired by" (loose parallel evolution) from "Lifted from" (direct borrowing, e.g., Ousterhout's deep-modules, Pocock's vertical-slice).

A dogfood scenario at `tests/dogfood/10-description-budget/` enforces the hard cap and target average automatically.

The policy is anchored by ADR-0001's load-bearing-protocol principle: skill descriptions are part of the always-loaded contract every chain invocation pays for, so they get budgeted accordingly.

## Consequences

### Positive

- Recovers ~500-800 tokens of always-loaded budget per turn (description-trim across 14 skills) — meaningful at 1% skill-listing budget today, increasingly meaningful as skill count grows.
- Brings descriptions structurally closer to Anthropic's canonical "capability + Use when + Do NOT use" pattern documented in `anthropics/skills/skill-creator`.
- The `## Origins` convention preserves transparent attribution (which mattered for `tdd-loop`/Pocock TDD, `vertical-slice`/Pocock tracer-bullets, `parallel-dev`/Superpowers subagent-driven-development) without paying a per-turn token tax for it.
- Three-keystone protected-anti-trigger rule is empirically grounded — these three skills have the widest user-phrase catchment and would over-fire otherwise.
- Dogfood scenario adds CI-style budget enforcement; future skill authoring can't accidentally drift past the cap.

### Negative / Accepted trade-offs

- Trimming descriptions risks losing a trigger keyword that was empirically catching some marginal user phrasing. Mitigated by preserving "Make sure to use this skill" + enumerated triggers across the board; the cuts target anti-triggers and acknowledgments, not the pushy core.
- The 600-char *target* is an average, not a hard cap — individual descriptions may exceed it (e.g., the three keystones plus any new high-catchment skills). The 1,200-char hard cap is the only mechanically enforced rule.
- The `## Origins` convention adds a body section to ~6-8 SKILL.md files that didn't have one. Small surface; small reading cost only when the SKILL.md actually triggers.
- One-way door for v1.9.0: if a future Claude Code model gets dramatically better at trigger inference, the pushy descriptions become wasted budget — but loosening is cheap (re-trim further), tightening would require this whole ADR again.

### Operational impact

- Slice 1 of v1.9.0 owns the bulk of the trim. New skills authored after v1.9.0 must pass `tests/dogfood/10-description-budget/` to merge.
- Documentation update: `skills/setup-habeebs-skill/SKILL.md` should reference this ADR when explaining the convention for future authors.
- `verify-output` (slice 3 of v1.9.0) — the first skill authored under this policy — must comply at creation time.

## Alternatives considered

### Trim only to Anthropic's 1,536-char hard cap

Match Anthropic's spec, no tighter. **Rejected** because 1,536 still leaves us paying ~22% of the 1% skill-listing budget for verbose anti-trigger enumerations and credits. The audit showed real waste below the spec ceiling.

### Move descriptions to file headers, keep frontmatter minimal

Use `name`-only frontmatter (like raw mattpocock style) and put the description in the SKILL.md body. **Rejected** — Anthropic's harness needs the description in frontmatter to make selection decisions; moving it out of metadata would silently break trigger discovery.

### Uniform anti-trigger trim across all 14 skills

Treat every skill identically. **Rejected** because three skills have demonstrably wider catchment and over-trigger without robust anti-trigger lists — empirically, "Do NOT use for trivial CRUD" in `prior-art-research` has prevented chain invocation on small tasks; that line is load-bearing.

### Per-skill description budget tuning (no global rule)

Let each SKILL.md set its own length. **Rejected** because skill authoring drifts without a global rule. The 1,200/600 numbers are defensible (well below Anthropic's cap; honors the audit's recovered-token target); a per-skill regime would re-create the problem v1.9.0 is fixing.

## Revisit triggers

This ADR should be reopened if any of:

- **Claude Code raises or removes the 1,536-char description cap.** The hard ceiling tracks the spec; re-evaluate if Anthropic loosens it.
- **Skill count grows past 20.** The always-loaded skill-listing budget approaches 5% of context window; the 600-char target should drop further (e.g., 400-500).
- **A model with materially better trigger inference ships.** If Claude trigger discovery improves to where pushy enumerations are no longer needed, descriptions can trim further.
- **The three-keystone list changes.** If a fourth skill is added that has the same wide-catchment problem, expand the protected anti-trigger list explicitly.
- **The dogfood budget assertion produces a sustained false positive rate.** Re-tune or remove the automatic enforcement if it becomes brittle.

## References

- Research: `docs/agents/SYSTEM_CONTEXT.md` § Last reconciliation outcome (2026-05-13 — habeebs-skill ecosystem audit)
- Spec: `docs/agents/specs/v1.9.0-ecosystem-alignment.md` (Slice 1)
- Grill: `docs/agents/specs/v1.9.0-ecosystem-alignment-grill.md` (Items 1, 2)
- Related: [ADR-0001](./0001-environment-binding-via-system-context.md) (skill descriptions are part of the always-loaded protocol surface)
- External sources:
  - [Claude Code Skills docs](https://code.claude.com/docs/en/skills) — 1,536-char cap, 1% skill-listing budget
  - [Anthropic Engineering — Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) — three-level progressive disclosure
  - [anthropics/skills skill-creator](https://github.com/anthropics/skills) — canonical pushy-description pattern

---

## Changelog

- 2026-05-13 — Initial ADR, status Accepted (decision locked by user's v1.9.0 scope approval)
- 2026-05-24 — Amended in place for v1.18.0 auto-trigger reliability. See "## 2026-05-24 Amendment" section below. Original Decision clauses superseded: (1) the 1,200-char hard cap drops to 1,024 to match Anthropic's actual spec, (2) the 600-char target average drops to 300, (3) the "Make sure to use this skill" canonical phrasing is replaced with the trigger-first / literal-quote / directive-imperative template, (4) chain-internal skills now carry `disable-model-invocation: true` so only 7 skills compete for auto-invocation. The three-keystone-anti-trigger rule and the `## Origins` body convention are unchanged.

---

## 2026-05-24 Amendment — v1.18.0 auto-trigger reliability

### Why this amendment

Empirical signal collected between 2026-05-13 (v1.9.0 ship) and 2026-05-24 contradicts two anchoring assumptions of the original ADR:

1. **Anthropic's actual `description` hard cap is 1,024 characters, not 1,536.** Verified at `platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices` (2026-05-24 fetch). The 1,536 number cited in the original Context section is from an earlier doc version; the live spec is lower. habeebs's 1,200 hard cap is therefore *over* the spec, not under it.

2. **The "Make sure to use this skill when…" phrasing reads as advisory, not directive.** The 650-trials empirical study (Seleznov, 2026) measured directive imperatives (`ALWAYS invoke this skill when X. Do not Y directly`) at 94-100% activation vs passive `Use when…` at 37-87% (Cohen's h = 1.83, p < 0.0001). `Make sure to use this skill` sits between the two — closer to directive than passive but never tested A/B against pure-directive variants. Real-session observation by the maintainer between v1.9.0 and v1.17.0: descriptions show up in `<system-reminder>` listings correctly (discovery works), but skills do *not* auto-fire on natural-language dev prompts ("refactor this", "add a feature", "fix this bug"). The user has to type `/research`, `/grill`, etc. manually.

Additionally, the original ADR treated all 14 (now 18) skills as equally entitled to auto-invocation. In practice, only the chain *entry points* fire on user language; downstream chain links (`draft-spec`, `socratic-grill`, `decision-record`, etc.) fire on upstream HANDOFF or explicit `/slash`. With 18 skills auto-invocable and 135 SKILL.md files installed system-wide, the fuzzy-match pool dilutes the entry points that should win.

The v1.18.0 audit confirmed the existing trigger-precision dogfood (scenario 13) reports 34/34 (100%) on a synthetic corpus — yet real sessions don't fire. That gap is exactly Hamel Husain's "synthetic prompts approach 100% by construction" red flag (`hamel.dev/blog/posts/evals-faq/`). The amendment fixes the description policy AND the eval methodology.

### Amended Decision

We will adopt the following amended description policy across all habeebs-skill SKILL.md files (existing 18 and any future skills):

#### A. Length budget (supersedes original Decision bullets 1 + 2)

- **Hard ceiling:** ≤**1,024** characters per `description` field. Matches Anthropic's actual spec verbatim; no implicit headroom (Anthropic enforces the cap on their end).
- **Target average:** ≤**300** characters across all skills in the plugin. (At v1.17.0 the avg is 596 chars; trim recovers ~5,300 tokens of always-loaded budget over 18 skills.)

#### B. Description anatomy (supersedes original Decision bullet 3 — "Pushy-trigger preservation")

Every description must follow this anatomy, in this exact order:

```
[Capability noun-phrase, ≤8 words]. [Imperative directive] when [literal user trigger phrase 1], [phrase 2], or [phrase 3]. [Tight scoped anti-trigger].
```

Specifically:

- **Capability lead** is a noun-phrase fragment ≤8 words. Title-case skill names already convey capability; this lead is a one-line elaboration, not a paragraph.
- **Imperative directive** is one of: `ALWAYS use` (highest-leverage entry points only — `prior-art-research`, `systematic-debugging`, `deep-modules`), `You MUST use` (reserved as the v1.19.0 fallback variant if v1.18.0 lift falls short of the success metric), or `Use when` (primitives where judgment-call firing is desired, e.g., `parallel-dev`). The legacy `Make sure to use this skill` phrasing is forbidden going forward.
- **Literal user trigger phrases** must appear in straight quotes (`"..."`), at least 2 per description. Quotes are how the fuzzy-match scorer locates user-language alignment. Paraphrased trigger conditions ("when the user reports a bug") are insufficient — must be `"this is broken"`, `"fix this bug"`, `"the test is failing"`.
- **Anti-trigger** is one tight, scoped clause. The three-keystone rule below preserves the ≥2-anti-trigger requirement for high-catchment skills; everything else gets one line or zero.

#### C. Auto-invocation scope — chain-internal skills get `disable-model-invocation: true` (new clause)

The Skills 2.0 frontmatter field `disable-model-invocation: true` makes a skill **user-invocable only** (via `/slash-command` or explicit `Skill(...)` dispatch from another skill). It does NOT remove the skill from the registry or break the slash-command surface.

We will set `disable-model-invocation: true` on the 11 chain-internal skills:

- `draft-spec`, `socratic-grill`, `decision-record`, `write-plan`, `tdd-loop`, `verify-output`, `release`, `vertical-slice`, `parallel-dev`, `agent-factors-check`, `devex-review`

Rationale per skill class:
- `draft-spec` / `socratic-grill` / `decision-record` / `write-plan` / `tdd-loop` / `verify-output` / `release` / `vertical-slice` — fire on upstream HANDOFF emitted by a predecessor chain skill, never on raw user language.
- `parallel-dev` — 3 internal callers (`prior-art-research` Phase 2.5 + Phase 4 Deep, `tdd-loop` AFK orchestration, `write-plan` parallelization-map consumer) vs 1 user-direct surface (`/parallel`). The math favors chain-internal.
- `agent-factors-check` and `devex-review` — sub-skill-invoked by `socratic-grill` Phase 1 (conditional extensions); no realistic user phrasing fires them solo.

The remaining 7 skills stay auto-invocable: **4 entry points** (`prior-art-research`, `systematic-debugging`, `deep-modules`, `security-audit`) and **3 support meta** (`using-habeebs-skill`, `setup-habeebs-skill`, `using-worktrees`).

#### D. Routing primer in CLAUDE.md (new clause)

We will add a `## Skill routing` block to `CLAUDE.md` near the top (after `## The chain`, before `## Triggering principles`). The block contains a Markdown table mapping user-signal phrases to slash-commands for the 4 entry-point skills plus the chain-handoff transitions (research→spec/grill, spec→tdd, tdd→release). The block closes with an "if ambiguous, ASK before picking a path" sentence.

The routing primer is **inline in CLAUDE.md**, not split to a separate file. CLAUDE.md is always-loaded in this repo; the always-loaded budget cost (~250-400 tokens per turn) is justified by routing being available at decision time. Splitting to `docs/agents/SKILL_ROUTING.md` becomes the revisit path if CLAUDE.md grows past 200 lines (Anthropic-recommended ceiling for system-prompt density).

#### E. Three-keystone anti-trigger rule (unchanged in spirit, updated keystone list)

The original three keystones were `prior-art-research`, `socratic-grill`, `tdd-loop`. Post-amendment, `socratic-grill` and `tdd-loop` are `disable-model-invocation: true` and therefore no longer compete for auto-invocation — they cannot over-trigger. The new keystone-anti-trigger list tracks the auto-invocable entry points with the widest catchment:

- `prior-art-research`, `systematic-debugging`, `deep-modules`

Each retains ≥2 anti-trigger clauses; `security-audit` is narrower (literal "audit" / "security review" trigger language) and operates with one anti-trigger.

#### F. `## Origins` body convention (unchanged)

Acknowledgments ("Inspired by X" / "Lifted from X") continue to live in `## Origins` body sections, not in frontmatter descriptions.

### Amended Consequences

#### Positive (additive to original ADR)

- Recovers ~5,300 additional tokens of always-loaded budget per turn (avg trim 596 → 300 across 18 skills). Combined with the v1.9.0 trim (which dropped avg from 785 → 596), total recovery from baseline is ~8,700 tokens — meaningful at the 1% skill-listing budget.
- 7 auto-invocable skills instead of 18 reduces fuzzy-match collision in the prompt-injection-resistant skill-listing surface.
- Routing primer in CLAUDE.md provides explicit task-type → skill mapping the agent reads at session start (CLAUDE.md is always-loaded), outranking fuzzy-match against 30+ competing skill descriptions.
- ADR-0007 now reflects empirically-verified Anthropic spec cap (1,024), removing the discrepancy with the live docs.

#### Negative / Accepted trade-offs (additive)

- Per-skill trigger-keyword density drops sharply. Today's 528-717 char descriptions enumerate 5-10 trigger phrases each; the 150-400 char target preserves only 2-4 literal user-phrases. The bet is that 3 well-chosen literal phrases beat 8 paraphrased ones (consistent with the 650-trials Variant B finding: keyword accumulation alone doesn't fix passive framing).
- `disable-model-invocation: true` removes 11 skills from any auto-`/help`-style discovery surface. Mitigation: the `using-habeebs-skill` skill (still auto-invocable as context) introduces the full chain on the first relevant trigger.
- Routing block costs ~250-400 tokens of CLAUDE.md always-loaded budget. Revisit if CLAUDE.md grows past 200 lines.
- The v1.18.0 rewrite is a soft one-way door: rollback means re-editing 18 SKILL.md descriptions back to v1.17.0 wording. The v1.19.0 fallback path is deliberately *forward* — a third imperative variant (`You MUST use this skill when…`) — not a revert, so we collect a third data point on the imperative gradient instead of losing directionality.

#### Operational impact (additive)

- Dogfood scenario 11 (`tests/dogfood/11-description-budget/check-description-budget.sh`) updates: `HARD_CAP=1024`, `TARGET_AVG=300`, expanded trigger regex `(use when|always use|you must use|trigger (on|when))`, new check that every description contains ≥1 straight-quoted literal user phrase, new block-scalar-rejection assertion guarding against the YAML-truncation bug documented in research Case 7.
- Dogfood scenario 13 (`tests/dogfood/13-trigger-precision/`) — synthetic-corpus precision check — remains alive as a "regression baseline" through v1.20.0. After 2 quarters of dual-tracking against the new real-session transcript eval, sunset if real-eval consistently outperforms.
- New methodology doc at `docs/agents/references/trigger-firing-eval.md` codifies the real-session transcript eval cadence, scoring rubric, and idempotency rule.
- **v1.18.0 success metric (load-bearing for v1.19.0 follow-up):** (sessions with `"build"` / `"add"` / `"refactor"` / `"fix this"` / `"design"` / `"implement"` in the user prompt AND the matched entry-point skill fires within 2 turns) / (all sessions with those keywords), measured pre-release and +30 days post-release. **>10 percentage-point lift = success.** If <10pp, file v1.19.0 candidate with the `You MUST use this skill when…` variant.

### Amended Alternatives considered

(Original alternatives in the ADR still apply for the length-budget portion. The amendment surfaces new alternatives for the anatomy and scope changes:)

#### Keep `Make sure to use this skill` phrasing pending Slice 6 transcript-eval baseline

Defer the rewrite. Measure firing-rate on current descriptions first via the new transcript eval, *then* decide if the rewrite is warranted. **Rejected** because the maintainer's lived experience between v1.9.0 and v1.17.0 already constitutes the baseline measurement (qualitative but consistent: skills don't auto-fire on natural-language dev prompts). Waiting another quarter to confirm what's already observed delays the fix without new information.

#### Rewrite to gerund names instead of changing anatomy

Anthropic recommends gerund naming (`processing-pdfs`, `writing-skills`). habeebs uses mostly noun-phrases (`prior-art-research`, `decision-record`). Renaming would force the gerund convention. **Rejected** for v1.18.0 because slash-command surface (`/research`, `/grill`, `/spec`) is load-bearing muscle memory for the maintainer; renaming breaks invocations that exist outside the agent's view (terminal history, scripts, docs). Deferred to v1.19.0 candidate if Layer 1 alone fails to hit the 10pp lift threshold.

#### Use `keywords` frontmatter field instead of trigger-phrase enumeration in description

Anthropic's SKILL.md supports a `keywords` field. **Rejected** per the 650-trials study finding: the `keywords` field has *zero measurable effect on activation rates*. The activation signal is the description body itself.

#### Split ADR-0007 amendment into a new ADR-0019

Create a separate `0019-trigger-anatomy-and-auto-invocation-scope.md` and mark ADR-0007 as partially-superseded. **Rejected** because the policy story belongs in one place — anyone reading "the description policy" should find both the budget rule and the anatomy rule in the same file. ADR-0007's original Decision bullets are individually superseded, not architecturally replaced; in-place amendment with a clear date-stamped section preserves the historical record while making the current rule authoritative.

### Amended Revisit triggers

(Original revisit triggers still apply, plus:)

- **Post-release transcript eval at +30 days shows <10pp firing-rate lift.** Open v1.19.0 with the `You MUST use this skill when…` variant. NOT a revert — the goal is three data points on the imperative gradient.
- **CLAUDE.md grows past 200 lines.** Split routing primer to `docs/agents/SKILL_ROUTING.md`.
- **Anthropic ships a description-cap change.** Track the spec; update `HARD_CAP` in dogfood 11.
- **A future Claude Code build exposes skill-firing telemetry.** Replace the manual transcript-review cadence with the telemetry source.
- **2 consecutive quarters of transcript eval show persistent undertriggering on 3+ skills.** Promote the gerund-renaming alternative to v1.20.0 candidate.

### References (amendment)

- Research: `docs/agents/research/2026-05-24-auto-trigger-reliability.md`
- Spec: `docs/agents/specs/v1.18.0-auto-trigger-reliability.md`
- Grill: `docs/agents/specs/v1.18.0-auto-trigger-reliability-grill.md`
- External sources:
  - [Anthropic — Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — canonical 1,024-char cap, third-person rule, evaluation-driven development principle
  - [anthropics/skills repo](https://github.com/anthropics/skills/tree/main/skills) — `pdf`, `docx`, `claude-api`, `skill-creator` description anatomy
  - [obra/superpowers skills](https://github.com/obra/superpowers/tree/main/skills) — gerund naming convention, 8-30 word descriptions, `Use when` trigger-first lede
  - [mattpocock/skills engineering](https://github.com/mattpocock/skills/tree/main/skills/engineering) — literal-user-phrase-in-quotes pattern, `disable-model-invocation` precedent
  - [Seleznov — Why Claude Code skills don't activate (650 trials)](https://medium.com/@ivan.seleznov1/why-claude-code-skills-dont-activate-and-how-to-fix-it-86f679409af1) — directive imperative 94-100% vs passive 37-87% (Cohen's h = 1.83)
  - [Hamel Husain — Evals FAQ](https://hamel.dev/blog/posts/evals-faq/) — "synthetic prompts approach 100% by construction" red flag, error-analysis-before-infrastructure thesis
- Related ADRs:
  - [ADR-0001](./0001-environment-binding-via-system-context.md) — load-bearing-protocol principle (descriptions are part of the always-loaded contract)
  - [ADR-0011](./0011-error-analysis-cadence.md) — error-analysis-first evals cadence (Husain thesis applied to the real-session transcript eval methodology)
  - [ADR-0016](./0016-chain-wide-depth-tier.md) — chain-wide depth tier (this amendment was grilled at Balanced)
