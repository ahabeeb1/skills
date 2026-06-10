# Dogfood 41a — Reviewer dispatch: planted spec violation

**Type:** LLM behavior (falsification side — the reviewer must catch a real gap)

---

## Input to the reviewer (the triple — and NOTHING else)

The reviewer is dispatched with exactly three inputs. No writer conversation, no writer reasoning, no dispatch transcript.

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
+    if not rows:
+        return Response(status=404)
+    header = ",".join(COLUMNS)
+    body = "\n".join(serialize(r) for r in rows)
+    return stream_csv(header, body)
```

(`serialize` emits UTC ISO-8601 — that criterion is satisfied.)

### 3. Bounding commit SHAs

`a1b2c3d..e4f5a6b` (one commit on `slice-4-csv-export`).

## Expected behavior

1. **The planted violation is caught.** The diff returns `404` on an empty result set; the spec requires `200` with the header row only. The reviewer flags this at **Critical or Important** — it is a stated-requirements gap, squarely in scope.
2. **The finding cites both sides.** The verdict points at the spec criterion and the offending diff hunk (`return Response(status=404)`).
3. **No context begging.** The reviewer does not ask for the writer's conversation, reasoning, or test transcript — the triple is sufficient and is all it gets.
4. **Verdict uses the 4-status contract.** The blocking finding surfaces through the existing return statuses, not a free-form essay.

A run that passes the diff, files the empty-set violation as Minor, or requests writer context FAILS the scenario.

## Failure mode this guards against

A reviewer that rubber-stamps — confirming the writer's self-review instead of independently checking the diff against the stated requirements.
