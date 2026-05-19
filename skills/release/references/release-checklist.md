# Release checklist

Printable checklist for the `release` skill (Phase 10 summary). Run through this in order. Every item must be checked before the tag is pushed.

## Pre-flight

- [ ] `tdd-loop` reached GREEN on this branch (all slice tests pass)
- [ ] `verify-output` returned `DONE` or `DONE_WITH_CONCERNS` (no unresolved BLOCKED)
- [ ] Working tree is clean (`git status` shows no unstaged changes)
- [ ] PR is open (or will be opened in this run)

## Phase 1 — Version bump type

- [ ] Identified bump type: `MAJOR` / `MINOR` / `PATCH` (per CHANGELOG Convention block)
- [ ] New version confirmed as `vX.Y.Z`

## Phase 2 — Doc-sync audit

- [ ] Coverage map run: every new/changed skill, command, ADR, and plan checked for cross-references
- [ ] Doc-sync WARN findings surfaced to user (none silently skipped)
- [ ] CHANGELOG sell-test applied to every entry: each explains *value*, not just the change

## Phase 3 — CHANGELOG entry

- [ ] New `## [X.Y.Z] — YYYY-MM-DD` block inserted above previous latest release
- [ ] Release headline is 1–2 sentences (single most important outcome)
- [ ] Every sub-item has a **Why** line
- [ ] Changed files are bolded in each sub-item
- [ ] ADR cross-references link to `docs/agents/adrs/`
- [ ] Sell-test passed for each entry

## Phase 4 — Version bump

- [ ] `.claude-plugin/plugin.json` `version` field updated to `X.Y.Z`
- [ ] `.claude-plugin/marketplace.json` `version` field updated to `X.Y.Z`
- [ ] Other version-like fields (e.g., `changelog_url`, `tag`) updated if present

## Phase 5 — History review

- [ ] `git log --oneline main...HEAD` reviewed
- [ ] No WIP / fixup! / squash! commits outstanding
- [ ] No commits that mix unrelated concerns
- [ ] Squash list surfaced to user if messy (not executed without instruction)

## Phase 6 — Commit and push

- [ ] `git add CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json`
- [ ] Commit message mirrors CHANGELOG headline in imperative mood
- [ ] `git push origin HEAD`

## Phase 7 — PR

- [ ] PR created or updated with structured body (Summary / What changed / Doc-sync audit / Checklist)
- [ ] PR title is `vX.Y.Z: <release headline>`

## Phase 8 — Tag (after merge or with explicit authorization)

- [ ] `git tag -a vX.Y.Z -m "vX.Y.Z: <release headline>"`
- [ ] `git push origin refs/tags/vX.Y.Z` (unambiguous form — required by ADR-0015)

## Phase 9 — GitHub release

- [ ] `gh release create vX.Y.Z` with CHANGELOG entry as body
- [ ] Release title matches tag and PR title

## Done

All boxes checked? The release is complete. The chain is closed.
