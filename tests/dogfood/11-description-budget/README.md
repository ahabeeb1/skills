# Dogfood scenario 11 — Description budget + chain integrity

Enforces the v1.9.0 description budget policy from [ADR-0007](../../../docs/agents/adrs/0007-description-budget-policy.md) and the chain-relationship surface rule from [ADR-0006](../../../docs/agents/adrs/0006-remove-next-skills-frontmatter.md).

## Files

- `check-description-budget.sh` — Slice 1 assertion. Parses every `skills/*/SKILL.md` frontmatter `description:` field, counts characters, asserts:
  - Per-skill hard ceiling: ≤1,200 chars (ADR-0007)
  - Plugin-wide target average: ≤600 chars (ADR-0007)
  - Every description contains "Make sure to use this skill" or "Use when" pushy-trigger phrase
  - No description contains the phrase "Inspired by" (moved to `## Origins` body section)
  - Three keystone skills retain ≥2 anti-trigger bullets: `prior-art-research`, `socratic-grill`, `tdd-loop`
- `chain-integrity.sh` — Slice 2 assertion. Reads pre-removal `next-skills` lines from git history; for each `(source, target)` pair, greps the source SKILL.md body for the target name in HANDOFF / `## See also` / prose. Fails on any unmatched pair.
- `no-next-skills.sh` — Slice 2 assertion. Confirms zero `next-skills:` lines remain in any `skills/*/SKILL.md` frontmatter.

## Running

```bash
bash tests/dogfood/11-description-budget/check-description-budget.sh
bash tests/dogfood/11-description-budget/no-next-skills.sh
bash tests/dogfood/11-description-budget/chain-integrity.sh
```

Each script exits 0 on pass, 1 on fail with diagnostic output.

## Pre-merge gate

These scripts run as part of the v1.9.0 slice-1 and slice-2 PR pre-merge dogfood suites. Not a per-commit hook (chain-integrity depends on git history which is brittle mid-rebase).
