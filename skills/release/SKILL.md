---
name: release
description: Version bump + CHANGELOG + PR + tag-push. Use when tdd-loop is GREEN and user types "/release", "ship this", "cut a release", "bump the version", or "tag this". Do not use mid-feature, for hotfixes bypassing the chain, or for deploy/canary requests — release stops at PR + tag, never touches production.
disable-model-invocation: true
---

# Release

Terminal link in the habeebs-skill chain. Runs after `tdd-loop` GREEN + `verify-output` DONE/DONE_WITH_CONCERNS. Assembles the release artifact set: version bump, CHANGELOG entry, clean history, PR body, doc-sync audit, and tag-push. Substrate-free — every step is a prompt driving Bash/Read/Edit/git/gh.

This is NOT a deploy step. `release` stops at a merged PR + pushed tag. No canary, no benchmark, no production push.

## When to use this skill

**Trigger on:**

- The user says "release", "ship", "cut a release", "bump the version", or "tag this"
- `tdd-loop` has completed and the user explicitly invokes `/release`
- A feature branch is merged and ready to tag

**Do NOT trigger on:**

- Mid-feature work (run `tdd-loop` first — this skill is the terminal link)
- Hotfixes that bypass the chain entirely
- Any request for a deploy, canary promotion, benchmark run, or production operation

## Pre-flight checklist

Before Phase 1, verify:

1. `tdd-loop` reached GREEN on this branch (all slice tests pass).
2. `verify-output` returned `DONE` or `DONE_WITH_CONCERNS` (no unresolved BLOCKED).
3. The working tree is clean (`git status` shows no unstaged changes).
4. The PR for this feature branch is open (or will be opened in Phase 4).

If any pre-flight check fails, halt with `STATUS: BLOCKED — pre-flight failed: <reason>`. Do not proceed.

## Core workflow

### Phase 1 — Determine version bump

Read the current version from `.claude-plugin/plugin.json` (field: `version`). Apply SemVer per `CHANGELOG.md`'s Convention block:

| Change type | Bump |
|---|---|
| Breaking change to a skill's frontmatter, output template, or handoff contract | MAJOR |
| New skill, new phase, new template, or new opt-in behavior | MINOR |
| Wording fixes, internal cleanups, doc clarifications | PATCH |

Confirm the bump type with the user if ambiguous. Output the new version as `vX.Y.Z`.

### Phase 2 — Doc-sync audit

Before writing the CHANGELOG, audit what was shipped:

**Step 2a — Coverage map.** For every new or changed skill, command, ADR, and plan file on this branch (`git diff --name-only main...HEAD`), check:

- If the skill is idea-ported, is attribution preserved (HTML-commented line in the body, or the introducing commit message)?
- Is the command file present in `commands/`?
- Is the ADR cross-referenced from the relevant skill's `## See also`?
- Is the plan file referenced from the relevant spec?

Record any gap as a doc-sync finding. Surface findings to the user; do not silently skip them. A finding is `WARN` (should fix before release) or `INFO` (can follow up in a patch). Continue to Phase 3 — don't block on `INFO`.

**Step 2b — CHANGELOG sell-test.** For each item you will write into the CHANGELOG, ask: does this entry explain *value to the user*, not just the change? The test: can a reader who hasn't seen the PR understand (a) what changed and (b) why it matters? If not, rewrite it before adding to CHANGELOG.md.

**Step 2c — Supersession-link integrity gate.** When any ADR on this branch flips its Status to `Superseded`, the doc-sync audit asserts the supersession record is navigable and self-describing. The mechanism is dogfood scenario 36; this step runs it as the release-time gate and confirms a human observes the result before tagging:

```bash
bash tests/dogfood/36-supersession-link-integrity/check-supersession-integrity.sh
```

The scenario scans `docs/agents/adrs/*.md` for every record whose Status line names a Superseded state and enforces two assertions:

- **Forward link.** The same record carries a forward markdown link (`](./<file>.md)`) to the superseding record, so a reader landing on a Superseded ADR reaches its replacement in one hop.
- **Surviving half.** For a PARTIAL supersession (the Status text names a "half" / "partial" / "part"), the record names which half survives (in force / retained / unchanged), and the superseding record re-states the same half as retained. A partial supersession that drops the surviving-half statement leaves the corpus ambiguous about what is still binding.

Exit 0 = the gate passes (and the case where no ADR is Superseded is a clean pass — the scan is near-free when no supersession is present). Exit nonzero = halt the release: add the missing forward link or surviving-half statement to the ADR, then re-run. This gate exists because a supersession recorded without a forward link or a surviving-half statement strands future readers on a stale decision with no path to the live one.

