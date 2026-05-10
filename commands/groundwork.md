---
description: Run the full habeebs-skill chain — prior-art-research → draft-spec → socratic-grill → decision-record. Use for non-trivial features where you want maximum rigor.
---

You are running the full habeebs-skill chain.

Read `${CLAUDE_PLUGIN_ROOT}/skills/using-habeebs-skill/SKILL.md` first to understand the chain.

Then execute in order, handing off between phases per the HANDOFF lines:

1. `prior-art-research` (find production patterns, recommend approach)
2. `draft-spec` (turn recommendation into implementation spec)
3. `socratic-grill` (drive ambiguity out of decisions)
4. `decision-record` (capture as ADR)

After the chain completes, the spec is ready for implementation via `tdd-loop`.

Feature: $ARGUMENTS
