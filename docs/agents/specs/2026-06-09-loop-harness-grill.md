# Grill Record: Loop harness — self-correcting autonomous development loops

**Spec:** [2026-06-09-loop-harness.md](./2026-06-09-loop-harness.md)
**Tier:** Deep (inherited from the spec)
**Grilled on:** 2026-06-10
**Items resolved:** 12 decided / 2 deferred / 0 out-of-scope

## TL;DR

All 10 spec open questions plus the slice-shape standing item resolved across 4 rounds; no architectural rethink needed. One user override against the recommendation: the run file extends `docs/agents/dispatches/` rather than opening a new `docs/agents/runs/` writer path. Two explicit deferrals, both with triggers: the ADR-0003 Stop-hook carve-out and the same-error-twice wait-exemption. One new decision surfaced: `/tdd --resume <run-id>` as the morning-after resume command.

---

## User mental model

(From the Phase 1 mental-model probes — Deep tier, all 3 run.)

- **Success criteria** (premortem inverse — user selected ALL FOUR failure narratives, so all four inverses are acceptance-gate candidates for `write-plan`):
  1. Loops converge within their retry/iteration budgets — no runaway token waste.
  2. Overnight runs make real progress — the loop does not halt so often that AFK mode is pointless.
  3. Merged work survives review — no slop reaches main under provisional execution.
  4. Ceremony stays thin — the harness is simple enough that it actually gets used.
- **Door classifications:** Loop shape (fresh-context-per-slice driver + run file) → **two-way door with costly undo**. Recorded undo cost: one minor release to remove, a CHANGELOG migration note, and the run-file format is frozen (no breaking field changes) until removal. (User was initially stuck on this probe; resolved in round 3 with a proposed classification the user ratified.)
- **Concrete example** (riskiest behavior, user-produced): overnight run hits a structural failure on slice 3 → loop parks slice 3 with a halt report and **continues** slices 4–5 (independent scope), terminating with slice 3 queued in RUN_SUMMARY. The user correctly exercised the scope-parking rule rather than whole-run termination.

---

## Grilling agenda

1. ADR-0004 amendment vehicle + changed-input rule (one-way door)
2. ADR-0003 Stop-hook carve-out deferral (one-way door)
3. Confirmation-gate provisional list (per-gate)
4. Reviewer placement + Critical-finding authority in AFK
5. Run-file directory
6. Outer-loop invocation surface + ceiling supply
7. History-less first-failure default
8. Waiting ≠ stuck — wait-exemption for same-error-twice
9. Discharging the Grill 2.0 line-76 revisit trigger
10. Reviewer falsifiability (dogfood design)
11. Slice table — standing slice-shape item (deprioritization, ordering, vertical-ness)
12. *(surfaced)* Morning-after resume UX
13. *(probe)* Door classification of the loop shape
14. *(probe)* Premortem + concrete example

---

## Per-item resolutions

### Item 1 — ADR-0004 amendment vehicle + changed-input rule

- **Starting state:** Spec flagged one-way door: amend-in-place vs new dated ADR; N=2 vs 1-with-changed-input; who judges "materially changed".
- **Axes grilled:** Reversibility, Failure modes.
- **Resolution:** DECIDED
- **Decision:** **Amend ADR-0004 Part 1 in place** (changelog entry, no supersession), bound **N=2** re-dispatches, each requiring materially changed input; **the dispatcher judges** "materially changed" (it composed the original input and can diff it); unchanged input escalates immediately as `BLOCKED`.
- **Spec update:** Slice 3 AC 1 — replace "via the vehicle the grill decides" with the concrete vehicle.

### Item 2 — ADR-0003 Stop-hook carve-out deferral

