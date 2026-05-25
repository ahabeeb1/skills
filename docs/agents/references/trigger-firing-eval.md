# Trigger-firing eval — real-session transcript review

**Status:** Active from v1.19.0 (primary firing-rate signal)
**Supersedes (partially):** Dogfood 13 (`tests/dogfood/13-trigger-precision/`) is retained as a regression baseline through v1.20.0; this doc is the new primary signal per ADR-0007 § Operational impact.

The synthetic-corpus dogfood reported 34/34 (100%) trigger precision in v1.10.0 and v1.11.0 audits — yet maintainer-observed real-session behavior between v1.9.0 and v1.18.0 showed habeebs skills *not* firing on natural-language dev prompts. This is exactly Hamel Husain's "synthetic prompts approach 100% by construction" red flag ([hamel.dev/blog/posts/evals-faq/](https://hamel.dev/blog/posts/evals-faq/)). The transcript eval closes that gap by measuring firing-rate on prompts the maintainer actually types, not prompts the maintainer would write to test the auditor.

## When this eval runs

**Cadence:** the first week of each calendar quarter, OR within 7 days of any v1.X release — whichever comes sooner. The 7-days-post-release rule is the load-bearing case: it produces the comparison data that gates v1.19.0 → v1.20.0 imperative-with-pronoun follow-up.

## Source

`~/.claude/projects/<repo-slug>/sessions/*.jsonl` — Claude Code writes a JSONL transcript per session in this path. The repo-slug is the URL-encoded filesystem path of the working directory (for this repo: `C--Users-habee-Projects-skills`).

## Sample

**Last 30 sessions OR last 14 days, whichever yields more transcripts.** Pin the sample-set in a date-range header at the top of the audit report — `Sample: 2026-MM-DD through 2026-MM-DD, N sessions`. Re-runs of the same audit against the same date-range must produce identical scores (idempotency requirement per OQ-6 resolution).

If a calendar window yields fewer than 5 sessions, expand to the next interval (60 days, 90 days) until ≥5 sessions are in the sample. An audit on <5 sessions is statistically meaningless — note in the report as "under-sampled, advisory only."

## Anonymization

Redact each user prompt to keyword-level summary before recording it in the audit doc. The goal: preserve trigger-language structure (which user phrases appeared) without leaking content (project-specific names, secrets, in-progress work).

Concretely, for each prompt, record:

- **Trigger keywords present** — `"build"`, `"add"`, `"refactor"`, `"fix this"`, `"design"`, `"implement"` — and any other natural-language signal the maintainer noticed
- **Verb mood** — declarative ("I want to X"), interrogative ("how should I X"), imperative ("do X")
- **One-line task summary** — heavily paraphrased, no project nouns

Skip prompts that are pure conversation continuation ("yes", "no", "continue", "thanks"). They have no trigger signal.

## Scoring rubric

### Primary signal — firing-rate lift (the v1.19.0 success metric)

**Denominator:** all sampled sessions containing at least one of the trigger keywords `"build"`, `"add"`, `"refactor"`, `"fix this"`, `"design"`, `"implement"` in the user prompt.

**Numerator:** denominator-qualified sessions where the matched entry-point skill fired within the next 2 turns of agent response.

Entry-point mapping per ADR-0007 § C:
- `"build"`, `"add"`, `"implement"`, `"design"`, `"architect"` → `prior-art-research`
- `"fix this"`, `"this is broken"`, `"test is failing"` → `systematic-debugging`
- `"refactor"`, `"this feels off"`, `"too many small files"` → `deep-modules`
- `"audit"`, `"security review"`, `"threat model"` → `security-audit`

A skill "fires" if either (a) the agent's response invokes the Skill tool with that skill's name, or (b) the agent's response explicitly cites the skill ("running `/research`..." / "invoking `prior-art-research`...") even without a tool call.

**Threshold:** v1.19.0 ships green if the post-release ratio exceeds the pre-release baseline by **>10 percentage points**. Below 10pp, file the v1.20.0 candidate with the `You MUST use this skill when…` variant — NOT a revert to current.

### Secondary signal — per-skill recall

For each of the 4 entry-point skills, compute: (sessions where it should have fired, AND it fired) / (sessions where it should have fired). The "should have fired" judgment is per the entry-point mapping above; any borderline case is logged in the audit report's notes.

