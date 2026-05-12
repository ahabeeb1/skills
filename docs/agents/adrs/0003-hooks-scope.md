# ADR-0003: habeebs-skill hooks — warn-only or block-only, multi-harness aware, never own state

**Status:** Accepted
**Date:** 2026-05-12
**Deciders:** Modie (Habeeb)

## Context

habeebs-skill v1.5.x is a markdown-only methodology plugin: skills + commands + ADRs + plans live in-repo, and the chain runs deliberately under user direction. The plugin has no hooks. A 2026-05-12 self-audit (prior-art-research, Quick-Deep hybrid mode) examined whether hooks would expand value. The audit produced two corrections to earlier framing assumptions:

First, **hooks are event handlers, not state storage** — per Anthropic's official `hook-development` SKILL, hooks fire on Claude Code events (SessionStart, PreToolUse, etc.) and inject context or block tools; they don't store anything between events. ADR-0002 rejected runtime *substrates* (state stores like `.omc/state/`), so hooks fall outside that rejection.

Second, **hooks CAN be multi-harness portable**. Superpowers' `session-start` hook detects `CLAUDE_PLUGIN_ROOT` vs `CURSOR_PLUGIN_ROOT` vs the bare SDK environment and outputs platform-specific JSON. The "hooks are Claude-Code-only" objection isn't a hard constraint — it's a property of how the hook script is written.

