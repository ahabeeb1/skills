# Prior-Art Research: Loop Harness — self-correcting autonomous development loops

**Researched on:** 2026-06-09
**Tier:** Deep (auto-detected — 8 sub-problems spanning disjoint literatures, 4+ hard constraints, two one-way-door ADR amendments in scope)
**Sources consulted:** 38 external (~5 fetcher dispatches) + 6 Tier-0 internal question-blocks
**Slug:** `loop-harness`

## TL;DR

Build the loop harness as a **plan-driven, fresh-context-per-slice outer loop** — superpowers' controller shape on habeebs-skill's existing Phase 0.5 resume machinery — not a Stop-hook re-prompt loop. Inner self-correction is **classify-then-route with tiny bounded budgets** (retry budget 2, same-error-twice escalates immediately), reviewer independence comes from a **context-starved read-task reviewer dispatch**, and unattended halts are **tiered by the existing 14-gate HITL classification**: decision gates and structured halts park scope into a halt report; only confirmation gates proceed provisionally, gated on green checks. One ADR amendment is needed now (ADR-0004 Part 1: NEEDS_CONTEXT re-dispatch 1→2 with a changed-input rule); the ADR-0003 Stop-hook carve-out is **deferred** — v1 doesn't need it. The headline trade-off: the loop is never fully hands-off — at every human-judgment surface it fails closed and queues for a morning read, which is exactly what every production system surveyed does.

## Context

