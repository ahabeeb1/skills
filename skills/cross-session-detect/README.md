# cross-session-detect

A **hook-support script library**, not a chain skill. It has no `SKILL.md` by
design: it is never invoked by the model or by a `/slash` command — it is driven
entirely by the habeebs-skill hooks (`hooks/session-start-peer-scan.sh`,
`hooks/pretool-use-peer-scan.sh`). That is also why it is not counted among the
18 chain `SKILL.md` skills (dogfood scenario 11 `check-disabled-list.sh`).

Its job: detect when **another live session** is working the same repo, so two
agents (or two humans, or a human + an AFK fleet) don't silently clobber each
other's work. Substrate-free per ADR-0002 — state lives in per-repo JSON
sidecars under `<git-common-dir>/habeebs-sessions/`, never a daemon or DB.
Concurrency model validated against Cursor's 8-cap JSON-sidecar approach
(see SYSTEM_CONTEXT reconciliation 2026-05-25).

## Scripts

**Live (wired into hooks, run every session):**

| Script | Role |
|---|---|
| `sidecar.sh` | Write/list/end per-session sidecar JSON; liveness probe (`process.kill(pid,0)` via node); TTL-gated pruning. Fails **safe** — when node is unavailable the liveness probe returns `inconclusive`, never `dead`, so a live peer's sidecar is never wrongly pruned. |
| `overlap.sh` | `git merge-tree` probe — does a peer's stashed work conflict with the file about to be edited? |
| `policy.sh` | Resolve the effective policy from `.claude/habeebs-policy.json` (e.g. `pretool_use: true` opt-in). |
| `audit.sh` | Append a conflict record to `docs/agents/conflicts/` when a session conflict is detected (runtime writer path per ADR-0019). |

**Halt-UX (NOT currently wired into any hook — manual/future use):**

| Script | Role | Status |
|---|---|---|
| `actions.sh` | Action handlers for a detected conflict (abort / merge / view / continue / sequence). | Unwired. `do_merge` reports the real merge outcome (`markers_inserted` / `merged_clean` / `merge_failed`), not an assumed success. |
| `halt-ux.sh` | Interactive 5-option halt menu. | Unwired **and** structurally incompatible with the current hook environment: it reads choices from stdin with `read`, but Claude Code hooks run non-interactively (no TTY). Wiring it would require a non-interactive redesign (emit a choice payload the model renders). |
| `trust.sh` | Signed-signal trust verification for halt signals. | Unwired; supports the halt-UX path above. |

The live scripts are cohesive, hook-consumed, and Windows/MSYS path-aware. The
halt-UX trio is retained because it is specced (v1.16.0 spec) and tested
(`tests/actions`, `tests/halt-ux`, `tests/trust`), but it is dormant at runtime
— see the audit note in SYSTEM_CONTEXT. Treat "wire or remove the halt-UX" as an
open decision, not a shipped feature.
