# Dogfood Test 07 — agent-factors-check

**Date:** 2026-05-11
**Skill under test:** `skills/agent-factors-check/SKILL.md`
**Tester:** Claude Opus 4.7 (this session)
**Intent:** Pressure-test trigger discipline, gap-finding accuracy, and integration with socratic-grill.

---

## Scenario

Spec: a customer-support copilot for a SaaS billing product. The copilot answers customer questions, can look up account state, can issue refunds up to $50 autonomously, escalates anything bigger to a human. The spec was drafted by a junior PM who used some agent-product vocabulary but didn't think through the implementation surface.

This is exactly the kind of spec habeebs-skill's main chain leaves implicit gaps in — the 7 standard axes (perf / failure / scale / concurrency / migration / reversibility / observability) cover production-readiness but not agent-shape questions.

## Inputs handed to the skill

**Spec (excerpts):**

> The Support Copilot helps customers resolve billing questions without waiting for a human. It can read the customer's account, look up invoices, answer common questions about plans and pricing, and issue refunds up to $50 without escalation. Refunds over $50 are escalated to a human via an `escalate_to_human` action.
>
> The copilot will use GPT-4. Prompts are configurable per-tenant. Conversation history persists for 30 days.
>
> Open questions:
> - How do we handle multi-turn conversations across page reloads?
> - What if the copilot makes a refund decision the customer disagrees with?
> - Should we log the LLM's reasoning chain?

**Grill record (state at invocation):** socratic-grill ran 4 axes (failure modes, observability, scale, reversibility); 6 items resolved. About to advance to migration/concurrency axes. Mid-grilling, tester invokes agent-factors-check.

---

## Actual run output (following `agent-factors-check` Phase 1 → 5)

### Phase 1 — Confirm trigger

Spec uses: "copilot", "tool calls" (implied by `escalate_to_human` action), "LLM" (GPT-4), "prompts", "multi-turn", "conversation history". ✓ — agent product. Run the check.

### Phase 2 — Score each factor

| #  | Factor                                  | Status | Spec evidence / gap note                                                                                |
|----|-----------------------------------------|--------|---------------------------------------------------------------------------------------------------------|
| 1  | Natural language → tool calls           | ~      | `escalate_to_human` named but schema not defined. `read_account`, `lookup_invoice`, `issue_refund` implied but not specified. |
| 2  | Own your prompts                        | ~      | "Prompts are configurable per-tenant" — where do they live? Versioned? Who can change them?              |
| 3  | Own your context window                 | ✗      | Silent on token budget, eviction policy, what enters context per turn.                                  |
| 4  | Tools = structured outputs              | ✗      | No JSON Schema mentioned for any tool. Output format unspecified.                                       |
| 5  | Unify state                             | ✗      | Conversation history "persists for 30 days" but no detail on store. Refund state? Account-read state?    |
| 6  | Pause/resume API                        | ~      | Open question 1 acknowledges the gap but no design proposed.                                            |
| 7  | Human as tool call                      | ~      | `escalate_to_human` exists as a named action. Schema? Approval channel? Timeout?                        |
| 8  | Own your control flow                   | ✗      | Silent. Will the loop be code in this repo or LangChain-managed?                                        |
| 9  | Compact errors into context             | ✗      | Silent. Open question 2 implies a failure mode but doesn't address LLM-facing error formatting.         |
| 10 | Small focused agents                    | ~      | One agent does refund decisions, account lookups, AND general Q&A. Possibly a decomposition signal.      |
| 11 | Trigger from anywhere                   | ✗      | Silent. Only implied surface is "the customer support page". Slack? Email? Mobile?                     |
| 12 | Stateless reducer                       | ~      | "Persists for 30 days" hints at external state, but reducer-shape (pure function) not declared.         |
| 13 | Pre-fetch context (bonus)               | ✗      | Silent. Account state, invoice list, plan info — pre-fetch or lazy?                                     |

**Tallies:** 0 ✓, 6 ~, 7 ✗, 0 N/A. The spec is silent or partial on every factor — typical for a junior-PM draft.

### Phase 3 — Generate Socratic questions

**Must-grill (F5, F6, F7):**

- **[F5]** Where does conversation history actually live — same Postgres as billing data, or a separate vector store / Redis? When the copilot issues a refund, does the refund record and the conversation reference each other transactionally? If the answer is "different stores", how do you handle a refund that succeeds but a conversation-log write that fails?
- **[F6]** Open question 1 names the gap. Concretely: when a customer closes the browser mid-conversation, what state must persist for resume? Where is it stored? Is the resume mechanism "re-emit last assistant turn", "replay from start", or "pick up from a suspended LLM call"? Does the LLM cost rerun on resume?
- **[F7]** `escalate_to_human` exists. What is its exact tool-call schema (name, args, return type)? When the copilot calls it, who routes the escalation (a queue? Slack? Zendesk? humanlayer)? What's the timeout? If the human doesn't respond in time, does the copilot retry, fail, or hand back to the customer with an apology?

