---
name: socratic-grill
description: Socratic ambiguity-reduction on a spec's open questions. Use when draft-spec emits "HANDOFF: grill ready", user types "/grill", "verify this design", "pressure-test this approach", or "we'll figure it out later". Do not use to brainstorm options or for pure debugging.
disable-model-invocation: true
---

# Socratic Grill

Drive ambiguity out of every important decision through structured questioning. Every "should," "probably," and "we'll figure it out later" in a spec is a future bug. This skill makes them explicit before implementation starts.

The mode is Socratic: ask questions, surface assumptions, force concrete answers. Never accept "it depends" without identifying what it depends on AND committing to a path.

## When to use this skill

**Trigger on:**

- A `draft-spec` output ended with `HANDOFF: grill ready`
- A spec or design has any "open questions" section that isn't empty
- The user uses hedging language ("probably," "we'll see," "tentatively")
- A decision in a research recommendation feels under-justified
- The user invoked `/grill` explicitly
- You're about to start implementation and you notice ambiguous parts of the plan

**Do NOT trigger on:**

- Tasks where there's only one reasonable approach (don't manufacture ambiguity)
- Exploration / brainstorming phase (use `prior-art-research` instead)
- Pure debugging tasks (the bug is the ambiguity-killer there)

## Core workflow

### Pre-flight — Environment check

Before Phase 1, verify `docs/agents/SYSTEM_CONTEXT.md` exists. If missing, halt with:

> **SETUP REQUIRED:** `docs/agents/SYSTEM_CONTEXT.md` missing. Run `/groundwork` (preferred — one-shot bootstrap) or `/research` (writes the file via Phase 0 reconnaissance) first.

This skill cannot produce reliable output without the environment-binding cache. Do not proceed to Phase 1.

**Staleness check:** Before reading SYSTEM_CONTEXT.md, run the staleness-check protocol per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md). If stale, emit the banner and proceed with a clear `[stale]` annotation on any inferences drawn from the cache. This skill is a READER — only `prior-art-research` Phase 0 writes SYSTEM_CONTEXT.md.

**GLOSSARY lookup (on-demand):** If methodology terminology in this spec / grill / plan feels ambiguous (e.g., "slice", "phase", "dispatch group", "pgroup", "HITL", "AFK"), Read `docs/agents/GLOSSARY.md` immediately before proceeding. Don't guess at habeebs-skill vocabulary — the glossary is the canonical reference.

### Phase 1 — Inventory open questions

Collect every ambiguous item from the inputs:

1. Explicit "Open questions" sections in specs / research outputs
2. Decisions marked "tentatively" or "to be confirmed"
3. Any item in the user's prose using hedging language
4. Decisions where the spec lists a choice but no reasoning

Show the user the list and ask if you missed anything. The list IS the grilling agenda.

**Inherit the tier.** Read the `**Tier:**` field from the spec header (Quick / Balanced / Deep — see [`docs/agents/references/tier-scale.md`](../../docs/agents/references/tier-scale.md)); echo it into the Grill Record header. The tier scales *how much* grilling runs, never *whether* a real ambiguity gets resolved:

- **Quick** — the grill runs *only if* the inventory above is non-empty. If it is empty, there is nothing to resolve; record "no open items — grill skipped" and hand off. If it is non-empty, run one focused round on exactly those items (skip the proactive 7-axis sweep of already-decided choices). A non-empty inventory is *always* grilled, even at Quick — that is `tier-scale.md` invariant 1.
- **Balanced** — full 7-axis grill (Phase 2 as written).
- **Deep** — full grill, multiple rounds where an item stays unresolved.

This holds under a user override: forcing `--quick` does not let a spec with open questions skip the grill.

**Domain extension — agent products:** If the spec describes building an agent / assistant / copilot / chatbot / LLM workflow / RAG system (anything where an LLM call is on the critical path), invoke `agent-factors-check` before Phase 2. It returns 6–13 additional Socratic questions targeting the gaps the standard 7 axes don't cover (tool-call schemas, state unification, pause/resume APIs, human-as-tool, trigger surfaces, pre-fetch). Interleave those into the agenda.

If the spec is a generic CRUD / web / mobile app with no LLM orchestration, skip the factor check. At the **Quick** tier, skip the proactive factor sweep too — but if an item already in the inventory touches an agent factor, grill it directly.

**Domain extension — developer-facing products:** If the spec describes a developer-facing product — a CLI, SDK, library API, plugin, or developer framework — invoke `devex-review` before Phase 2. It returns one Socratic question per developer-experience gap (onboarding friction, first-time-developer roleplay, API/CLI ergonomics, error-message quality, docs-as-experienced, upgrade friction) — gaps the standard 7 axes don't cover. Interleave those into the agenda. Both domain extensions can fire on the same spec (e.g. a developer-facing SDK that also orchestrates LLM calls). Skip `devex-review` for non-developer-facing specs (internal CRUD, end-user web/mobile apps).

