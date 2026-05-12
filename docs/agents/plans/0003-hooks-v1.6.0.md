# Plan: Ship two hooks per ADR-0003 — v1.6.0

| Field         | Value                                                     |
|---------------|-----------------------------------------------------------|
| Plan ID       | `plans/0003-hooks-v1.6.0`                                 |
| ADR           | [`adrs/0003-hooks-scope`](../adrs/0003-hooks-scope.md)    |
| Status        | Active                                                    |
| Last updated  | 2026-05-12                                                |
| Owner         | Modie (Habeeb)                                            |

## Goal

Ship the first two hooks ever in habeebs-skill — `SessionStart` (warn on ghost-commit divergence) and `PreToolUse on Bash` (block `git commit` / `git push` on the default branch). Together they automate two documented pain points without violating ADR-0001 (portability), ADR-0002 (no runtime substrate), or ADR-0003 (warn-only or block-only, multi-harness aware, stateless).

## Success measure

A fresh install of v1.6.0 produces all three observable behaviors within one Claude Code session:

1. `/plugin install` succeeds with no validator errors (regression test for v1.5.4 manifest fix).
2. Opening a session in a repo with `ahead=0, behind>0` surfaces the SessionStart warning banner on the first user prompt.
3. Attempting `git commit -m "..."` while on `main` (default branch) produces the BLOCKED message and exits code 2.

All three verified end-to-end against this very repo immediately after v1.6.0's own squash-merge.

## Phases

### Phase 1 — Write the hook scripts and manifest

**Slices:** #1, #2, #3 (hooks.json, session-start.sh, preventing-commits-to-default.sh)

**Acceptance gate:** All three files exist; `bash hooks/session-start.sh` and `bash hooks/preventing-commits-to-default.sh < sample-input.json` both exit cleanly (no syntax errors); `hooks/hooks.json` parses as valid JSON via PowerShell `ConvertFrom-Json`.

**Top risks:**
1. Auto-discovery fragility per Superpowers issue #773 — the `hooks/hooks.json` file may not be picked up by the user's Claude Code version. Mitigated by Phase 2 (manual-install README section).
2. JSON parsing in `preventing-commits-to-default.sh` depends on `jq` for robust extraction. Without `jq`, fall back to `sed` regex which is fragile on nested quotes. Both paths shipped; `jq` preferred when present.
3. Multi-harness env-var detection may miss future harnesses (e.g., OpenCode, Cody). Hook scripts gracefully degrade by checking `git rev-parse --is-inside-work-tree` as the universal "are we in a git repo" gate.

**Rollback hook:** All three files are new; `git revert` removes them cleanly. If hooks misfire after install, users set `HABEEBS_DISABLE_HOOKS=1` per ADR-0003's emergency exit.

### Phase 2 — Wire the discovery surfaces

**Slices:** #4, #5 (README.md Hooks section, repo scaffolding tree update)

**Acceptance gate:** README contains a "Hooks (v1.6.0+)" section with: what each hook does, how to verify it's loaded, manual `~/.claude/settings.json` snippet for the issue-#773 workaround, `HABEEBS_DISABLE_HOOKS` env var documentation, opt-out via `.claude/habeebs-allowed-branches`. Repo scaffolding tree shows the new `hooks/` directory between `agents/` and `docs/`.

**Top risks:**
1. README gets long — the Hooks section adds ~50 lines. Mitigated by placing it after the existing skill tables, before Status, so quick-readers can still scan the top.
2. Manual-install snippet drifts from auto-discovery format. Mitigated by deriving both from the same `hooks/hooks.json`.

**Rollback hook:** Same as Phase 1.

### Phase 3 — Release

**Slices:** #6, #7, #8 (CHANGELOG v1.6.0 entry, manifest bump, commit + PR)

**Acceptance gate:** CHANGELOG entry sits above v1.5.4 with the **Why** convention satisfied; both manifests at `1.6.0`; PR opens cleanly with a test plan that exercises all three success-measure behaviors.

**Top risks:**
1. MINOR bump (not patch) because hooks are new opt-in behavior — distinct from v1.5.x patches. Risk of mislabeling as patch. Mitigated by explicit "Why this is a minor" section in the CHANGELOG entry.
2. The PR must NOT auto-tag — slice #9 stays HITL:inline as in v1.5.2 and v1.5.3.

**Rollback hook:** Pre-merge: `git reset --soft HEAD~1` away. Post-merge: ADR-0003 stays Accepted, but a v1.6.1 hotfix can change manifest version or remove a hook if it misfires badly. The disable env var means rollback isn't urgent — users with broken hooks can self-disable.

## Slice table

