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

- Does the skill have an `## Origins` section (if idea-ported)?
- Is the command file present in `commands/`?
- Is the ADR cross-referenced from the relevant skill's `## See also`?
- Is the plan file referenced from the relevant spec?

Record any gap as a doc-sync finding. Surface findings to the user; do not silently skip them. A finding is `WARN` (should fix before release) or `INFO` (can follow up in a patch). Continue to Phase 3 — don't block on `INFO`.

**Step 2b — CHANGELOG sell-test.** For each item you will write into the CHANGELOG, ask: does this entry explain *value to the user*, not just the change? The test: can a reader who hasn't seen the PR understand (a) what changed and (b) why it matters? If not, rewrite it before adding to CHANGELOG.md.

### Phase 3 — Write the CHANGELOG entry

Open `CHANGELOG.md`. Insert a new `## [X.Y.Z] — YYYY-MM-DD` block above the previous latest release, following the Convention block exactly.

Rules:
- Every sub-item gets a **Why** line. No exceptions. "Why: X" explains the reason the feature exists, not just what it is.
- Sub-items group under `### Added`, `### Changed`, `### Fixed`, or `### Removed`. Use only the groups that apply.
- The release headline (the sentence directly under `## [X.Y.Z]`) is a 1–2 sentence summary of the release's single most important outcome.
- Bold the changed file/skill path in each sub-item.
- Cross-reference ADRs with links to `docs/agents/adrs/`.

Validate with the sell-test from Phase 2b before writing.

### Phase 4 — Version bump

Edit exactly two files:

1. `.claude-plugin/plugin.json` — update the `version` field to the new version string.
2. `.claude-plugin/marketplace.json` — update the `version` field to the same version string.

Check both files for any other version-like fields (e.g., `changelog_url`, `tag`) that must be updated in tandem. Update them if present.

### Phase 5 — Clean commit history review

Run `git log --oneline main...HEAD`. Review the commit list:

- Are there any WIP, fixup!, or squash! commits that should be cleaned up before the PR?
- Are there any commits that mix unrelated concerns (e.g., a refactor commit that also touches the version bump)?

If the history is messy, surface a list of suggested squashes to the user. Do NOT `git rebase -i` or rewrite history without explicit user instruction. Output the recommended squash as a bulleted list; the user decides.

If history is clean, proceed.

### Phase 6 — Stage, commit, and push

```bash
git add CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json
# Also add any doc-sync fixes from Phase 2a if the user addressed them
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

## Release checklist

- [ ] `tdd-loop` GREEN on this branch
- [ ] `verify-output` DONE or DONE_WITH_CONCERNS
- [ ] CHANGELOG entry written with Why lines
- [ ] Version bumped in plugin.json and marketplace.json
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

**Always use the `refs/tags/` form** — `git push origin refs/tags/vX.Y.Z` — not `git push origin vX.Y.Z`. The unambiguous refspec ensures the commit-block hook (ADR-0003/ADR-0015) correctly identifies this as a tag-only push and allows it on the default branch.

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
- [ADR-0015](../../docs/agents/adrs/0015-hook-allow-tag-pushes-on-default.md) — the hook amendment that allows tag-only pushes on the default branch
- [ADR-0003](../../docs/agents/adrs/0003-hooks-scope.md) — commit-block hook scope; tag-push carve-out recorded as amendment
- [`references/release-checklist.md`](references/release-checklist.md) — printable release checklist
- [`references/doc-sync-procedure.md`](references/doc-sync-procedure.md) — expanded doc-sync audit procedure
