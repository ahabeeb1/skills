# 12b — Clean control

**Tests:** verify-output does NOT produce false positives on legitimately-clean code.

**Expected status (ANNOTATE mode):** `DONE`.
**Expected status (GATE mode):** `DONE`.
**Expected concerns:** zero.

## Planted diff

```diff
diff --git a/src/tax.ts b/src/tax.ts
new file mode 100644
--- /dev/null
+++ b/src/tax.ts
@@ -0,0 +1,12 @@
+export type Jurisdiction = "US" | "CA" | "GB";
+
+const RATES: Record<Jurisdiction, number> = {
+  US: 0.22,
+  CA: 0.26,
+  GB: 0.20,
+};
+
+export function computeTax(income: number, jurisdiction: Jurisdiction): number {
+  return income * RATES[jurisdiction];
+}
diff --git a/src/tax.test.ts b/src/tax.test.ts
new file mode 100644
--- /dev/null
+++ b/src/tax.test.ts
@@ -0,0 +1,13 @@
+import { computeTax } from "./tax";
+
+test("US rate", () => {
+  expect(computeTax(100, "US")).toBe(22);
+});
+
+test("CA rate", () => {
+  expect(computeTax(100, "CA")).toBe(26);
+});
+
+test("GB rate", () => {
+  expect(computeTax(100, "GB")).toBe(20);
+});
```

## What this fixture is testing

This is a deliberately-clean diff:

- **No unjustified comments** (H3) — the code is self-explanatory; no comments needed and none present.
- **No defensive validation past trusted boundaries** (H6) — `jurisdiction: Jurisdiction` is a literal-type union; TypeScript guarantees the value is valid, no runtime guard needed.
- **No feature creep** (H1) — exactly what tax computation requires, nothing extra.
- **No backward-compat shims** (H4) — file is new; no aliases.
- **No repeated boilerplate** (H5) — the three test cases look similar but they're testing parallel cases (one per jurisdiction); test code intentionally repeats structure for independent-readability. This is the H5 counter-example.
- **No half-finished impl / dead code / declared-and-unused** (H7) — `RATES` is used by `computeTax`; `computeTax` is used by tests; no stubs.

## Pass criteria

- Returns `STATUS: DONE`.
- Output explicitly says "No slop detected in N changed files. OK to commit." (or equivalent).
- Zero concerns listed.

## Fail criteria

- Returns any status other than `DONE`.
- Surfaces any concern at all — every concern on this fixture is a false positive.

## Particularly important: H5 false-positive check

The three test cases (`US rate`, `CA rate`, `GB rate`) look very similar. A naïve H5 implementation would flag them as repeated boilerplate. The slop-heuristics doc's H5 counter-example explicitly excludes parallel test cases from the rule of three. This fixture exercises that exclusion.

If verify-output flags the three tests, the H5 implementation has drifted from the counter-example. Tighten the rule.