**Step 2d — Description-policy audit.** For any release that adds a new SKILL.md or modifies an existing one, run both checks and confirm exit 0 BEFORE tagging (record the pass/fail; the PR body in Phase 7 carries only the result, not these instructions):

```bash
bash tests/dogfood/11-description-budget/check-description-budget.sh
bash tests/dogfood/11-description-budget/check-disabled-list.sh
```

They enforce: the ≤1,024 hard / ≤300 avg length budget; the description anatomy `[Capability ≤8 words]. [Imperative directive] when [trigger 1], [phrase 2], or [phrase 3]. [Tight anti-trigger].`; `disable-model-invocation: true` on chain-internal skills; three-keystone anti-trigger thickness (`prior-art-research`, `systematic-debugging`, `deep-modules`); and the block-scalar regression guard (no `|`/`>` on the `description:` line). If either script fails, halt the release — new SKILL.md files must comply at creation time.

### Phase 3 — Enrich the CHANGELOG entry (changesets generate it; you craft it)

> **Ordering.** Phase 3.25 (changeset aggregation) is the mechanism that actually
> bumps the version files and prepends the CHANGELOG section — and it runs FIRST,
> at the start of release-PR creation. Phases 3 and 4 do NOT write those files from
> scratch; they verify and enrich what 3.25 generated. This avoids the double-write
> that results from manually authoring a block AND running the aggregation script.

**Changeset path (default).** `aggregate-changesets.sh` (Phase 3.25) has already prepended a `## vX.Y.Z` section to `CHANGELOG.md` with one bullet per `why:` line. In this phase you *enrich* that generated section in place — do not write a second block:

- Every sub-item gets a **Why** line (the `why:` from the changeset is the seed — sharpen it to explain the reason the feature exists, not just what it is).
- Regroup the flat bullet list under `### Added`, `### Changed`, `### Fixed`, or `### Removed`. Use only the groups that apply.
- Write the release headline (the sentence directly under `## [X.Y.Z]`) — a 1–2 sentence summary of the release's single most important outcome.
- Bold the changed file/skill path in each sub-item.
- Cross-reference ADRs with links to `docs/agents/adrs/`.
- Validate with the sell-test from Phase 2b.

**No-changesets fallback (rare — doc-only PRs with no `.changeset/*.md`).** When Phase 3.25 found nothing to aggregate, author the `## [X.Y.Z] — YYYY-MM-DD` block by hand here, above the previous latest release, following the Convention block exactly and the same rules above.

### Phase 3.25 — Changeset aggregation + path audit

The feature branch never edits `plugin.json` / `marketplace.json` / `CHANGELOG.md` directly. Instead, each release-worthy PR drops a `.changeset/<slug>.md` carrying `bump:` + `why:`. This phase is the FIRST step of release-PR creation and runs BEFORE Phase 4 (version bump) — in fact it does the bump.

**Step 1 — Path audit.** Verify the diff against the REQUIRED/OPTIONAL/NEVER matrix:

```bash
bash skills/release/scripts/check-changeset-required.sh
```

Exit 1 = a REQUIRED path was modified without an accompanying `.changeset/*.md` — the release halts loud with the operator-facing message ("PR modifies skill files but contains no `.changeset/*.md`..."). The matrix:

- **REQUIRED:** `skills/`, `hooks/`, `.claude-plugin/`, `plugin.json`, `marketplace.json`
- **OPTIONAL** (INFO note, does not block): `docs/`, `CLAUDE.md`, `AGENTS.md`, `README.md`, `CHANGELOG.md`
- **NEVER required:** `tests/`, `.gitignore`, `.github/`, `.gitattributes`

**Step 2 — Aggregation.** Dry-run first:

```bash
bash skills/release/scripts/aggregate-changesets.sh --dry-run
```

Verify the aggregated bump (highest of major > minor > patch) + the new version + the bullet count match expectations. Then apply:

```bash
bash skills/release/scripts/aggregate-changesets.sh
```

The script atomically (a) bumps `plugin.json` + `marketplace.json` from the current version, (b) prepends a `## vX.Y.Z` section to CHANGELOG.md with one bullet per `why:` line, (c) deletes the consumed changesets. Exit codes: 0 = success or nothing-to-do; 1 = aborted clean (write failure detected; working tree unchanged); 2 = aborted dirty (manual intervention required — should never happen given the temp-staging-dir + backup-and-rollback approach but documented for safety).

Feature branches NEVER directly edit the three aggregated files. Two simultaneous release PRs targeting the same version slot will collide at git merge time (loud, not silent — operator closes the second PR + re-aggregates against post-first-merge state).

