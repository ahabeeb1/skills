# Prior-Art Research Report — Output Template

**Use this exact structure.** Downstream skills (`draft-spec`, `socratic-grill`, `decision-record`) parse this format.

---

# Prior-Art Research: [Feature Name]

**Researched on:** [Date]
**Mode:** Quick | Deep
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

HANDOFF: spec ready — invoke `draft-spec` to turn this into an implementation spec.
HANDOFF: grill ready — invoke `socratic-grill` to drive ambiguity out of the open questions and decisions above.
HANDOFF: record ready — once spec + grill complete, invoke `decision-record` to capture the chosen architecture as an ADR.
