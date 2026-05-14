# Trigger-precision corpus — 30 prompts

Hand-curated 2026-05-13 per the Q6 grill resolution in [`specs/v1.10.0-context-engineering-alignment-grill`](../../../docs/agents/specs/v1.10.0-context-engineering-alignment-grill.md) § Item Q6: 15 happy-path + 15 adversarial/boundary cases across 4 adversarial categories (vague, wrong-skill-bait, multi-skill-applicable, edge cases).

Each prompt is tagged with `expected:` — the skill the auditor expects to trigger. `[no-skill]` means no chain skill should fire (the prompt is trivial, off-topic, or insufficient to commit to a skill). For multi-applicable prompts, `expected:` names the *primary* trigger (the one the description language most strongly matches); secondary candidates are listed in the auditor's notes during the audit.

---

## Happy-path (15)

### P01 — prior-art-research
**Prompt:** I want to build a real-time collaborative document editor for our team — should support 5-10 concurrent editors per doc, offline mode, AWS Lambda backend.
**expected:** `prior-art-research`
**rationale:** Non-trivial feature ("build"); ambiguous architecture space (CRDT vs OT vs server-authoritative); explicit scale + stack — textbook research trigger.

### P02 — draft-spec
**Prompt:** That research recommendation looks good. Now turn it into a spec we can start implementing from.
**expected:** `draft-spec`
**rationale:** Research recommendation is in context; user wants to convert to implementation spec — `draft-spec`'s primary trigger.

### P03 — socratic-grill
**Prompt:** This spec has too many "we'll figure it out later" sentences. Drive the ambiguity out before we start coding.
**expected:** `socratic-grill`
**rationale:** Hedging language explicit; spec has open questions — `socratic-grill`'s primary trigger.

### P04 — decision-record
**Prompt:** Let's lock in the Yjs + Hocuspocus architecture as an ADR before we move to implementation.
**expected:** `decision-record`
**rationale:** "Lock this in" explicit phrasing; non-trivial architectural decision pending capture.

### P05 — write-plan
**Prompt:** ADR-0008 is locked. Give me a phased delivery plan with acceptance gates and parallelization for the 7 slices.
**expected:** `write-plan`
**rationale:** Locked ADR + 3+ slices + acceptance gates request — `write-plan`'s primary trigger.

### P06 — tdd-loop
**Prompt:** Plan is locked. Let's start building slice #1 with TDD — write the failing test first, then minimal code to pass.
**expected:** `tdd-loop`
**rationale:** Implementation starts; explicit red-green-refactor request.

### P07 — parallel-dev
**Prompt:** These four documentation passes touch different files and have no inter-dependencies. Dispatch them in parallel.
**expected:** `parallel-dev`
**rationale:** Independent work units + explicit "dispatch in parallel" — primary trigger.

### P08 — vertical-slice
**Prompt:** Break this PRD into vertical slices labeled HITL or AFK so we can decide what to parallelize.
**expected:** `vertical-slice`
**rationale:** "Break down" + "create tickets" + HITL/AFK labeling — primary trigger.

### P09 — deep-modules
**Prompt:** This module feels off — too many tiny files each with a one-line wrapper. Probably some shallow modules to consolidate.
**expected:** `deep-modules`
**rationale:** "This code feels off" + "too many small files" — direct quote from `deep-modules` trigger language.

### P10 — using-worktrees
**Prompt:** Let's start a new feature in an isolated branch + worktree off main, with a verified-clean test baseline.
**expected:** `using-worktrees`
**rationale:** "Start a new feature", "isolated branch", "let's experiment" pattern — primary trigger.

### P11 — systematic-debugging
**Prompt:** The auth flow is broken. Worked yesterday, fails today. Walked through my code three times and don't see what changed.
**expected:** `systematic-debugging`
**rationale:** "Worked yesterday" + previous fix attempts failed (vibe-fixes failure mode) — explicit primary trigger.

### P12 — verify-output
**Prompt:** I just finished implementing — all tests pass. Before commit, can you scan the diff for slop or half-finished bits?
**expected:** `verify-output`
**rationale:** Post-GREEN, pre-commit, "scan for slop" — verbatim trigger language.

### P13 — agent-factors-check (invoked from socratic-grill)
**Prompt:** We're shipping an LLM-powered customer support agent. The grill should also pressure-test against the 12-factor-agents lens — tool schemas, state, pause/resume.
**expected:** `agent-factors-check`
**rationale:** Agent/copilot/LLM workflow product + explicit 12-factor request — agent-factors-check's primary trigger from inside socratic-grill.

