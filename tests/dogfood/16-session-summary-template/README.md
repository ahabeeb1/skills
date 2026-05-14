# Dogfood scenario 16 — session-summary template (ADR-0012)

Enforces the 7-section session-summary template from [ADR-0012](../../../docs/agents/adrs/0012-compress-at-overflow-protocol.md), committed at [`docs/agents/templates/session-summary-template.md`](../../../docs/agents/templates/session-summary-template.md).

## Files

- `check-session-summary-template.sh` — asserts the template file exists at `docs/agents/templates/session-summary-template.md` and contains the 7 required sections (Active artifacts / Current slice / Last successful action / What's blocking / Open grill Qs / Recent test state / Branch / worktree pointer) plus the "Fresh sub-session resume protocol" tail section.

- `check-using-habeebs-section.sh` — asserts `skills/using-habeebs-skill/SKILL.md` contains the "## When sessions grow long" section and references ADR-0012 + the template path.

## Running

```bash
bash tests/dogfood/16-session-summary-template/check-session-summary-template.sh
bash tests/dogfood/16-session-summary-template/check-using-habeebs-section.sh
```

Each script exits 0 on pass, 1 on fail with diagnostic output.

## Pre-merge gate

These scripts run as part of the v1.10.0 Slice #5 and Slice #6 PR pre-merge dogfood suites.

## Note on `.scratch/` files

This scenario does NOT assert anything about `.scratch/session-summary-*.md` files in user repos — those are ephemeral working-set artifacts (not committed; gitignored by convention). The template file IS committed and IS asserted.
