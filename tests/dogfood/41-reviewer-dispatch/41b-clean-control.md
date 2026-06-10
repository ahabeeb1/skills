# Dogfood 41b — Reviewer dispatch: clean control

**Type:** LLM behavior (control side — sound work must pass without hallucinated findings)

---

## Input to the reviewer (the triple — and NOTHING else)

Same dispatch shape as 41a: diff + slice spec + bounding SHAs, no writer context.

### 1. Slice spec

> **Slice 4 — CSV export endpoint (AFK)**
>
> **Acceptance criteria:**
> - [ ] `GET /reports/:id/export` streams the report rows as CSV.
> - [ ] Timestamps are serialized as UTC ISO-8601.
> - [ ] An export of an empty result set returns `200` with the header row only — never an error status.

### 2. Diff (bounded by the SHAs below)

```diff
+def export_report(report_id):
+    rows = fetch_rows(report_id)
+    header = ",".join(COLUMNS)
+    body = "\n".join(serialize(r) for r in rows)
+    return stream_csv(header, body)  # empty rows -> 200, header only
```

(`serialize` emits UTC ISO-8601; an empty `rows` list yields the header row and status `200`.)

### 3. Bounding commit SHAs

`a1b2c3d..f7e8d9c` (one commit on `slice-4-csv-export`).

## Expected behavior

1. **PASS, with zero hallucinated Critical/Important findings.** Every acceptance criterion is satisfied; the reviewer must not invent a blocking gap to appear diligent.
2. **Style stays out of scope.** Naming taste, formatting preference, or "I'd structure this differently" must not surface as findings at all — gaps-not-style.
3. **Minor observations are allowed but never block.** If the reviewer records a Minor note, the verdict is still PASS and progression continues.
4. **PASS lands as evidence.** The verdict is recorded in the dispatch record as evidence — it does not claim to replace the deterministic assertions.

A run that blocks sound work, escalates a style preference to Critical/Important, or hedges with a non-verdict FAILS the scenario.

## Failure mode this guards against

The judge-literature false-positive mode: a reviewer that manufactures findings on clean diffs, turning the review gate into noise that erodes trust in real Critical findings.
