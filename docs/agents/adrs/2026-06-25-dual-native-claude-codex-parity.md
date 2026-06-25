---
Status: Accepted
Date-Created: 2026-06-25
Last-Reviewed: 2026-06-25
Superseded-By: null
Tier: Deep
Deciders: [Modie (Habeeb)]
---

# ADR: Achieve dual-native Claude Code + Codex parity from a single canonical skill source

**Status:** Accepted
**Date:** 2026-06-25
**Deciders:** Modie (Habeeb)
**Tier:** Deep

## Context

habeebs-skill ships as a Claude Code plugin (v1.28.0): 18 `SKILL.md` skills, 17 `commands/*.md` slash-command shims, 6 hook scripts + `hooks.json`, 4 subagent prompts in `agents/`, and `.claude-plugin/` manifests. The repo's existing Codex story (`AGENTS.md` §"Codex-specific notes", README §Installation) assumes Codex CLI has "no plugin system" and can only "read markdown on demand" — so the documented Codex path is vendor-the-repo-and-invoke-skills-in-prose, with no hooks and no subagents.

That assumption is now false. As of mid-2026 Codex CLI has a native **Agent Skills** system (same `SKILL.md` + `name`/`description` frontmatter, same progressive disclosure, same `references/` subdir, invoked with `$skill-name`), a **hooks engine that deliberately mirrors Claude's `hooks.json` schema** (same events including `SessionStart`/`PreToolUse`/`PostToolUse`/`SubagentStart`/`SubagentStop`, same `matcher`/`type:command`/`command`/`timeout` shape, stable since v0.124.0), native **subagents**, and **MCP**. Codex **custom prompts are deprecated in favor of skills**. The two harnesses are now ~80% structurally identical, so "100% Codex compatible" is a parity-reconciliation problem, not a port-to-a-dumber-runtime problem. The decision needed now is the source-of-truth topology — everything downstream (release type, drift policy, test shape) hangs off it.

## Decision

We will make habeebs-skill **dual-native** — a first-class plugin under Claude Code AND a first-class skill bundle under Codex CLI — from a **single canonical source** with **generated derivatives and a CI drift-check**. Specifically:

- **`skills/` stays the one canonical skill tree.** The Codex discovery tree (`.agents/skills/`) is *generated* from it by a sync script (`bin/sync-codex.sh`), never hand-edited. A CI drift-check test fails the build if the generated tree diverges from canonical.
- **Hooks are reconciled, not duplicated.** A `.codex/config.toml` registers the *same* six scripts under Codex's hooks engine; the scripts get a harness-agnostic path-resolution shim (`CLAUDE_PLUGIN_ROOT` → `CURSOR_PLUGIN_ROOT` → `git rev-parse --show-toplevel`) so one script body runs under both. Matchers are written to satisfy both Claude literal and Codex regex (`^Bash$`) dialects.
- **Frontmatter stays minimal** (`name`/`description`/`disable-model-invocation`), gated on an empirical verification that Codex ignores the foreign `disable-model-invocation` key; if it does not, fall back to a dual-key superset (this is an acceptance gate in the spec, not a silent assumption).
- **Subagent parity is full, not degraded.** Codex subagent dispatch (`SubagentStart`/`SubagentStop`) is wired into `prior-art-research` Deep mode and `parallel-dev` so the `agents/*.md` prompts run on both harnesses.
- **The change is additive.** The Claude plugin layout, install flow, and `skills/` tree are untouched, so this ships as a **minor (v1.29.0)**, not a major.

Single-source-plus-generation is the only option consistent with the repo's existing single-writer / single-source-of-truth discipline (ADR-0001, ADR-0005): it makes divergence a deterministic CI failure rather than a silent runtime bug, and it preserves the one place each skill is authored.

## Consequences

### Positive

- True dual-native parity: skills, hooks, and subagents all run on both harnesses, not a documented "Codex is second-class" fallback.
- Drift is caught by CI, not by a Codex user hitting a stale skill.
- No breaking change for existing Claude installs → minor release, low blast radius.
- Corrects a now-false claim in `AGENTS.md`/README that undersold Codex.

### Negative / Accepted trade-offs

- A build step (`bin/sync-codex.sh`) now sits between authoring and the Codex tree — contributors must run it (or let CI regenerate) rather than edit `.agents/skills/` directly. Accepted: the drift-check makes forgetting loud.
- Two hook-registration surfaces (`hooks/hooks.json` for Claude, `.codex/config.toml` for Codex) point at one script set — a third surface to keep in sync, mitigated by both referencing the same scripts and a parity test.
- Full subagent parity is the heaviest slice and carries the most Codex-specific test surface; we accept the larger v1.29.0 over a faster degraded ship.

### Operational impact

- Release flow unchanged in shape (changeset → bump → CHANGELOG → doc-sync → tag-push); the doc-sync audit gains `.agents/skills/` and `.codex/` as synced paths.
- The commit-block / tag-push carve-out (ADR-0015) and `pre-push.sh` continue to apply.

## Alternatives considered

### Option B — symlink `.agents/skills → skills`

Zero build step. Rejected: symlinks may not survive plugin packaging, fresh clones on Windows, or all CI checkouts, making Codex discovery non-deterministic across environments.

### Option C — relocate skills to one tree both harnesses natively read

Cleanest long-term, single physical tree. Rejected for v1: it breaks the Claude plugin's expected `skills/` layout, forcing a **2.0.0 major** and a migration for existing installs — disproportionate to the goal, which is achievable additively.

### Keep the prose-only Codex bridge (status quo)

Vendor-and-invoke-in-prose, no hooks/subagents. Rejected: it is built on the now-false premise that Codex lacks skills/hooks, and leaves Codex users without the guardrails (hooks) and Deep-mode research (subagents) Claude users get.

## Revisit triggers

This ADR should be reopened if any of:

- Codex changes its skill discovery paths, frontmatter schema, or hooks-event contract such that the generated tree or `.codex/config.toml` no longer loads.
- The sync script + drift-check proves insufficient (≥3 drift escapes reaching a release) — escalate to Option C single-tree.
- Claude Code changes its plugin layout to natively read `.agents/skills/`, collapsing the two trees (then Option C becomes free).
- The empirical frontmatter check fails and the dual-key superset materially bloats the description budget (ADR-0007).

## References

- Research: in-session prior-art recon + external Codex CLI capability research (2026-06-25)
- Spec: [codex-dual-native-parity](../specs/2026-06-25-codex-dual-native-parity.md)
- Plan: [codex-dual-native-parity](../plans/2026-06-25-codex-dual-native-parity.md)
- Related: ADR-0001 (single-writer SYSTEM_CONTEXT), ADR-0003 (multi-harness hook scope), ADR-0005 (lifecycle split), ADR-0007 (description budget), ADR-0015 (tag-push carve-out)
- External sources:
  - Codex Agent Skills — https://developers.openai.com/codex/skills
  - Codex hooks — https://developers.openai.com/codex/hooks
  - Codex config reference — https://developers.openai.com/codex/config-reference
  - Codex custom prompts (deprecated) — https://developers.openai.com/codex/custom-prompts

---

## Changelog

- 2026-06-25 — Initial ADR, status Accepted (decisions locked via grill on 2026-06-25).
