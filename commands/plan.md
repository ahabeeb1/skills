---
description: Sequence a signed-off Design into a phased delivery plan with acceptance gates and rollback hooks — multi-phase work only. Delegates to the write-plan skill.
---

You are running the `write-plan` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/write-plan/SKILL.md` and follow it exactly. Also read `${CLAUDE_PLUGIN_ROOT}/skills/write-plan/references/plan-template.md` for the output format.

Plan target (ADR / spec path or slug): $ARGUMENTS

Expected inputs (the skill halts if any are missing):
- Signed-off Design from `socratic-grill` (Overview, Key decisions, Decided section)
- Slice list from `vertical-slice`
- `docs/agents/SYSTEM_CONTEXT.md` from `prior-art-research` Phase 0
- An ADR from `decision-record`, if the Design had a one-way-door decision

If a plan already exists at `docs/agents/plans/<slug>.md`, switch to UPDATE mode (surgical edit, bump `Last updated`, append to Change log). Never write a second plan for the same ADR.
