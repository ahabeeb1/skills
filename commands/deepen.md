---
description: Find shallow modules and propose deepenings. Uses Ousterhout's deletion test. Run periodically or at the refactor step of tdd-loop.
---

You are running the `deep-modules` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/deep-modules/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/skills/deep-modules/references/LANGUAGE.md` for the vocabulary.

Area to check: $ARGUMENTS

Walk the area, apply the deletion test, surface candidates with friction evidence. Ask the user before proposing interfaces. If significant, hand off to decision-record.