- **Building:** A target-iterate-verify loop harness for the chain — verifiable target, unattended iteration, verification baked in — closing 5 confirmed v1.24 capability-audit gaps: (1) no auto-retry on verify-output BLOCKED; (2) systematic-debugging not auto-invoked on unexpected RED; (3) no reviewer-subagent role in parallel-dev (writer == verifier); (4) no outer loop iterating slices until plan-done-or-blocked; (5) NEEDS_CONTEXT allows exactly one re-dispatch.
- **Scale:** 19 skills, 8-deep chain, single maintainer, public OSS plugin; loop runs bounded by plan slice counts (single-digit slices per run, ≤8 concurrent per ADR-0004).
- **Stack:** Markdown-only Claude Code plugin — skills + 6 bash hooks + git. No daemons, no runtime substrate.
- **Constraints:** ADR-0002 markdown-only (hard); ADR-0003 hook rules (amendable only via deliberate dated ADR, ADR-0019 precedent shape); must compose with the v1.22 HITL pivot gate, v1.24 executable assertions, and the v1.25 re-grill edge (whose ADR's line-76 revisit trigger fires on exactly this feature).
- **Existing:** Brownfield, methodology-mature — much of the loop substrate already exists (Phase 0.5 idempotent resume, 4-status contract, re-grill 7-field payload, ADR-0019 sidecar staleness contract).
- **Priorities:** User selected all priority options (signal: wants everything); shipping speed + correctness treated as primary `[assumed]`.

## Sub-problems

1. **SP1** — Bounded auto-retry on verification failure (gap 1, gap 5)
2. **SP2** — Outer-loop orchestration + runaway guards (gap 4)
3. **SP3** — Writer/reviewer subagent pairs (gap 3)
4. **SP4** — Failure-triage auto-routing: auto-diagnose vs escalate (gap 2)
5. **SP5** — Autonomy policy for human-decision surfaces (HITL/re-grill halts)
6. **SP6** — Loop-state persistence across session death
7. **SP7** — Audit trail + escalation surface for unattended runs
8. **SP8** — Permission boundary for autonomous operation

## Phase 2.5 outcome — Category-completeness critic

The critic reviewed the original 5-sub-problem decomposition (SP1–SP5, mapped 1:1 onto the five capability-audit gaps plus the halt-policy question) and proposed four additions:

| Critic proposal | Verdict | Disposition |
|---|---|---|
| Loop-state persistence across session death | **Accepted** → SP6 | The gaps assumed a live session; an overnight loop dies and must resume — distinct literature (state files, git-as-state, leases) |
| Audit trail + escalation surface for unattended runs | **Accepted** → SP7 | "What did the loop do while I slept" is its own design surface, not a byproduct of SP2 |
| Permission boundary for autonomous operation | **Accepted** → SP8 | AFK loops widen the blast radius; the enforcement substrate (deny rules, hooks, sandboxing) is disjoint from orchestration |
| Dogfood-testability of loop behavior | **Rejected** | Test strategy is a spec/tdd-loop concern, not a research sub-problem — the v1.24 executable-assertion machinery already defines how loop skills get tested; researching it separately would duplicate the existing convention rather than surface new prior art |

Final decomposition: 8 sub-problems (5 planner + 3 critic). One iteration, as bounded.

## Case studies

### Tier 0 — habeebs-skill's own loop substrate — most of the harness already exists

- **Architecture:** ADR-0004 Part 4 idempotent re-invocation (git as durability layer, tdd-loop Phase 0.5 resume-by-inspection via `Dispatch-id:` greps); the v1.25 re-grill edge with its 7-field halt payload and `scope_classification` pause semantics; ADR-0019's advisory sidecar staleness contract; a 14-gate HITL inventory already classified into decision / confirmation / structured-halt.
- **Key decision:** Resume is re-derived from the repo, never from a checkpoint file; re-grill is human-mediated by deliberate rejection of autonomous re-planning.
- **Trade-off accepted:** Mid-flight uncommitted work lost on kill; every spec-invalidating ambiguity costs a human round-trip.
- **Source:** ADR-0004, ADR-0003, ADR-0019, `2026-06-09-add-regrill-edge` ADR, tdd-loop/parallel-dev/verify-output SKILL.md (Tier-0 miner record).

### Anthropic — Claude Code best practices — bounded correction + fresh-context review as official doctrine

- **Architecture:** Session-level "after two failed corrections, /clear and restart with a better prompt"; a deterministic Stop-hook gate force-overridden after 8 consecutive blocks; an adversarial reviewer subagent that sees "only the diff and the criteria you give it" with findings constrained to gaps-not-style; an explicit verification ladder (deterministic checks below LLM judgment).
- **Key decision:** Restart beats persist — context polluted with failed attempts degrades further attempts.
- **Trade-off accepted:** Context continuity across the restart boundary; learnings carried manually.
- **Source:** https://code.claude.com/docs/en/best-practices ; https://code.claude.com/docs/en/hooks

### The Ralph lineage (Huntley → official ralph-wiggum plugin → aihero rebuttal) — the outer-loop fork, argued inside one ecosystem

- **Architecture:** Huntley: `while`-loop re-prompting, fresh session per iteration, state = plan file + git, quality collapse observed at 147–152k tokens. Official plugin: same loop moved in-session via Stop hook + frontmatter state file, `--max-iterations` as "the primary safety mechanism". aihero: direct rebuttal — the in-session loop hits the ~40% "dumb zone" by iteration 3–4.
- **Key decision (lineage net):** Fresh context per iteration is the load-bearing trick; durable artifacts are the inter-iteration memory.
- **Failure evidence:** claude-code #15047 — the Stop-hook loop's directory-scoped state hijacked a concurrent unrelated session (closed not-planned, labeled security).
- **Source:** https://ghuntley.com/ralph ; anthropics/claude-code `plugins/ralph-wiggum` ; https://www.aihero.dev/why-the-anthropic-ralph-plugin-sucks ; anthropics/claude-code#15047

### obra/superpowers — controller/implementer/two-reviewer triad in pure markdown

- **Architecture:** Controller iterates the plan's work list; fresh implementer subagent per task; spec-compliance reviewer then code-quality reviewer, each receiving only a summary + requirements + bounding SHAs, never the implementer's conversation; severity-tiered findings (Critical/Important block); implementer may challenge with evidence.
- **Key decision:** "Don't force through blockers—stop and ask" — blocked is a legitimate terminal state, not something to loop past.
- **Trade-off accepted:** Cannot run unattended overnight; review latency per task.
- **Source:** obra/superpowers `subagent-driven-development`, `requesting-code-review`, `executing-plans` SKILL.md files (code read)

### OpenHands — pattern-based stuck detection, park-and-resume on failure

- **Architecture:** StuckDetector hashes semantic action+observation pairs every step — same-action→error 3×, same-action→same-observation 4×, ping-pong 6+ — nested inside MAX_ITERATIONS ≈ 100; on stuck, PR #5500 replaced the hard crash with a graceful pause that resumes on the next human message.
- **Key decision:** Error-repeats trigger earlier than success-repeats; auto-continuing past detected stuckness is rejected outright.
- **Failure evidence:** #5355 — legitimately polling agents are indistinguishable from stuck ones; false-positive kills accepted as the cost of default-on protection.
- **Source:** OpenHands `controller/stuck.py`, PR #5500, issues #5355/#5480

### Slack — flaky-test auto-detection — automate the routing, never the fix

- **Architecture:** Classify by rerun history (flaky = eventually passes; failing = consistent); automation auto-quarantines via PR + files a ticket + notifies owners; the fix stays human. Main-branch stability 19.82% → 96%.
- **Key decision:** V1 classified without history and misclassified new broken tests as flaky, leaking them to production — history (or a conservative default) is mandatory before trusting a "transient" verdict.
- **Trade-off accepted:** Coverage while quarantined; escalation became asynchronous.
- **Source:** https://slack.engineering/handling-flaky-tests-at-scale-auto-detection-suppression/

---

## Patterns

(Adopting the pattern-extractor's P1–P8 verbatim in name; condensed here. Bugbot, Devin, Renovate, pytest-rerunfailures, and the judge literature are cited where load-bearing.)

### P1 — Layered budgets: tiny fixed inner retry + hard outer ceiling

Anthropic's 2-corrections rule, aider's hardcoded 3 reflections, OpenHands' 3×-error threshold, ralph-wiggum's max-iterations, mini-SWE-agent's 250 steps. Nobody ships exponential backoff for agent fix loops — backoff solves contention, not non-convergence. Every cap is a termination guarantee, never a tuned optimum. **Fits when:** any retry surface (gaps 1, 5).

### P2 — Fresh context per iteration; durable artifacts are the memory

Three independent token-collapse observations (~100–150k) triangulate the ceiling; inter-iteration memory = plan file + git, never session memory. **Fits when:** the outer loop and every fix-attempt restart (gap 4).

### P3 — Classify before retrying, on cheap signals; same-error-twice = structural

pytest-rerunfailures gates retry on exception identity (`--only-rerun` regex; assertion failures never retry); OpenHands hashes errors; Slack requires history. Same-error-twice detection is pure string comparison over a transcript — implementable as a prompt rule. **Fits when:** the triage gate in front of every retry (gaps 1, 2).

### P4 — Fail-closed when unattended: halt/park in resumable state, never improvise

Cross-vendor convergence (Anthropic headless aborts on repeated blocks; dontAsk auto-denies; OpenHands parks; superpowers stops-and-asks; Renovate doesn't merge absent green checks). The single sanctioned softening is provisional-execution-plus-async-ratification (Devin green, Renovate automerge), reserved for rubber-stamp decisions gated on green checks. **Fits when:** every human-judgment surface the loop reaches AFK (SP5).

### P5 — Reviewer independence via context starvation + constrained findings

Anthropic, superpowers, and Cursor Bugbot independently discovered both halves: the reviewer never sees the writer's reasoning, and findings must be constrained (gaps-not-style, severity gates) or the reviewer overcalls. The judge literature shows the opposite hazard — rubber-stamping near-correct same-family work — is highest in exactly the loop-harness case; Bugbot's resolution-rate metric (52% → ~70-80%) is the transferable efficacy measure. **Fits when:** gap 3.

### P6 — Resume-by-inspection beats checkpoint files

Both Ralph lineages, superpowers' plan-as-work-list, and Tier 0's Phase 0.5 re-derive loop state from the repo at every restart. Mutable bookkeeping (retry counts, last-error hash) has no git-metadata home — notes don't sync, trailers are immutable — so it belongs in a tracked frontmatter block. **Fits when:** SP6; extend Phase 0.5 rather than invent a state file.

### P7 — Two-tier audit trail: append-only detail + curated markdown morning-read

GitHub Actions job summaries, OpenHands event store + visualizer, Devin's consolidated Slack post + ticket-per-finding. No production system makes humans read raw logs. **Fits when:** SP7; detail tier already exists (dispatch records, commit trailers).

### P8 — Loop state must be session/worktree-scoped, advisory, staleness-aware

#15047 (directory-scoped state hijacks concurrent sessions) + lease-with-TTL literature + ADR-0019's existing advisory contract. **Fits when:** SP6/SP8 guard on any run file.

### Competing forks (extractor leans adopted; no divergence)

- **F1 — Stop-hook continuous loop vs fresh-session-per-slice → fresh-per-slice.** Evidence is lopsided (even Anthropic's best-practices doc undermines its own plugin's shape), and the Stop-hook design carries two Tier-0 costs: its state file is precisely ADR-0003 Rule 3's forbidden artifact, and #15047 is its hazard class. Caveat: the fork is entirely intra-Anthropic-ecosystem (see Limitations).
- **F2 — Hard-stop vs queue-and-pause vs bounded-autonomy at HITL halts → tiered by the Tier-0 gate classification.** Queue-and-pause (B) as the spine — the `scope_classification` seam in parallel-dev already implements it; bounded autonomy (C) only at confirmation gates, gated on green checks; never pure hard-stop (A, wastes the built seam) and never C at decision gates (zero production precedent).
- **F3 — Fixed retry integer vs pattern-based stuck detection → hybrid.** Same-error-twice routes to escalation immediately; a fixed cap of 2 terminates everything else; the outer ceiling backstops both. Neither side alone survived contact with users (aider #3450; OpenHands #5355).

---

## Recommendation

**For habeebs-skill's markdown-only, single-maintainer, chain-composing context: build the loop harness as a plan-driven fresh-context outer loop with classify-then-route inner correction and a tiered fail-closed halt policy — extending Tier-0 machinery at every point rather than adopting new substrate.**

The outer loop (gap 4) is not new infrastructure: it is tdd-loop Phase 0.5 promoted from a resume mechanism to an iteration driver — "re-inspect, dispatch next pending slice in fresh context, repeat until plan-done-or-BLOCKED," with a hard iteration ceiling as the runaway guard. Inner correction (gaps 1–2) is a triage prompt rule in front of every retry: transient-shaped failures get one fresh-context retry within a budget of 2; same-error-twice or assertion-shaped failures route immediately — to systematic-debugging for unexpected RED, to a halt report for verify-output BLOCKED that survives a fix attempt; spec-implicated failures take the existing re-grill edge unchanged. The reviewer (gap 3) is a context-starved read-task dispatch (Anthropic-validated, no merge surface per parallel-dev's task-class split) sitting above v1.24's deterministic assertions in the verification ladder. Gap 5 needs the one ADR amendment: ADR-0004 Part 1's "re-dispatch once" becomes "re-dispatch up to 2, each with materially changed input; unchanged input escalates immediately." On the user's central question — AFK treatment of re-grill/HITL halts — the evidence re-affirms the Grill 2.0 ADR's autonomous-re-plan rejection (P4 is four-vendor convergent): the loop **parks scope per the existing `scope_classification` seam and writes a structured halt report**; what changes is halt *handling*, never halt *authority*. This shape is slice-able along the gap boundaries (each gap = an independently shippable vertical slice touching its own skill surface); the spec cuts those slices.

### Concrete picks

| Decision | Choice | Reason |
|---|---|---|
| Gap 1 — verify-output BLOCKED retry | Classified bounded retry: 1 fresh-context fix attempt, budget 2; same-finding-twice → halt report | P1 + P3 (Anthropic 2-corrections; pytest assertion-never-retries) |
| Gap 2 — unexpected RED routing | Triage rule in tdd-loop: transient → 1 re-run; structural/same-error-twice → auto-invoke systematic-debugging (fresh context); spec-implicated → re-grill edge | P3 (Slack/pytest/OpenHands classify-then-route); composes with existing 7-field payload |
| Gap 3 — reviewer in parallel-dev | Read-task reviewer dispatch: diff + slice spec + bounding SHAs only; severity-gated gaps-not-style findings; 4-status verdict; PASS = evidence, not oracle | P5 (Anthropic/superpowers/Bugbot triple convergence + judge-literature bound) |
| Gap 4 — outer loop | Phase 0.5 promoted to iteration driver: fresh subagent per slice over the plan work-list; ceiling = 2× open slices (stated convention); terminal states DONE / BLOCKED-with-halt-report | F1 lean + P2/P6; zero new substrate, ADR-0002 untouched |
| Gap 5 — NEEDS_CONTEXT multi-retry | Amend ADR-0004 Part 1: 1→2 re-dispatches, changed-input rule | P1; cap is a termination guarantee, documented as convention |
| Halt policy (SP5) | Tiered: decision gates + structured halts park scope + queue; confirmation gates proceed provisionally gated on green checks, ratified via run summary | F2 lean; Devin-green/Renovate class only |
| Loop state (SP6/SP8) | Per-run frontmatter block in a tracked per-worktree run file; staleness contract copied from ADR-0019; advisory, skill-written (Rule 3 bars hooks) | P6 + P8 + #15047 |
| Audit trail (SP7) | Per-run RUN_SUMMARY markdown (morning read) + existing dispatch records (detail); halt report = re-grill payload extended with cause/evidence/options | P7; Tier 0's payload already exceeds public prior art |
| Stop-hook carve-out (ADR-0003) | **Defer.** No Stop hook in v1; in-slice fix loops are prompt rules within the dispatched subagent | F1 lean; avoids a one-way-door amendment v1 doesn't need |
| Permission posture (SP8) | AFK runs documented fail-closed (deny rules + existing block-only hooks); bypassPermissions only inside a sandbox, documented not provisioned | SP8 convergence; boundary enforced at harness, never prose |

### What you're explicitly giving up

- **True hands-off continuation past human-judgment surfaces.** The loop parks at decision gates and re-grill halts; an overnight run can end early with work queued, not finished.
- **In-session ergonomics.** Fresh-context-per-slice discards session memory; repo artifacts carry everything, which costs re-read tokens per iteration.
- **Adaptive retry budgets.** Fixed caps will occasionally truncate an almost-converged fix loop (aider #3450 class); accepted until field evidence demands configurability.
- **Reviewer verdict certainty.** A prompt-only reviewer's PASS is evidence, not proof; deterministic assertions remain the floor.

### When to revisit

- Re-grill rounds fire >2× per release cycle (existing Grill 2.0 ADR trigger — now doubly load-bearing).
- Retry caps repeatedly hit on legitimately converging tasks → make budgets configurable (aider's exact trajectory).
- Credible non-Claude loop-harness evidence (Cursor background agents, Factory) contradicts fresh-per-slice → re-open F1.
- The June 15, 2026 headless credit-pool change materially changes fresh-session economics.
- A real need emerges for hook-enforced in-slice loop determinism → take the deferred ADR-0003 carve-out (four ADR-0019-shaped sub-clauses + `stop_hook_active` + session-ID guard are mandatory minimums).

---

## Decisions to make next

These feed `socratic-grill` and `draft-spec`:

1. **ADR-0004 amendment vehicle and wording** — amend-in-place vs new dated ADR (post-v1.23 convention favors dated for substantial change; this contract is consumed by tdd-loop, parallel-dev, verify-output, and all dispatch records). Exact changed-input rule phrasing: who judges "materially changed"?
2. **Retry budget homes** — where the per-slice retry counter and last-error hash live (run-file frontmatter recommended) and whether budgets are per-finding, per-slice, or per-run.
3. **Confirmation-gate provisional list** — which of the 4 confirmation gates (fixture-ID confirm, verify-output H1–H6 ANNOTATE, spec-compliance review, version-bump confirm) get provisional execution in v1, per-gate.
4. **Reviewer placement and authority** — per-slice in tdd-loop Phase 5 vs per-dispatch in parallel-dev; does a Critical finding hard-block in AFK mode (GATE-equivalent) given no human can override overnight?
5. **Run file + RUN_SUMMARY format and directory** — new runtime writer path (ADR-0021 classification, `.gitkeep`d) vs extending `docs/agents/dispatches/`; halt-report field list (existing 7 + cause/evidence/options).
6. **Outer-loop invocation surface** — a new skill/flag (`/tdd --loop`?) vs behavior folded into tdd-loop Phase 0.5; how `--max-iterations` is supplied and recorded.

## Open questions

Things research didn't resolve. These feed `socratic-grill`:

1. **(One-way door) ADR-0004 Part 1 amendment** — raising the NEEDS_CONTEXT re-dispatch bound from 1 to N is a locked-contract change; once consumers depend on N=2 semantics, reverting is breaking. Grill must pressure-test N=2 vs keeping 1-with-changed-input-only, and the amendment vehicle.
2. **(One-way door) ADR-0003 Stop-hook carve-out** — recommended deferred, but the grill must establish whether any v1 surface genuinely needs hook-enforced continuation (deterministic gate the model can't talk past). If taken later, the carve-out's shape (Rule-3 exception) is hard to walk back once a state-writing hook ships.
3. **F2 halt-policy boundary** — provisional execution at confirmation gates rests on vendor-reported efficacy only (Devin's confidence-gate stats, Renovate's discipline); zero production precedent exists for provisional execution at decision gates, and the per-gate boundary needs grilling gate-by-gate.
4. **Discharging the Grill 2.0 revisit trigger** — its line-76 trigger ("unattended execution → re-research the autonomous-re-plan rejection") fired; this research re-affirms the rejection on four-vendor convergence and changes only halt handling. Grill should confirm the re-affirmation and record it in that ADR's changelog so the trigger is formally discharged, not left dangling.
5. **History-less first-failure classification** — Slack's V1 failure mode is unresolved in all sources: with no rerun history, is a novel failure transient or structural by default? (Recommended default: assertion-shaped → structural, error-shaped → one retry; needs grilling.)
6. **Waiting ≠ stuck** — same-error-twice may misfire on legitimately slow checks (OpenHands #5355 class). Does the triage rule need a wait-exemption, or is the budget of 2 forgiving enough?
7. **Reviewer rubber-stamp risk** — the judge literature says same-family review of near-correct work is the worst case; no source measures writer/reviewer pairs in a prompt-only substrate. What's the dogfood scenario that would falsify the reviewer's value?
8. **F1 contradiction within the evidence** — the official Anthropic plugin ships continuous-session while Anthropic's own best-practices doc prescribes fresh-context restarts; the lean follows the doc + independent collapse observations, but the vendor's own artifacts disagree with each other. Surface-level contradiction, resolved by evidence weight, flagged for the record.
9. **Headless credit-pool change (2026-06-15)** — `-p` moving to a separate Agent SDK credit pool may alter fresh-session-per-slice operational cost; unverifiable today.

### Limitations and evidence gaps

- **Homogeneity bias (material):** Anthropic-adjacent sources anchor P1, P2, P4, P5, and the *entire* F1 fork is one ecosystem's family tree arguing with itself (Huntley → official plugin → aihero). "Fresh-per-slice wins" is strong-within-ecosystem; non-Claude loop harnesses (Cursor background agents, Factory, Sweep, AutoGPT lineage) are absent. Counterweights: SP4 is genuinely cross-ecosystem (Slack/pytest/Chromium) and P4 spans four vendors — those conclusions are robust.
- **Devin escalation mechanics unpublished:** how a stopped overnight run announces *why* is a hole in public prior art (3 query attempts), not just in this search.
- **Halt-report prior art absent:** Tier 0's 7-field re-grill payload already exceeds everything public — the harness extends its own precedent, with no external validation available.
- **Retry-cap values are folklore:** 2, 3, 8, 100, 250 — all termination guarantees, none tuned. Any number picked is a convention and must be documented as one.
- **Vendor-stat optimism:** Devin confidence numbers and Bugbot resolution rates are vendor-reported; treat provisional-execution efficacy as plausible, not proven.

---

## Sources

1. **Anthropic — Claude Code best practices** — https://code.claude.com/docs/en/best-practices — 2-corrections rule, 8-block override, adversarial reviewer, verification ladder.
2. **Claude Code hooks docs + guide** — https://code.claude.com/docs/en/hooks — Stop-hook primitive, `stop_hook_active`, 8-consecutive-block force-override.
3. **Claude Code headless docs** — https://code.claude.com/docs/en/headless — fresh-session primitive, abort-on-repeated-blocks policy, cost telemetry, credit-pool change.
4. **Claude Code permission modes / permissions** — https://code.claude.com/docs/en/permission-modes — fail-closed unattended policy; deny+hook as the enforcement point.
5. **Geoffrey Huntley — Ralph** — https://ghuntley.com/ralph — fresh-session outer loop; 147–152k collapse; failure catalog.
6. **anthropics/claude-code ralph-wiggum plugin** — stop-hook.sh + README — frontmatter state file, max-iterations as primary guard, completion-promise limits.
7. **claude-code issue #15047** — directory-scoped Stop-hook state hijacking a concurrent session.
8. **aihero.dev — plugin critique** — https://www.aihero.dev/why-the-anthropic-ralph-plugin-sucks — "dumb zone" context-utilization argument for fresh sessions.
9. **obra/superpowers** — subagent-driven-development, requesting-code-review, executing-plans SKILL.md — triad shape, context-starved reviewer, stop-and-ask.
10. **aider** — lint/test docs + issues #1090/#3450/#3865 — max_reflections=3; cap-as-backstop; configurability demand.
11. **OpenHands** — StuckDetector docs/code, PR #5500, issues #5355/#5480 — pattern-based stuck detection, park-and-resume, polling false positives.
12. **mini-SWE-agent / OpenHands eval harness** — hard outer step/cost envelopes.
13. **Slack — flaky tests at scale** — https://slack.engineering/handling-flaky-tests-at-scale-auto-detection-suppression/ — history-based classification; automate routing never the fix; V1 failure.
14. **pytest-rerunfailures** — exception-identity retry gating (`--only-rerun`).
15. **Chromium LUCI/Findit** — automate evidence-gathering, human-owned verdicts.
16. **Cursor — Building a better Bugbot** — https://cursor.com/blog/building-bugbot — resolution-rate metric; suppress-style discipline; admitted regressions.
17. **LLM-as-judge literature** — arxiv 2406.07791, 2507.16587, adaline.ai survey — position/self-preference bias; rubber-stamp risk on near-correct same-family work.
18. **Anthropic — multi-agent research system** — https://www.anthropic.com/engineering/multi-agent-research-system — decision-pattern tracing, checkpoint resume.
19. **Cognition — Devin posts** (dogfood, scheduled Devins, Devin 2.1) — morning-triage surface, cross-run notes, confidence-gated ask-vs-proceed; escalation path unpublished.
20. **GitHub — Actions job summaries** — curated-summary-over-logs morning-read pattern.
21. **OpenHands event store / ATIF trajectory RFC** — two-tier audit shape (metadata + append-only events).
22. **Renovate — automerge docs** — https://docs.renovatebot.com/key-concepts/automerge/ — auto-approve only rubber-stamp classes, gated on green checks.
23. **git notes vs trailers; Kleppmann/k8s/py-filelock** — mutable bookkeeping needs a tracked file; lease-with-TTL, advisory-only.
24. **Sandboxing sources** — Anthropic auto-mode post, devcontainer docs, claude-code #19978 — environment as the boundary when prompts are skipped.
25. **Tier 0** — ADR-0003 (+ Rule 4 amendment), ADR-0004 (+ Parts 3/5 amendments), ADR-0019, `2026-06-09-add-regrill-edge-and-grill-alignment-axes.md`, tdd-loop/parallel-dev/verify-output SKILL.md, 14-gate HITL inventory — the substrate every recommendation extends.

---

HANDOFF: spec ready — invoke `draft-spec` to turn this into an implementation spec.
HANDOFF: grill ready — invoke `socratic-grill` to drive ambiguity out of the open questions and decisions above.
HANDOFF: record ready — once spec + grill complete, invoke `decision-record` to capture the chosen architecture as an ADR.
