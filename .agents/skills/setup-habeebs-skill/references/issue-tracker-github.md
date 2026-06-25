# Issue Tracker — GitHub

This repo uses GitHub Issues for slice tracking. Skills that publish issues use the `gh` CLI.

## How `vertical-slice` publishes

For each slice:

```bash
gh issue create \
  --title "<slice-name>" \
  --body "$(cat <slice-spec>.md)" \
  --label "<triage-label>" \
  --assignee "<optional>"
```

Topological ordering: publish in dependency order so `Blocked by: #N` references can use real issue IDs.

## Conventions

- One issue per slice
- Title format: `<feature-slug>: Slice N — <slice name>` (e.g., `collab-editor: Slice 3 — Two clients sync edits`)
- Body: the full slice spec section copied verbatim
- Labels: from `triage-labels.md`
- Closing: link the merging PR to auto-close the issue (`Closes #N` in PR body)

## Read patterns

When skills need to read existing issues (e.g., `vertical-slice` re-reading prior slices to avoid duplicates):

```bash
gh issue list --label "<triage-label>" --json number,title,body
```
