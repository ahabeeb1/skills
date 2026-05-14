# Dogfood scenario 13 — trigger-precision audit (R4)

One-time manual audit measuring whether habeebs-skill's 15 SKILL.md descriptions actually trigger correctly on realistic user prompts. Per Anthropic's [Claude Code best-practices](https://code.claude.com/docs/en/best-practices), description quality is **the** load-bearing correctness axis for skills — v1.9.0 trimmed all 14 pre-existing descriptions for budget compliance ([ADR-0007](../../../docs/agents/adrs/0007-description-budget-policy.md)) but did not measure whether the trimmed descriptions still trigger correctly. This audit fills that gap per the v1.10.0 R4 recommendation.

## Methodology

A manual reading exercise. Hamel Husain + Shreya Shankar's "[error analysis before infrastructure](https://hamel.dev/blog/posts/evals-faq/)" thesis applies: dogfood-style synthetic prompts approach 100% pass rate by construction (Hamel's red flag), so the corpus deliberately includes **15 adversarial/boundary prompts** alongside 15 happy-path prompts. Goal: discover wrong-skill triggers and no-skill-when-one-should triggers, not rubber-stamp the v1.9.0 trim.

For each prompt, the auditor:

1. Reads the user prompt cold (no chain context).
2. Reads each of the 15 skill descriptions independently, asking "does this description's 'trigger when X' / 'use when Y' / 'Make sure to use this skill whenever Z' language match this prompt?"
3. Records the skill that matched most strongly (or `[no-skill]` if nothing should trigger).
4. Compares against the expected trigger labeled in the corpus.
5. Notes ambiguity, near-misses, and false positives.

Precision per skill = (true-positives) / (true-positives + false-positives). Recall per skill = (true-positives) / (true-positives + false-negatives). Any skill with precision or recall < 0.8 is flagged for v1.11.0 description-tuning follow-up.

## Files

- `corpus.md` — 34 prompts in three sections (15 happy-path + 15 v1.10.0 adversarial + 4 v1.11.0 new Cat-3), each tagged with expected trigger
- `audit-report-2026-05-13.md` — the v1.10.0 baseline audit: 27/30 (90%), 4 skills flagged for v1.11.0 tuning
- `audit-report-2026-05-14.md` — the v1.11.0 re-audit after tuning: 34/34 (100%), 0 skills flagged

## Running

```bash
# Inspect the corpus
cat tests/dogfood/13-trigger-precision/corpus.md

# Read the latest audit report
cat tests/dogfood/13-trigger-precision/audit-report-2026-05-14.md
```

The audit itself is a human-graded manual exercise — there is no automated script (per Hamel's anti-eval-driven-development thesis, automating trigger precision before observing failure modes is premature). Future re-audits append a new dated audit-report file; the corpus may be re-curated per the revisit triggers in the v1.10.0 plan.

## Cadence

One-time for v1.10.0. Revisit triggers (from [`plans/0010-context-engineering-alignment-v1.10.0`](../../../docs/agents/plans/0010-context-engineering-alignment-v1.10.0.md) § Revisit triggers):

- If 5+ new skills land between v1.10.0 and a future release, the corpus needs re-curation
- If 6 months pass since the last audit
- If a postmortem in `docs/agents/postmortems/` names a description-trigger collision as the failure category
