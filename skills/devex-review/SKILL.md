---
name: devex-review
description: Domain extension of socratic-grill for developer-facing product specs (CLI, SDK, library API, plugin, or developer framework). Surfaces DX gaps habeebs-skill's main chain misses: onboarding friction, first-time-developer roleplay, API/CLI ergonomics, error-message quality, docs-as-experienced, and upgrade friction. Returns one Socratic question per DX gap for the grilling agenda. Make sure to use this skill whenever the spec is for a CLI tool, SDK, library API, plugin system, or developer framework. Do NOT use for internal CRUD services, end-user web/mobile apps, or non-developer-facing products.
disable-model-invocation: true
---

# Devex Review

Surface the developer-experience gaps in a spec before grilling resolves it. The job is not to design the DX — it's to generate the Socratic questions that force the spec to confront its own rough edges for developers who will actually use it.

This skill is invoked **from** `socratic-grill`, not a standalone phase. It adds one Socratic question per DX gap to the grilling agenda. After grilling resolves them, control returns to the main chain.

Why a separate skill instead of folding into `socratic-grill`'s axes? The standard seven axes (performance, failure modes, scale, concurrency, migration, reversibility, observability) are domain-agnostic and production-readiness focused. DX gaps are specific to developer-facing products: they cluster around the first-run experience, API surface design, error messages developers read, and docs developers actually encounter — not what the product does in production at scale. A separate skill keeps the main chain lean and fires only when the product is developer-facing.

## When to use this skill

**Trigger on:**

- The spec describes a CLI tool, SDK, library API, plugin, or developer framework — anything where developers are the primary consumer
- The spec uses vocabulary like "developer experience", "onboarding", "time-to-first-success", "API ergonomics", "error messages", "docs", "plugin API", "public interface", "breaking change"
- `socratic-grill` is mid-grill on a developer-facing product and the standard axes haven't touched first-run friction, API naming, or error quality
- The user invokes `/devex-review` explicitly

**Do NOT trigger on:**

- Internal CRUD services (no developer consumers)
- End-user web or mobile apps where developers are not the primary audience
- Back-end services that developers deploy but end-users consume (the end-user experience is primary)
- Infrastructure tools with no public API surface (deployment scripts, CI configs)

If unclear whether it's a developer-facing product, ask one question: **"Is a developer — not an end-user — the primary consumer of this product's interface?"** If yes → developer-facing, run the review. If no → skip.

## The 6 DX gap dimensions

The gap catalog is documented in full in [`references/dx-gap-catalog.md`](references/dx-gap-catalog.md). Summary:

1. **Onboarding friction / time-to-first-success** — How long from `npm install` to working output? Is there a fast path?
2. **First-time-developer roleplay** — If a developer has never used this before, what is the first error they hit? Can they recover alone?
3. **API & CLI ergonomics** — Are names consistent? Are defaults sensible? Is the surface size minimal?
4. **Error-message quality** — Are errors actionable? Do they tell you what went wrong AND what to do?
5. **Documentation-as-experienced** — Does the doc order match the usage order? Does the first example actually work?
6. **Upgrade / migration friction** — What breaks on a major version? Is the migration path documented?

## Mapping to habeebs-skill's existing coverage

| DX Dimension | Already covered by | Status |
|---|---|---|
| Ergonomics / surface size | `deep-modules` (deletion test) | Partial — shape only, not naming or defaults |
| API contracts | `draft-spec`, `vertical-slice` | Partial — functionality, not consumer experience |
| Breaking changes | `socratic-grill` reversibility axis | Partial — rollback, not developer migration friction |

**Gaps no skill covers (these are the focus of this review):**

| DX Dimension | Why it's a gap |
|---|---|
| Onboarding friction | No skill asks "how long to first working output?" |
| First-time-developer roleplay | No skill adopts the beginner developer's perspective |
| Error-message quality | No skill mandates actionable, diagnostic errors |
| Docs-as-experienced | No skill checks doc order against usage order |
| Upgrade friction | `socratic-grill` reversibility axis targets production rollback, not developer migration |

## Core workflow

### Pre-flight — Environment check

This skill is invoked from inside `socratic-grill` and inherits its environment. If invoked standalone (e.g., `/devex-review` directly), apply the staleness-check protocol per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md) before reading SYSTEM_CONTEXT.md. This skill is a READER — only `prior-art-research` Phase 0 writes SYSTEM_CONTEXT.md.

### Phase 1 — Confirm trigger

Read the spec (or the active grilling context). Apply the trigger test from above. If the product is not developer-facing, halt with:

```
SKIP: devex-review does not apply.
  Reason: <one line — e.g., "spec is an end-user mobile app with no developer-facing API".>
  Returning control to socratic-grill.
```

If unclear, ask the one-question test. Don't run the review on a non-developer-facing spec — wasted tokens and noise in the grilling record.

### Phase 2 — Score each DX dimension against the spec

For each of the 6 DX dimensions, mark one of:

- **✓ Addressed** — spec is explicit. Cite the spec section.
- **~ Partial** — spec touches it but leaves an ambiguity. Note what's ambiguous.
- **✗ Missing** — spec is silent. Flag as a gap.
- **N/A** — dimension doesn't apply to this product **by design**. State the design reason.

Bias toward Partial/Missing on first pass. If you're tempted to mark something Addressed, look for the *specific* sentence in the spec — if you can't quote it, it's Partial.

