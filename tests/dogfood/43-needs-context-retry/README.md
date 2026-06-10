# Dogfood 43 — NEEDS_CONTEXT bounded multi-retry

Verifies spec slice #3 of `loop-harness`: ADR-0004 Part 1 is amended in place to widen the NEEDS_CONTEXT re-dispatch bound from 1 to 2 — each re-dispatch requires materially changed input (the dispatcher judges; it composed the original input and can diff it), unchanged input escalates immediately as `BLOCKED` — and parallel-dev's return-contract wording matches.

| File | Type | Asserts |
|---|---|---|
| `check-needs-context-retry.sh` | Executable (bash) | ADR-0004 states the up-to-2 bound; materially-changed-input rule with the dispatcher as judge; immediate BLOCKED escalation on unchanged input; dated 2026-06-10 amendment line citing the loop-harness decision; parallel-dev return contract matches on bound + escalation; no stale re-dispatch-once wording survives |
| `43a-unchanged-input-escalates.md` | LLM behavior | Simulated NEEDS_CONTEXT return whose input cannot be materially changed → immediate BLOCKED escalation, no second dispatch, siblings preserved |

Run the executable half: `bash tests/dogfood/43-needs-context-retry/check-needs-context-retry.sh`
