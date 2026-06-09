# Dogfood 37 — Slice-shape ambiguity axis

Verifies spec slice #1 of `grill-2.0-alignment`: the grill interrogates the spec's slice decomposition, not just feature decisions.

| File | Type | Asserts |
|---|---|---|
| `check-slice-shape-axis.sh` | Executable (bash) | Axis 8 exists with ≥4 question-shaped probes covering vertical-ness / deprioritization / HITL / ordering; slice table is a standing Phase 1 inventory item; grill axis count is eight; no rubric language |
| `37a-planted-horizontal-slices.md` | LLM behavior (positive) | Planted horizontal decomposition + unjustified HITL gate → both surfaced |
| `37b-sound-slices-control.md` | LLM behavior (control) | Sound slice table → reviewed and passed with zero manufactured objections |

Run the executable half: `bash tests/dogfood/37-slice-shape-axis/check-slice-shape-axis.sh`
