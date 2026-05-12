---
name: agent-factors-check
description: Domain-specific checklist invoked from socratic-grill when the spec is for an LLM/agent product (not generic CRUD). Runs the spec against the 12 factors from humanlayer/12-factor-agents and surfaces the 6 gaps habeebs-skill's main chain otherwise misses — tool-call schemas (F1/F4), state unification (F5), pause/resume API (F6), human-as-tool (F7), trigger surface (F11), and pre-fetch context (F13). Returns one Socratic question per gap to be folded into the active grilling agenda. Make sure to use this skill whenever the spec describes building an agent, assistant, copilot, chatbot, LLM workflow, RAG system, or any product where an LLM call is on the critical path. Do NOT use for generic web/CRUD/mobile apps where an LLM is absent or only peripheral, for infra-only changes, or for products that merely *consume* an external AI API without orchestrating their own agent loop.
next-skills: [socratic-grill, draft-spec]
---

# Agent Factors Check

Pressure-test an LLM/agent product spec against the 12-factor-agents manifesto. The job is not to grade — it's to surface the questions habeebs-skill's main chain (research → spec → grill → ADR) otherwise leaves implicit when the product *is* an agent.

This skill is invoked **from** `socratic-grill`, not a standalone phase. It adds 6–13 Socratic questions to the grilling agenda. After grilling resolves them, control returns to the main chain.

Why a separate skill instead of folding into `socratic-grill`'s axes? `socratic-grill`'s seven axes (performance, failure modes, scale, concurrency, migration, reversibility, observability) are domain-agnostic. The 12 factors are specific to agent products and don't apply to 80% of specs. Forcing them on every spec is overkill. A separate skill keeps the main chain lean and lets this trigger only when relevant.

## When to use this skill

**Trigger on:**

- The spec describes building an agent, assistant, copilot, chatbot, LLM workflow, RAG system, autonomous worker, or any product where an LLM call is on the critical path
- The spec uses any of: "tool call", "agent", "LLM", "prompt", "RAG", "MCP", "function calling", "human in the loop", "agentic workflow"
- `socratic-grill` is mid-grill on an agent product and you notice the standard axes don't cover tool-schema design, prompt versioning, or pause-resume semantics
- The user invokes `/factor-check` explicitly

**Do NOT trigger on:**

