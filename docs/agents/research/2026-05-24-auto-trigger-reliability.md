# Auto-trigger reliability of habeebs-skill descriptions

**Tier:** Balanced — 5 sub-problems, low ambiguity, 3 hard constraints. Brownfield retrofit.
**Date:** 2026-05-24
**Phase 2.5 outcome:** ADDITIONS PROPOSED (2). Accepted #1 (evals), rejected #2 (install-time priming) with reason — folded the first-contact angle into sub-problem 4 instead.

## Executive summary

habeebs-skill descriptions don't auto-invoke because they violate three patterns the rest of the ecosystem converged on: **(1) trigger-first, capability-second** (your descriptions lead with a 30-word capability sentence before the trigger phrase ever appears); **(2) literal user-phrase enumeration in quotes** (your "Make sure to use this skill" lines paraphrase user intent instead of quoting actual user words); **(3) directive imperative mood** ("ALWAYS invoke" / "TRIGGER when" / "You MUST use") which an empirical 650-trial study found beat passive "Use when" by a 20× odds ratio. ADR-0007's 1,200-char budget is *much* larger than what actually fires reliably — Superpowers averages ~120 chars per description; Anthropic's own `pdf` and `docx` are 300-500 chars and fire on a single keyword.

**Recommendation: tighten descriptions to a strict trigger-first template, rename ~8 skills to gerund form, demote chain-internal skills with `disable-model-invocation: true`, and add a CLAUDE.md "## Skill routing table" block that gives the agent an explicit per-task-type mapping at session start.** Tier-0 ADR-0007 is amended, not rewritten — the budget cap remains, the trigger-pattern policy underneath gets replaced.

## Problem

habeebs-skill v1.17.0 ships 18 skills. ADR-0007 mandates "pushy" descriptions (1,200-char hard cap, ≤600-char avg target) with the canonical pattern: `[capability statement]. Make sure to use this skill when [enumerated triggers]. Do NOT use for [anti-triggers].` On the user's natural-language dev tasks ("refactor this", "fix this bug", "add a button"), none of the skills auto-invoke. The user must `/research`, `/grill`, etc. manually. Constraint: preserve the ≤1,200 char budget, preserve `/research` `/grill` etc. slash-command paths, remain standalone per ADR-0002.

## Case studies

### Case 1 — Anthropic `pdf` skill (anthropics/skills) [Tier 1]

500-char description, all imperative: `"Use this skill whenever the user wants to do anything with PDF files. This includes reading or extracting text/tables from PDFs, combining or merging... If the user mentions a .pdf file or asks to produce one, use this skill."` Pattern: **trigger-first command** (`Use this skill whenever the user wants to`), **literal-trigger enumeration** (`mentions a .pdf file`), explicit closing `use this skill` reinforcement. No capability statement before the trigger — the trigger IS the leading sentence. Source: `https://github.com/anthropics/skills/blob/main/skills/pdf/SKILL.md`

### Case 2 — Anthropic `docx` skill (anthropics/skills) [Tier 1]

~750-char description with explicit `Triggers include: any mention of 'Word doc', 'word document', '.docx'` enumeration in quoted user-phrases. Closes with `Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.` Pattern: **trigger-first + literal quoted user-phrases + scoped anti-trigger**. Source: `https://github.com/anthropics/skills/blob/main/skills/docx/SKILL.md`

### Case 3 — Anthropic `claude-api` skill (anthropics/skills) [Tier 1]

Uses all-caps `TRIGGER when:` and `SKIP:` markers with concrete pattern-matchable signals: `code imports anthropic/@anthropic-ai/sdk`, `filename like *-openai.py`. Pattern: **directive markers + machine-detectable conditions** (file content, filename glob, import statement) rather than user-language alone. Highest signal-to-noise observed in the sample. Source: this session's `claude-api` system reminder text.

### Case 4 — Superpowers (`obra/superpowers`) [Tier 2]