| ID  | Name                                                          | Label           | Phase | pgroup     | Blocked by | Est   | Rollback hook                       |
|-----|---------------------------------------------------------------|-----------------|-------|------------|------------|-------|-------------------------------------|
| #1  | Write `hooks/hooks.json`                                      | AFK:full-auto   | 1     | pgroup-1A  | —          | 0.1d  | `git revert`                        |
| #2  | Write `hooks/session-start.sh`                                | AFK:full-auto   | 1     | pgroup-1A  | —          | 0.25d | `git revert`                        |
| #3  | Write `hooks/preventing-commits-to-default.sh`                | AFK:full-auto   | 1     | pgroup-1A  | —          | 0.25d | `git revert`                        |
| #4  | Add "Hooks (v1.6.0+)" section to `README.md`                  | AFK:full-auto   | 2     | pgroup-2A  | #1, #2, #3 | 0.2d  | `git revert`                        |
| #5  | Update repo scaffolding tree in `README.md` for `hooks/`      | AFK:full-auto   | 2     | pgroup-2A  | —          | 0.05d | `git revert`                        |
| #6  | CHANGELOG v1.6.0 entry                                        | AFK:full-auto   | 3     | pgroup-3A  | #1–#5      | 0.15d | `git revert`                        |
| #7  | Bump `plugin.json` + `marketplace.json` to 1.6.0              | AFK:full-auto   | 3     | pgroup-3A  | #1–#5      | 0.05d | `git revert`                        |
| #8  | Commit, push, open PR                                         | AFK:full-auto   | 3     | pgroup-3B  | #6, #7     | 0.1d  | `git reset --soft HEAD~1`           |
| #9  | Tag `v1.6.0`, release, dogfood-verify hooks on the squash     | HITL:inline     | 3     | pgroup-3C  | #8         | 0.1d  | `git tag -d v1.6.0` (one-way after release publish) |

**Label legend:**
- `AFK:full-auto` — no human in the loop; safe for dispatch
- `HITL:inline` — human gates in the active chat session

## Dependency DAG

```
#1 ─┐
#2 ─┼─→ #4 ─┐
#3 ─┘       ├─→ #6 ─┐
            #5 ─────┤├─→ #8 ─→ #9
                    #7 ─┘
```

## Parallelization map

- `pgroup-1A` = {#1, #2, #3} — Phase 1, three new files in three different paths; no overlap. `parallel-dev` eligible.
- `pgroup-2A` = {#4, #5} — Phase 2, both touch `README.md`. Sequential by single-writer; #5 first (small tree update), then #4 (large section append). NOT `parallel-dev` eligible (file overlap).
- `pgroup-3A` = {#6, #7} — Phase 3, no inter-file overlap. Parallelizable but not worth the dispatch overhead.
- `pgroup-3B` = {#8} — single slice.
- `pgroup-3C` = {#9} — single HITL slice.

## Risk register

| #   | Phase | Risk                                                                | Likelihood | Impact | Mitigation                                                       |
|-----|-------|---------------------------------------------------------------------|------------|--------|------------------------------------------------------------------|
| R1  | 1     | Plugin auto-discovery doesn't pick up `hooks/hooks.json` (issue #773)| Medium     | Medium | Phase 2 ships manual-install snippet; users can paste into `~/.claude/settings.json` |
| R2  | 1     | `jq` not available on user's machine                                | Medium     | Low    | PreToolUse hook falls back to `sed` regex extraction             |
| R3  | 1     | False positive on PreToolUse during mid-rebase / cherry-pick        | Medium     | Medium | Hook detects `.git/REBASE_HEAD` / `MERGE_HEAD` / `CHERRY_PICK_HEAD` and exits 0 |
| R4  | 1     | SessionStart hook fails on slow `git fetch` and blocks session start | Low        | Medium | Hook has `timeout: 10s` in `hooks.json`; script also exits 0 on fetch failure |
| R5  | 2     | Manual-install snippet drifts from auto-discovery config            | Low        | Low    | Both derived from same source in `hooks/hooks.json`; document update flow |
| R6  | 3     | MINOR bump confused as patch by downstream auto-updaters            | Low        | Low    | Explicit "Why this is a MINOR" section in CHANGELOG               |

## Revisit triggers

- A user-reported false positive on either hook accumulates to >2 reports → revisit the hook logic OR the allowlist mechanism.
- Anthropic deprecates `hooks/hooks.json` or changes auto-discovery → revisit the structural format (likely ADR-0003 revisit too).
- A use case emerges for a third hook → fresh ADR-grade evaluation per ADR-0003 rule (no batch adoption).
- The `HABEEBS_DISABLE_HOOKS` env var proves insufficient (e.g., users want per-hook disable) → ADR-0003 revisit.

If a trigger fires, halt at the current phase gate and re-run `socratic-grill` on the affected sections before continuing.

## Change log

- 2026-05-12 — Initial plan written from ADR-0003.

## References

- ADR: [`adrs/0003-hooks-scope`](../adrs/0003-hooks-scope.md)
- Sister ADRs: [`adrs/0001-environment-binding-via-system-context`](../adrs/0001-environment-binding-via-system-context.md), [`adrs/0002-habeebs-skill-standalone`](../adrs/0002-habeebs-skill-standalone.md)
- SYSTEM_CONTEXT: [`SYSTEM_CONTEXT.md`](../SYSTEM_CONTEXT.md)
- External:
  - [Anthropic — `plugin-dev/skills/hook-development/SKILL.md`](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/hook-development/SKILL.md)
  - [obra/superpowers `hooks/session-start`](https://github.com/obra/superpowers/blob/main/hooks/session-start)
  - [mattpocock/skills `git-guardrails-claude-code/SKILL.md`](https://github.com/mattpocock/skills/blob/main/skills/misc/git-guardrails-claude-code/SKILL.md)
  - [obra/superpowers issue #773 (auto-discovery failure)](https://github.com/obra/superpowers/issues/773)
