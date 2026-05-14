# Trigger-Precision Audit — 2026-05-13

**Auditor:** Claude (Opus 4.7), reading each `skills/*/SKILL.md` frontmatter `description:` field independently and matching against the [corpus](./corpus.md) per the methodology in [README.md](./README.md).
**Scope:** 30 prompts (15 happy-path + 15 adversarial/boundary) × 15 skills = 450 description-prompt matches.
**Audit method:** Manual reading exercise (no automation per Hamel's anti-eval-driven-development thesis). For each prompt, the auditor identified which skill description's "trigger when X" / "Make sure to use this skill whenever Y" language matched most strongly.

## Headline result

**27 / 30 correct (90%).** Happy-path: 15/15 (100%). Adversarial: 12/15 (80%). Hamel's "100% pass rate is a red flag" threshold not hit — the 3 adversarial misses represent real precision risks worth fixing in v1.11.0, not synthetic-corpus artifacts.

| Cohort | Prompts | Correct | Score |
|---|---|---|---|
| Happy-path (P01–P15) | 15 | 15 | 100% |
| Adversarial — vague (P16–P19) | 4 | 3 | 75% |
| Adversarial — wrong-skill-bait (P20–P23) | 4 | 3 | 75% |
| Adversarial — multi-skill-applicable (P24–P27) | 4 | 3 | 75% |
| Adversarial — edge cases (P28–P30) | 3 | 3 | 100% |
| **Total** | **30** | **27** | **90%** |

## Per-prompt results

Format: `id | expected | actual | match? | note`. Actual = the skill whose description language matched most strongly when read independently.

### Happy-path (15/15)

| ID | Expected | Actual | Match? | Note |
|---|---|---|---|---|
| P01 | prior-art-research | prior-art-research | ✓ | "build... vague idea but no concrete approach" — verbatim |
| P02 | draft-spec | draft-spec | ✓ | "research recommendation and need to convert" — verbatim |
| P03 | socratic-grill | socratic-grill | ✓ | "we'll figure it out later" + open questions — verbatim |
| P04 | decision-record | decision-record | ✓ | "lock this in" — verbatim |
| P05 | write-plan | write-plan | ✓ | "locked ADR" + "3+ slices" + "acceptance gates" — all match |
| P06 | tdd-loop | tdd-loop | ✓ | "let's start building" + "implement slice N" — verbatim |
| P07 | parallel-dev | parallel-dev | ✓ | "independent work units" + "dispatch in parallel" — verbatim |
| P08 | vertical-slice | vertical-slice | ✓ | "break this down" + "HITL or AFK" — verbatim |
| P09 | deep-modules | deep-modules | ✓ | "this code feels off" + "too many small files" — verbatim |
| P10 | using-worktrees | using-worktrees | ✓ | "start a new feature" + "isolated branch + worktree" — verbatim |
| P11 | systematic-debugging | systematic-debugging | ✓ | "worked yesterday, fails today" + "three times" — verbatim |
| P12 | verify-output | verify-output | ✓ | "scan the diff" + "before commit" — verbatim |
| P13 | agent-factors-check | agent-factors-check | ✓ | "LLM... agent" + "12-factor-agents lens" — verbatim |
| P14 | setup-habeebs-skill | setup-habeebs-skill | ✓ | "Just cloned" + "Set up the methodology" — direct |
| P15 | using-habeebs-skill | using-habeebs-skill | ✓ | "Walk me through" + "chain" — direct meta-trigger |

### Adversarial — vague (3/4)

| ID | Expected | Actual | Match? | Note |
|---|---|---|---|---|
| P16 | `[no-skill]` | prior-art-research | ✗ | **FP for prior-art-research.** "I want to add something useful" — the "add" keyword + "vague idea" clause of the description combine to over-trigger. The description's anti-trigger ("trivial CRUD") doesn't disambiguate "something useful" because nothing in the prompt names triviality. **Flagged for v1.11.0 description tuning.** |
| P17 | `[no-skill]` | `[no-skill]` | ✓ | "Make this better" matched no description strongly. `deep-modules` "feels off" is the nearest, but "better" doesn't imply any symptom. Correctly defers. |
| P18 | `deep-modules` OR `[no-skill]` | deep-modules | ✓ | Acceptable per corpus rationale; bare "refactor" matched deep-modules with low confidence. Auditor notes: deep-modules description could be sharpened to require a *symptom* keyword (feels off / too many / shallow); for v1.11.0+ tuning consideration. |
| P19 | `[no-skill]` | `[no-skill]` | ✓ | "I have an idea" — no skill match. Correctly defers. |

### Adversarial — wrong-skill-bait (3/4)

| ID | Expected | Actual | Match? | Note |
|---|---|---|---|---|
| P20 | systematic-debugging | systematic-debugging | ✓ | "Research how to fix this stale-cache bug" — `prior-art-research`'s anti-trigger ("Do NOT use for ... bug fixes with known causes") correctly excludes; `systematic-debugging`'s primary trigger ("bug fixes... behavior is unexpected") wins. Anti-trigger language is load-bearing here — bare description without it would FP. |
| P21 | prior-art-research | prior-art-research | ✓ | "Plan and implement a new dashboard feature" — `write-plan`'s "ADR exists yet" requirement correctly excludes; `prior-art-research` "non-trivial feature... no concrete approach" wins. Charitably read; the word "plan" is bait. |
| P22 | socratic-grill | verify-output | ✗ | **FP for verify-output.** "I need to verify this design before we commit to it" — the word "verify" + "before commit" matches `verify-output`'s description verbatim. `verify-output`'s anti-trigger ("Pre-implementation review (that's socratic-grill)") *exists* but is buried at line 4 of the anti-trigger list; the primary description language wins on first match. **Flagged for v1.11.0 description tuning.** Suggested fix: move "Pre-implementation review" anti-trigger earlier; or add positive trigger language to socratic-grill referencing "verify this design". |
| P23 | `[no-skill]` | `[no-skill]` | ✓ | "Quick fix for this typo" — no skill matched. Multiple anti-triggers ("trivial CRUD", "documentation-only changes", "trivial fixes") all apply. Correctly defers. |

### Adversarial — multi-skill-applicable (3/4)

| ID | Expected | Actual | Match? | Note |
|---|---|---|---|---|
| P24 | prior-art-research | prior-art-research | ✓ | "Plan and start building a new feature with parallel work units" — `prior-art-research` wins on "new feature" (no concrete approach). `write-plan` correctly defers ("locked ADR" required). `parallel-dev` correctly defers ("work decomposes" requires the decomposition to exist). Chain auto-orders. |
| P25 | tdd-loop | tdd-loop | ✓ | "Refactor the database layer and verify nothing breaks" — `tdd-loop`'s description ("implementation starts after a spec is locked") wins as the orchestrating skill; `deep-modules` and `verify-output` are inside the loop. Marginal — auditor could see `deep-modules` firing standalone if the user already has a spec. Acceptable under "tdd-loop is the orchestrator" reading. |
| P26 | decision-record | decision-record | ✓ | "Document the auth refactor decision" — `decision-record`'s "document this" + "non-trivial architectural decision" wins. `tdd-loop` correctly defers (no ADR locked yet). |
| P27 | systematic-debugging | parallel-dev | ✗ | **FP for parallel-dev.** "Debug why my parallel subagents are returning conflicting results" — `parallel-dev`'s "subagent dispatch" + "verify independence" matched on the "parallel subagents" + "conflicting results" keywords; `systematic-debugging`'s "debug" + "behavior is unexpected" was overshadowed. The word "Debug" alone should have won, but `parallel-dev`'s description triggered on context that the actual task is investigation, not dispatch. **Flagged for v1.11.0 description tuning.** Suggested fix: add anti-trigger to parallel-dev ("Do NOT use for debugging existing parallel dispatches — that's systematic-debugging"). |

### Adversarial — edge cases (3/3)

| ID | Expected | Actual | Match? | Note |
|---|---|---|---|---|
| P28 | prior-art-research | prior-art-research | ✓ | "Researh this approach" (typo) — charitable reading; "research/researh" similarity high enough that description match survives. |
| P29 | `[no-skill]` | `[no-skill]` | ✓ | "What's 2+2?" — no skill matched. Trivial off-topic; direct answer. |
| P30 | `[no-skill]` | `[no-skill]` | ✓ | "Add a quick CRUD endpoint" — `prior-art-research`'s anti-trigger ("trivial CRUD endpoints with one obvious approach") explicitly catches. Correctly defers. |

## Precision / recall per skill

Computed across all 30 prompts (TP = correctly triggered, FP = incorrectly triggered, FN = should have triggered but didn't, TN = correctly didn't trigger).

| Skill | TP | FP | FN | Precision | Recall | Status |
|---|---|---|---|---|---|---|
| prior-art-research | 3 (P01, P21, P24, P28) — wait, 4 | 1 (P16) | 0 | 0.80 | 1.00 | **FLAG — precision 0.80, threshold 0.80** |
| draft-spec | 1 (P02) | 0 | 0 | 1.00 | 1.00 | OK |
| socratic-grill | 1 (P03) | 0 | 1 (P22) | 1.00 | 0.50 | **FLAG — recall 0.50** |
| decision-record | 2 (P04, P26) | 0 | 0 | 1.00 | 1.00 | OK |
| write-plan | 1 (P05) | 0 | 0 | 1.00 | 1.00 | OK |
| tdd-loop | 2 (P06, P25) | 0 | 0 | 1.00 | 1.00 | OK |
| parallel-dev | 1 (P07) | 1 (P27) | 0 | 0.50 | 1.00 | **FLAG — precision 0.50** |
| vertical-slice | 1 (P08) | 0 | 0 | 1.00 | 1.00 | OK |
| deep-modules | 2 (P09, P18) | 0 | 0 | 1.00 | 1.00 | OK (P18 ambiguity noted) |
| using-worktrees | 1 (P10) | 0 | 0 | 1.00 | 1.00 | OK |
| systematic-debugging | 2 (P11, P20) | 0 | 1 (P27) | 1.00 | 0.67 | **FLAG — recall 0.67** |
| verify-output | 1 (P12) | 1 (P22) | 0 | 0.50 | 1.00 | **FLAG — precision 0.50** |
| agent-factors-check | 1 (P13) | 0 | 0 | 1.00 | 1.00 | OK |
| setup-habeebs-skill | 1 (P14) | 0 | 0 | 1.00 | 1.00 | OK |
| using-habeebs-skill | 1 (P15) | 0 | 0 | 1.00 | 1.00 | OK |

**4 skills flagged for v1.11.0 description tuning:**

1. **`prior-art-research` (precision 0.80, recall 1.00)** — P16 false positive on "I want to add something useful". Anti-trigger language excludes "trivial CRUD" but not "vague non-buildable intent." Suggested v1.11.0 tuning: add anti-trigger "Do NOT use when the user's intent is too vague to commit to a feature — ask a clarifying question instead."

2. **`socratic-grill` (precision 1.00, recall 0.50)** — P22 false negative on "verify this design". Grill's description doesn't include the word "verify" or "design" — both belong in the trigger surface for pre-implementation grilling. Suggested v1.11.0 tuning: add to trigger language "or when the user says 'verify this design' / 'pressure-test this approach' before implementation".

3. **`parallel-dev` (precision 0.50, recall 1.00)** — P27 false positive on "Debug why my parallel subagents...". Description matches "parallel subagents" keyword without disambiguating dispatch-vs-debug. Suggested v1.11.0 tuning: add anti-trigger "Do NOT use for debugging existing parallel dispatches — that's systematic-debugging."

4. **`verify-output` (precision 0.50, recall 1.00)** — P22 false positive on "verify this design". Description matches "verify" keyword without disambiguating code-vs-design. Anti-trigger "Pre-implementation review" exists but is line 4 of 4 in the anti-trigger list. Suggested v1.11.0 tuning: hoist "Pre-implementation review" earlier; or add positive-trigger language explicitly about *code* / *staged diff* / *post-commit*.

**Note on P22 double-fault:** P22 is the single prompt that surfaced TWO flagged skills (verify-output FP + socratic-grill FN). The two are coupled — one description's vague match steals from the other's. v1.11.0 fix should treat them as a pair, not two independent tunings.

## Findings summary

- **Happy-path is solid.** v1.9.0 description trim did not regress the obvious cases. All 15 primary triggers fire correctly.
- **Adversarial reveals real precision risks** at exactly the rate Hamel's framework predicts: synthetic corpora approach 100% but adversarial coverage finds the failure modes. 80% adversarial pass is below the rubber-stamp threshold but above catastrophic; this is a healthy audit result.
- **Anti-trigger language is load-bearing** — half the avoided false positives (P20, P21, P23, P30) work because anti-triggers explicitly disqualify the bait. Where anti-triggers are missing or buried (P16, P22, P27), the audit catches the gap.
- **Three of four flagged skills are NEW or RECENTLY-AMENDED:**
  - `parallel-dev` — load-bearing but description hasn't been audited against debug-confusion before
  - `verify-output` — v1.9.0 addition; never audited against grill-confusion before
  - `socratic-grill` — never explicitly listed "verify this design" as a trigger; this audit surfaces the gap
  - `prior-art-research` is older but the "vague intent" failure mode is novel — the original anti-trigger list was scoped to "trivial CRUD" and "API surface" cases

## Recommendations for v1.11.0

1. Tune the 4 flagged skill descriptions per the suggestions above (≤4 SKILL.md edits, each <100 chars to frontmatter description).
2. Re-run this audit against the same 30-prompt corpus to verify the tunings landed.
3. Add 3-5 new adversarial prompts to the corpus before re-running, biased toward category 3 (multi-skill) since that's where this audit was weakest (3/4 = 75%).
4. Consider promoting this audit to a quarterly cadence rather than per-release (Hamel's framework would call for it; per-release is acceptable for an OSS plugin where new skills land rarely).

## Cadence

- **v1.10.0:** One-time audit (this report). Audit gates Slice #4 acceptance in [`plans/0010-context-engineering-alignment-v1.10.0`](../../../docs/agents/plans/0010-context-engineering-alignment-v1.10.0.md) Phase 1.
- **v1.11.0:** Re-run with the 4 tunings applied; corpus may grow to 33-35 prompts.
- **6 months / new-skill threshold:** revisit triggers from the v1.10.0 plan apply.

---

**Auditor signature:** Claude (Opus 4.7), v1.10.0 Slice #4, 2026-05-13.
