---
name: plan
description: Turn a locked ADR + sliced spec into a phased delivery plan with acceptance gates and rollback hooks. Delegates to the write-plan skill.
---

Invoke the `write-plan` skill from `skills/write-plan/SKILL.md`.

Expected inputs (the skill halts if any are missing):
- ADR from `decision-record` (locked)
- Sliced spec from `vertical-slice` / `draft-spec`
- Grill record from `socratic-grill` (for accepted trade-offs and revisit triggers)
- `docs/agents/SYSTEM_CONTEXT.md` from `prior-art-research` Phase 0

If a plan already exists at `docs/agents/plans/<slug>.md`, switch to UPDATE mode (surgical edit, bump `Last updated`, append to Change log). Never write a second plan for the same ADR.
