---
description: Pressure-test an agent/copilot/LLM-workflow spec against the 13 agent quality factors. Delegates to the agent-factors-check skill.
---

You are running the `agent-factors-check` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/agent-factors-check/SKILL.md` and follow it exactly.

Audit target (spec path): $ARGUMENTS

This skill is normally invoked *from* `socratic-grill` mid-grill when the spec is for an agent product. Direct invocation via `/factor-check` runs the same procedure standalone — useful when retro-checking an already-grilled spec or when the spec was authored outside the chain.

Honor the trigger test: if the spec is not an agent product (no LLM orchestration, no tool calls), the skill halts with `SKIP` and returns control rather than producing noise.
