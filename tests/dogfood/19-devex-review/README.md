# Dogfood 19 — `devex-review` skill (2-scenario trigger-precision suite)

**Date:** 2026-05-18
**Skill under test:** `skills/devex-review/SKILL.md`
**Slice:** v1.14.0 #3 (gstack-capability-adoption spec)
**Spec:** [`docs/agents/specs/v1.13.0-gstack-capability-adoption.md`](../../../docs/agents/specs/v1.13.0-gstack-capability-adoption.md) Slice 3
**ADR:** [ADR-0014](../../../docs/agents/adrs/0014-adopt-gstack-capabilities-markdown-idea-port.md)

## Why trigger-precision is the load-bearing property

`devex-review` is a conditional domain extension of `socratic-grill` — it fires only when the spec's product is consumed primarily by developers. The risk profile is asymmetric:

- **False positive** (fires on a non-developer-facing spec): pollutes the grill record with irrelevant DX questions, wastes turns grilling onboarding for an internal service that has no onboarding.
- **False negative** (silently skips a developer-facing spec): the DX gaps are never surfaced; habeebs-skill ships a CLI or SDK with unexamined onboarding friction, opaque errors, and an unlabelled breaking-change surface.

The negative scenario (19b) is therefore load-bearing: an over-triggering DX review is noise; an under-triggering one lets bad DX into production.

## The scenarios

| File | Type | Trigger expected | DX dimensions exercised |
|---|---|---|---|
| [19a-cli-tool-spec.md](./19a-cli-tool-spec.md) | Positive | **MUST trigger** — developer-facing CLI | D1 (onboarding), D3 (ergonomics), D4 (errors), D6 (upgrade) |
| [19b-internal-crud-service.md](./19b-internal-crud-service.md) | Negative | **MUST NOT trigger** — internal CRUD, no developer-facing API | n/a — SKIP expected |

## Acceptance bar

Slice 3 is not complete unless:

1. **19a** — `devex-review` fires, scores all 6 DX dimensions, and generates at least 2 Socratic questions for the grilling agenda. Must include at least one Must-grill question (D1 or D3).
2. **19b** — `devex-review` emits a `SKIP` with a one-line reason and returns control to `socratic-grill` without generating any DX questions.

19b is the precision control: a skill that fires on every spec regardless of domain is not a conditional extension — it's just more noise on every grill.

## How to run

These are illustrative scenarios, not automated tests (consistent with dogfood 07 and 17). Run each manually:

1. Feed the scenario's spec excerpt to `socratic-grill` mid-grill (or invoke `/devex-review` standalone).
2. Inspect the skill's Phase 1 trigger decision.
3. For 19a: verify the DX dimension table is populated and questions are on the grilling agenda.
4. For 19b: verify the SKIP is emitted with a reason and no questions are generated.
5. Pass / fail per each scenario's "Pass / fail" section.

## Revisit triggers

- A non-developer-facing spec type (e.g., an end-user data-export feature) slips past the trigger test and generates DX questions → tighten the trigger predicate and add a 19c negative control.
- A developer-facing product is missed (false negative) — e.g., a plugin system the trigger test doesn't recognize → add to the positive trigger list and add a 19d positive scenario.
- The DX dimensions themselves evolve (new gap class discovered post-merge) — add new dimensions to `references/dx-gap-catalog.md` and extend 19a to cover them.
