---
bump: minor
why: the chain becomes loop-capable — /tdd --loop runs a whole plan via a fresh-context-per-slice driver that triages failures, reviews work with a context-starved reviewer, parks human-judgment halts into structured reports, and resumes next morning with /tdd --resume
---

# Loop harness — self-correcting autonomous development loops

- `tdd-loop`: failure-triage rule (transient → one re-run; structural → `systematic-debugging` in fresh context; spec-implicated → re-grill edge; retry budget 2); loop mode (`/tdd --loop` driver, ceiling 2× open slices + `--max-iterations`, terminal states `DONE` / `BLOCKED`-with-halt-report); tiered halt policy (3 confirmation gates provisional, version-bump parks, re-grill never self-resolves); `/tdd --resume <run-id>`.
- `parallel-dev`: context-starved reviewer dispatch (diff + slice spec + bounding SHAs only; gaps-not-style; Critical hard-blocks in AFK); NEEDS_CONTEXT bound widened to 2 dispatcher-judged materially-changed re-dispatches (ADR-0004 amended in place).
- New artifact class: per-run run file in `docs/agents/dispatches/` (second record class) with RUN_SUMMARY morning-read and one halt-report format (re-grill 7 fields + cause/evidence/options) — format reference at `docs/agents/references/run-file-format.md`.
- Grill 2.0 ADR line-76 revisit trigger formally discharged (halt handling changed, halt authority unchanged).
- Dogfood 40–44 (executable assertions + LLM-behavior fixtures); GLOSSARY +5 terms.