15 skills, all **gerund-named** (`brainstorming`, `dispatching-parallel-agents`, `verification-before-completion`, `using-git-worktrees`, etc.). Descriptions are 8-30 words: e.g. `tdd` is `"Use when implementing any feature or bugfix, before writing implementation code"`. The `brainstorming` description leads with `"You MUST use this before any creative work"` — directive imperative. No capability statement; the gerund name carries the capability. Source: `https://github.com/obra/superpowers/tree/main/skills`

### Case 5 — Mattpocock skills (`mattpocock/skills`) [Tier 2]

Engineering skills (`tdd`, `diagnose`, `grill-with-docs`, `to-prd`, `zoom-out`, `triage`). Pattern: **one-sentence capability + `Use when user [says X] / mentions Y / does Z`**. Literal user phrases in quotes: `Use when user says "diagnose this" / "debug this", reports a bug, says something is broken/throwing/failing`. The `zoom-out` skill uses `disable-model-invocation: true` to make it explicit-only — a precedent for chained or context-sensitive skills that shouldn't compete for auto-invocation. Source: `https://github.com/mattpocock/skills/tree/main/skills/engineering`

### Case 6 — Empirical "650 trials" study (Medium, Seleznov 2026) [Tier 4]

A/B-tested three description variants across 650 prompts:
- **Variant A (passive `Use when…`)** — 37% activation under hook pressure, max ~85% bare.
- **Variant B (passive + keyword expansion)** — 81-100% bare, 60% under hook pressure.
- **Variant C (directive `ALWAYS invoke this skill when [triggers]. Do not [alternative] directly`)** — 94-100% activation across all conditions. Cohen's h = 1.83, p < 0.0001. The keyword `keywords` frontmatter field had zero measurable effect. Source: `https://medium.com/@ivan.seleznov1/why-claude-code-skills-dont-activate-and-how-to-fix-it-86f679409af1`

### Case 7 — Agent Engineer Master post on activation failure modes [Tier 4]

Identifies three named failure modes: (1) **missing trigger condition** — capability-only descriptions, (2) **multi-line description YAML truncation** — block scalars discarded after line 1, (3) **trigger-phrase mismatch** — formal language users never type. Recommended pattern: `Triggers when [condition]. Does not trigger for [exclusion]. Returns [output type].` — three-part anatomy in fixed order. Source: `https://agentengineermaster.com/skills/skill-auto-activation-broken-...`

### Case 8 — Internal habeebs-skill ADR-0007 [Tier 0]

Existing policy: ≤1,200 char hard cap, ≤600 avg target, canonical `Make sure to use this skill when [triggers]` pattern. **Anchored on the wrong evidence base.** Cited "Anthropic's 1,536-char hard cap" — the live spec is 1,024 (verified in this run from `platform.claude.com/docs/.../best-practices`). The pushy-trigger preservation rule was correct in spirit but the chosen phrasing (`Make sure to use this skill`) is a *suggestion* the model can override, not the *directive* the 650-trials study found dominant. Source: `docs/agents/adrs/0007-description-budget-policy.md`

## Patterns

Four patterns emerged across the eight cases. They're complementary, not competing — the strongest implementations use multiple at once.

### Pattern A — Trigger-first lede

