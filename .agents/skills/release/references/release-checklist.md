# Release checklist

Printable checklist for the `release` skill. Run through it in order. Every item must be checked before the tag is pushed. (Mirrors the phase list in `SKILL.md`; the SKILL is authoritative if they ever diverge.)

## Pre-flight

- [ ] `tdd-loop` reached GREEN on this branch (all slice tests pass)
- [ ] `verify-output` returned `DONE` or `DONE_WITH_CONCERNS` (no unresolved BLOCKED)
- [ ] Working tree is clean (`git status` shows no unstaged changes)
- [ ] PR is open (or will be opened in this run)

## Phase 1 — Version bump type

- [ ] Identified bump type: `MAJOR` / `MINOR` / `PATCH` (per CHANGELOG Convention block)
- [ ] New version confirmed as `vX.Y.Z` (cross-checked against the aggregated changeset bump in Phase 3.25)

## Phase 2 — Doc-sync audit

- [ ] 2a coverage map: every new/changed skill, command, ADR, and plan checked for cross-references; WARN findings surfaced (none silently skipped)
- [ ] 2b sell-test applied to every CHANGELOG entry: each explains *value*, not just the change
- [ ] 2c supersession-link integrity gate run (`check-supersession-integrity.sh` exit 0)
- [ ] 2d description-policy audit run if any SKILL.md added/changed (`check-description-budget.sh` + `check-disabled-list.sh` exit 0)

## Phase 3.25 — Changeset aggregation (runs first; does the bump)

- [ ] Path audit run (`check-changeset-required.sh` exit 0 — no REQUIRED path modified without a `.changeset/*.md`)
- [ ] `aggregate-changesets.sh --dry-run` reviewed (aggregated bump + new version + bullet count match expectations)
- [ ] `aggregate-changesets.sh` applied (bumped plugin.json + marketplace.json, prepended CHANGELOG section, deleted consumed changesets) — OR skipped (doc-only PR, nothing to aggregate)

## Phase 3 — Enrich the CHANGELOG entry

- [ ] Enriched the changeset-generated section in place (no second block written) — OR authored the block by hand in the no-changesets fallback
- [ ] Release headline is 1–2 sentences (single most important outcome)
- [ ] Every sub-item has a **Why** line; bullets grouped under Added/Changed/Fixed/Removed
- [ ] Changed files bolded; ADR cross-references link to `docs/agents/adrs/`
- [ ] Sell-test passed for each entry

## Phase 4 — Verify the version bump

- [ ] `.claude-plugin/plugin.json` `version` reads `X.Y.Z` (set by aggregation, or by hand in the fallback)
- [ ] `.claude-plugin/marketplace.json` `version` reads `X.Y.Z`
- [ ] Other version-like fields (e.g., `changelog_url`, `tag`) updated if present

## Phase 5 — History review

- [ ] `git log --oneline main...HEAD` reviewed
- [ ] No WIP / fixup! / squash! commits outstanding; no commits mixing unrelated concerns
- [ ] Squash list surfaced to user if messy (not executed without instruction)

## Phase 6 — Commit and push

- [ ] `git add CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json .changeset/` (stages the consumed-changeset deletions)
- [ ] Commit message mirrors CHANGELOG headline in imperative mood
- [ ] `git push origin HEAD`

## Phase 7 — PR

- [ ] PR created or updated with structured body (Summary / What changed / Doc-sync audit / Description-policy status / Checklist)
- [ ] PR title is `vX.Y.Z: <release headline>`

## Phase 8 — Tag (after merge or with explicit authorization)

- [ ] `git tag -a vX.Y.Z -m "vX.Y.Z: <release headline>"`
- [ ] `git push origin refs/tags/vX.Y.Z` (unambiguous form — required by ADR-0015)

## Phase 9 — GitHub release

- [ ] `gh release create vX.Y.Z` with CHANGELOG entry as body
- [ ] Release title matches tag and PR title

## Phase 9.5 — Editorial dormancy scan (minor + major only)

- [ ] On minor/major: ADR + plan corpus scanned for `Status: Proposed/Active` with stale `Last-Reviewed:`; warnings surfaced (advisory, non-blocking). Skipped on patch.

## Done

All boxes checked? The release is complete. The chain is closed.