### Phase 2 — Grill each item against the ambiguity axes

For each item, work through the dimensions in `references/ambiguity-axes.md`. Not all axes apply to every decision — pick the relevant 2-4 per item and dig in.

The seven axes:

1. **Performance** — what's the budget? Where does it bind? What happens at 10x load?
2. **Failure modes** — what breaks? How? What does the user see? How do you recover?
3. **Scale** — what changes at 10x, 100x, 1000x users/data/requests?
4. **Concurrency** — what if two of these happen at once? Three? In any order?
5. **Migration** — how do you get from current state to target state? Roll back?
6. **Reversibility** — if this turns out wrong, how do you undo it? What's the blast radius?
7. **Observability** — how do you know it's working in production? When it breaks, how do you find out?

**Grilling style:**

- Ask one question at a time. Wait for the answer. Then drill deeper or move to the next axis.
- Take the user's first answer as a starting point — challenge it. "What if X happens?" "Why not Y?" "How do you measure that?"
- Don't accept abstract answers ("we'll log it" — log WHAT, exactly, queried HOW)
- If the user keeps deflecting, name it: "This decision is under-specified. Either commit, or explicitly defer with a revisit trigger."

### Phase 3 — Resolve each item

Each item exits the skill in one of three states:

1. **Decided** — user committed to a concrete answer. Capture it.
2. **Explicitly deferred** — user chose to revisit later, with a stated trigger condition. Capture the trigger.
3. **Out of scope** — the grilling revealed this decision belongs to a different problem. Punt it.

Never let an item exit as "we'll see." That's the failure mode the skill exists to prevent.

### Phase 4 — Produce the grill output

Write a Grill Record to `docs/agents/specs/YYYY-MM-DD-<spec-slug>-grill.md`, mirroring the dated spec it grills (same date and slug, `-grill` suffix). Its `**Spec:**` link points at the spec, which carries the version in frontmatter. Halt loud if the dated filename already exists.

Use `references/grill-output-template.md`:

- Every item, its starting state, the dimensions grilled on, the resolution
- New decisions surfaced during grilling (often the grill reveals decisions the spec didn't anticipate)
- Updates to push back into the spec (mark them clearly)
- Items to add to the ADR (high-impact decisions that future readers need to understand)

### Phase 5 — Hand off

```
HANDOFF: spec update ready — the following items in the spec need updating: [list]. Re-run draft-spec on those sections OR apply the updates directly.
HANDOFF: record ready — invoke `decision-record` to capture the high-impact decisions surfaced during grilling.
```

If the grill surfaced a fundamental architectural rethink (rare but possible), hand off back to `prior-art-research`:

```
HANDOFF: re-research needed — the grill revealed a fundamental issue with the chosen architecture. Re-invoke `prior-art-research` with the new constraint: [constraint].
```

## Anti-patterns this skill guards against

- **Manufactured ambiguity.** If there's only one reasonable answer, don't grill — accept it and move on.
- **Performative questioning.** Asking 47 questions to look thorough without driving toward resolution. Each question must serve a decision.
- **Letting the user off the hook.** "We'll figure it out later" is not a resolution. Push for either commit or explicit-defer-with-trigger.
- **Grilling decisions that aren't yours to make.** Compliance, budget, hiring — surface these to the user but don't try to resolve them yourself.
- **Treating the user like a hostile witness.** Tone matters. The grill is collaborative — you're surfacing what they already know but haven't said. Be direct, not adversarial.
- **Pre-supposing the answer.** Ask open questions. "How do you handle X?" not "You're going to handle X by Y, right?"

## Grilling tone and pacing

- Direct, not abrasive. ("What happens when the connection drops mid-write?" not "You're going to lose data, aren't you?")
- One axis at a time. Don't pile on.
- Acknowledge good answers briefly, then go deeper or move on.
- If the user is stuck, propose 2-3 options and ask which they prefer.
- Track time/turns informally — if you're 20+ turns deep on one decision, something is wrong with how the decision is framed.

## See also

- `draft-spec` — upstream; produces specs with open questions this skill resolves
- `prior-art-research` — fallback if grilling reveals a fundamental architectural problem
- `decision-record` — downstream; captures grilled decisions as ADRs
- `agent-factors-check` — domain extension invoked from Phase 1 when the spec is for an agent product
- `references/ambiguity-axes.md` — the 7 dimensions to grill on
- `references/grill-output-template.md` — output format
- `docs/agents/references/tier-scale.md` — the tier this grill inherits and how it scales the grill