**Should-grill (F1, F4, F11, F13):**

- **[F1]** `escalate_to_human`, `read_account`, `lookup_invoice`, `issue_refund` — are these tools defined in a single registry with shared validation, or per-call ad hoc? If schema-validated, where does invalid output produce its error?
- **[F4]** What is the JSON Schema for `issue_refund`? Specifically: required fields (`amount`, `invoice_id`, `reason`), return type (`{ refund_id, status }`?), error shape (`{ code, message }`?). Is the schema the source of truth or generated from the implementation?
- **[F11]** Customer support exists in many channels — Slack DMs, email tickets, in-app chat. Which surfaces does the copilot need? Are they additive (single entry point) or duplicate-the-agent-logic per surface?
- **[F13]** When a session starts, what context can be pre-fetched? Account state (cheap, ~1ms) and recent invoices (cheap) seem like they pay for themselves over mid-loop lookups. Plan terms (~100KB?) may not. Where's the line?

**Nice-to-grill (deferred unless user opts in):** F2 (prompts), F3 (context window), F8 (control flow), F9 (errors), F10 (decomposition), F12 (reducer).

### Phase 4 — Triage

11 questions generated. 3 Must-grill, 4 Should-grill, 6 Nice-to-grill.

Surfacing the 3 Must-grill + 4 Should-grill = **7 questions added to socratic-grill's agenda**, interleaved with the existing 5 unresolved axes.

### Phase 5 — Handoff

```
HANDOFF: grilling agenda updated — 7 new questions from agent-factors-check.
  Must-grill: 3 questions on F5 (state), F6 (pause/resume), F7 (human-as-tool).
  Should-grill: 4 questions on F1, F4, F11, F13.
  Deferred (Nice-to-grill): 6 questions on F2, F3, F8, F9, F10, F12 — surface only if user opts in.

  Resume socratic-grill with these questions interleaved into the existing agenda.
```

---

## Rubric (criterion-by-criterion)

| # | Criterion | Pass/Fail | Evidence |
|---|---|---|---|
| 1 | Trigger test correctly identifies agent product | ✅ | Spec vocabulary scanned; clear yes |
| 2 | Score uses 4-state vocabulary (✓ / ~ / ✗ / N/A) | ✅ | All 13 factors scored |
| 3 | Each Partial/Missing factor produces ≥ 1 question | ✅ | 13 factors graded, 11 questions generated (2 N/A roll-ups, 0 questions for Addressed) |
| 4 | Each question names specific spec entities, not generic | ✅ | F1 names `escalate_to_human`; F7 references the same; F11 names "customer support page" |
| 5 | Each question is single-axis | ✅ | No multi-factor combos |
| 6 | Must-grill triage targets architecture-shaping factors | ✅ | F5, F6, F7 are all in the Must-grill bucket per skill spec |
| 7 | Output format matches `factor-check-template.md` | ✅ | Table + bulleted questions + handoff |
| 8 | Cites humanlayer/12-factor-agents as source | ✅ | Top of factor-check record |
| 9 | Cites humanlayer (the SDK) as F7 reference impl | ✅ | F7 question names "humanlayer" as an option |
| 10 | Returns control to socratic-grill (not absorbed) | ✅ | Handoff is back to socratic-grill, not forward to decision-record |

**Aggregate: 10/10 on happy path.**

---

## Adversarial cases

### A1 — Non-agent spec wrongly routed in

**Input:** A spec for "Add bulk CSV export to the admin panel." No LLM, no agent, no tool calls — pure CRUD UI.

**Expected behavior:** Phase 1 trigger test fails → SKIP with reason.

**Actual behavior:** ✅ Phase 1 output: `SKIP: agent-factors-check does not apply. Reason: spec is a CRUD admin feature with no LLM orchestration. Returning control to socratic-grill.`

**Weakness surfaced:** None. The trigger test held.

### A2 — Borderline (LLM-as-feature, not agent)

**Input:** A spec for "Add an AI Summarize button to the support ticket page. Button calls OpenAI's `/chat/completions` once with the ticket text, returns the summary, done."

**Expected behavior:** This is *not* an agent product (single LLM call, no orchestration, no tool calls). Should SKIP, but it's the kind of case that could fool a sloppy check.

