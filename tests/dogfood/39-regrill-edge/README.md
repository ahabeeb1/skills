# Dogfood 39 — The re-grill edge

Verifies spec slice #3 of `grill-2.0-alignment`: when implementation reveals spec ambiguity mid-slice, tdd-loop halts through a first-class edge and a scoped grill round resolves it — forward, in fresh context, on the record.

| File | Type | Asserts |
|---|---|---|
| `check-regrill-edge.sh` | Executable (bash) | re-grill rides BLOCKED's suggested_action; 7 payload fields; halt block with two exits; Phase 6 routing; scoped round with fresh context; three-condition blast-radius boundary; dated back-linked `-regrill` record; domain-touch rule |
| `39a-mid-slice-ambiguity.md` | LLM behavior | Simulated ambiguous criterion → halt → payload → scoped round → minor exit → resume |

Run the executable half: `bash tests/dogfood/39-regrill-edge/check-regrill-edge.sh`
