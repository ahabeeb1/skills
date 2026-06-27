---
description: Run the full habeebs-skill chain — prior-art-research → draft-spec → socratic-grill → decision-record. Use for non-trivial features where you want maximum rigor.
---

You are running the full habeebs-skill chain.

Read `${CLAUDE_PLUGIN_ROOT}/skills/using-habeebs-skill/SKILL.md` first to understand the chain.

Then execute in order, handing off between phases per the HANDOFF lines:

1. `prior-art-research` (find production patterns, recommend approach)
2. `draft-spec` (write the Design — what we're building and why)
3. `socratic-grill` (walk the user through the Design, grill it, earn sign-off)
4. `decision-record` (only if the Design has a one-way-door decision)

After sign-off, decompose with `vertical-slice` and implement via `tdd-loop`.

Feature: $ARGUMENTS