**Skip this phase** if no changesets are present AND no REQUIRED path was modified (rare; only documentation-only PRs that touch nothing release-worthy). Aggregation script exits 0 with "No changesets to aggregate." in that case.

### Phase 4 — Verify the version bump

**Changeset path (default).** `aggregate-changesets.sh` (Phase 3.25) already bumped both `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` to the new version. Do NOT edit them again — verify:

1. Both `version` fields read the expected `X.Y.Z` (matches the aggregated bump from Phase 3.25's dry-run).
2. Any other version-like fields (e.g., `changelog_url`, `tag`) that must move in tandem are updated — fix those by hand if the script left them.

**No-changesets fallback.** When Phase 3.25 aggregated nothing (doc-only PR), edit the two `version` fields by hand here to the new version string, plus any tandem version-like fields.

### Phase 5 — Clean commit history review

Run `git log --oneline main...HEAD`. Review the commit list:

- Are there any WIP, fixup!, or squash! commits that should be cleaned up before the PR?
- Are there any commits that mix unrelated concerns (e.g., a refactor commit that also touches the version bump)?

If the history is messy, surface a list of suggested squashes to the user. Do NOT `git rebase -i` or rewrite history without explicit user instruction. Output the recommended squash as a bulleted list; the user decides.

If history is clean, proceed.

### Phase 6 — Stage, commit, and push

```bash
git add CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json .changeset/
# .changeset/ stages the deletions aggregate-changesets.sh made when it consumed them.
# Also add any doc-sync fixes from Phase 2a if the user addressed them.
git commit -m "$(cat <<'EOF'
vX.Y.Z: <release headline in imperative mood>

<one-line detail per Changed/Added/Fixed item — mirrors the CHANGELOG entry>

EOF
)"
git push origin HEAD
```

The commit message mirrors the CHANGELOG entry's headline and sub-items. This is the release commit; it should be the last commit on the branch before the PR merge.

### Phase 7 — Open or update the PR

```bash
gh pr create --title "vX.Y.Z: <release headline>" --body "$(cat <<'EOF'
## Summary

<2-3 bullet points from the CHANGELOG entry>

## What changed

<Sub-items from ### Added / ### Changed / ### Fixed, verbatim from CHANGELOG>

## Doc-sync audit

<Status line: "All features have doc coverage" OR list of WARN/INFO findings from Phase 2a>

## Description-policy audit

<Status line: "N/A — no SKILL.md added/changed" OR "PASS — description-budget + disabled-list checks exit 0 (Phase 2d)". The audit itself runs in Phase 2d, not here.>

## Release checklist

- [ ] `tdd-loop` GREEN on this branch
- [ ] `verify-output` DONE or DONE_WITH_CONCERNS
- [ ] CHANGELOG entry written with Why lines
- [ ] Version bumped in plugin.json and marketplace.json
- [ ] Dogfood 11 description-budget AND disabled-list checks pass
- [ ] History clean (no WIP/fixup commits)
- [ ] Tag push ready (Phase 8)

🤖 Released with habeebs-skill `/release`
EOF
)"
```

If a PR is already open for this branch, update it with `gh pr edit`.

### Phase 8 — Create and push the tag

After the PR is merged (or if the user authorizes tagging before merge — unusual but valid):

```bash
git tag -a vX.Y.Z -m "vX.Y.Z: <release headline>"
git push origin refs/tags/vX.Y.Z
```

**Always use the `refs/tags/` form** — `git push origin refs/tags/vX.Y.Z` — not `git push origin vX.Y.Z`. The unambiguous refspec ensures the commit-block hook correctly identifies this as a tag-only push and allows it on the default branch.

Do NOT use `git push --tags` for a single-release push — it pushes all local tags, including any draft tags. Prefer the explicit form above.

### Phase 9 — Create the GitHub release

```bash
gh release create vX.Y.Z \
  --title "vX.Y.Z: <release headline>" \
  --notes "$(cat <<'EOF'
<CHANGELOG entry for this version, verbatim>
EOF
)"
```

### Phase 9.5 — Editorial dormancy scan (minor + major releases only)

On minor and major releases ONLY (patches skipped — low signal, redundant with the most-recent minor scan), walk the ADR and plan corpus to surface dormant decisions. The scan is advisory; it does NOT block the release.

Run only when the version bump from Phase 1 is `minor` or `major`. Skip on `patch`.

```bash
# Threshold: max(3 minor releases ago, 6 months ago) — whichever produces the older cutoff
# Minor-releases approach: count git tags matching v*.*.0 since the artifact's Last-Reviewed
# Date approach: subtract 6 months from today

today=$(date +%Y-%m-%d)
six_months_ago=$(date -d '6 months ago' +%Y-%m-%d 2>/dev/null || date -v-6m +%Y-%m-%d)

# For each ADR + plan with YAML frontmatter, extract Status: and Last-Reviewed:
for f in docs/agents/adrs/*.md docs/agents/plans/*.md; do
  # Skip files without YAML frontmatter (the frozen integer ADRs carry only the
  # markdown block and are never back-filled — see GLOSSARY § ADR two-era scheme)
  head -1 "$f" | grep -q '^---$' || continue

  status=$(awk '/^---$/{c++; next} c==1 && /^Status:/{sub(/^Status: */, ""); print; exit}' "$f")
  last_reviewed=$(awk '/^---$/{c++; next} c==1 && /^Last-Reviewed:/{sub(/^Last-Reviewed: */, ""); print; exit}' "$f")

  # Only flag artifacts in non-terminal states
  case "$status" in
    Proposed|Active) ;;
    *) continue ;;
  esac

  # Flag if Last-Reviewed older than 6 months
  if [ "$last_reviewed" \< "$six_months_ago" ]; then
    echo "DORMANCY WARNING: $f — Status: $status, Last-Reviewed: $last_reviewed"
  fi
done
```

If any warnings print, surface them to the user as a single block. The maintainer reads the warnings and decides whether to land an update PR. The release continues regardless — dormancy is signal, not blockage.

**Why this exists.** ADRs and plans drift across releases. Without a release-time check, decisions land in `Status: Proposed` and stay there silently. `Last-Reviewed:` carries deliberate-review semantics (NOT auto-bumped on every commit), so a stale `Last-Reviewed:` is meaningful signal.

**Related cadence.** The trigger-firing eval (`docs/agents/references/trigger-firing-eval.md`) runs on the same release-adjacent cadence — within 7 days of any release — measuring real-session trigger firing-rate. If this release changed any skill `description:`, re-run that eval per its own procedure.

**Why minor+major only.** Patch releases are wording fixes; the scan would re-flag the same items on every patch with no new information. Re-flagging adds noise without signal.

**ADRs without YAML frontmatter are skipped automatically** by the `head -1 "$f" | grep -q '^---$' || continue` guard. This makes the scan tolerant of mixed conventions (pre-telemetry ADRs and post-telemetry ADRs in the same corpus) without changing the scan logic if back-fill ships later.

### Phase 10 — Handoff

```
HANDOFF: release complete — vX.Y.Z tagged, PR body written, GitHub release created.
  Tag: git push origin refs/tags/vX.Y.Z (done)
  Next: merge the PR; the chain is closed.
```

If doc-sync WARN findings remain unresolved:

```
HANDOFF: release complete with doc-sync concerns — vX.Y.Z tagged.
  Unresolved doc-sync WARNs: <list>
  These should be addressed in a patch release (vX.Y.Z+1) or the next MINOR.
```

## Anti-patterns this skill guards against

- **Shipping without a Why line.** Every CHANGELOG sub-item must explain why the feature exists. Future readers — human and agent — use this to judge whether a feature is still load-bearing.
- **Pushing `--tags` on the default branch.** `git push --tags` pushes every local tag. Use `git push origin refs/tags/<version>` — the unambiguous form the hook recognizes.
- **Committing a version bump on the default branch directly.** The bump commit lives on the feature branch and lands on main via PR, same as any other change.
- **Skipping the doc-sync audit.** Features shipped without docs are invisible to future researchers. Phase 2a is not optional.
- **Adding deploy or production steps.** This skill ends at PR + tag. Any production operation is out of scope and should be rejected by the caller.
- **Tagging before the PR is reviewable.** Phase 8 runs after merge (or with explicit user authorization). Don't tag a branch that hasn't been code-reviewed.

## See also

- [`tdd-loop`](../tdd-loop/SKILL.md) — primary caller; `release` is the terminal link after `tdd-loop` GREEN
- [`verify-output`](../verify-output/SKILL.md) — must reach DONE/DONE_WITH_CONCERNS before `release` runs
- [`CHANGELOG.md`](../../CHANGELOG.md) — the Convention block this skill follows
- [`hooks/`](../../hooks/) — the commit-block hook scope and tag-push carve-out it implements
- [`references/release-checklist.md`](references/release-checklist.md) — printable release checklist
- [`references/doc-sync-procedure.md`](references/doc-sync-procedure.md) — expanded doc-sync audit procedure
