# Dogfood 09b — Category critic: missing hooks (the v1.6.0 reproducer)

**Type:** Positive (planted gap)
**Planted missing category:** `Hooks / event handlers`

This scenario is the **literal reproducer of the v1.6.0 audit miss** that drove this entire v1.7.0 work. The chain ran `prior-art-research` on whether to expand habeebs-skill's value surface and the planner decomposed only into "skill catalog" + "chain composition" — missing `hooks / event handlers` entirely. The miss was caught only by a manual audit. Phase 2.5 must catch it automatically.

---

## Input to `prior-art-research`

**Feature (Phase 1 message 1):**

> Should we expand habeebs-skill's value surface beyond just chain skills? Looking at how other plugin-style methodology systems (Superpowers, mattpocock/skills) extend value, and whether any of those patterns apply here.

**Phase 1 context (gap-fill answers):**

- Stack: Markdown + JSON plugin (Claude Code plugin format), no runtime
- Scale: Personal-use + small OSS distribution; install count untracked
- Constraints: ADR-0001 (portability), ADR-0002 (no runtime substrate) — but the user has signaled the no-substrate constraint is reconsiderable if a strong pattern fits
- Existing: brownfield, habeebs-skill v1.5.4 is shipped; chain is 6 skills + 6 primitives
- Priorities: value-per-line-of-spec, low maintenance burden

**Optional steering:**

- Anchor: "look at how Superpowers extends beyond core skills"
- Avoid: "anything that requires a runtime daemon"

## Synthetic Phase 2 decomposition (input to Phase 2.5 critic)

The planner produced (this is the *actual* v1.6.0 audit miss reproduced):

```json
{
  "proposed_decomposition": [
    "Skill catalog expansion (which new skills are worth adding)",
    "Chain composition patterns (how to chain skills meaningfully)",
    "Reference implementations to study (Superpowers + mattpocock/skills)"
  ]
}
```

## Expected critic output

**Verdict:** ADDITIONS PROPOSED

**Categories the critic MUST surface:**

- `Hooks / event handlers` — Superpowers ships 5+ hooks (SessionStart, PreToolUse, etc.) and mattpocock/skills has `git-guardrails-claude-code` with a PreToolUse hook. The decomposition explicitly cites these as reference implementations but does not name "hooks" as an architectural category to research. This is the bleeding gap.
- `Subagent / multi-agent orchestration` — Superpowers has `subagent-driven-development` and `dispatching-parallel-agents`; the decomposition would miss these too. Should appear unless the critic is overly conservative.

**Acceptable additional surfacings (bonus, not required):**

- `Trigger surfaces` — slash commands, plugin commands, /<skill> invocation
- `Runtime substrate / state machines` — if the critic interprets the avoid-anchor strictly, this might be marked Non-applicable; either is fine

**Forbidden (would indicate hallucination):**

- `Security / auth / permissions` — N/A for a personal-use methodology plugin
- `Migration / backfill / rollback` — N/A for new feature additions
- `Pre-fetch / context loading` — N/A at this layer
- `Concurrency / ordering / idempotency` — N/A for chain skills

## Pass / fail

- **Pass:** `Hooks / event handlers` appears in `Proposed additions` with rationale citing the Superpowers / mattpocock precedent. Bonus pass if `Subagent / multi-agent orchestration` also surfaces.
- **Fail (false negative — the catastrophic case):** critic returns APPROVED. This is the literal v1.6.0 failure mode reproduced; if the critic ships and still fails this scenario, the slice failed.
- **Fail (false positive):** critic surfaces 2+ forbidden categories above.

## Why this scenario

This is the **load-bearing test** for v1.7.0. The whole purpose of Phase 2.5 is to catch this specific miss. If 09b fails, no other dogfood matters — the slice fundamentally didn't solve the user's problem. Modie reads this output verbatim before slice #8 squash-merge.
