---
Status: Accepted
Date-Created: 2026-06-13
Last-Reviewed: 2026-06-13
Superseded-By: null
Tier: Quick
Deciders: [Modie (owner), Claude (audit follow-up)]
---

# Remove the unwired, non-interactive-incompatible cross-session halt-UX

**Status:** Accepted
**Date:** 2026-06-13
**Deciders:** Modie (owner), Claude (audit follow-up)
**Tier:** Quick

## Context

The v1.16.0 cross-session conflict-detection feature ([spec](../specs/v1.16.0-cross-session-conflict-detection.md)) shipped two layers. The **detection** layer — `sidecar.sh`, `overlap.sh`, `policy.sh`, `audit.sh` — is wired into the SessionStart and PreToolUse peer-scan hooks and runs every session (advisory: it warns/annotates, never blocks). The **halt-UX** layer — `actions.sh` (conflict action handlers), `halt-ux.sh` (a 5-option menu), and `trust.sh` (signed-signal verification) — was specced and tested but never wired into any hook.

The 2026-06-13 full skill-base audit found the halt-UX layer is not merely dormant pending wiring: `halt-ux.sh` reads the operator's choice via interactive `read` from stdin, and Claude Code hooks (and agent turns) run **non-interactively** with no TTY. The menu can never execute in its target environment as written. ~400 lines of skill code plus three test suites (~34 assertions) were unreachable in production while passing against a self-contained test harness.

## Decision

Delete `skills/cross-session-detect/{actions.sh,halt-ux.sh,trust.sh}` and their test suites (`tests/{actions,halt-ux,trust}/`). Remove their references from the dogfood-19 sub-runner (`run-all.sh` Slices 7-12+14) and the end-to-end `scenarios.sh` (scenario (f)). The detection layer is untouched and remains the shipped behavior: cross-session detection is **advisory** (warn/annotate), not a blocking halt.

If in-session conflict *halting* (rather than warning) is wanted in the future, it must be rebuilt non-interactively — emitting a structured choice payload the model renders and acts on, never reading a TTY. That is a new feature behind a fresh spec, not a re-wiring of this code.

## Consequences

- ~400 lines of unreachable skill code and three dead test suites removed; the cross-session library is now four cohesive, hook-consumed scripts.
- No runtime behavior changes — the deleted code never ran in production.
- The v1.16.0 spec and ADR-0019 remain accurate about the detection layer; only the halt-UX half is retired.

## Alternatives considered

- **Wire it via a non-interactive redesign.** Rejected for now: in-session blocking halts were never an active requirement, and the advisory detection layer already covers the surfaced need. Left as a clearly-scoped future option.
- **Leave it dormant + documented.** Rejected: documenting dead weight that *cannot* run in its target environment is honest but still ships unreachable code and maintenance surface against the "no waste / earned complexity" bar.

## Revisit triggers

- A concrete need for blocking (not advisory) in-session conflict resolution arises → spec a non-interactive halt-UX from scratch.

## References

- [v1.16.0 cross-session conflict-detection spec](../specs/v1.16.0-cross-session-conflict-detection.md)
- [ADR-0019](./0019-amend-adr-0002-for-advisory-in-flight-reads.md) — the advisory in-flight read guard governing the surviving detection layer
- `skills/cross-session-detect/README.md` — current library description
