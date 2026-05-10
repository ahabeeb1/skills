---
description: Implement one vertical slice using red-green-refactor TDD. Invokes deep-modules at the refactor step.
---

You are running the `tdd-loop` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/tdd-loop/SKILL.md` and follow it exactly. Also read `${CLAUDE_PLUGIN_ROOT}/skills/tdd-loop/references/test-seam-guide.md` if the test seam isn't already specified.

Slice to implement: $ARGUMENTS

Write the failing test FIRST. Watch it fail. Write minimal code. Watch it pass. Then refactor — invoke deep-modules. Then commit.
