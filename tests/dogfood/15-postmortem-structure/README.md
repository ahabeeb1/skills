# Dogfood scenario 15 — postmortem structure (ADR-0011)

Enforces the postmortem template structure from [ADR-0011](../../../docs/agents/adrs/0011-error-analysis-cadence.md) and the template at [`docs/agents/postmortems/README.md`](../../../docs/agents/postmortems/README.md).

## Files

- `check-postmortem-structure.sh` — Slice 3 assertion. For every `*.md` file in `docs/agents/postmortems/` other than `README.md`, asserts the file contains the 8 required sections (Summary / User prompt / Expected outcome / Actual outcome / Transition-failure matrix / Failure category / Fix applied / v1.X.Y+ candidate rule). Section 9 (Notes / trace fidelity) is optional.

- `check-postmortem-readme.sh` — asserts the README template at `docs/agents/postmortems/README.md` documents all 8 required sections and references ADR-0011.

## Running

```bash
bash tests/dogfood/15-postmortem-structure/check-postmortem-structure.sh
bash tests/dogfood/15-postmortem-structure/check-postmortem-readme.sh
```

Each script exits 0 on pass, 1 on fail with diagnostic output.

## Pre-merge gate

These scripts run as part of the v1.10.0 Slice #3 and Slice #6 PR pre-merge dogfood suites.

## Note on retrospective entries

The check-postmortem-structure assertion treats `[trace-from-memory]`-tagged retrospective entries identically to `[full-trace-reviewed]` real-time entries. Both must contain the 8 required sections. The trace-fidelity tag is metadata for readers; it does not relax structural requirements.