- **Starting state:** Spec recommended deferring; grill pressure-tested whether any v1 surface needs hook-enforced continuation.
- **Axes grilled:** Reversibility, Failure modes.
- **Resolution:** DEFERRED (deferral confirmed as the decision)
- **Revisit trigger:** A real need for hook-enforced in-slice determinism emerges; mandatory minimums if taken: ADR-0019-shaped sub-clauses, `stop_hook_active` check, session-ID guard. (Already in the spec's revisit triggers — unchanged.)
- **Spec update:** None; tick the OQ.

### Item 3 — Confirmation-gate provisional list

- **Starting state:** 4 confirmation gates, per-gate provisional-vs-park undecided.
- **Axes grilled:** Failure modes, Reversibility.
- **Resolution:** DECIDED
- **Decision:** **Provisional in AFK (gated on green checks, logged for ratification):** fixture-ID confirm, verify-output H1–H6 ANNOTATE concerns, spec-compliance review. **Parks:** version-bump confirm (release-facing; the human ratifies versioning).
- **Spec update:** Slice 5 halt-policy table gets the four concrete rows.

### Item 4 — Reviewer placement + authority

- **Starting state:** Per-slice in tdd-loop vs per-dispatch in parallel-dev; Critical hard-block question.
- **Axes grilled:** Concurrency, Failure modes.
- **Resolution:** DECIDED
- **Decision:** **parallel-dev defines the reviewer; both skills consume it** (tdd-loop loop mode dispatches it per slice via the same contract). **Critical findings hard-block in AFK** — no overnight override; the slice parks with a halt report.
- **Spec update:** Slice 2 description already matches; add the "both consume" line to Slice 2 notes.

### Item 5 — Run-file directory

- **Starting state:** New runtime writer path (`docs/agents/runs/`, recommended) vs extending `docs/agents/dispatches/`.
- **Axes grilled:** Migration, Observability.
- **Resolution:** DECIDED — **USER OVERRIDE of the recommendation.**
- **Decision:** **Extend `docs/agents/dispatches/`.** Run files live alongside dispatch records in the existing ADR-0021-classified runtime writer path; the dispatch-record contract widens to cover the run-file class instead of opening a second writer path. Rationale: one runtime writer path for loop bookkeeping beats two near-identical directories (consistent with the user's resist-doc-overhead preference).
- **Spec update:** Slice 4 AC 1 — replace "directory (per grill decision)" with the dispatches/-extension; the reference doc defines the run file as a new record class within the existing directory's contract.

### Item 6 — Outer-loop invocation surface

- **Starting state:** `/tdd --loop` flag vs new wrapper skill; ceiling supply mechanism.
- **Axes grilled:** Slice shape, Observability.
- **Resolution:** DECIDED
- **Decision:** **`/tdd --loop` flag** — no new skill. Ceiling defaults to 2× open slices; **`--max-iterations N` override**, with the effective ceiling recorded in run-file frontmatter either way.
- **Spec update:** Slice 5 AC 1 — name the flag and the override field.

### Item 7 — History-less first-failure default

- **Resolution:** DECIDED — defaults confirmed as specced: assertion-shaped → structural (straight to systematic-debugging); error-shaped → one retry.
- **Spec update:** None; tick the OQ.

### Item 8 — Wait-exemption (waiting ≠ stuck)

- **Resolution:** DEFERRED — no wait-exemption in v1; budget 2 absorbs the OpenHands #5355 class for now.
- **Revisit trigger:** Field evidence of a legitimate long-wait failure mode being misclassified as structural → add the exemption.
- **Spec update:** Add the trigger to the spec's revisit triggers.

### Item 9 — Grill 2.0 revisit-trigger discharge

- **Resolution:** DECIDED — re-affirmation confirmed: AFK loops change halt *handling* (park + structured report + RUN_SUMMARY), never halt *authority*; the human-mediated re-grill rejection stands. Slice 6 AC already carries the changelog entry.
- **Spec update:** None; tick the OQ.

### Item 10 — Reviewer falsifiability

- **Starting state:** OQ asked what dogfood scenario proves the reviewer catches what assertions + self-review miss.
- **Axes grilled:** Observability, Failure modes.
- **Resolution:** DECIDED
- **Decision:** **Both-sided test** — fixture with a planted spec violation the reviewer must catch, plus a clean control diff the reviewer must pass without hallucinated Critical findings. (A third style-nit case was considered and rejected — the gaps-not-style rule is enforced by the finding constraints, not a third fixture.)
- **Spec update:** Slice 2 AC 5 already encodes both sides; tick the OQ.

### Item 11 — Slice table (standing slice-shape item)

- **Axes grilled:** Slice shape.
- **Resolution:** DECIDED
- **Decision:** Slice shape ratified: all 6 vertical, ordering reflects real file-surface dependencies, both pgroups sound. **Severability ranking under scope pressure: Slice 3 (NEEDS_CONTEXT multi-retry) goes first** — the loop ships on the existing 1-retry contract and Slice 3 slots into a patch release. Slices 1 + 5 are the spine and are not severable. No slice was thrown away.
- **Spec update:** Note the severability ranking in the Parallelization section (informs write-plan's phase ordering).

### Item 12 — Morning-after resume UX *(surfaced during grilling)*

- **Starting state:** Spec defined RUN_SUMMARY + halt reports but no resume affordance — the artifact existed, the interaction didn't.
- **Axes grilled:** Observability, Failure modes.
- **Resolution:** DECIDED
- **Decision:** **`/tdd --resume <run-id>`** — reads the run file, finds parked slices, replays each halt report as seed context, resumes from RED on the parked slice. Resume-by-inspection: no state beyond the run file + git.
- **Spec update:** New AC on Slice 5 (the driver owns resume); RUN_SUMMARY halt section names the resume command (Slice 4 AC).

---

## New decisions surfaced during grilling

1. **`/tdd --resume <run-id>` resume command** — the grill exposed that the spec shipped a morning-read with no morning-action; resume-by-inspection extends naturally to a flag.
2. **Slice severability ranking** (3 first, then 2, then 4; 1+5 spine) — feeds write-plan's phase ordering and any mid-release descope.
3. **Loop-shape door closed as two-way with costly undo** — undo cost recorded (one minor release + CHANGELOG migration note + frozen run-file format until removal); goes into the ADR's consequences.

---

## Spec updates required

Push these back into the spec:

- [ ] Header: `Status: Draft` → `Status: Grilled`
- [ ] Slice 3 AC 1: amendment vehicle = amend ADR-0004 Part 1 in place, N=2, dispatcher judges materially-changed
- [ ] Slice 4 AC 1: run file extends `docs/agents/dispatches/` (widened record contract, no new directory)
- [ ] Slice 4 RUN_SUMMARY AC: halt section names `/tdd --resume <run-id>`
- [ ] Slice 5 AC 1: invocation = `/tdd --loop`, ceiling default 2× open slices, `--max-iterations` override recorded in run-file frontmatter
- [ ] Slice 5: new AC for `/tdd --resume <run-id>` (parked-slice re-entry from halt report)
- [ ] Slice 5 halt-policy AC: enumerate the 4 confirmation gates (3 provisional, version-bump parks)
- [ ] Slice 2 notes: reviewer defined in parallel-dev, consumed by both skills
- [ ] Parallelization section: severability ranking (Slice 3 most deferrable)
- [ ] Revisit triggers: add wait-exemption field-evidence trigger
- [ ] Open questions: tick all 10

---

## ADR candidates

High-impact decisions for `decision-record`:

1. **Loop-harness architecture** — fresh-context-per-slice driver, classify-then-route triage, tiered fail-closed halt policy, run file in dispatches/; two-way door with recorded undo cost.
2. **ADR-0004 Part 1 amendment** — NEEDS_CONTEXT 1→2 re-dispatches, dispatcher-judged materially-changed rule (amend in place).
3. **Grill 2.0 ADR changelog discharge** — line-76 revisit trigger fired and re-affirmed (halt handling changed, halt authority unchanged).

---

HANDOFF: spec update ready — apply the updates listed above.
HANDOFF: record ready — invoke `decision-record` to capture the high-impact decisions.
