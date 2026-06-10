# Dogfood 44 — Loop mode: the outer-loop driver + tiered halt policy

Verifies spec slice #5 of `loop-harness`: `/tdd --loop` promotes Phase 0.5 to an iteration driver — inspect → dispatch fresh → verify → update run file → next — with exactly two terminal states and a tiered halt policy that parks decision gates and proceeds provisionally on the three confirmation gates.

| File | Type | Asserts |
|---|---|---|
| `check-outer-loop.sh` | Executable (bash) | `/tdd --loop` + driver algorithm; fresh context per slice; ceiling default 2× open slices + `--max-iterations` + recorded in frontmatter; two terminal states + RUN_SUMMARY at run end; park-vs-provisional table with the three provisional gates and version-bump parking; re-grill never self-resolves + `scope_classification` governs continuation; `/tdd --resume` with session-identity-first guard; failure-triage referenced not restated; Phase 0.5 NEEDS_CONTEXT row carries the ADR-0004 2-bound materially-changed rule |
| `44a-two-slice-loop-to-done.md` | LLM behavior | Two-slice plan → fresh dispatch per slice → run file updated each iteration → DONE within ceiling → RUN_SUMMARY |
| `44b-planted-ambiguity-parks.md` | LLM behavior | Spec-implicated failure on slice 2 of 3 → slice-local park with 10-field halt report → siblings complete → RUN_SUMMARY queues the halt and names `/tdd --resume <run-id>` |

Run the executable half: `bash tests/dogfood/44-outer-loop/check-outer-loop.sh`
