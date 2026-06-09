# Implementation Spec: Loop harness — self-correcting autonomous development loops

**Slug:** `loop-harness`
**Status:** Draft
**Version:** v1.26.0 (candidate — assigned at release per changeset convention)
**Tier:** Deep (inherited from research)
**Spec'd from:** [docs/agents/research/2026-06-09-loop-harness-research.md](../research/2026-06-09-loop-harness-research.md)
**Spec'd on:** 2026-06-09

## TL;DR

A plan-driven, fresh-context-per-slice outer loop with classify-then-route inner correction and a tiered fail-closed halt policy — extending Tier-0 machinery (Phase 0.5 resume, 4-status contract, re-grill payload) at every point rather than adopting new substrate. 6 slices, all AFK, ~50% parallelizable. One ADR amendment in scope (ADR-0004 NEEDS_CONTEXT re-dispatch 1→2); the ADR-0003 Stop-hook carve-out is explicitly deferred.

## Architecture

No runtime components — the harness is contract changes across three skill surfaces plus one new artifact class. `tdd-loop` gains a failure-triage rule (transient / structural / spec-implicated routing) and a loop mode that promotes Phase 0.5 from resume mechanism to iteration driver; `parallel-dev` gains a context-starved reviewer dispatch and the widened NEEDS_CONTEXT bound; a new per-run tracked markdown file carries mutable bookkeeping (iteration count, retry counters, last-error hash) plus the RUN_SUMMARY morning-read and structured halt reports. Data flow: loop driver → fresh subagent per slice → triage on failure → bounded retry / systematic-debugging / re-grill edge → run file updated each iteration → terminal state DONE or BLOCKED-with-halt-report.

```
plan work-list ──► loop driver (tdd-loop Phase 0.5 promoted)
                      │  fresh context per slice, ceiling = 2× open slices
                      ▼
                 slice subagent ──► verification (assertions → reviewer → verify-output)
                      │ fail                                   │ pass
                      ▼                                        ▼
                 triage rule                              commit, next slice
        transient / structural / spec-implicated
            │           │              │
       1 re-run   systematic-     re-grill edge
       (budget 2)  debugging      (park scope per
                  (fresh ctx)     scope_classification)
                      │
              run file + RUN_SUMMARY + halt report (morning read)
```

## Concrete picks (from research)

| Decision | Choice | Reason |
|---|---|---|
| Outer-loop shape | Fresh-context-per-slice driver on Phase 0.5; never a Stop-hook loop | Context collapse ~100–150k (3 independent observers); Stop-hook state file is ADR-0003 Rule 3's forbidden artifact |
| Gap 1 — verify-output BLOCKED | Classified bounded retry: 1 fresh-context fix attempt, budget 2; same-finding-twice → halt report | Anthropic 2-corrections + pytest assertion-never-retries |
| Gap 2 — unexpected RED | Triage rule: transient → 1 re-run; structural / same-error-twice → auto-invoke systematic-debugging; spec-implicated → existing re-grill edge | Slack/pytest/OpenHands classify-then-route convergence |
| Gap 3 — reviewer | Context-starved read-task dispatch: diff + slice spec + bounding SHAs only; gaps-not-style, severity-gated; PASS = evidence, not oracle | Anthropic/superpowers/Bugbot triple convergence + judge-literature bound |
| Gap 4 — outer loop | Phase 0.5 promoted to iteration driver; ceiling = 2× open slices; terminal states DONE / BLOCKED-with-halt-report | Zero new substrate; ADR-0002 untouched |
| Gap 5 — NEEDS_CONTEXT | Amend ADR-0004 Part 1: 1→2 re-dispatches, materially-changed-input rule | Cap is a termination guarantee, documented as convention |
| Halt policy | Tiered by the existing HITL gate classification: decision gates + structured halts park scope + queue; confirmation gates proceed provisionally gated on green checks | Four-vendor fail-closed convergence; re-affirms the Grill 2.0 autonomous-re-plan rejection |
| Loop state | Per-run tracked frontmatter run file, session/worktree-scoped, advisory, skill-written | Resume-by-inspection + #15047 hazard + ADR-0019 staleness-contract shape |
| Audit trail | RUN_SUMMARY morning-read + existing dispatch records as detail tier; halt report = re-grill 7-field payload + cause/evidence/options | Two-tier audit convergence; Tier 0's payload already exceeds public prior art |
| ADR-0003 Stop-hook carve-out | **Defer** — no hook change in v1 | Avoids a one-way-door amendment v1 doesn't need |

