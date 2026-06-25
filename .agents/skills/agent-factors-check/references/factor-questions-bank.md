# Factor Questions Bank

Concrete question templates per factor. Use these as starting points; customize with the actual entity names from the spec. Never paste verbatim — vague templates produce vague answers.

---

## F1 — Natural language → tool calls

**What's at stake:** the agent's output must be a deterministic structured call, not free-form text that some code attempts to parse later.

**Question templates:**
- "When the agent decides to do `<action>`, what is the exact tool-call schema? Name the tool, list its arguments with types, and state its return type."
- "Are tool calls validated at the LLM boundary (e.g., JSON Schema) or only when downstream code parses them? Where does invalid schema produce its error?"
- "If the LLM emits an action the schema doesn't recognize, what happens — retry, fallback, or escalate?"

## F2 — Own your prompts

**What's at stake:** prompts hidden inside framework defaults rot silently and can't be reviewed in PRs.

**Question templates:**
- "Where do the prompts for `<agent name>` live in the repo? Are they tracked files or runtime strings?"
- "Are prompts versioned? When `<agent name>`'s prompt changes, is the old version retained for replay/regression?"
- "Who can change a prompt without code review? If 'anyone via env var', is that intentional?"

## F3 — Own your context window

**What's at stake:** uncontrolled context blows token budgets, leaks PII, and confuses the model.

**Question templates:**
- "What's the per-turn token budget for `<agent name>`'s context window? What enters that context — system prompt, recent turns, retrieved docs, tool outputs, anything else?"
- "When context approaches the budget, what's the eviction policy — oldest turn out, summarize, hard-fail?"
- "Is any user PII ever in the context window? If yes, what redaction runs before the LLM call?"

## F4 — Tools are structured outputs

**What's at stake:** tools are JSON Schema, not arbitrary objects. Frameworks that hide the schema make debugging harder.

**Question templates:**
- "Where is the JSON Schema for `<tool name>` defined? Is it the source of truth, or generated from code annotations?"
- "If the schema changes, do downstream consumers (UI, audit logs, replay) pick up the change automatically or via a versioned schema registry?"
- "Are tool outputs typed end-to-end (LLM → app code → response) or do they get stringified somewhere?"

## F5 — Unify execution + business state

**What's at stake:** if the agent's state lives in a separate store from the business data, you get drift and inconsistent recovery.

**Question templates:**
- "When the agent updates `<business entity>`, does it write to the same database as the business app does? If a separate store, how are they kept consistent?"
- "After a crash mid-conversation, can the next process read the agent's state and the business state from the same transactional boundary?"
- "Is there a single 'source of truth' query that returns both 'what the agent thinks' and 'what the user sees'?"

## F6 — Launch / pause / resume APIs

**What's at stake:** real agents pause for humans, timeouts, async work. The pause/resume API is load-bearing — if absent, the agent can only run synchronously to completion.

**Question templates:**
- "If `<agent name>` is mid-conversation and the user closes the browser, what state must persist? Where is it stored, and what's the API to resume?"
- "Can the agent be paused programmatically (e.g., timer fires, external event)? What's the pause API — a flag, a queue, a workflow engine?"
- "When resuming, does the agent re-emit the last tool call, replay from the start, or pick up from the suspended point?"

## F7 — Contact humans with tool calls

**What's at stake:** human escalation should use the same tool-call mechanism as everything else, not be a special chat-message hack.

**Question templates:**
- "When `<agent name>` needs human approval for `<action>`, does it call a `request_human_approval` tool with structured output, or does it write a chat message? If a tool, who routes the request and how is the response wired back?"
- "What's the timeout on a human approval? What happens if it expires?"
- "If multiple humans can approve, how is the race resolved — first wins, quorum, designated approver?"

## F8 — Own your control flow

**What's at stake:** framework-managed loops hide control-flow decisions and complicate debugging.

**Question templates:**
- "Where is `<agent name>`'s main loop? Is it explicit code in this repo, or hidden inside a framework call?"
- "What are the loop exit conditions — max turns, success signal, error? Are they explicit?"
- "If the loop is framework-managed, can you trace what happens between turn N and turn N+1 by reading code in this repo alone?"

## F9 — Compact errors into context

**What's at stake:** verbose errors waste context; opaque errors lead the LLM into the same failure again.

**Question templates:**
- "When `<tool name>` fails, what's the error format fed back into the LLM context? Is it the raw stack trace, a one-line summary, or a structured `{code, message}` object?"
- "Are repeated failures deduplicated, or does the same error consume context turn after turn?"
- "Does the LLM see enough to recover (e.g., 'auth token expired' → it can retry with refreshed token), or just enough to fail again?"

## F10 — Small focused agents

**What's at stake:** one mega-agent doing many things is a maintenance disaster. Decompose.

**Question templates:**
- "How many distinct responsibilities does `<agent name>` have? Could it be split into two specialized agents with a coordinator?"
- "If the spec describes multiple workflows (refund, escalation, knowledge-query), is each its own agent or are they one prompt with mode flags?"
- "What's the test surface for the whole agent vs. for its sub-responsibilities?"

## F11 — Trigger from anywhere

**What's at stake:** agents should be reachable from where the user already is (Slack, email, web, cron).

**Question templates:**
- "What invocation surfaces does `<agent name>` support — web UI, Slack, email, cron, webhook? Are they additive or does each duplicate the agent logic?"
- "Is there a single entry point that all surfaces call into, or does each surface have its own agent instance?"
- "What's the latency profile per surface? Cron can be slow; Slack must be sub-second-perceived."

## F12 — Stateless reducer

**What's at stake:** agents that maintain in-memory state across turns are hard to scale horizontally and hard to recover.

**Question templates:**
- "Is `<agent name>` a pure function `(state, event) → (new_state, action)`, or does it hold state in-process between turns?"
- "Can two replicas of `<agent name>` handle alternating turns of the same conversation without coordination, given access to the shared state store?"
- "Where does cross-turn state actually live — in-memory, Redis, Postgres, the LLM's context window?"

## F13 — Pre-fetch context (bonus)

**What's at stake:** lazy mid-loop fetches add latency and tokens. Pre-fetching is often cheaper.

**Question templates:**
- "What context can be loaded BEFORE the first LLM call for a given session? (user profile, recent activity, relevant docs)"
- "Are there mid-loop fetches that the spec describes as 'just-in-time' — could they be pre-fetched instead?"
- "What's the budget trade-off — pre-fetching saves latency but costs upfront tokens. Where's the line?"
