# Depth tiers — the chain-wide effort scale

Canonical reference for the **tier** that governs how much of the chain
(Human layer `prior-art-research → draft-spec` writes the Design `→
socratic-grill`; Machine layer `vertical-slice → tdd-loop → release`; with
`decision-record` and `write-plan` conditional) runs for a given feature.
Established by [ADR-0016](../adrs/0016-chain-wide-depth-tier.md). Chain skills
link here instead of restating the scale. The tier scales the *design* depth
that precedes implementation; `tdd-loop`, `verify-output`, and `release` always
run in full regardless of tier (they inherit the `Tier:` header only to scale
their own optional ceremony, never their rigor).

## The two invariants

**1. Tiers scale effort, never decision quality.** A lighter tier removes
*ceremony for decisions that do not exist* — it never produces a worse
decision. A real decision always pulls in the skill that handles it,
regardless of tier:

- Non-empty `Open questions` on a spec always triggers `socratic-grill`.
- A one-way-door / hard-to-reverse decision always triggers an ADR.
- This holds under a user override: forcing `--quick` changes the *default*
  depth — it never disables a quality gate that a real decision has triggered.

**2. User-facing output stays focused.** The tier announcement and HANDOFF
lines state the tier and a **task-based** reason only — sub-problem count,
residual ambiguity, constraint count. They never justify the tier with token,
cost, or time-budget language. The effort figures in this doc are *authoring*
targets, not user-facing copy.

- Good: `Tier: Quick — 1 sub-problem, low ambiguity, no hard constraints.`
- Banned: any phrasing framed as "to save tokens / time / cost".

## The three tiers

`tdd-loop` always runs in full — the tier governs how much *design* precedes
implementation, not implementation rigor. Quick *skips* heavy optional steps
(it does not merely shrink them); every skip is conditional and reversible per
invariant 1.

| Chain step | Quick | Balanced | Deep |
|---|---|---|---|
| research Phase 1 gate | 2 questions / 1 confirm line | full 2-then-3 | full 2-then-3 + steering |
| research Phase 2.5 critic | skipped (existing valve) | runs | runs |
| research depth | 1 agent, ~5 sources | 1 agent, ~8-10 sources | subagent/sub-problem, 10-20 sources |
| draft-spec (the Design) | short Overview + key decisions + trade-offs + open questions | full Design template | full Design + fuller why-this-approach with rejected alternatives |
| socratic-grill | skipped *only if* the Design's open-questions empty; else 1 short round + sign-off | full 8-axis grill + sign-off | full grill, multi-round; agent-factors-check if applicable + sign-off |
| decision-record | ADR only for a one-way-door decision (same at every tier) | ADR only for a one-way-door decision; standard template | one-way-door ADR, full template, ≥3 alternatives |
| vertical-slice (slice list) | slices + acceptance + test seam; no DAG | slice list; DAG if 5+ slices | slice list + DAG + parallelization always |
| write-plan | only if multi-phase | only if multi-phase (3+ slices across real phase gates) | runs when multi-phase — phased plan, gates, pgroups |
| tdd-loop | runs | runs | runs (pgroup auto-dispatch) |

Effort targets (authoring guidance, **not** user-facing copy): Quick ≈ 1 agent
/ ~5 sources; Balanced ≈ 1 agent / ~8-10 sources; Deep ≈ one subagent per
sub-problem / 10-20 sources.

## Auto-detection

`prior-art-research` Phase 3 decides the tier after Phase 1 (context) and
Phase 2 (decomposition). Three signals, each scored {low 0, medium 1, high 2}:

1. **Residual ambiguity after Phase 1** — count of partial / `[assumed]` /
   `[unknown]` answers: 0-1 low, 2-3 medium, 4+ high.
2. **Sub-problem count** — 1 low, 2-3 medium, 4+ high.
3. **Constraint count / complexity** — hard constraints from Phase 1 Q2; a
   constraint that rules out a common architecture counts double: 0-1 low,
   2-3 medium, 4+ high.

Sum (0-6): **0-1 → Quick**, **2-4 → Balanced**, **5-6 → Deep**.

Guards:

- **Ambiguity floor (invariant 1).** If the ambiguity signal is high, the tier
  is at least Balanced regardless of the sum — a genuinely unclear task never
  auto-routes to Quick.
- If "shipping speed" is a top-2 priority and the computed tier is Balanced,
  drop to Quick. Never drops Deep.
- If "correctness" is a top-2 priority and the project is greenfield and the
  computed tier is Balanced, bump to Deep.

The rule is a heuristic, not a hard gate (consistent with ADR-0013) — a user
override always wins.

## Selection and propagation

- **Auto-detect** is the default (the rule above).
- **Override:** `/research --quick | --balanced | --deep`. A mid-chain override
  (`/grill --deep`) updates that skill's own artifact header; later skills
  inherit the new value. An override never disables a quality gate that a real
  decision has triggered (invariant 1).
- The tier is decided **once**, by `prior-art-research` Phase 3, and written
  into the research report header as `**Tier:**`. Every downstream skill reads
  it from the upstream artifact it already reads in full, and echoes
  `**Tier:**` into its own output header. Downstream skills inherit the tier;
  they do not re-decide it. The exceptions are an explicit mid-chain override
  flag and a `re-research` restart.
