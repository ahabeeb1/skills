# Factor Check Template

Appended to the Design's **Decided** section by `agent-factors-check`. Lives inline in the Design or as a sibling `<slug>-factor-check.md` if the run is long.

Copy from here. Replace bracketed placeholders. Keep all 13 rows; mark a non-applicable factor `N/A` in the status column and give the design reason in the Skip notes section below — don't delete rows.

---

# Factor Check — [feature slug]

**Run by:** agent-factors-check, [YYYY-MM-DD]
**Invoked from:** socratic-grill on [Design path]

## Scope decision

Is this an agent product? **Yes** / No — [one-line reason. If No, this record stops here and control returns to socratic-grill with a SKIP note.]

## Factor scores

| #  | Factor                                  | Status                  | Spec evidence / gap note                                                    |
|----|-----------------------------------------|-------------------------|-----------------------------------------------------------------------------|
| 1  | Natural language → tool calls           | ✓ / ~ / ✗ / N/A         | [Cite spec line if ✓; describe ambiguity if ~; state silence if ✗.]         |
| 2  | Own your prompts                        | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| 3  | Own your context window                 | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| 4  | Tools = structured outputs              | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| 5  | Unify execution + business state        | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| 6  | Launch / pause / resume APIs            | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| 7  | Contact humans with tool calls          | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| 8  | Own your control flow                   | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| 9  | Compact errors into context             | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| 10 | Small focused agents                    | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| 11 | Trigger from anywhere                   | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| 12 | Stateless reducer                       | ✓ / ~ / ✗ / N/A         | [...]                                                                       |
| 13 | Pre-fetch context (bonus)               | ✓ / ~ / ✗ / N/A         | [...]                                                                       |

## Questions added to grilling agenda

### Must-grill (architecture-shaping)

- **[F<n>]** [Concrete, single-axis question that names specific spec entities.]
- **[F<n>]** [...]

### Should-grill (interface-shaping)

- **[F<n>]** [...]

### Nice-to-grill (deferred unless user asks for the full sweep)

- (None / list)

## Skip notes

(Factors marked N/A or ✓ with no question. One bullet each. Optional.)

- **F<n>** — [Reason. e.g., "spec explicitly defers prompt-versioning to v2 milestone; deferral noted, no question needed now."]

## Recommendation back to socratic-grill

- [ ] Resume grilling with **N** new questions interleaved into the existing agenda
- [ ] If Missing count > 6, recommend handing back to `draft-spec` for a re-draft before grilling continues
- [ ] If 0 questions, no-op return to socratic-grill (factor check passed)
