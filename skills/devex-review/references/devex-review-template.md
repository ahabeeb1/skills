# Devex Review Template

Appended to the active grill record by `devex-review`. Lives inline in the grill document or as a sibling `<slug>-devex-review.md` if the grill is long.

Copy from here. Replace bracketed placeholders. Keep all rows; mark a non-applicable dimension `N/A` in the status column and give the design reason in the Skip notes section below — don't delete rows.

---

# DX Review — [feature slug]

**Dimensions:** `skills/devex-review/references/dx-gap-catalog.md`
**Run by:** devex-review, [YYYY-MM-DD]
**Invoked from:** socratic-grill on [grill record path]

## Scope decision

Is this a developer-facing product? **Yes** / No — [one-line reason. If No, this record stops here and control returns to socratic-grill with a SKIP note.]

## DX dimension scores

| #  | Dimension                              | Status                  | Spec evidence / gap note                                                    |
|----|----------------------------------------|-------------------------|-----------------------------------------------------------------------------|
| D1 | Onboarding / time-to-first-success     | ✓ / ~ / ✗ / N/A         | [Cite spec line if ✓; describe ambiguity if ~; state silence if ✗.]         |
| D2 | First-time-developer roleplay          | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| D3 | API & CLI ergonomics                   | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| D4 | Error-message quality                  | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| D5 | Documentation-as-experienced           | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| D6 | Upgrade / migration friction           | ✓ / ~ / ✗ / N/A         | [...]                                                                       |

## Questions added to grilling agenda

### Must-grill (adoption-shaping)

- **[D<n>]** [Concrete, single-axis question that names specific spec entities.]
- **[D<n>]** [...]

### Should-grill (daily-experience-shaping)

- **[D<n>]** [...]

### Nice-to-grill (deferred unless user asks for the full sweep)

- (None / list)

## Skip notes

(Dimensions marked N/A or ✓ with no question. One bullet each. Optional.)

- **D<n>** — [Reason. e.g., "spec is an internal SDK consumed by one team; D5 docs-as-experienced is N/A by design."]

## Status

`DONE` / `DONE_WITH_CONCERNS` / `BLOCKED` / `NEEDS_CONTEXT`

[One line explaining the status if not DONE.]

## Recommendation back to socratic-grill

- [ ] Resume grilling with **N** new questions interleaved into the existing agenda
- [ ] If Missing count > 4, recommend handing back to `draft-spec` for a re-draft before grilling continues
- [ ] If 0 questions, no-op return to socratic-grill (DX review passed)
