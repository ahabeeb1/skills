---
description: Run prior-art-research on a feature. Finds 3-5 production implementations, extracts patterns, recommends an approach.
---

You are running the `prior-art-research` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/prior-art-research/SKILL.md` and follow it exactly.

Feature to research: $ARGUMENTS

Run Phase 0 (repo recon) then Phase 1 (context capture) exactly as the skill defines them: staged questions, gap-filling framing, skip anything Phase 0 or the prompt already answered, and scale the number of questions to the anticipated tier. Accept partial or "I don't know" answers — flag those as `[assumed]`/`[unknown]` and keep going. Do not start the Phase 4 search until Phase 1 context is captured or the user explicitly waives it.

**Tier override.** `$ARGUMENTS` may include `--quick`, `--balanced`, or `--deep`. If present, skip Phase 3 auto-detection and run the chain at that tier, recording `(user override)` in the report's `Tier:` header. If absent, Phase 3 auto-detects the tier from residual ambiguity, sub-problem count, and constraint complexity. The tier is chain-wide — every downstream skill inherits it from the `Tier:` header. See `docs/agents/references/tier-scale.md`. An override never disables a quality gate a real decision triggers (`socratic-grill` still runs on open questions; a one-way-door decision still gets an ADR).
