# Dogfood Scenario 19b — Internal CRUD service (negative trigger-precision control)

**Scenario type:** Negative — `devex-review` MUST NOT trigger
**Expected behavior:** SKIP with one-line reason; zero DX questions generated

---

## Spec under test (excerpt)

> **Product:** `expense-tracker` — an internal web service for the finance team to log, categorize, and approve employee expense claims.
>
> **Users:** Finance team (approvers) and employees (submitters). No external API surface. No public SDK or CLI.
>
> **Stack:** Next.js frontend, Postgres database, REST endpoints consumed only by the Next.js frontend. No versioned public API.
>
> **Features:**
> - Submit an expense claim with amount, category, and receipt photo
> - Finance team approves or rejects claims in a dashboard
> - Monthly export to CSV for accounting
>
> **Open questions:**
> - Should we add an email notification when a claim is approved?
> - Should the CSV export be scheduled or manual?

---

## Phase 1 — Confirm trigger

**Trigger test:** "Is a developer — not an end-user — the primary consumer of this product's interface?"

**Answer from spec:** No. `expense-tracker` is a web service consumed by employees and the finance team via a Next.js dashboard. There is no public API, no SDK, no CLI, no plugin surface. Developers build it; they are not its users. The primary consumers are end-users (employees submitting claims and finance team approving them). ✗ — not a developer-facing product.

**Expected output:**

```
SKIP: devex-review does not apply.
  Reason: spec is an internal end-user web service (expense claim management) with no developer-facing API, CLI, SDK, or plugin surface.
  Returning control to socratic-grill.
```

---

## Why this scenario is load-bearing

`expense-tracker` is representative of the most common mis-trigger class: a web application with a REST API. The skill must distinguish between:

- A REST API that is a **public developer-facing interface** (e.g., a payments SDK with a `/v1/charge` endpoint developers integrate) → trigger
- A REST API that is **internal plumbing** consumed only by the product's own frontend → no trigger

The spec makes the boundary explicit: "REST endpoints consumed only by the Next.js frontend. No versioned public API." A skill that triggers here — asking about CLI ergonomics and onboarding friction for an expense claim CRUD dashboard — would be noise that trains users to ignore the review entirely.

---

## Adversarial variant: ambiguous hybrid

**Input modification:** Suppose the spec is amended to add: "The finance team can also query the API directly via curl for ad-hoc reports."

**Expected behavior:** This does NOT flip the trigger. An internal API accessed only by the finance team via curl is still not a developer-facing product. The trigger predicate requires that developers are the **primary consumer** — the spec's primary users remain employees and the finance team, not developers integrating an SDK.

**If the amendment were instead:** "We will publish a public REST API for third-party expense-management integrations, with versioning and a developer portal" — then the trigger WOULD fire, because the new surface is explicitly developer-facing.

---

## Pass / fail criteria

| # | Criterion | Pass condition |
|---|---|---|
| 1 | Phase 1 trigger does NOT fire | devex-review emits SKIP, does not advance to Phase 2 |
| 2 | SKIP includes a one-line reason | Reason names the product type and explains why it's not developer-facing |
| 3 | Zero DX questions generated | No questions are added to the grilling agenda |
| 4 | Control returns to socratic-grill | Skill does not absorb the grilling turn; SKIP note is returned |
| 5 | Adversarial variant handled correctly | "curl access for finance team" still produces SKIP; "public third-party API" would produce trigger |
