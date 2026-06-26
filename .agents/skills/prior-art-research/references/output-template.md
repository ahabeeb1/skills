# Prior-Art Research Report — Output Template

**Use this exact structure.** Downstream skills (`draft-spec`, `socratic-grill`, `decision-record`) parse this format.

---

# Prior-Art Research: [Feature Name]

**Researched on:** [Date]
**Tier:** Quick | Balanced | Deep [— `(user override)` if set by flag]
**Sources consulted:** [N]

## TL;DR

[2-3 sentences. Lead with the recommendation: "Use [pattern X] with [concrete picks]." State the single biggest trade-off. A reader who trusts your research should be able to act on just this paragraph.]

## Context

- **Building:** [One sentence]
- **Scale:** [Numbers, order of magnitude]
- **Stack:** [Languages, frameworks, infra]
- **Constraints:** [Hard constraints]
- **Existing:** [Greenfield / retrofit / replacement]
- **Priorities:** [Top 2 from: shipping speed, operational simplicity, scale headroom, cost, correctness]

## Sub-problems

1. [Sub-problem 1]
2. [Sub-problem 2]
3. ...

## Phase 2.5 outcome — Category-completeness critic

(Include this section unless Phase 2.5 was skipped per the documented escape valve. If skipped, state the skip reason in one line and move on.)

**Verdict:** APPROVED | ADDITIONS PROPOSED (N) | SKIPPED — \<reason\>

**Critic-surfaced additions and lead's response:**

| Category | Suggested sub-problem | Lead's response | Reason |
|---|---|---|---|
| [e.g. Hooks / event handlers] | [one-line sub-problem] | Accepted — added to decomposition | — |
| [e.g. Security / auth] | [one-line sub-problem] | Rejected — non-applicable | [REQUIRED when rejected; one sentence on why this category genuinely doesn't apply to this feature + context] |
| ... | ... | ... | ... |

Silent rejection is forbidden. Every rejected addition MUST carry a written reason.

If verdict was APPROVED with zero additions, write: "Critic approved the decomposition; no additions proposed."

## Case studies

### [Team / Product] — [One-line summary]

- **Architecture:** [1-2 sentence sketch]
- **Key decision:** [What they chose and why, in their words paraphrased]
- **Scale:** [Numbers]
- **Trade-off accepted:** [What they explicitly gave up]
- **Source:** [Link with citation]

### [Team / Product] — [One-line summary]

[Same structure, 3-5 total]

---

## Patterns

### Pattern A — [Name]

[2-4 sentences describing the pattern in your own words. Cite which case studies use it.]

**Fits when:** [Conditions where this pattern is the right choice]

### Pattern B — [Name]

[Same structure. Include if multiple patterns compete.]

**Fits when:** [...]

---

## Recommendation

**For [user's context], use [Pattern X with specific choices].**

[3-5 sentences defending the recommendation, referencing the case studies and the user's stated priorities. Be opinionated. If the user picked "shipping speed + operational simplicity," do not recommend the FAANG-scale option.]

### Concrete picks

| Decision | Choice | Reason |
|---|---|---|
| [Sub-problem 1 implementation] | [Pick] | [1 line] |
| [Sub-problem 2 implementation] | [Pick] | [1 line] |
| ... | ... | ... |

### What you're explicitly giving up

- [Trade-off 1]
- [Trade-off 2]

### When to revisit

- [Scale milestone where this needs to change]
- [Capability gap that triggers a rewrite]

---

## Steering reconciliation

(Include this section ONLY if the user supplied steering hints in Phase 1. If no steering, omit the section entirely.)

For each anchor captured in Phase 1, state the verdict: **Honored**, **Honored with caveat**, or **Overridden** — with a one-line reason and citation when overridden. See `references/steering-hints.md` for the override rule.

| Steering slot | Value | Verdict | Reason |
|---|---|---|---|
| Anchor | [term] | Honored \| Honored with caveat \| Overridden | [1 line; cite source if Overridden] |
| Look at | [source] | Honored \| Overridden | [1 line] |
| Avoid | [term] | Honored \| Overridden | [1 line] |

---

## Decisions to make next

These feed `socratic-grill` and `draft-spec`:

1. **[Decision name]** — [What needs deciding, with options]
2. **[Decision name]** — [...]
3. ...

## Open questions

Things research didn't resolve. These feed `socratic-grill`:

- [Question 1]
- [Question 2]

---

## Sources

1. **[Title]** — [URL]
   What it gave us: [1 line]
2. **[Title]** — [URL]
   What it gave us: [1 line]
...

---

HANDOFF: spec ready — invoke `draft-spec` to turn this recommendation into the plain-language Design the user reads.
HANDOFF: grill ready — once the Design is written, invoke `socratic-grill` to walk the user through it and earn sign-off.