Open the description with the trigger condition, not the capability. Capability is conveyed by the skill name (especially when it's a gerund). Cases supporting: Superpowers (all 15 skills), Mattpocock (all 11 skills), Anthropic `pdf` and `docx`. The two Anthropic skills that lead with capability (`mcp-builder`, `claude-api`) compensate with a `TRIGGER when:` marker immediately after.

**When this fits:** when the skill name is descriptive enough to be the capability statement. **When it doesn't:** for genuinely novel concepts where the name needs to be paired with a sentence to be parseable — but in habeebs's case, every skill name is meaningful (`socratic-grill`, `decision-record`, `tdd-loop`).

### Pattern B — Literal user-phrase enumeration in quotes

Don't paraphrase user intent — quote it. `Use when user says "diagnose this" / "debug this"`. `Triggers include: any mention of 'Word doc', 'word document', '.docx'`. Cases supporting: Mattpocock (`diagnose`, `tdd`, `triage`), Anthropic `docx`. The fuzzy match scores high when the user's literal words appear in the description.

**When this fits:** always — habeebs descriptions habitually paraphrase (`when implementation starts`, `when a spec has open questions`). The actual user phrasing (`let's build`, `start coding this`, `does this design make sense`) appears nowhere.

### Pattern C — Directive imperative mood

`ALWAYS invoke this skill when [X]` / `TRIGGER when [X]` / `You MUST use this before [X]`. Cases supporting: Anthropic `claude-api` (`TRIGGER when:` / `SKIP:`), Superpowers `brainstorming` (`You MUST use this before any creative work`), empirical 650-trials study (94-100% vs 37%). habeebs's `Make sure to use this skill when` is *almost* imperative but reads as advisory — "make sure to" is hedged compared to "MUST" or "ALWAYS".

**When this fits:** any skill that should pre-empt the agent's default goal-directed behavior. **When it doesn't fit:** standalone primitives where the agent should make a judgment call (e.g., `deep-modules` triggering on every refactor would over-fire). For these, use Pattern A + B without escalating to imperative.

### Pattern D — Explicit-only chained skills via `disable-model-invocation`

Chain links downstream of an entrypoint shouldn't compete for auto-invocation — they should only fire when the upstream skill hands off, or when the user `/explicitly-invokes`. Cases supporting: Mattpocock `zoom-out` (`disable-model-invocation: true`). Inverse anti-pattern: habeebs has 18 skills all auto-invocable but only ~3 are meaningful entry points (`prior-art-research`, `systematic-debugging`, `security-audit`). The other 15 dilute the trigger space.

**When this fits:** every habeebs chain-internal link (`draft-spec`, `socratic-grill`, `decision-record`, `write-plan`, `tdd-loop`, `verify-output`, `release`, `agent-factors-check`, `devex-review`, `vertical-slice`). They run *because* an upstream skill handed off, not because the user said something. Auto-invocation should be off; they remain `/slash-invocable` and HANDOFF-invocable.

### Pattern E — Repo-bound priming via CLAUDE.md / AGENTS.md skill routing table

For brownfield repos with a known skill set, document a routing table in CLAUDE.md that maps task-types to skills. Anthropic best-practices: `name and description in your Skill's metadata are particularly critical. Claude uses these when deciding whether to trigger`. But the *system prompt* (CLAUDE.md) also gets a pass — explicit routing instructions in CLAUDE.md outrank fuzzy-match against 30+ competing skill descriptions. Internal precedent: habeebs's CLAUDE.md already has a `## Agent skills` block (line 88 of `CLAUDE.md`), but it documents *file paths*, not *task-type-to-skill mappings*.

**When this fits:** the user's own repo (where the methodology is the product). **When it doesn't fit:** as a substitute for description quality — if descriptions are bad, the routing table papers over a leak.

## Recommendation for your context

**Three-layer fix, shipping as v1.18.0.**

### Layer 1 — Description rewrite per the converged template (load-bearing)

Replace every SKILL.md description with this exact anatomy, in this exact order:

```
[Capability noun-phrase, ≤8 words]. Use when [literal user trigger phrase 1], [user phrase 2], or [user phrase 3]. Do not use for [tight scoped anti-trigger].
```

Target length: **150-400 chars** (an order of magnitude smaller than today's 528-717 chars). Cap stays at ≤1,200 (ADR-0007 unchanged). Drop the `Make sure to use this skill` phrasing — replace with literal `Use when` for primitives, `ALWAYS use` or `You MUST use` for the three entry points (`prior-art-research`, `systematic-debugging`, `security-audit`).

Concrete rewrites for the three highest-catchment skills:

**`prior-art-research`** (current 662 chars):
> Old: `Research-grounded implementation discovery. Before building any non-trivial feature, find 3-5 production implementations... Make sure to use this skill whenever the user wants to "build", "implement", "design", "architect", or "add" any non-trivial feature...`
>
> New (315 chars): `Research-grounded implementation discovery before building anything non-trivial. ALWAYS use when user says "let's build X", "I want to add Y", "how should I implement Z", "design this", "architect this", or describes a feature with multiple valid approaches. Do not use for trivial CRUD, bug fixes, or single-function utilities.`

**`systematic-debugging`** (current 617 chars):
> Old: `Root-cause debugging via reproduce → minimize → hypothesis-driven probe → fix → regression-test → postmortem... whenever the user reports a bug, a test starts failing, behavior is unexpected, or something "worked yesterday"...`
>
> New (270 chars): `Disciplined root-cause debugging loop. ALWAYS use when user says "this is broken", "fix this bug", "the test is failing", "this worked yesterday", reports unexpected behavior, or describes a performance regression. Do not use when the fix is obvious from a one-line stack trace.`

**`deep-modules`** (current 587 chars, runs at refactor step — not an entry point):
> Old: `Deep-module checker and improver. Identifies shallow modules... Make sure to use this skill at the REFACTOR step of every tdd-loop cycle, periodically as a standalone codebase-health pass, or when the user says "this code feels off" or "too many small files"...`
>
> New (220 chars): `Find and deepen shallow modules using the deletion test. Use when user says "this code feels off", "refactor this", "too many small files", "this abstraction earns nothing", or at the refactor step inside tdd-loop.` (No `ALWAYS` — judgment call.)

### Layer 2 — Demote chain-internal skills with `disable-model-invocation: true`

The 10 skills below are chain-internal: they should only run because an upstream skill handed off OR the user explicitly invoked the slash command. They should NOT compete for auto-invocation:

- `draft-spec`, `socratic-grill`, `decision-record`, `write-plan`, `tdd-loop`, `verify-output`, `release`, `vertical-slice`, `agent-factors-check`, `devex-review`

Adding `disable-model-invocation: true` to each removes them from the auto-trigger pool. They remain user-invocable via `/spec`, `/grill`, etc. (constraint preserved). When a chain-runner skill like `prior-art-research` emits a HANDOFF, the lead invokes the next skill explicitly via `Skill(...)` — same as it does today, no behavior change for the chain itself.

The 5 remaining auto-invocable skills become a clean ENTRY-POINT set:
1. `prior-art-research` — "I want to build X"
2. `systematic-debugging` — "this is broken"
3. `deep-modules` — "refactor this"
4. `security-audit` — "audit this"
5. `parallel-dev` — "do these N things in parallel"

Plus 3 support skills auto-loadable as context, not action:
- `using-habeebs-skill` (chain orientation, auto-loads when any habeebs-skill fires)
- `setup-habeebs-skill` (one-time per-repo bootstrap)
- `using-worktrees` (used by parallel-dev and tdd-loop, primitive)

Net: 8 auto-invocable skills (down from 18) — competing in the fuzzy-match pool at 44% density instead of 100%.

### Layer 3 — CLAUDE.md skill routing table

Add a `## Skill routing` block to CLAUDE.md that the model reads at session start (CLAUDE.md is always in the prompt for an open project). The block gives the model a per-task-type cheat sheet that outranks fuzzy-match competition:

```markdown
## Skill routing

When the user's request matches the LEFT column, invoke the RIGHT skill BEFORE anything else.

| User signal                                          | Skill                  |
|------------------------------------------------------|------------------------|
| "let's build", "implement", "add a feature", "design"| /research              |
| "this is broken", "fix this bug", "test is failing"  | /debug                 |
| "refactor", "this feels off", "clean this up"        | /deepen                |
| "audit this", "security review", "threat model"      | /security-audit        |
| "do these N things in parallel"                      | /parallel              |
| "/research output emitted"                           | /spec then /grill      |
| "spec is locked", "start building"                   | /tdd                   |
| "ready to ship", "cut a release"                     | /release               |

If the request is ambiguous, ASK before picking a path. Do not skip the chain to vibe-code.
```

This is substrate-free (markdown in CLAUDE.md) and complies with ADR-0002. It primes the model with the routing decision before fuzzy-match competition happens.

### Steering reconciliation

- **Anchor "Anthropic guidelines on Skills 2.0 + description fuzzy-match":** Honored — Layer 1 template is lifted from `platform.claude.com/.../best-practices`, including the 1024-char correction, third-person rule, trigger-first guidance, and "build evaluations first" iteration model.
- **Look-at "anthropics/skills repo":** Honored — `pdf`, `docx`, `claude-api`, `skill-creator` patterns directly informed Layer 1 anatomy.
- **Look-at "obra/superpowers":** Honored — Layer 1 gerund-renaming guidance, Layer 2 `disable-model-invocation` for chain-internals, the 8-30 word description target lifted from this source.
- **Look-at "mattpocock/skills":** Honored — Layer 1 literal-user-phrase-in-quotes pattern and the `zoom-out` `disable-model-invocation` precedent (Layer 2) are both Mattpocock-direct lifts.
- **Look-at "Yeachan-Heo/oh-my-claudecode":** Honored implicitly — OMC's CLAUDE.md routing pattern (keyword triggers list in user's global CLAUDE.md) is the precedent for Layer 3. Reaffirmed ADR-0002 by *not* adopting OMC's runtime hooks.
- **Avoid "runtime substrate":** Honored — all three layers are markdown/frontmatter edits. No hooks, MCP, daemons, or session-state. (The Scott Spence post recommends UserPromptSubmit hooks as a workaround; rejected per ADR-0002.)

## Specific decisions to make next

These feed `socratic-grill` and `draft-spec`:

1. **Rename to gerund?** Anthropic recommends gerund; Mattpocock uses imperative-verb; Superpowers uses gerund consistently. Renaming `tdd-loop` → `tdd-looping`, `decision-record` → `recording-decisions`, `draft-spec` → `drafting-specs`, etc. is a *breaking* change for slash-command muscle memory. **Open question:** rename or hold? My lean: hold the existing names (slash-command surface is load-bearing), add the gerund as a fallback if eval data shows undertriggering after Layer 1.

2. **What's the eval harness?** The 650-trials study used scripted prompts → activation rate. We have no equivalent. **Open question:** build a dogfood scenario at `tests/dogfood/11-trigger-activation/` that scripts 30 representative natural-language prompts and asserts which skill the lead invokes, OR ship Layer 1-3 and measure on real sessions via transcript scraping. My lean: dogfood scenario — it's the same shape as the existing 09-category-critic dogfood, and the budget-policy dogfood (`tests/dogfood/10-description-budget/`) per ADR-0007. Codify the activation expectation per skill the same way.

3. **`disable-model-invocation: true` granularity.** Do `agent-factors-check` and `devex-review` (conditional extensions of `socratic-grill`) get demoted? They're not entry points but they ARE skill-decision routers (whether the spec is an agent or a CLI). **Open question:** disable, or keep auto-invocable on the narrow "agent spec"/"CLI spec" signals? My lean: disable. They're invoked *by* socratic-grill, not directly by user signals.

4. **Layer 3 placement.** CLAUDE.md is currently a methodology document — adding a routing table changes its character. **Open question:** add the routing table inline at the top of CLAUDE.md, or split it into `docs/agents/SKILL_ROUTING.md` and reference from CLAUDE.md? My lean: inline at the top. CLAUDE.md is the always-loaded surface; one indirection cuts the routing-table-read in half of sessions.

5. **ADR-0007 amendment.** Layer 1 contradicts the existing `Make sure to use this skill` canonical phrasing. **Decision needed:** does this become ADR-0019 (super-cedes ADR-0007), or an in-place amendment to ADR-0007? My lean: in-place amendment, dated 2026-05-24, marking the cap unchanged but replacing the pushy-trigger preservation rule with the trigger-first/literal-quote/directive-imperative template. The pattern shift is empirical, not architectural — same ADR, refined rule.

6. **Description budget recalibration.** Today's avg is 596 chars. Layer 1 targets 150-400. **Decision needed:** drop the 600-char target to 300, or keep 600 as the loose upper bound and let trim-aggressively land where it lands? My lean: drop target to 300, keep 1,200 as hard cap (still well below Anthropic's 1,024 actual — wait, that's the issue: Anthropic's cap is 1,024, your hard cap is 1,200, you're *over* the spec). **Action item:** drop hard cap to 1,024 to match spec.

## Open questions

- **Does removing `Make sure to use this skill` actually move the needle?** The 650-trials study tested `Use when` (passive) vs `ALWAYS invoke` (directive), not specifically `Make sure to use this skill` (advisory imperative). It's plausible `Make sure to` reads closer to directive than to passive — we have no direct A/B. The Layer 1 dogfood scenario (decision #2) is the only way to know.
- **Is the YAML multi-line truncation bug real for habeebs?** Case 7 claims block-scalar descriptions get truncated at line 1. habeebs descriptions are single quoted strings spanning lines after YAML folding — need to verify the rendered description in the system prompt matches what's in the SKILL.md file. (Spot check: this session's system reminder shows habeebs descriptions in full, so the truncation bug doesn't seem to bite here. But worth a single inspection.)
- **Does ADR-0007's dogfood scenario at `tests/dogfood/10-description-budget/` need updating?** If we drop the target from 600 to 300, the dogfood assertion has to follow.
- **Should `parallel-dev` stay auto-invocable?** It's listed as an entry point but users rarely say "do these in parallel" as the literal phrasing. It's more often invoked *by* habeebs (Phase 2.5 critic dispatch, Deep tier research fan-out). **Open question for grill:** demote with `disable-model-invocation: true`?

## Sources

- [Anthropic — Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — canonical 1024-char cap, third-person rule, "description is critical for skill selection: Claude uses it to choose the right Skill from potentially 100+", evaluation-driven development principle.
- [anthropics/skills (canonical)](https://github.com/anthropics/skills/tree/main/skills) — `pdf`, `docx`, `claude-api`, `skill-creator`, `mcp-builder`, `webapp-testing` frontmatters; trigger-first + literal-keyword + anti-trigger anatomy.
- [obra/superpowers](https://github.com/obra/superpowers/tree/main/skills) — 15-skill plugin demonstrating consistent gerund naming, 8-30 word descriptions, `Use when [scenario]` trigger-first lede.
- [mattpocock/skills (engineering subset)](https://github.com/mattpocock/skills/tree/main/skills/engineering) — `tdd`, `diagnose`, `grill-with-docs`, `to-prd`, `zoom-out`, `triage`; literal-user-phrase-in-quotes pattern + `disable-model-invocation` precedent.
- [Seleznov — Why Claude Code skills don't activate (650 trials)](https://medium.com/@ivan.seleznov1/why-claude-code-skills-dont-activate-and-how-to-fix-it-86f679409af1) — empirical A/B: directive imperative + negative-constraint = 94-100% activation; passive `Use when` alone = 37-87%. Cohen's h = 1.83.
- [Agent Engineer Master — Skill auto-activation broken](https://agentengineermaster.com/skills/skill-auto-activation-broken-why-your-claude-code-skill-works-via-slash-command-but-never-fires-automatically) — three failure modes (missing trigger, multi-line truncation, phrase mismatch); `Triggers when X. Does not trigger for Y. Returns Z.` three-part anatomy.
- [Spence — Claude Code skills don't auto-activate (workaround)](https://scottspence.com/posts/claude-code-skills-dont-auto-activate) — diagnoses imperative-vs-suggestion gap; recommends UserPromptSubmit hooks (rejected here per ADR-0002).
- [GitHub issue anthropics/claude-code#11266](https://github.com/anthropics/claude-code/issues/11266) — confirms discovery (not activation) is broken only for `~/.claude/skills/` user skills; plugin-installed skills like habeebs are discovered correctly, so the issue is purely activation. Closed as duplicate, no fix shipped.
- [ADR-0007 — Adopt a description budget policy](../adrs/0007-description-budget-policy.md) — Tier 0 internal precedent; provides the cap-and-target framework that Layer 1 amends in-place.

---

HANDOFF: spec ready — invoke `draft-spec` to turn this into an implementation spec. Source: `docs/agents/research/2026-05-24-auto-trigger-reliability.md`.
HANDOFF: grill ready — invoke `socratic-grill` to drive ambiguity out of the 6 decisions-to-make-next and 4 open questions above.
HANDOFF: record ready — once spec + grill complete, invoke `decision-record` to capture the rewritten description-pattern policy as an ADR-0007 amendment (or supersession ADR-0019, per decision #5).
