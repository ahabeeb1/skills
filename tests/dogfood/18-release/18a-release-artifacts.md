# Dogfood 18a — release skill: correct artifact set, no deploy steps

**Type:** Positive (skill behavior)
**Tested:** `skills/release/SKILL.md` — Phases 1–9 (version bump, CHANGELOG, doc-sync, PR body, tag-push instructions)

---

## Target state

A feature branch `feature/v1.14.0-gstack-capability-adoption` has:

- `tdd-loop` completed (GREEN — all slice tests pass).
- `verify-output` returned `DONE`.
- Three new files: `skills/release/SKILL.md`, `skills/release/references/release-checklist.md`, `skills/release/references/doc-sync-procedure.md`.
- One modified hook: `hooks/preventing-commits-to-default.sh`.
- Two modified ADRs: `docs/agents/adrs/0003-hooks-scope.md`, `docs/agents/adrs/0015-hook-allow-tag-pushes-on-default.md`.
- One new command: `commands/release.md`.
- One new dogfood suite: `tests/dogfood/18-release/`.
- Current version in `.claude-plugin/plugin.json`: `1.13.0`.

The user invokes `/release`.

## Expected output

### Phase 1 — Version bump

The skill determines the bump type is **MINOR** (new skill, new command, new dogfood suite — matches the MINOR definition). It proposes version `1.14.0`.

### Phase 2 — Doc-sync audit

The skill runs a coverage check against the diff and reports:

- `skills/release/SKILL.md` — new skill, `commands/release.md` exists ✓, `## Origins` present ✓, `## See also` cross-references tdd-loop and verify-output ✓
- `docs/agents/adrs/0015-hook-allow-tag-pushes-on-default.md` — referenced from `skills/release/SKILL.md` See also ✓, referenced from ADR-0003 amendment ✓
- `tests/dogfood/18-release/README.md` — present ✓, scenario files present ✓

**Expected doc-sync verdict:** No WARN findings. At most INFO (e.g., plugin.json + marketplace.json not yet wired — acceptable INFO because shared-surface wiring is the lead's task).

### Phase 3 — CHANGELOG entry

The skill writes a `## [1.14.0] — 2026-05-18` block above `## [1.13.0]`. The entry:

- Has a 1–2 sentence release headline naming the `release` skill and the hook carve-out.
- Has `### Added` sub-items for `skills/release/SKILL.md`, `commands/release.md`, `tests/dogfood/18-release/`, and `docs/agents/adrs/0015-hook-allow-tag-pushes-on-default.md`.
- Has `### Changed` sub-items for `hooks/preventing-commits-to-default.sh` and `docs/agents/adrs/0003-hooks-scope.md`.
- **Every sub-item has a Why line** that explains value (not just "added per ADR-0015").
- Passes the sell-test: a reader who hasn't seen the PR can understand what changed and why it matters.

### Phase 4 — Version bump files

The skill edits:

- `.claude-plugin/plugin.json` → `"version": "1.14.0"`
- `.claude-plugin/marketplace.json` → `"version": "1.14.0"`

### Phase 8 — Tag-push instruction

The skill outputs the tag-push command as:

```bash
git push origin refs/tags/v1.14.0
```

**NOT** `git push origin v1.14.0` (ambiguous). **NOT** `git push --tags` (pushes all tags).

### No deploy steps

The skill's output contains NO reference to: deploy, canary, benchmark, production, staging, `gh workflow run`, CI trigger, or any production operation.

## Pass / fail

- **Pass:** All six artifact checks above are satisfied. Version is `1.14.0`. Tag-push uses `refs/tags/` form. No deploy steps in output.
- **Fail (wrong bump):** Skill proposes `1.13.1` (PATCH) instead of `1.14.0` (MINOR) — new skill addition is a MINOR.
- **Fail (missing Why):** Any CHANGELOG sub-item lacks a Why line.
- **Fail (ambiguous tag):** Skill outputs `git push origin v1.14.0` instead of `git push origin refs/tags/v1.14.0`.
- **Fail (deploy leak):** Any deploy/canary/production step appears in output.
- **Fail (sell-test):** A CHANGELOG entry explains only the change, not the value (e.g., "Updated hook" with no Why).

## Why this scenario

The release skill must produce a complete, correct artifact set on its first invocation of a real release. 18a verifies the full happy path — version bump, CHANGELOG quality, doc-sync coverage, and the tag-push form — in one end-to-end run. The no-deploy-steps check is load-bearing: gstack `/ship` includes deploy pipeline execution; this skill explicitly does not.