### P14 — setup-habeebs-skill
**Prompt:** Just cloned this repo. Set up the methodology — pick the issue tracker, triage labels, ADR directory layout.
**expected:** `setup-habeebs-skill`
**rationale:** One-time per-repo bootstrap; explicit setup request.

### P15 — using-habeebs-skill
**Prompt:** Walk me through the habeebs-skill chain — what runs after `prior-art-research`, what's HITL vs AFK, how does the abort protocol work?
**expected:** `using-habeebs-skill`
**rationale:** Introduction request; meta-question about chain shape — primary auto-load trigger.

---

## Adversarial / boundary (15)

### Category 1 — Vague prompts (4)

#### P16
**Prompt:** I want to add something useful to this codebase.
**expected:** `[no-skill]`
**rationale:** No buildable feature named; no architecture space implied; "useful" is content-free. Should NOT fire `prior-art-research` ("build/implement non-trivial feature"). At most might fire `using-habeebs-skill` if "this codebase" implies habeebs-skill (umbrella auto-load). Auditor checks: does anything wrongly fire?

#### P17
**Prompt:** Make this better.
**expected:** `[no-skill]`
**rationale:** Pronoun "this" with no antecedent; no concrete improvement axis. Should NOT fire any chain skill. Watch for false positive on `deep-modules` ("feels off") or `tdd-loop` ("let's start building").

#### P18
**Prompt:** Refactor this.
**expected:** `deep-modules` (with low confidence) OR `[no-skill]`
**rationale:** Ambiguous — could be deep-modules (interface depth) or tdd-loop refactor step. Per `deep-modules` anti-trigger ("Do NOT use to rewrite already-deep modules or to add abstractions that aren't yet earned"), bare "refactor" without symptoms is closer to `[no-skill]`. Acceptable to fire `deep-modules` if it asks the user "what feels off?" first.

#### P19
**Prompt:** I have an idea.
**expected:** `[no-skill]`
**rationale:** No content. Should produce a clarifying-question response, not a skill trigger.

### Category 2 — Wrong-skill bait (4)

#### P20
**Prompt:** Research how to fix this stale-cache bug.
**expected:** `systematic-debugging`
**rationale:** The word "research" is the bait. Bug fixes go to `systematic-debugging` (per its trigger: "the user reports a bug, a test starts failing"), NOT `prior-art-research` (whose anti-trigger explicitly excludes bug fixes — "Do NOT use for ... bug fixes with known causes"). False positive on `prior-art-research` is a known failure mode for this prompt class.

#### P21
**Prompt:** Plan and implement a new dashboard feature.
**expected:** `prior-art-research` (then `draft-spec` → ... → `tdd-loop`)
**rationale:** "New feature" with no recommended approach yet triggers the chain from Phase 1, not from `write-plan`. The word "plan" is bait — `write-plan` requires a locked ADR. False positive on `write-plan` is a known failure mode.

#### P22
**Prompt:** I need to verify this design before we commit to it.
**expected:** `socratic-grill`
**rationale:** "Verify" is the bait — sounds like `verify-output`, but `verify-output` is about CODE slop (post-GREEN, pre-commit), not design. Design verification is grilling — `socratic-grill`. False positive on `verify-output` is a known failure mode.

#### P23
**Prompt:** Quick fix for this typo in the README.
**expected:** `[no-skill]`
**rationale:** Trivial; not worth even `tdd-loop`'s overhead. Direct edit. `tdd-loop` anti-trigger: "Do NOT use for ... documentation-only changes". `prior-art-research` anti-trigger: "trivial CRUD". `[no-skill]` is correct.

### Category 3 — Multi-skill-applicable (4)

#### P24
**Prompt:** Plan and start building a new feature with parallel work units.
**expected:** `prior-art-research` (primary; chain triggers from Phase 1)
**rationale:** Three skills are applicable in sequence (`prior-art-research` → `write-plan` → `parallel-dev` via `tdd-loop`), but the chain MUST start at Phase 1 since "new feature" implies no locked ADR. The auditor scores whether the description-match correctly picks `prior-art-research` first, not `write-plan` or `parallel-dev`.

#### P25
**Prompt:** Refactor the database layer and verify nothing breaks.
**expected:** `tdd-loop` (with refactor step invoking `deep-modules`; verify step is `verify-output`)
**rationale:** `tdd-loop` is the orchestrating skill (red-green-refactor explicitly named); `deep-modules` and `verify-output` are invoked from within. False positive: firing `deep-modules` or `verify-output` standalone before TDD wraps them.