**N/A is a legitimate score** when a dimension is explicitly out of scope (e.g., a spec that ships no public docs because it's an internal SDK used by one team — D5 docs-as-experienced is N/A by design). N/A is NOT an escape hatch for "I don't know" — that's ~ Partial. N/A means "we chose, with a reason."

### Phase 3 — Generate one Socratic question per gap

For each Partial or Missing dimension, write ONE concrete question to add to the grilling agenda. The question must be:

- Specific to this product (not "have you thought about error messages?" — use the actual command names, API surface, or error scenarios from the spec)
- Single-axis (don't combine DX dimensions into one question)
- Resolvable in one or two grill turns (no questions that are themselves features)

See [`references/dx-gap-catalog.md`](references/dx-gap-catalog.md) for question templates per dimension. Customize with actual spec entities.

Examples (good):
- D1: "The spec describes a CLI with `init`, `build`, and `deploy` commands. What is the exact output a first-time user sees after `devtool init` — does it produce a working directory structure, or does it require further manual steps before `devtool build` succeeds?"
- D3: "The `client.query()` method accepts an `options` object. Which fields are required vs. optional with defaults? If a developer calls `client.query(sql)` without options, does it work or throw?"
- D4: "When `client.connect()` fails because the database isn't running, what does the error message say? Does it say 'connection refused' with the host:port, or just 'connection error'?"

Examples (bad — reject these):
- "Is your onboarding experience good?" (vague)
- "Docs, error messages, AND ergonomics — how do you handle them?" (multi-axis)
- "Should you use React or Vue for the docs site?" (framework war, not a DX gap)

### Phase 4 — Score skip-able vs. must-grill

Not every gap needs grilling. Apply a triage:

- **Must-grill** (high blast radius if wrong): D1 (onboarding), D3 (API/CLI ergonomics). These affect whether developers adopt the product at all; getting them wrong forces breaking API changes.
- **Should-grill** (medium blast radius): D4 (error-message quality), D6 (upgrade/migration friction). Affect day-to-day developer experience; wrong choices cause friction but rarely force a rewrite.
- **Nice-to-grill** (low blast radius): D2 (first-time-developer roleplay), D5 (docs-as-experienced). Important but often addressable after an initial ship if the core API is sound.

Default rule: surface ALL Must-grill questions; surface Should-grill questions only if at least one Partial/Missing exists; surface Nice-to-grill questions only if the user asks for the full sweep.

### Phase 5 — Hand back to socratic-grill

Produce a DX review record using [`references/devex-review-template.md`](references/devex-review-template.md) and append it to the active grill record. Output:

```
HANDOFF: grilling agenda updated — <N> new questions added from devex-review.
  Must-grill: <count> questions on dimensions <list>.
  Should-grill: <count> questions on dimensions <list>.
  Resume socratic-grill with these questions interleaved into the existing agenda.
```

## Return contract

This skill produces one of four statuses at the end of every run (consistent with ADR-0004):

| Status | Meaning |
|---|---|
| `DONE` | Review complete; all questions added to grilling agenda; no blocking issues. |
| `DONE_WITH_CONCERNS` | Review complete but ≥1 Must-grill gap was found with no obvious resolution path — flag for extra grilling depth. |
| `BLOCKED` | Cannot complete the review — spec is too thin to score any DX dimension. Hand back to `draft-spec`. |
| `NEEDS_CONTEXT` | A key DX dimension requires information not in the spec (e.g., target developer audience, release channel). Ask the one clarifying question before proceeding. |

## Anti-patterns this skill guards against

- **Running on non-developer-facing specs.** Wastes tokens, pollutes the grill record. Honor the trigger test.
- **Generating design instead of questions.** This skill produces Socratic questions. Proposing "use a wizard-style CLI init" is design — that's `socratic-grill`'s job after the question is asked. Don't jump ahead.
- **Treating DX dimensions as a scorecard.** This isn't a grade; it's a gap-finder. A spec with 4 Missings isn't "bad" — it's a spec that hasn't thought through DX yet.
- **Conflating production observability with DX.** Error messages for developers in their terminal are DX. Error messages that appear in production logs are observability (covered by `socratic-grill`'s observability axis). Don't double-count.
- **Folding all gaps into one mega-question.** Each DX gap gets one question. A developer might answer D1 in turn 1 and D4 in turn 4.

## Integration with the chain

- **Upstream:** `socratic-grill` (this skill is invoked from it for developer-facing products)
- **Downstream:** `socratic-grill` continues with the augmented agenda; outputs flow to `decision-record` as usual
- **Sibling:** `agent-factors-check` — fires for agent/LLM products; `devex-review` fires for developer-facing products. Both can fire on the same spec (e.g., a developer-facing SDK that also orchestrates LLM calls)
- **Sibling:** `deep-modules` — addresses module shape at the refactor step; `devex-review` addresses DX at the design/grill step

## See also

- `socratic-grill` — the skill that invokes this one
- `agent-factors-check` — sibling domain extension for agent/LLM product specs
- `draft-spec` — fallback if the spec needs re-drafting (too many Missings)
- `decision-record` — captures resolved DX decisions in the ADR
- `deep-modules` — adjacent; module-shape review at the refactor step (not DX)
- [`references/dx-gap-catalog.md`](references/dx-gap-catalog.md) — the 6 DX gap dimensions with question templates
- [`references/devex-review-template.md`](references/devex-review-template.md) — output format
