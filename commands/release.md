---
description: Terminal chain link — version bump, CHANGELOG entry, doc-sync audit, PR body, and tag-push. Runs after tdd-loop GREEN.
---

You are running the `release` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/release/SKILL.md` and follow it exactly. Also read:
- `${CLAUDE_PLUGIN_ROOT}/skills/release/references/release-checklist.md` — the printable phase-by-phase checklist
- `${CLAUDE_PLUGIN_ROOT}/skills/release/references/doc-sync-procedure.md` — expanded doc-sync audit procedure
- `${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md` Convention block — the format every entry must follow

Release target: $ARGUMENTS

Run the phases in order: pre-flight, (1) bump type, (2) doc-sync audit, (3.25) changeset aggregation — which does the version bump + CHANGELOG generation, (3) enrich the CHANGELOG entry, (4) verify the bump, (5) history review, (6) commit, (7) PR, (8) tag-push, (9) GitHub release, (9.5) dormancy scan on minor/major, (10) handoff. The version files and CHANGELOG are produced by changeset aggregation, not hand-edited (except the documented no-changesets fallback). Stop at PR + tag. No deploy, canary, or production steps.
