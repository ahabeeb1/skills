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

All four are live: wired into the hooks and run every session.

| Script | Role |
|---|---|
| `sidecar.sh` | Write/list/end per-session sidecar JSON; liveness probe (`process.kill(pid,0)` via node); TTL-gated pruning. Fails **safe** — when node is unavailable the liveness probe returns `inconclusive`, never `dead`, so a live peer's sidecar is never wrongly pruned. |
| `overlap.sh` | `git merge-tree` probe — does a peer's stashed work conflict with the file about to be edited? |
| `policy.sh` | Resolve the effective policy from `.claude/habeebs-policy.json` (e.g. `pretool_use: true` opt-in). |
| `audit.sh` | Append a conflict record to `docs/agents/conflicts/` when a session conflict is detected (runtime writer path per ADR-0019). |

The scripts are cohesive, hook-consumed, and Windows/MSYS path-aware. Detection
is **advisory** — the hooks warn/annotate; they never block or auto-resolve.

> **Removed in v1.28.0:** an interactive halt-UX trio (`actions.sh`,
> `halt-ux.sh`, `trust.sh`) was deleted. It was specced in v1.16.0 and tested,
> but never wired into a hook, and `halt-ux.sh` read choices via interactive
> `read` — which cannot run in Claude Code's non-interactive hook environment. If
> in-session conflict *halting* (not just warning) is wanted later, it needs a
> non-interactive redesign that emits a choice payload the model renders. See the
> removal ADR.
