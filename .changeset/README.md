# Changesets

Append-only intent files for v1.20.0+ releases. Per [`adr-late-binding-and-changesets`](../docs/agents/adrs/adr-late-binding-and-changesets.md), this directory replaces the v1.19.0-and-earlier pattern where every PR edited `plugin.json`, `marketplace.json`, and `CHANGELOG.md` directly. Direct edits to those files are now reserved for the release skill at release-PR-creation time.

## Schema

Every changeset is a markdown file with YAML frontmatter:

```yaml
---
bump: patch | minor | major
why: one-sentence explanation of what changed and why
---
```

- `bump` is required. Value must be exactly `patch`, `minor`, or `major`. The release skill picks the highest bump across all pending changesets when aggregating.
- `why` is required. A single non-empty line. Aggregated into the CHANGELOG entry as a bullet point.

The file body (anything below the frontmatter) is optional and currently unused by the release skill — it's a place for richer context if you want it.

## Workflow

When you open a release-worthy PR (any PR modifying `skills/`, `hooks/`, `.claude-plugin/`, `plugin.json`, or `marketplace.json`):

1. Copy the example: `cp .changeset/EXAMPLE.md .changeset/<your-branch-slug>.md`
2. Edit the `bump` and `why` fields to describe your change.
3. Commit the changeset alongside your other changes.
4. Open the PR.

The release skill (at PR-creation time, NOT mid-PR) reads all pending `.changeset/*.md` files, picks the highest bump, writes the version bump + CHANGELOG entry, and deletes the consumed changesets in one atomic commit.

## Which PRs need a changeset?

Per the release-skill path-audit matrix (full spec in [`adr-late-binding-and-changesets`](../docs/agents/adrs/adr-late-binding-and-changesets.md) § Decision):

- **REQUIRED if PR modifies any of:** `skills/`, `hooks/`, `.claude-plugin/`, `plugin.json`, `marketplace.json`
- **OPTIONAL (emits INFO note, does not block):** `docs/`, `CLAUDE.md`, `AGENTS.md`, `README.md`, `CHANGELOG.md`
- **NEVER required:** `tests/`, `.gitignore`, `.github/`, `.gitattributes`

## Schema validation

`bash tests/dogfood/22-changeset-schema/check-schema.sh` validates every changeset against the schema. Exit 0 = all valid; exit 1 = malformed.

## Filename convention

Use your branch slug (e.g., `feature/v1.21.0-foo` → `.changeset/v1.21.0-foo.md`). Single-author repo means branch slugs are unique by construction. If a second author joins and ≥3 filename collisions emerge in any 90-day window, switch to random-id naming (revisit trigger in `adr-late-binding-and-changesets`).

Reserved names: `README.md`, `EXAMPLE.md`, `.gitkeep`. These are not parsed as changesets.
