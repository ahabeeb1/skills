# Skill voice — the house style every skill is written in

Canonical reference for how habeebs-skill SKILL.md bodies and human-facing artifacts read.
Established by the [house-voice decision](../adrs/2026-06-26-adopt-superpowers-house-voice.md).
Skills link here instead of restating the rules. This reference is documentation (prose is
fine); the rules it defines are applied as imperative content inside skill bodies, which stay
behavioral-only per [ADR-0022](../adrs/0022-behavioral-only-skill-body.md).

The goal is one thing: a reader — human or agent — understands what to do, and why, on first
read, without a jargon decoder. The voice is a senior engineer giving a capable junior firm,
unambiguous rules.

## The two layers

Every chain run has a **Human layer** and a **Machine layer**. They are written to different
audiences, and the voice rules apply differently to each.

- **Human layer** — `prior-art-research` → the **Design** → `socratic-grill`. The user reads
  these. They MUST be plain-English, comprehensive, and readable cold. This is where the user
  learns what is being built and why, and signs off before any code.
- **Machine layer** — the slice list, `tdd-loop`, `parallel-dev`. The user does not read these.
  They are written for the implementing subagent and optimized for correct output. Technical
  vocabulary is fine here; plain-English narration is not required.

When in doubt about how plain a document must be: if the user reads it, it is Human-layer and
must read cold. If only a subagent reads it, it is Machine-layer and may be terse and technical.

## The four devices

### 1. Iron law — one line, at the very top

Every skill opens with a single imperative line stating its non-negotiable rule, in capitals,
before anything else in the body. One law per skill. It is the rule the reader carries away.

- Good (`socratic-grill`): `NO DECISION EXITS AS "WE'LL SEE."`
- Good (`tdd-loop`): `NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.`
- Good (`decision-record`): `ONLY ONE-WAY DOORS GET AN ADR.`
- Bad: `This skill helps drive ambiguity out of decisions through structured questioning.`
  (A description, not a law. No punch, nothing to carry away.)

If a skill genuinely needs two laws, two is the ceiling. More than two means the skill does too
much — split it.

### 2. Plain imperatives

Short, declarative, present-tense. Tell the agent what to do. Prefer `YOU MUST`, `STOP`,
`DO NOT`, and numbered steps over descriptive prose. State the what and the why in one breath.

- Good: `Write the test first. Watch it fail. If you didn't watch it fail, you don't know it
  tests the right thing.`
- Bad: `It is generally advisable to consider writing tests prior to implementation where
  practical, as this can help ensure correctness.`

### 3. Thought → Reality tables

Every skill's anti-pattern list is a two-column table. The left column is the rationalization the
agent will reach for in the moment; the right column is the reality that refutes it. Naming the
excuse is what makes the rule hard to evade.

| Thought | Reality |
|---|---|
| "This spec is simple — skip the grill." | Simple specs hide the worst assumptions. Grill it. |
| "I'll keep the old code as reference." | You'll adapt it. That's the old design leaking in. Delete means delete. |
| "I remember what this skill says." | Skills change. Re-read the current version. |

Write the left column in the agent's own voice — the actual thought, in quotes. Write the right
column as a flat refutation plus the correct action.

### 4. Plain English first, jargon glossed

On the Human layer, lead with plain language; a reader who only reads the first paragraph knows
what is happening. For methodology terms:

- A term WITH a `GLOSSARY.md` entry (slice, tier, pgroup, HITL, AFK, one-way door, dispatch
  group) may be used unexplained **only if** the document carries a GLOSSARY footer link.
- A term WITHOUT a GLOSSARY entry gets a 3–8-word inline gloss on its first use.
- A document-specific identifier (a phase name, a fixture id) gets an inline definition on first
  use.

Footer form, on any Human-layer artifact: `> Terms: see [GLOSSARY](../GLOSSARY.md).`

## What this does not change

- ADR-0022 still governs bodies: no theory prose, no inline `ADR-NNNN` citations, no version or
  date tags, ≤500 lines. Iron laws, imperatives, and Thought→Reality tables are all imperative
  content — they comply.
- The `## See also` footer (forward links only) and `## Origins` conventions are unchanged.
- Machine-layer documents are exempt from the plain-English-first rule (device 4) — they keep
  their technical vocabulary.

## See also

- [`tier-scale.md`](./tier-scale.md) — the effort scale skills also inherit and link.
- [`GLOSSARY.md`](../GLOSSARY.md) — the vocabulary the gloss rule defers to.
- [`adr-template`](../../skills/decision-record/references/adr-template.md) and the Design
  template — the artifact formats this voice applies to.