#### P26
**Prompt:** Document the auth refactor decision and start implementing.
**expected:** `decision-record` (primary; then `tdd-loop`)
**rationale:** Two skills applicable in sequence. The first action is capture-as-ADR; "start implementing" happens after the ADR locks. Auditor checks: does `decision-record`'s description match more strongly than `tdd-loop`'s for this prompt?

#### P27
**Prompt:** Debug why my parallel subagents are returning conflicting results.
**expected:** `systematic-debugging`
**rationale:** "Debug" is the load-bearing word; `parallel-dev` and `ADR-0004` are background context (the dispatcher / contract), but the active task is debugging. Watch for false positive on `parallel-dev` ("dispatch ... independent work").

### Category 4 — Edge cases (3)

#### P28
**Prompt:** Researh this approach.
**expected:** `prior-art-research`
**rationale:** Typo on "research". Should still match `prior-art-research`'s description if the auditor reads charitably. Watch for false-negative (description match fails on the typo).

#### P29
**Prompt:** What's 2+2?
**expected:** `[no-skill]`
**rationale:** Off-topic. No chain skill should fire. Direct answer.

#### P30
**Prompt:** Add a quick CRUD endpoint for the new `notifications` table.
**expected:** `[no-skill]`
**rationale:** Explicitly trivial. `prior-art-research` anti-trigger: "trivial CRUD endpoints with one obvious approach". Direct implementation; chain is overkill. `tdd-loop` could fire if the user wants TDD for the endpoint, but the prompt doesn't request TDD — `[no-skill]` is the most conservative answer. Acceptable to fire `tdd-loop` if the user has tdd-default culture; auditor notes the ambiguity.

---

## v1.11.0 corpus expansion (4 new Cat-3 prompts)

Added 2026-05-14 per v1.10.0 audit recommendation #3 ("Add 3-5 new adversarial prompts to the corpus before re-running, biased toward category 3 (multi-skill) since that's where this audit was weakest"). P31 + P32 specifically probe the v1.11.0 tunings; P33 + P34 probe Cat-3 boundaries not exercised by v1.10.0.

### Category 3 — Multi-skill-applicable (new)

#### P31
**Prompt:** Pressure-test our proposed event-sourcing approach before we commit to it.
**expected:** `socratic-grill`
**rationale:** "Pressure-test this approach" is verbatim language added to socratic-grill's trigger in v1.11.0. The word "before commit" is bait for `verify-output`, but v1.11.0 hoisted verify-output's "Do NOT use for pre-implementation review of designs, plans, or specs (that's socratic-grill)" anti-trigger to first position. False positive on `verify-output` is the v1.10.0 P22 failure mode — this prompt validates the fix from the other side (proactive design review, not reactive).

#### P32
**Prompt:** Why are my three parallel research subagents converging on the same answer instead of exploring different paths?
**expected:** `systematic-debugging`
**rationale:** "Debug" isn't said outright, but "Why are X behaving Y" + reported-unexpected-outcome ("converging instead of exploring") = bug. `parallel-dev`'s v1.11.0 anti-trigger ("Do NOT use for debugging existing parallel dispatches — that's systematic-debugging") explicitly catches this. v1.10.0 P27 failure mode (parallel-dev FP on "parallel subagents" keyword) — this prompt validates the fix.

#### P33
**Prompt:** ADR is locked, but the slices are obvious. Skip the plan doc and just start TDD on slice 1.
**expected:** `tdd-loop`
**rationale:** Two skills are nominally applicable (`write-plan` since ADR is locked, `tdd-loop` since implementation is starting), but the user explicitly says "skip the plan doc" — `write-plan` is skippable per `CLAUDE.md` ("write-plan is skip-able when the slice list is trivial and ordering is obvious"). The auditor should match `tdd-loop`'s "implement slice N" / "let's start building" trigger over `write-plan`'s "ADR locked" trigger when the user has explicitly opted out of the plan step. Tests whether description language respects user opt-out cues.

#### P34
**Prompt:** We have a 200-line PRD but no ADR yet. Break it into tickets we can prioritize.
**expected:** `vertical-slice`
**rationale:** Three skills are nominally applicable (`prior-art-research` since "PRD exists, no ADR" implies research-gap; `vertical-slice` since "break it into tickets"; `write-plan` since multi-slice + prioritization). `write-plan` correctly defers (anti-trigger: "no ADR exists yet"). `prior-art-research` could trigger but the PRD names the feature, removing the "vague idea" trigger. `vertical-slice`'s "break this down, create tickets" matches verbatim. Tests Cat-3 boundary between `prior-art-research` (architecture not yet picked) and `vertical-slice` (decomposition pending) — the prompt sits in the gap where a PRD exists but ADR doesn't.
