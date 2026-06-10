# Dogfood 42 — The run-file format

Verifies spec slice #4 of `loop-harness`: the loop's only new artifact class — a per-run tracked markdown file in `docs/agents/dispatches/` (second record class beside dispatch JSON, per the grill's Item 5 user override) carrying frontmatter bookkeeping, one halt-report format for all four halt classes, and the RUN_SUMMARY morning read.

| File | Type | Asserts |
|---|---|---|
| `check-run-file-format.sh` | Executable (bash) | location/naming + template cross-link; all frontmatter fields incl. effective-ceiling rule and status enum; #15047 session-identity resume guard; skill-written-only writer rule (ADR-0003); advisory-only + ADR-0019-shaped staleness contract; 7+3 halt-report fields, one format per halt class; RUN_SUMMARY shape naming `/tdd --resume <run-id>`; format-freeze rule |
| `fixture-run-file.md` | Conforming fixture | A realistic 3-slice run: slices 1 and 3 DONE, slice 2 parked on a re-grill halt; full halt report + RUN_SUMMARY |

Run the executable half: `bash tests/dogfood/42-run-file-format/check-run-file-format.sh`
