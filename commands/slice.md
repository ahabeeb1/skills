---
description: Decompose a spec or plan into vertical slices labeled HITL or AFK. Optionally publishes to the configured issue tracker.
---

You are running the `vertical-slice` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/vertical-slice/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/skills/vertical-slice/references/hitl-vs-afk.md`.

Input plan / spec / feature: $ARGUMENTS

Each slice must be VERTICAL (end-to-end), not horizontal. Default to AFK label unless the slice genuinely needs human input mid-flow.
