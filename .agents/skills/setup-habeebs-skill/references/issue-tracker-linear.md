# Issue Tracker — Linear

This repo uses Linear for slice tracking. Skills that publish issues use the Linear MCP server (if connected) or the Linear API.

## How `vertical-slice` publishes

Via Linear MCP:

```
linear:create_issue
  team: <team-id-or-key>
  title: "<slice-name>"
  description: <slice-spec-markdown>
  labels: ["<triage-label>"]
  priority: <optional>
```

Without MCP, use the Linear API directly with a service account token in `LINEAR_API_KEY`.

## Conventions

- Title format: `<feature-slug>: Slice N — <slice name>`
- Description: full slice spec
- Project: optional — group slices of one feature under one Linear project
- Labels: from `triage-labels.md`
- Dependencies: use Linear's "blocked by" relation to link issues
