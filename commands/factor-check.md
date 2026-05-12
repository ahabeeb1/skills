---
name: factor-check
description: Pressure-test an agent/copilot/LLM-workflow spec against the 12 factors from humanlayer/12-factor-agents. Delegates to the agent-factors-check skill.
---

Invoke the `agent-factors-check` skill from `skills/agent-factors-check/SKILL.md`.

This skill is normally invoked *from* `socratic-grill` mid-grill when the spec is for an agent product. Direct invocation via `/factor-check` runs the same procedure standalone — useful when retro-checking an already-grilled spec or when the spec was authored outside the chain.

Honor the trigger test: if the spec is not an agent product (no LLM orchestration, no tool calls), the skill halts with `SKIP` and returns control rather than producing noise.
