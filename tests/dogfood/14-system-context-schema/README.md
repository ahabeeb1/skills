# Dogfood scenario 14 — SYSTEM_CONTEXT schema (ADR-0010)

Enforces the v1.10.0 SYSTEM_CONTEXT.md contents-prune schema from [ADR-0010](../../../docs/agents/adrs/0010-system-context-contents-prune.md).

## Files

- `check-system-context-schema.sh` — Slice 1 assertion. Reads `docs/agents/SYSTEM_CONTEXT.md` and asserts:
  - **Retained sections present:** Scale envelope, Methodology / agent setup, Notable absences, Project mode, Active steering, Last reconciliation outcome
  - **Dropped sections absent** (top-level `## ` headers — these are re-derivable per Anthropic's prune test): Stack, Persistence, Deployment shape, External services, Recent hot files, Open / unknown, Tracked manifests
  - **Schema marker present:** the file mentions "ADR-0010" or "per ADR-0010" in the header area (signals migration to the new schema)

- `check-template-schema.sh` — asserts the template at `skills/prior-art-research/references/system-context-template.md` exposes only the retained sections (template should not document dropped sections as live).

## Running

```bash
bash tests/dogfood/14-system-context-schema/check-system-context-schema.sh
bash tests/dogfood/14-system-context-schema/check-template-schema.sh
```

Each script exits 0 on pass, 1 on fail with diagnostic output.

## Pre-merge gate

These scripts run as part of the v1.10.0 Slice #1 and Slice #6 PR pre-merge dogfood suites. Not a per-commit hook (the SYSTEM_CONTEXT.md migration happens once per release; per-commit enforcement would over-fire on in-flight refreshes).

## Migration note

Per ADR-0010 § Decision, existing repos auto-migrate via `prior-art-research` Phase 0 single-writer on next refresh. This test asserts the *post-migration* state; it does not test the migration path itself (that's covered by Slice #6's repo self-migration acceptance criteria).