With both blockers relaxed, the audit identified two narrow high-value hook candidates: a `SessionStart` hook that runs a silent ghost-commit check (addresses the documented squash-merge cleanup pain), and a `PreToolUse` hook on `Bash` that blocks `git commit` / `git push` on the default branch (enforces ADR-0001's never-commit-to-default rule mechanically). The convergent pattern across Superpowers (5 hooks, with SessionStart for context injection) and mattpocock/skills (one targeted PreToolUse hook in `git-guardrails-claude-code` for guardrails) confirms the SessionStart-plus-PreToolUse pair is the canonical entry into hook-shipping for a methodology plugin.

The decision is needed NOW because v1.6.0 will introduce hooks for the first time. Without an ADR locking scope, the next audit will re-litigate whether to add UserPromptSubmit, PostToolUse, prompt-based hooks, auto-formatter hooks, and so on — and "should we add this hook?" becomes a recurring question with no rubric. ADR-0003 sets the rubric.

## Decision

We will adopt hooks under three rules. Specifically:

- **Rule 1 — Warn-only or block-only, never auto-fix.** Hooks may inject context (warn) or deny a tool call (block); they may NOT modify files, reset branches, delete data, or run destructive git operations. Auto-fix belongs in skills the user invokes deliberately (e.g., `/sync`), not in event handlers that fire on their own.
- **Rule 2 — Multi-harness aware via env-var detection.** Every hook script checks `CLAUDE_PLUGIN_ROOT` / `CURSOR_PLUGIN_ROOT` / similar and emits platform-appropriate output, following Superpowers' `session-start` pattern. Hooks that genuinely cannot work on a given harness (e.g., a Claude-Code-only event) exit cleanly with no output on other harnesses.
- **Rule 3 — Stateless event handlers; no state storage.** Hooks read existing in-repo state (`SYSTEM_CONTEXT.md`, ADRs, git refs) and react to events; they NEVER write to a state directory, cache file, lock file, queue, or other persistent runtime artifact. This is ADR-0002's "no runtime substrate" rule applied at the hook level.

Two structural choices follow from the rules:

- **Plugin-discovered AND manual-install documented.** Per Superpowers issue #773, plugin hook auto-discovery is fragile in some Claude Code versions. Every hook we ship is BOTH declared in `hooks/hooks.json` (auto-discovered) AND documented in `README.md` with a manual `~/.claude/settings.json` snippet users can paste if discovery fails. This is belt-and-suspenders, not paranoia — issue #773 was unresolved at last check.
- **Disable mechanism: `HABEEBS_DISABLE_HOOKS=1` env var.** Every hook script checks this env var as its first action and exits cleanly if set. Users who want to disable our hooks without uninstalling the plugin can set the env var globally or per-shell. This is also the recommended "panic button" if a hook misfires in production.

The scope of v1.6.0 is exactly two hooks: `SessionStart` (silent `/sync check`, warn-only) and `PreToolUse` on `Bash` (block `git commit` / `git push` on default branch). No `UserPromptSubmit`, no `PostToolUse`, no prompt-based hooks, no auto-formatter or auto-test hooks. Each additional hook requires a fresh ADR-grade evaluation against the three rules — no batch adoption.

## Consequences

### Positive

- Hooks expand value at two documented pain points (squash-merge cleanup, accidental default-branch commits) without violating ADR-0001 (portability) or ADR-0002 (no runtime substrate).
- The three rules form a clear rubric for evaluating future hook proposals. "Does it auto-fix?" / "Is it multi-harness aware?" / "Does it write state?" are tractable yes/no questions.
- Multi-harness users (Codex/Cursor/OpenCode) get graceful degradation — hooks no-op cleanly on non-Claude-Code harnesses.
- The manual-install fallback path documents what users already do when issue-#773-class bugs hit; we don't pretend auto-discovery always works.
- The `HABEEBS_DISABLE_HOOKS` env var gives users an emergency exit without uninstalling the plugin — important because hooks load only at session start (no hot-swap per Anthropic spec).

### Negative / Accepted trade-offs

- **Hook authoring burden.** Every hook script must check the disable env var, detect the harness, handle absent dependencies (e.g., `gh` not installed), and exit cleanly on all failure modes. Roughly 30-50 lines of bash per hook vs the bare minimum of ~10. Accepted because the alternative (sprawl + flaky behavior) is worse.
- **No prompt-based hooks in v1.6.0.** Anthropic recommends prompt-based hooks for context-aware decisions, but command hooks are more deterministic and easier to reason about for a first release. Deferred to v1.7.x if/when we understand the failure modes of the two command hooks we're shipping.
- **No hot-swap.** Hooks load at session start; changes require restarting Claude Code. Accepted because this is a platform limitation, not a habeebs-skill choice. Documented in README.
- **One opinionated default per hook.** The PreToolUse block-list (`git commit` / `git push` on default branch) is opinionated and may false-positive on a small number of legitimate workflows (e.g., direct hotfixes by a solo dev who knows what they're doing). Mitigated by: (a) the env-var disable, (b) a per-repo allowlist file documented in the hook's README. Not by per-install authorization (rejected as too much friction).

### Operational impact

- No new install steps for users on the happy path (auto-discovery works).
- README gains a "Hooks" section with: what each hook does, how to verify it's installed, manual-install snippet, disable env var.
- v1.6.0 manifest bump is MINOR (new opt-in behavior — hooks fire automatically on install).
- No new tests required (hooks are bash scripts, tested via dogfood — same approach as the rest of the skills).

## Alternatives considered

### Reject hooks entirely

Keep habeebs-skill markdown-only, no hooks ever. Rejected: the research surfaced two real user pains (squash-merge cleanup, default-branch commits) that hooks solve materially better than skill text alone. ADR-0001 and ADR-0002 don't block hooks once you separate event handlers from state substrate.

### Adopt a full hook system (all 5+ events)

Ship `SessionStart`, `UserPromptSubmit`, `PostToolUse`, `Stop`, and `SessionEnd` from the start — match Superpowers' coverage. Rejected: hook sprawl risk. `UserPromptSubmit` fires on every prompt and is the easiest to misclassify and misfire. `PostToolUse` after destructive ops (e.g., `gh pr merge`) is appealing but couples us to specific tool patterns that may change. Better to ship two hooks, learn the failure modes, then expand if and only if a specific value-add is demonstrated.

### Per-install hook authorization (user OKs each hook on install)

Make hook installation interactive — user types `y` per hook before it activates. Rejected: too much friction for the value delivered. mattpocock's `git-guardrails` activates hooks on install without per-hook confirmation; the disable env var is sufficient as a backstop.

### Prompt-based hooks only

Use Anthropic's "prompt" hook type instead of command hooks — let the model evaluate each event in context. Rejected for v1.6.0: prompt hooks are more flexible but harder to reason about and add a per-event Anthropic API call. Command hooks are deterministic and free. Revisit in v1.7.x after command hooks have shipped and we understand the patterns.

### Hooks that auto-fix (e.g., auto-run `/sync` on SessionStart)

Have SessionStart not just warn but actually run `git reset --hard origin/<default>` when ghost commits are detected. Rejected: violates rule 1 (warn-only or block-only). Auto-fix on session start means the user can't audit what happened — they see the new state with no agency. The user explicitly authorized destructive ops twice today (the two squash-merge cleanups); same posture applies to hooks.

## Revisit triggers

This ADR should be reopened if any of:

- Anthropic deprecates the `hooks/hooks.json` schema or changes hook discovery in a way that breaks the plugin-discovered path. Manual-install fallback continues to work either way.
- Claude Code's plugin hook auto-discovery becomes reliable enough that the manual-install fallback section in README can be removed (track via Superpowers issue #773 resolution).
- A use case emerges that requires a stateful hook (e.g., persisting which slice is in progress across sessions). This would require revisiting rule 3 — likely by externalizing the state to an in-repo file rather than a hook-owned cache.
- A user-reported false-positive on the PreToolUse default-branch block accumulates to the point that the opinionated default is wrong. Likely a v1.6.x patch, not an ADR reopen — unless the right fix is a fundamentally different scope.
- The disable env var `HABEEBS_DISABLE_HOOKS=1` is found to be insufficient (e.g., users need per-hook disable, or a runtime toggle). Revisit the disable mechanism.

## References

- Research: prior-art-research output (in-conversation, 2026-05-12) — hooks audit
- Sister ADRs: [`adrs/0001-environment-binding-via-system-context`](./0001-environment-binding-via-system-context.md) (portability), [`adrs/0002-habeebs-skill-standalone`](./0002-habeebs-skill-standalone.md) (no runtime substrate). ADR-0003 sits between them: hooks add Claude-Code-event-handling without violating either.
- Plan (forthcoming): `plans/0003-hooks-v1.6.0.md` — implementation plan for the two hooks plus README + CHANGELOG.
- SYSTEM_CONTEXT: [`SYSTEM_CONTEXT.md`](../SYSTEM_CONTEXT.md)
- External sources:
  - [Anthropic — `plugin-dev/skills/hook-development/SKILL.md`](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/hook-development/SKILL.md) — authoritative authoring guide; schema, events, security cautions.
  - [Anthropic — Hooks reference](https://code.claude.com/docs/en/hooks) — full hook event documentation.
  - [obra/superpowers `hooks/session-start`](https://github.com/obra/superpowers/blob/main/hooks/session-start) — direct precedent for SessionStart, including multi-platform env-var detection.
  - [obra/superpowers issue #773](https://github.com/obra/superpowers/issues/773) — real-world auto-discovery failure that motivates the manual-install fallback.
  - [mattpocock/skills `git-guardrails-claude-code/SKILL.md`](https://github.com/mattpocock/skills/blob/main/skills/misc/git-guardrails-claude-code/SKILL.md) — direct precedent for PreToolUse-on-Bash; one-targeted-hook pattern.

---

## Changelog

- 2026-05-12 — Initial ADR, status Accepted (implementation lands in v1.6.0 per plan 0003).
