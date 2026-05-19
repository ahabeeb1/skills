---
description: Terminal chain link — version bump, CHANGELOG entry, doc-sync audit, PR body, and tag-push. Runs after tdd-loop GREEN.
---

You are running the `release` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/release/SKILL.md` and follow it exactly. Also read:
- `${CLAUDE_PLUGIN_ROOT}/skills/release/references/release-checklist.md` — the Phase 10 checklist
- `${CLAUDE_PLUGIN_ROOT}/skills/release/references/doc-sync-procedure.md` — expanded doc-sync audit procedure
- `${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md` Convention block — the format every entry must follow

Release target: $ARGUMENTS

Run all ten phases — pre-flight, version bump, doc-sync audit, CHANGELOG entry, version file edits, history review, release commit, PR, tag-push, GitHub release. Stop at PR + tag. No deploy, canary, or production steps.