## Trade-offs accepted

- **No true hands-off continuation past human-judgment surfaces.** Overnight runs can end early with work parked and queued, not finished.
- **Fresh-context-per-slice discards session memory** — repo artifacts carry everything, costing re-read tokens per iteration.
- **Fixed retry budgets will occasionally truncate an almost-converged fix loop** (aider #3450 class); accepted until field evidence demands configurability.
- **Reviewer PASS is evidence, not proof** — deterministic assertions remain the verification floor.

## Open questions (feed `socratic-grill`)

Run `socratic-grill` before implementation:

- [ ] **(One-way door)** ADR-0004 amendment vehicle (amend-in-place vs new dated ADR) and the changed-input rule wording — who judges "materially changed"? N=2 vs 1-with-changed-input-only?
- [ ] **(One-way door)** ADR-0003 Stop-hook carve-out deferral — does any v1 surface genuinely need hook-enforced continuation the model can't talk past?
- [ ] Confirmation-gate provisional list — which of the 4 confirmation gates (fixture-ID confirm, verify-output H1–H6 ANNOTATE, spec-compliance review, version-bump confirm) run provisionally in v1, per gate?
- [ ] Reviewer placement and authority — per-slice in tdd-loop Phase 5 vs per-dispatch in parallel-dev; does a Critical finding hard-block in AFK mode given no overnight override?
- [ ] Run-file directory — new runtime writer path (ADR-0021 classification, `.gitkeep`) vs extending `docs/agents/dispatches/`?
- [ ] Outer-loop invocation surface — `/tdd --loop` flag vs new wrapper skill; how the iteration ceiling is supplied and recorded?
- [ ] History-less first-failure default — novel failure: assertion-shaped → structural, error-shaped → one retry. Confirm the default?
- [ ] Waiting ≠ stuck — does same-error-twice need a wait-exemption (OpenHands #5355 class), or is budget 2 forgiving enough?
- [ ] Discharging the Grill 2.0 revisit trigger — confirm the autonomous-re-plan re-affirmation and record it in that ADR's changelog so the fired trigger is formally closed.
- [ ] Reviewer falsifiability — what dogfood scenario would prove the reviewer catches what assertions + writer self-review miss?

---

## Vertical slices

Numbered in dependency order. Each slice cuts end-to-end. HITL = human-in-the-loop required; AFK = autonomous-friendly.

### Slice 1 — Failure-triage rule + bounded retry in tdd-loop (AFK)

**Description:** Any verification failure in tdd-loop (unexpected RED in Phases 2–4, verify-output BLOCKED in Phase 5c) hits a triage rule that classifies on cheap signals and routes: transient-shaped → one fresh-context re-run; structural (assertion-shaped or same-error-twice) → auto-invoke systematic-debugging in fresh context with an evidence payload; spec-implicated → the existing re-grill edge, unchanged. Closes gaps 1 and 2.

**Acceptance criteria:**
- [ ] `tdd-loop/SKILL.md` defines the three-route triage classification with the same-error-twice rule (string comparison against the recorded last failure) and the default for history-less failures (assertion-shaped → structural; error-shaped → one retry).
- [ ] Per-slice retry budget of exactly 2, documented as a convention (not a tuned optimum); exhaustion emits `BLOCKED` with a halt payload.
- [ ] verify-output `BLOCKED` gets exactly 1 fresh-context fix attempt; the same finding surviving the fix → halt, never a second identical attempt.
- [ ] systematic-debugging auto-invocation specified: fresh context, receives the failure evidence (test output, diff, attempted fix) as input.
- [ ] Spec-implicated failures route to the re-grill edge with zero changes to its 7-field payload or halt block.
- [ ] Dogfood: one fixture per route (transient re-run succeeds; structural auto-invokes systematic-debugging; budget exhaustion halts well-formed).

**Test strategy:** Dogfood scenario — at `tests/dogfood/<next-free-N>-failure-triage/` (confirm N against live tree at implementation).

**Blocked by:** None

### Slice 2 — Reviewer subagent in parallel-dev (AFK)

**Description:** parallel-dev gains a context-starved reviewer dispatch: after a write-task subagent returns `DONE`, a reviewer in fresh context receives only the diff, the slice spec, and the bounding SHAs — never the writer's conversation. Findings are severity-gated and constrained to gaps-not-style; the verdict uses the existing 4-status contract. Closes gap 3.

**Acceptance criteria:**
- [ ] `parallel-dev/SKILL.md` defines the reviewer as a read-task-class dispatch (no merge surface; read-task rules apply) with the input triple (diff + slice spec + bounding SHAs) and the context-starvation rule stated explicitly.
- [ ] Finding constraints: correctness/stated-requirements only, severity tiers, what blocks progression (Critical/Important) vs what is recorded (Minor).
- [ ] One writer fix round per Critical/Important finding; a finding surviving its fix round → `BLOCKED` (composes with Slice 1's same-finding-twice rule).
- [ ] Reviewer PASS recorded as evidence in the dispatch record, positioned above deterministic assertions in narrative but never replacing them.
- [ ] Dogfood: fixture where the reviewer receives only the input triple and a planted spec violation is caught; control fixture with sound work yields no hallucinated Critical findings.

**Test strategy:** Dogfood scenario — at `tests/dogfood/<next-free-N>-reviewer-dispatch/` (confirm N at implementation).

**Blocked by:** None

### Slice 3 — NEEDS_CONTEXT bounded multi-retry (AFK)

**Description:** The ADR-0004 Part 1 amendment lands (re-dispatch up to 2, each requiring materially changed input; unchanged input escalates immediately as `BLOCKED`) and parallel-dev's return-contract wording updates to match. Closes gap 5.

**Acceptance criteria:**
- [ ] ADR-0004 amended via the vehicle the grill decides, with the changed-input rule and who judges it.
- [ ] `parallel-dev/SKILL.md` NEEDS_CONTEXT row reflects the new bound and the immediate-escalation rule for unchanged input.
- [ ] Dogfood: fixture where a second re-dispatch with unchanged input escalates to `BLOCKED` immediately rather than dispatching.

**Test strategy:** Dogfood scenario — at `tests/dogfood/<next-free-N>-needs-context-retry/` (confirm N at implementation).

**Blocked by:** #2 (same file: `parallel-dev/SKILL.md`)

### Slice 4 — Run file + RUN_SUMMARY + halt report (AFK)

**Description:** Defines the loop's only new artifact class: a per-run tracked markdown file with frontmatter bookkeeping (iteration count, per-slice retry counters, last-error hash, session/worktree binding), a RUN_SUMMARY morning-read section, and the structured halt report (re-grill 7-field payload extended with cause / evidence / options). Covers SP6 + SP7.

**Acceptance criteria:**
- [ ] A reference doc defines the run-file format: frontmatter fields enumerated, directory (per grill decision), ADR-0021 runtime-writer-path classification, advisory-only semantics, staleness contract in the ADR-0019 shape.
- [ ] Session/worktree scoping rule: a session-identity field checked before any resume touches the file (the #15047 guard).
- [ ] Skill-written only — hooks never write it (ADR-0003 Rule 3 untouched); stated in the reference doc.
- [ ] Halt-report format: the existing 7 re-grill fields + `cause`, `evidence`, `options` — one format for every halt class (re-grill, budget exhaustion, reviewer block, parked gate).
- [ ] RUN_SUMMARY format: per-slice status table, halts queued with their reports, provisional actions awaiting ratification.

**Test strategy:** Dogfood scenario — at `tests/dogfood/<next-free-N>-run-file-format/` (confirm N at implementation); executable assertions on a fixture run file.

**Blocked by:** None

### Slice 5 — Outer-loop driver + tiered halt policy (AFK)

**Description:** tdd-loop Phase 0.5 is promoted to an iteration driver (invocation surface per grill): re-inspect, dispatch the next pending slice in fresh context, repeat until plan-done-or-BLOCKED, ceiling = 2× open slices. The tiered halt policy maps the existing HITL gate classification to AFK behavior: decision gates and structured halts park scope (via `scope_classification`) into a halt report; confirmation gates proceed provisionally, gated on green checks and logged for ratification. Closes gap 4 and resolves SP5.

**Acceptance criteria:**
- [ ] `tdd-loop/SKILL.md` loop mode: driver algorithm (inspect → dispatch fresh → verify → next), iteration ceiling = 2× open slices recorded in the run file, terminal states `DONE` / `BLOCKED`-with-halt-report — no third exit.
- [ ] Halt-policy table enumerating every HITL gate the loop can reach, each labeled park or provisional per the grill's per-gate decisions.
- [ ] Re-grill halts park scope per `scope_classification` and never self-resolve; the loop writes the halt report and moves to unaffected slices or terminates per the scope.
- [ ] Each iteration updates the run file; run end (either terminal state) writes the RUN_SUMMARY.
- [ ] Dogfood: a 2-slice plan fixture loops to plan-done; a planted-ambiguity fixture parks with a well-formed halt report and untouched sibling scope.

**Test strategy:** Dogfood scenario — at `tests/dogfood/<next-free-N>-outer-loop/` (confirm N at implementation).

**Blocked by:** #1 (same file: `tdd-loop/SKILL.md`; triage routes are the loop's inner edges), #4 (run-file format consumed)

### Slice 6 — Docs sync + changeset (AFK)

**Description:** GLOSSARY gains the new terms (loop run, triage rule, halt report, run file, provisional execution); `using-habeebs-skill` chain doc shows the loop mode; the Grill 2.0 ADR changelog records the discharged revisit trigger; changeset written.

**Acceptance criteria:**
- [ ] GLOSSARY.md defines the 5 new terms.
- [ ] `using-habeebs-skill/SKILL.md` chain-at-a-glance reflects the loop driver.
- [ ] Grill 2.0 ADR changelog entry closes the fired line-76 revisit trigger (re-affirmed, halt handling changed, halt authority unchanged).
- [ ] Changeset entry present (minor); release doc-sync audit passes with zero WARN findings.

**Test strategy:** Manual smoke — release skill's doc-sync audit is the verifier.

**Blocked by:** #3, #5

---

## Dependency DAG

```
1 ──────────► 5 ──► 6
2 ──► 3 ───────────┘
4 ──────────► 5
```

## Parallelization

AFK slices with no shared dependencies can run via `parallel-dev`:

- Group A (parallel): #1, #2, #4 — disjoint file surfaces (`tdd-loop`, `parallel-dev`, new reference doc)
- Group B (parallel): #3, #5 — disjoint surfaces (`parallel-dev`+ADR vs `tdd-loop`+run file)
- Sequential: #6

## Revisit triggers

- Retry budgets repeatedly hit on legitimately converging fixes → make budgets configurable (aider's exact trajectory).
- Re-grill rounds fire >2× per release cycle (existing Grill 2.0 trigger — now doubly load-bearing).
- Credible non-Claude loop-harness evidence contradicts fresh-per-slice → re-open the F1 fork.
- A real need for hook-enforced in-slice determinism emerges → take the deferred ADR-0003 carve-out (ADR-0019-shaped sub-clauses + `stop_hook_active` + session-ID guard are mandatory minimums).
- The 2026-06-15 headless credit-pool change materially alters fresh-session economics.

---

HANDOFF: grill ready — invoke `socratic-grill` to resolve open questions and challenge ambiguous decisions.
HANDOFF: record ready — invoke `decision-record` after grill to capture as an ADR.
HANDOFF: implementation ready — invoke `tdd-loop` per slice in dependency order.
