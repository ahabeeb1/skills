---
name: devex-review
description: Conditional socratic-grill extension for developer-facing specs. Use when socratic-grill detects "CLI tool", "SDK", "library API", "plugin system", "developer framework", or user types "/devex-review". Do not use for internal CRUD services, end-user web/mobile apps, or non-developer-facing products.
disable-model-invocation: true
---

# Devex Review

**WALK THE DESIGN AS A FIRST-TIME DEVELOPER. FRICTION YOU DON'T FEEL, THEY WILL.**

Surface the developer-experience gaps in a spec before grilling resolves it. The job is not to design the DX — it's to generate the Socratic questions that force the spec to confront its own rough edges for developers who will actually use it.

This skill is invoked **from** `socratic-grill`, not a standalone phase. It adds one Socratic question per DX gap to the grilling agenda. After grilling resolves them, control returns to the main chain.

Why a separate skill instead of folding into `socratic-grill`'s axes? The standard production-readiness axes (performance, failure modes, scale, concurrency, migration, reversibility, observability) are domain-agnostic and production-readiness focused. DX gaps are specific to developer-facing products: they cluster around the first-run experience, API surface design, error messages developers read, and docs developers actually encounter — not what the product does in production at scale. A separate skill keeps the main chain lean and fires only when the product is developer-facing.

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

Follow the shared **[grill-extension protocol](../../docs/agents/references/grill-extension-protocol.md)** — pre-flight environment check, Phase 1 confirm-trigger (the SKIP block + the one-question test in "When to use" above), Phase 2 score each dimension (✓/~/✗/N/A, bias to Partial/Missing), Phase 3 one specific single-axis Socratic question per gap, Phase 4 triage, Phase 5 hand back via `HANDOFF: grilling agenda updated`. The protocol carries the shared anti-patterns. Only the DX-specific pieces are below.

**Phase 4 triage — which dimensions sit in which tier:**

- **Must-grill** (wrong forces breaking API changes / blocks adoption): D1 (onboarding), D3 (API/CLI ergonomics).
- **Should-grill** (day-to-day friction): D4 (error-message quality), D6 (upgrade/migration friction).
- **Nice-to-grill** (addressable after initial ship): D2 (first-time-developer roleplay), D5 (docs-as-experienced).

**Phase 3** — see [`references/dx-gap-catalog.md`](references/dx-gap-catalog.md) for question templates per dimension; customize with actual spec entities. Example questions (good — specific, single-axis):

- D1: "The spec describes a CLI with `init`, `build`, and `deploy` commands. What is the exact output a first-time user sees after `devtool init` — does it produce a working directory structure, or does it require further manual steps before `devtool build` succeeds?"
- D3: "The `client.query()` method accepts an `options` object. Which fields are required vs. optional with defaults? If a developer calls `client.query(sql)` without options, does it work or throw?"
- D4: "When `client.connect()` fails because the database isn't running, what does the error message say? Does it say 'connection refused' with the host:port, or just 'connection error'?"

**DX-specific anti-pattern (beyond the shared set):** don't conflate production observability with DX — error messages a developer reads in their terminal are DX; error messages in production logs are observability (`socratic-grill`'s observability axis). Don't double-count.

**Record:** produce a DX review record using [`references/devex-review-template.md`](references/devex-review-template.md); the hand-back names the dimensions per tier. If most dimensions are Missing, hand back to `draft-spec` before grilling continues.

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
