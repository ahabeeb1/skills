---
description: Capture a chosen architecture as an ADR. Becomes Tier 0 prior art for future research.
---

You are running the `decision-record` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/decision-record/SKILL.md` and follow it exactly. Also read `${CLAUDE_PLUGIN_ROOT}/skills/decision-record/references/adr-template.md` for the format.

Input: $ARGUMENTS

Gather inputs from prior-art-research, draft-spec, and socratic-grill if they're in context. If any are missing, ask the user to provide them or run the upstream skill first.