- Generic web/CRUD/mobile app specs (the factors don't apply)
- Infra-only changes (deployment, CI, monitoring; no agent involved)
- Products that merely *consume* an external AI API (e.g., a single `/summarize` button calling OpenAI) without orchestrating their own agent loop — the factors target agent *systems*, not LLM-as-feature
- Specs where the LLM is peripheral (e.g., a search app that *might* use embeddings later)

If unclear whether it's an agent product, ask one question: **"Does this product orchestrate multiple LLM calls across turns, OR use tool / function calls of any kind?"** If yes to either → agent product, run the check. If no to both → skip.

The "OR tool calls" branch catches single-turn workflows that *do* use tools (e.g., a one-shot "summarize and tag this ticket using a `tag_ticket` tool"). Even one tool call makes the product agent-shaped — F1, F4, F7 all become relevant.

## The 12 factors (canonical reference)

From [humanlayer/12-factor-agents](https://github.com/humanlayer/12-factor-agents). Cite the source in any output that references a factor.

1. **Natural Language to Tool Calls** — Intent → structured function call.
2. **Own Your Prompts** — Prompts as first-class versioned artifacts.
3. **Own Your Context Window** — Deliberately engineer what reaches the LLM.
4. **Tools Are Just Structured Outputs** — Tool = JSON schema, nothing more.
5. **Unify Execution State and Business State** — Agent state == app state, same store.
6. **Launch / Pause / Resume with Simple APIs** — Workflows suspend for humans, resume cleanly.
7. **Contact Humans with Tool Calls** — Human escalation via the same tool-call interface.
8. **Own Your Control Flow** — Explicit orchestration, no framework magic loops.
9. **Compact Errors into Context Window** — Distill failures for retry without wasting tokens.
10. **Small, Focused Agents** — Specialized, narrow scope; compose, don't monolithize.
11. **Trigger From Anywhere, Meet Users Where They Are** — Decouple invocation from surface.
12. **Stateless Reducer** — Agent = pure function `(state, event) → state`.
13. **(Bonus) Pre-fetch All the Context You Might Need** — Load upfront, not lazily mid-loop.

## Mapping to habeebs-skill's existing coverage

| Factor | Already covered by | Status |
|---|---|---|
| F2 Own prompts | `draft-spec`, `prior-art-research` (context-capture) | Partial |
| F3 Own context window | `prior-art-research` Phase 0 SYSTEM_CONTEXT | Partial |
| F8 Own control flow | `tdd-loop`, `vertical-slice` | Partial |
| F9 Compact errors | `systematic-debugging` | Partial |
| F10 Small focused agents | `deep-modules`, `vertical-slice` | Yes |
| F12 Stateless reducer | `parallel-dev` isolation principle | Partial |

**Gaps no skill covers (these are the focus of this check):**

| Factor | Why it's a gap |
|---|---|
| F1 NL → Tool calls | No skill mandates tool-call schema design |
| F4 Tools = structured outputs | No skill mandates JSON Schema for tool I/O |
| F5 Unify state | No skill addresses agent-state ↔ business-state coupling |
| F6 Pause/resume API | HITL labels exist but no API design for the suspend mechanic |
| F7 Human as tool call | HITL semantics exist but not as a tool-call surface |
| F11 Trigger from anywhere | No skill addresses invocation surfaces (Slack, email, web, cron) |
| F13 Pre-fetch context | Partially in `prior-art-research`, not a primitive |

## Core workflow

### Phase 1 — Confirm trigger

Read the spec (or the active grilling context). Apply the trigger test from above. If the spec is not an agent product, halt with:

```
SKIP: agent-factors-check does not apply.
  Reason: <one line — e.g., "spec is a CRUD app with no LLM orchestration".>
  Returning control to socratic-grill.
```

If unclear, ask the one-question test. Don't run the check on a non-agent spec — wasted tokens and noise in the grilling record.

### Phase 2 — Score each factor against the spec

For each of the 13 factors, mark one of:

- **✓ Addressed** — spec is explicit. Cite the spec section.
- **~ Partial** — spec touches it but leaves an ambiguity. Note what's ambiguous.
- **✗ Missing** — spec is silent. Flag as a gap.
- **N/A** — factor doesn't apply to this product **by design**. State the design reason in the gap-note column.

Bias toward Partial/Missing on first pass. If you're tempted to mark something Addressed, look for the *specific* sentence in the spec — if you can't quote it, it's Partial.

**N/A is a legitimate score** for products that are intentionally single-surface (F11 N/A by design), intentionally monolithic for one bounded responsibility (F10 N/A for a tightly-scoped single-purpose agent), or intentionally synchronous-end-to-end (F6 N/A if pause/resume is explicitly out of scope). N/A is NOT an escape hatch for "I don't know" — that's ~Partial. N/A means "we chose, with a reason." State the reason.

### Phase 3 — Generate one Socratic question per gap

For each Partial or Missing factor, write ONE concrete question to add to the grilling agenda. The question must be:

- Specific to this product (not "have you thought about tool schemas?" — use the actual tool names from the spec)
- Single-axis (don't combine factors into one question)
- Resolvable in one or two grill turns (no questions that are themselves features)

Examples (good):
- F1: "The spec mentions an `escalate_to_engineer` action. What is its exact tool-call schema — name, args, return type — and does it live in the same registry as `query_logs` and `restart_service`?"
- F6: "If a user closes the browser mid-conversation, what state must persist? Where is it stored, and how does the next page-load resume the conversation?"
- F7: "When the agent needs a refund approval, does it call a `request_human_approval` tool with structured output, or does it write a chat message and wait? If the former, who routes the approval and how is the response wired back?"

Examples (bad — reject these):
- "Have you thought about state management?" (vague)
- "Tool schemas, prompts, AND error formatting — what's the plan?" (multi-axis)
- "Should we use LangChain or build our own?" (framework war, not a gap question)

### Phase 4 — Score skip-able vs. must-grill

Not every gap needs grilling. Apply a triage:

- **Must-grill** (high blast radius if wrong): F5 (state), F6 (pause/resume), F7 (human-as-tool). These shape system architecture; getting them wrong forces a rewrite.
- **Should-grill** (medium blast radius): F1, F4, F11, F13. Affect interfaces and integration; wrong choices cause friction but not rewrites.
- **Nice-to-grill** (low blast radius): F2, F3, F8, F9, F10, F12. Important but often resolvable during implementation if missed.

Default rule: surface ALL Must-grill questions; surface Should-grill questions only if at least one Partial/Missing exists; surface Nice-to-grill questions only if the user asks for the full sweep.

### Phase 5 — Hand back to socratic-grill

Produce a factor-check record using `references/factor-check-template.md` and append it to the active grill record. Output:

```
HANDOFF: grilling agenda updated — <N> new questions added from agent-factors-check.
  Must-grill: <count> questions on factors <list>.
  Should-grill: <count> questions on factors <list>.
  Resume socratic-grill with these questions interleaved into the existing agenda.
```

## Anti-patterns this skill guards against

- **Running on non-agent specs.** Wastes tokens, pollutes the grill record. Honor the trigger test.
- **Surveying instead of grilling.** The output is concrete questions, not a factor-by-factor essay. If a factor is fine, skip it — don't write a paragraph defending the skip.
- **Treating the factors as a scoring rubric.** This isn't a grade; it's a gap-finder. A spec with 7 Missings isn't "bad" — it's an early-stage spec with 7 things worth grilling.
- **Inventing factors not in the source.** Cite humanlayer/12-factor-agents. If you find yourself adding F14, that's a new skill or a new ADR — don't smuggle it in.
- **Doing the grilling here.** This skill *generates questions*. `socratic-grill` *runs* the grilling. Don't try to resolve questions in this skill.
- **Folding all gaps into one mega-question.** Each gap gets one question. Composability matters — the user might answer F5 in turn 1 and F7 in turn 5.

## Integration with the chain

- **Upstream:** `socratic-grill` (this skill is invoked from it for agent products)
- **Downstream:** `socratic-grill` continues with the augmented agenda; outputs flow to `decision-record` as usual
- **Sibling:** `draft-spec` — if many factors are Missing, the spec may need re-drafting before grilling continues. Hand back if Missing count > 6.

## See also

- `socratic-grill` — the skill that invokes this one
- `draft-spec` — fallback if the spec needs re-drafting (too many Missings)
- `decision-record` — captures resolved factor decisions in the ADR
- humanlayer/12-factor-agents — canonical source for the factors (https://github.com/humanlayer/12-factor-agents)
- humanlayer/humanlayer — reference implementation for F7 (human-as-tool) via approval gates (https://github.com/humanlayer/humanlayer)
- `references/factor-check-template.md` — output format
- `references/factor-questions-bank.md` — example questions per factor
