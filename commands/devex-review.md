---
description: DX lens for developer-facing product specs — onboarding friction, API ergonomics, error-message quality, docs-as-experienced, upgrade friction. Conditional extension of socratic-grill; fires for CLI/SDK/library/plugin/framework specs only.
---

You are running the `devex-review` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/devex-review/SKILL.md` and follow it exactly.

Review target (spec path): $ARGUMENTS

This skill is normally invoked *from* `socratic-grill` mid-grill when the spec is for a developer-facing product (CLI, SDK, library API, plugin, or developer framework). Direct invocation via `/devex-review` runs the same procedure standalone — useful when retro-checking an already-grilled spec or when the spec was authored outside the chain.

Honor the trigger test: if the product is not developer-facing (internal CRUD, end-user web/mobile app), the skill halts with `SKIP` and returns control rather than producing noise.
