# Issue Tracker — GitHub

This repo uses GitHub Issues for slice tracking. Skills that publish issues use the `gh` CLI.

## How `vertical-slice` publishes

For each slice:

```bash
gh issue create \
  --title "<feature-slug>: Slice N — <slice name>" \
  --body "$(cat <slice-spec>.md)" \
  --label "<triage-label>" \
  --assignee "<optional>"
```

Topological ordering: publish in dependency order so `Blocked by: #N` references can use real issue IDs.

## Conventions

- One issue per slice
- Title format: `<feature-slug>: Slice N — <slice name>` (e.g., `v1.8.0-glossary-rename: Slice 1 — Rename CONTEXT.md → GLOSSARY.md`)
- Body: the full slice section copied verbatim from the spec under `docs/agents/specs/`
- Labels: from `triage-labels.md`
- Closing: link the merging PR to auto-close the issue (`Closes #N` in PR body)

## Read patterns

When skills need to read existing issues (e.g., `vertical-slice` re-reading prior slices to avoid duplicates):

```bash
gh issue list --label "<triage-label>" --json number,title,body
```

## Repo-specific notes

- Default branch: `main`.
- This repo is `ahabeeb1/skills` on GitHub.
- PR convention: one PR per release (e.g., v1.6.0, v1.7.0). Individual slices are committed onto the release branch; the PR title is the release header.
- Releases are tagged after merge via `gh release create vX.Y.Z`.
