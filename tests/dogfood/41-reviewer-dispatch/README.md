# Dogfood 41 — Context-starved reviewer dispatch

Verifies spec slice #2 of `loop-harness`: after a write-task subagent returns `DONE`, a context-starved reviewer in fresh context checks the work against the slice spec — input is exactly the triple (diff + slice spec + bounding SHAs), findings are gaps-not-style and severity-gated, and a PASS is evidence that never replaces deterministic assertions.

| File | Type | Asserts |
|---|---|---|
| `check-reviewer-dispatch.sh` | Executable (bash) | fires after write-task DONE in fresh context; read-task-class with no merge surface; input triple; explicit context starvation; gaps-not-style constraints; Critical/Important block vs Minor recorded; one fix round then BLOCKED via same-finding-twice; PASS-as-evidence positioning; parallel-dev defines / both skills consume; AFK Critical hard-block |
| `41a-planted-violation.md` | LLM behavior | Reviewer given ONLY the triple catches a planted spec violation at Critical/Important |
| `41b-clean-control.md` | LLM behavior | Reviewer passes sound work with zero hallucinated Critical findings |

The two LLM-behavior fixtures are deliberately both-sided (grill item 10): 41a falsifies a rubber-stamp reviewer, 41b falsifies a noise-generating one.

Run the executable half: `bash tests/dogfood/41-reviewer-dispatch/check-reviewer-dispatch.sh`
