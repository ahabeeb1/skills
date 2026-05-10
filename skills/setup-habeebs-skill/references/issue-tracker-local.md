# Issue Tracker — Local Markdown

This repo uses local markdown files for slice tracking. No external service required. Useful for small teams, prototypes, or pre-formal-tracking-system stages.

## How `vertical-slice` publishes

For each slice, write to:

```
.scratch/slices/<NNN>-<slug>.md
```

Where NNN is a 3-digit zero-padded number incremented per slice across the repo's history.

## Conventions

- One file per slice
- Filename: `<3-digit>-<feature-slug>-<slice-slug>.md` (e.g., `001-collab-editor-single-user-editor.md`)
- File header includes: status, blocked-by, labels
- File body: the slice spec section verbatim
- "Closing" a slice: rename file to add `.done` (`001-collab-editor-single-user-editor.md.done`) OR move to `.scratch/slices/done/`

## Read patterns

```bash
ls .scratch/slices/*.md  # open slices
grep -l "Status: in-progress" .scratch/slices/*.md
```

## Migration path

If you later adopt GitHub or Linear, the markdown files can be imported. `vertical-slice` supports a one-time migration mode.
