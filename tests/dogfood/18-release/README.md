# Dogfood 18 — `release` skill + ADR-0015 hook carve-out (3-scenario suite)

**Date:** 2026-05-18
**Skill under test:** `skills/release/SKILL.md`
**Hook under test:** `hooks/preventing-commits-to-default.sh` (tag-push carve-out)
**Slice:** v1.14.0 #2 (gstack-capability-adoption spec)
**Spec:** [`docs/agents/specs/v1.13.0-gstack-capability-adoption.md`](../../../docs/agents/specs/v1.13.0-gstack-capability-adoption.md) Slice 2
**ADRs:** [ADR-0014](../../../docs/agents/adrs/0014-adopt-gstack-capabilities-markdown-idea-port.md), [ADR-0015](../../../docs/agents/adrs/0015-hook-allow-tag-pushes-on-default.md), [ADR-0003](../../../docs/agents/adrs/0003-hooks-scope.md)

## Why a directory, not a single file

`release` is the terminal chain link and the first skill that pushes a tag on the default branch. It has two distinct verification surfaces: the skill behavior (does it produce the correct artifact set?) and the hook behavior (does the ADR-0015 carve-out allow the tag-push without allowing branch-commits?). Testing both in one scenario would conflate them. Three scenarios separate the concerns cleanly.

## The scenarios

| File | Type | What is tested | Expected verdict |
|---|---|---|---|
| [18a-release-artifacts.md](./18a-release-artifacts.md) | Positive — skill behavior | Release skill produces correct version bump + CHANGELOG entry + PR body; emits no deploy steps | All artifacts correct; no deploy/canary/benchmark output |
| [18b-hook-allows-tag-push.md](./18b-hook-allows-tag-push.md) | Positive — hook carve-out | `git push origin refs/tags/v1.14.0` on the default branch is ALLOWED | Hook exits 0 (allows the push) |
| [18c-hook-still-blocks-branch.md](./18c-hook-still-blocks-branch.md) | Negative — hook control | `git commit` and bare `git push` on the default branch are still BLOCKED | Hook exits 2 (blocks both commands) |

## Acceptance bar

Slice 2 is not complete unless all three scenarios produce the expected verdict:

- **18a** verifies the skill's artifact set is complete and correct — the core release behavior.
- **18b** verifies the ADR-0015 carve-out works — the tag-push that would previously have been blocked is now allowed.
- **18c** is the load-bearing control — the carve-out must not have widened the block predicate. `git commit` and bare `git push` on the default branch must still exit 2.

18c failing means the carve-out is too broad and the ADR-0001 never-commit-to-default protection has been weakened. That is a blocking defect.

## How to run

These are illustrative scenarios, not automated tests (consistent with dogfood 17). Run each manually:

1. Set up (or mentally model) the scenario's described target state.
2. Invoke the skill or simulate the hook input as described.
3. Inspect the output against the scenario's "Expected output" and "Pass / fail" sections.
4. Pass / fail per the scenario's criteria.

## Revisit triggers

- A release run produces a tag push that hits the hook block post-merge — add a scenario for the ambiguous form that caused it.
- 18c fails (the hook allows a bare `git push` on the default branch) — the carve-out logic has a bug; fix `preventing-commits-to-default.sh` and re-run.
- The `release` skill emits a deploy step in a production run — add a scenario for the specific form that leaked through.