Per-skill recall <80% in 2 consecutive quarters is a description-tuning issue for that specific skill — escalate to a targeted description rewrite, not a full v1.X+1 release.

### Tertiary signal — wrong-skill fires

When a skill fired but it wasn't the right entry point (e.g., `deep-modules` fired on a "build new feature" prompt that should have routed to `prior-art-research`). Count and tag in the audit report. Three or more wrong-skill fires in the same direction (e.g., `deep-modules` over-firing on build-language) is a description-anti-trigger issue for `deep-modules`.

## Idempotency

Two auditors auditing the same sample-set (same date-range, same session list) must produce the same numerator/denominator/per-skill-recall. To enforce:

- The sample-set is pinned by the date-range header — don't expand mid-audit
- The entry-point mapping above is the only authoritative source for "should have fired" judgments
- Borderline cases get logged in the audit report's "Notes" section, not silently bucketed

If re-runs produce different scores, the rubric is under-specified — surface the disagreement and amend this doc.

## Failure response

| Signal | Threshold | Action |
|---|---|---|
| Primary lift | < 10pp post-release | File v1.X+1 candidate with `You MUST use` (imperative-with-pronoun) variant. NOT a revert. |
| Per-skill recall | < 80% for 2 consecutive quarters on the same skill | Targeted description rewrite for that skill, shipped as a patch release |
| Wrong-skill fires | 3+ in same direction in one quarter | Anti-trigger tightening on the over-firing skill |
| Per-skill recall | < 50% on any skill, 1 quarter | Halt; file urgent issue; investigate whether description anatomy is broken for that skill |

## Audit report template

Each audit produces a dated file at `docs/agents/postmortems/trigger-firing-<YYYY-MM-DD>.md` (uses the postmortem directory from ADR-0011; transcript-eval audits ARE postmortems in the chain-postmortem sense).

```markdown
# Trigger-firing eval — YYYY-MM-DD

**Sample:** YYYY-MM-DD through YYYY-MM-DD, N sessions
**Anchored to:** v1.X.Y on main (commit <sha>)
**Auditor:** <name>

## Primary signal

| Metric | Value |
|---|---|
| Denominator (trigger-keyword sessions) | N |
| Numerator (matched skill fired ≤2 turns) | M |
| Firing rate | M/N = X.X% |
| Baseline (last audit) | X.X% |
| Lift vs baseline | ±X.X pp |
| Threshold | >10 pp for v1.X+1 green |
| Verdict | GREEN / FILE-V1.X+1-CANDIDATE |

## Per-skill recall

| Skill | Sessions where it should have fired | Fired | Recall |
|---|---|---|---|
| prior-art-research | N1 | M1 | M1/N1 = X% |
| systematic-debugging | N2 | M2 | M2/N2 = X% |
| deep-modules | N3 | M3 | M3/N3 = X% |
| security-audit | N4 | M4 | M4/N4 = X% |

## Wrong-skill fires

| Prompt summary (anonymized) | Fired | Should have fired | Direction |
|---|---|---|---|

## Notes

(Borderline cases, ambiguous prompts, anything that didn't fit the rubric.)

## Verdict and follow-up

(One paragraph: green / file what / when.)
```

## Sunset for dogfood 13

Dogfood 13 (`tests/dogfood/13-trigger-precision/`) runs in parallel as a regression baseline through v1.20.0. After 2 quarters of dual-tracking, if the transcript eval consistently surfaces failures dogfood 13 misses (e.g., real wrong-skill fires the synthetic corpus didn't predict), dogfood 13 is sunset and this doc becomes the sole firing-rate signal. The sunset decision is logged in a postmortem and an ADR amendment to 0007.

## References

- ADR-0007 (amended 2026-05-24) § Operational impact — codifies this eval as the primary signal
- ADR-0011 — error-analysis-first cadence (Hamel Husain / Shreya Shankar); this eval is the chain-postmortem section's primary input
- `docs/agents/specs/v1.19.0-auto-trigger-reliability.md` Slice #6 — this doc's spec
- `docs/agents/specs/v1.19.0-auto-trigger-reliability-grill.md` OQ-1 + OQ-6 resolutions — the 10pp threshold and dual-tracking decision
- [Hamel Husain — Evals FAQ](https://hamel.dev/blog/posts/evals-faq/) — "synthetic prompts approach 100% by construction" red flag
