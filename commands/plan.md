---
description: Turn a locked ADR + sliced spec into a phased delivery plan with acceptance gates and rollback hooks. Delegates to the write-plan skill.
---

You are running the `write-plan` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/write-plan/SKILL.md` and follow it exactly. Also read `${CLAUDE_PLUGIN_ROOT}/skills/write-plan/references/plan-template.md` for the output format.

Plan target (ADR / spec path or slug): $ARGUMENTS

Expected inputs (the skill halts if any are missing):
- ADR from `decision-record` (locked)
- Sliced spec from `vertical-slice` / `draft-spec`
- Grill record from `socratic-grill` (for accepted trade-offs and revisit triggers)
- `docs/agents/SYSTEM_CONTEXT.md` from `prior-art-research` Phase 0

If a plan already exists at `docs/agents/plans/<slug>.md`, switch to UPDATE mode (surgical edit, bump `Last updated`, append to Change log). Never write a second plan for the same ADR.
