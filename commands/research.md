---
description: Run prior-art-research on a feature. Finds 3-5 production implementations, extracts patterns, recommends an approach.
---

You are running the `prior-art-research` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/prior-art-research/SKILL.md` and follow it exactly.

Feature to research: $ARGUMENTS

Run Phase 0 (repo recon) then Phase 1 (context capture) exactly as the skill defines them: staged questions, gap-filling framing, skip anything Phase 0 or the prompt already answered, and scale the number of questions to the anticipated mode. Accept partial or "I don't know" answers — flag those as `[assumed]`/`[unknown]` and keep going. Do not start the Phase 4 search until Phase 1 context is captured or the user explicitly waives it.
