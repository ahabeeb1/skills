---
name: agent-factors-check
description: Conditional socratic-grill extension for LLM/agent specs. Use when socratic-grill detects "this is an agent", "we're building a copilot", "RAG system", "function-calling product", or user types "/factor-check" on an LLM-orchestration spec. Do not use for generic CRUD/web/mobile apps without LLM orchestration.
disable-model-invocation: true
---

# Agent Factors Check

**PRESSURE-TEST EVERY AGENT FACTOR THE DESIGN TOUCHES.**

Pressure-test an LLM/agent product spec against the 13 agent quality factors. The job is not to grade — it's to surface the questions habeebs-skill's main chain (research → spec → grill → ADR) otherwise leaves implicit when the product *is* an agent.

This skill is invoked **from** `socratic-grill`, not a standalone phase. It adds 6–13 Socratic questions to the grilling agenda. After grilling resolves them, control returns to the main chain.

Why a separate skill instead of folding into `socratic-grill`'s axes? `socratic-grill`'s production-readiness axes (performance, failure modes, scale, concurrency, migration, reversibility, observability) are domain-agnostic. The agent factors are specific to agent products and don't apply to 80% of specs. Forcing them on every spec is overkill. A separate skill keeps the main chain lean and lets this trigger only when relevant.

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

## The 13 factors (canonical reference)

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

Follow the shared **[grill-extension protocol](../../docs/agents/references/grill-extension-protocol.md)** — pre-flight environment check, Phase 1 confirm-trigger (the SKIP block + the one-question test in "When to use" above), Phase 2 score each factor (✓/~/✗/N/A, bias to Partial/Missing), Phase 3 one specific single-axis Socratic question per gap, Phase 4 triage, Phase 5 hand back. The protocol also carries the shared anti-patterns (run only on agent specs, generate questions not design, don't fold gaps into mega-questions, don't invent factors beyond the closed 13). Only the factor-specific pieces are below.

**Phase 4 triage — which factors sit in which tier:**

- **Must-grill** (wrong forces a rewrite): F5 (state), F6 (pause/resume), F7 (human-as-tool).
- **Should-grill** (interface/integration friction): F1, F4, F11, F13.
- **Nice-to-grill** (resolvable during implementation): F2, F3, F8, F9, F10, F12.

**Phase 3 example questions** (good — specific, single-axis):

- F1: "The spec mentions an `escalate_to_engineer` action. What is its exact tool-call schema — name, args, return type — and does it live in the same registry as `query_logs` and `restart_service`?"
- F6: "If a user closes the browser mid-conversation, what state must persist? Where is it stored, and how does the next page-load resume the conversation?"
- F7: "When the agent needs a refund approval, does it call a `request_human_approval` tool with structured output, or does it write a chat message and wait? If the former, who routes the approval and how is the response wired back?"

**Record:** produce a factor-check record using `references/factor-check-template.md`; the hand-back `HANDOFF: grilling agenda updated` line names the factors per tier. If Missing count > 6, hand back to `draft-spec` before grilling continues (the spec may need re-drafting).

## Integration with the chain

- **Upstream:** `socratic-grill` (this skill is invoked from it for agent products)
- **Downstream:** `socratic-grill` continues with the augmented agenda; outputs flow to `decision-record` as usual
- **Sibling:** `draft-spec` — if many factors are Missing, the spec may need re-drafting before grilling continues. Hand back if Missing count > 6.

## See also

- `socratic-grill` — the skill that invokes this one
- `draft-spec` — fallback if the spec needs re-drafting (too many Missings)
- `decision-record` — captures resolved factor decisions in the ADR
- `references/factor-check-template.md` — output format
- `references/factor-questions-bank.md` — example questions per factor