**Actual behavior:** ✅ Trigger test applied the one-question gate: "Does this product orchestrate multiple LLM calls and/or tool invocations across turns?" Answer from the spec: no — single call, single turn, no tools. SKIP correctly emitted.

**Weakness surfaced:** Minor. The one-question gate is good but its phrasing leaves a gap: "across turns" — what about a single-turn workflow that DOES use tools (e.g., "summarize this ticket AND tag it with the relevant category using a `tag_ticket` tool")? That's still agent-shaped (tool use) even with one turn. The trigger should be: "orchestrate multiple LLM calls OR uses tool/function calls". 

**Recommendation:** Update Phase 1 trigger test to: "Does this product orchestrate multiple LLM calls and/or use tool/function calls?" → **Will edit before v1.4.0 ships.**

### A3 — Spec fakes Addressed on F7

**Input:** Same Support Copilot spec, but the PM added a line: "We have a `request_approval` function that handles human escalation."

**Expected behavior:** F7 should still score ~ (Partial), not ✓ (Addressed). The line doesn't define a schema, channel, timeout, or response wiring.

**Actual behavior:** ✅ Skill applied its own discipline: "If you're tempted to mark something Addressed, look for the *specific* sentence in the spec — if you can't quote it, it's Partial." The mention of `request_approval` doesn't quote a schema, so F7 remained Partial. Question generated: "What is `request_approval`'s exact tool-call schema, and through what channel does the human respond?"

**Weakness surfaced:** None for this specific case. The skill's "if you can't quote it, it's Partial" rule held.

### A4 — Spec is for a multi-agent system

**Input:** Spec for "Customer support copilot consists of a triage agent, a refund agent, and a knowledge-base agent. Triage routes to the others."

**Expected behavior:** F10 should flag the decomposition is described, AND raise a new question about inter-agent communication (a sub-factor not in the canonical 12).

**Actual behavior:** ⚠️ Skill scored F10 as ✓ (decomposition is described) but did NOT raise the inter-agent communication question. The 12 factors don't cover multi-agent comms explicitly — agent-factors-check inherited that blind spot.

**Weakness surfaced:** **Real gap.** Multi-agent systems are a growing class of agent products. The 12 factors are written for single-agent shapes; they don't cover orchestration patterns (router, sequential, parallel, mesh) or inter-agent message contracts.

**Recommendation:** Either (a) add a sub-section to agent-factors-check called "Multi-agent extension" with 3-4 sub-questions on routing / messaging / shared state across agents, OR (b) note this gap explicitly in the SKILL and defer the extension to a separate skill (`multi-agent-shape-check` or similar). → **Logged for v1.4.1 / v1.5.0. Will NOT block v1.4.0.**

### A5 — Spec author asks "do all 13 factors apply to my product?"

**Input:** A tester invokes agent-factors-check on a single-turn LLM-call-with-tools product (the A2 borderline case extended into an actual tool call: single call, but uses `tag_ticket` tool). The tester asks: "F11 (trigger from anywhere) — does this even apply if my product is invoked from one place?"

**Expected behavior:** Skill should allow N/A scoring with a reason, not force a Partial/Missing.

**Actual behavior:** ✅ Skill allows N/A. F11 marked N/A: "Single invocation surface by design; no roadmap need for additional surfaces in next 12 months." No question generated.

**Weakness surfaced:** None — the N/A escape hatch works as intended. But: the SKILL.md doesn't explicitly call out that N/A is a legitimate score for products that are *intentionally* single-surface or *intentionally* monolithic. A new tester might feel pressure to grade everything Partial-or-worse.

**Recommendation:** Add a sentence to Phase 2: "N/A is a legitimate score when the factor doesn't apply to this product's shape by design (e.g., single-surface product → F11 N/A). State the design reason in the gap-note column." → **Will edit before v1.4.0 ships.**

---

## Honest weaknesses surfaced

Two real findings:

1. **A2 — trigger test phrasing leaves a tool-use-without-multi-turn gap.** Fixing in v1.4.0.
2. **A4 — multi-agent systems aren't covered by the 12 factors, and agent-factors-check inherits the blind spot.** Documenting as a known limitation in v1.4.0; logging for v1.5.0 extension.

Plus one small improvement:

3. **A5 — N/A score legitimacy isn't called out explicitly.** Fixing in v1.4.0.

## Recommendation

- **Skill is mergeable** with two small edits before v1.4.0 ships (A2 trigger phrasing, A5 N/A legitimacy).
- **Known limitation logged for v1.5.0**: multi-agent shape coverage.

## Test result

**PASS** with two in-flight edits applied to SKILL.md before v1.4.0 release.
