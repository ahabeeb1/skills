# Dogfood scenario 20 — depth-tier detection eval

> Note: this suite shares the `20-` prefix with `20-semantic-repo-discovery`
> (a frozen historical collision — see `tests/dogfood/README.md` § Known
> scenario-number collisions). Refer to it by its full directory name, not "20".

Measures whether `prior-art-research` Phase 3 routes a feature to the **correct
depth tier** (Quick / Balanced / Deep), and whether the two tier invariants
hold. Introduced with [ADR-0016](../../../docs/agents/adrs/0016-chain-wide-depth-tier.md);
the tier mechanism is documented in
[`docs/agents/references/tier-scale.md`](../../../docs/agents/references/tier-scale.md).

## Why this eval exists

The feature's core risk is the auto-detect picking the *wrong* tier — a
genuinely complex feature routed to Quick would skip ceremony it needed. The
methodology follows Anthropic's skill-creator eval guidance and *Demystifying
evals for AI agents*: define success measurably, build a small labelled set
that includes borderline cases, and **grade the outcome, not the path** (the
tier chosen, not the reasoning that produced it).

## Methodology

`calibration-set.md` holds tier-detection cases. Each case fixes the
*post-Phase-1 / post-Phase-2 state* — residual ambiguity, sub-problem count,
constraints, priorities — so the auto-detect score is reproducible, and labels
the expected tier. The set deliberately includes **borderline cases** straddling
the score thresholds (sum 1↔2 and 4↔5) and the ambiguity floor — those are
where mis-tiering is most likely.

For each case the auditor:

1. Reads the fixed post-Phase-1/2 state cold.
2. Applies the `tier-scale.md` auto-detect rule: score the three signals
   {low 0, medium 1, high 2}, sum, map (0-1 Quick / 2-4 Balanced / 5-6 Deep),
   then apply the guards (ambiguity floor, shipping-speed drop, correctness
   bump).
3. Compares the computed tier against the case's `Expected tier`.

**Primary metric:** % of cases routed to the expected tier. Acceptance bar:
≥ 90% of the calibration set.

## Invariant checks (must all pass)

Beyond routing accuracy, `calibration-set.md` § Invariant checks covers:

- **Quality gate holds under override** — `--quick` forced on a spec with
  non-empty open questions: `socratic-grill` still runs. `--quick` on a
  one-way-door decision: an ADR is still written.
- **Ambiguity floor** — a high-ambiguity case never routes to Quick.
- **Focused output** — the tier announcement cites task-based reasons only;
  no token / cost / time-budget justification language.

## Files

- `calibration-set.md` — labelled tier-detection cases + the invariant checks.

## Running

```bash
cat tests/dogfood/20-depth-tier/calibration-set.md
```

The audit is a human-graded reading exercise — there is no automated script
(consistent with scenario 13's rationale: automating before failure modes are
observed is premature). Future re-audits append a dated audit-report file.

## Cadence

Revisit triggers (from [ADR-0016](../../../docs/agents/adrs/0016-chain-wide-depth-tier.md) § Revisit triggers):

- Routing accuracy drops below 90% → re-weight the three signals or the
  thresholds.
- Users routinely override the auto-detected tier in one direction → the
  default rule is mis-calibrated.
- A new chain skill changes how a tier scales a step → re-curate the cases.
