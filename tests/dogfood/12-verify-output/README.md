# Dogfood scenario 12 — verify-output

Validates the `verify-output` skill (slice 3 of v1.9.0; [ADR-0008](../../../docs/agents/adrs/0008-verify-output-skill-scope.md)) against three planted-diff scenarios.

## Scenarios

- **12a — planted moderate slop.** A diff with H1-H6 hits (unjustified comments, defensive validation past trusted boundaries, etc.). Expected: `DONE_WITH_CONCERNS` in ANNOTATE mode (default); `BLOCKED` in `--gate` mode.
- **12b — clean control.** A diff with no slop. Expected: `DONE` in both modes.
- **12c — severe slop.** A diff with H7 hits (half-finished implementation, unreachable code, declared-and-unused). Expected: `BLOCKED` in both modes.

## How to run

Each scenario is a markdown fixture describing:
1. The planted diff (as a code block — paste into a scratch repo or apply via `git apply` to a fresh branch)
2. Expected `verify-output` invocation
3. Expected status and concerns list

Run `verify-output` against the planted diff (staged via `git add`), capture the output, compare against the expected status. Failure = the skill produced a different status OR missed a planted concern.

These are integration scenarios — they exercise the actual skill against realistic-looking diffs, not unit tests of the heuristic-detection logic.

## Pre-merge gate

These scenarios run as part of the slice-3 PR pre-merge dogfood suite. They also re-run any time `references/slop-heuristics.md` changes (a heuristic edit must keep all three scenarios passing).
