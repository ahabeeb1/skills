# 12c — Severe slop

**Tests:** H7 (severe slop: half-finished implementation + declared-and-unused).

**Expected status (ANNOTATE mode):** `BLOCKED`.
**Expected status (GATE mode):** `BLOCKED`.
**Expected concerns:** ≥2, with at least one H7 hit.

## Planted diff

```diff
diff --git a/src/payment.ts b/src/payment.ts
new file mode 100644
--- /dev/null
+++ b/src/payment.ts
@@ -0,0 +1,29 @@
+import { Stripe } from "stripe";
+import { Logger } from "./logger";
+import { sleep } from "./time";
+
+export interface ChargeInput {
+  amount: number;
+  currency: string;
+  customerId: string;
+  description: string;
+}
+
+export class PaymentService {
+  constructor(private stripe: Stripe, private logger: Logger) {}
+
+  async charge(input: ChargeInput): Promise<{ ok: boolean }> {
+    // TODO: validate amount > 0
+    if (input.amount <= 0) {
+      // implement me
+    }
+    const result = await this.stripe.charges.create({
+      amount: input.amount,
+      currency: input.currency,
+      customer: input.customerId,
+    });
+    return { ok: true };
+    this.logger.info("charge succeeded");
+  }
+}
```

## What this fixture is testing

The diff has **three** independent severe-slop hits, any one of which should return `BLOCKED`:

1. **[H7-stub]** `src/payment.ts:16-18` — `if (input.amount <= 0) { // implement me }` — half-finished implementation. The TODO + `implement me` comment confirms the stub is shipped intentionally as production code, which silently accepts zero-or-negative-amount charges as success. **This alone is BLOCKED-level severity.**
2. **[H7-unreachable]** `src/payment.ts:25` — `this.logger.info(...)` after `return { ok: true }` on line 24 is unreachable. The function returns; the log never fires.
3. **[H7-unused]** `src/payment.ts:3` — `import { sleep } from "./time"` is declared but `sleep` is never used in the file. Declared-and-unused import.

Plus one moderate-slop hit (should be surfaced even though BLOCKED is already determined by H7):

4. **[H3]** `src/payment.ts:25` — `// charge succeeded` log message would be a moderate H3 hit, except the line is already unreachable per #2; the concern is subsumed.

## Pass criteria

- Returns `STATUS: BLOCKED` in BOTH modes (ANNOTATE and GATE).
- Surfaces all 3 H7 hits.
- Output specifies that the commit is blocked and references the `--override` escape hatch.

## Fail criteria

- Returns any status other than `BLOCKED`.
- Misses any of the 3 H7 hits (a half-finished impl that the skill fails to catch is the worst-case failure mode).
- Returns `DONE_WITH_CONCERNS` (treating severe slop as moderate is a violation of the ANNOTATE/GATE separation).

## The `--override` smoke test

Append a second invocation: `verify-output --override TICKET-456` on the same fixture. Expected behavior:

- Status: `DONE_WITH_CONCERNS` (the override-aware status — concerns still surface but the commit is not blocked).
- Output includes: `verify-output: --override TICKET-456` in the commit message guidance.
- The override line is `git log --grep="verify-output: --override"`-discoverable after commit.

This validates the escape hatch documented in `skills/verify-output/SKILL.md` § "The `--override` escape hatch."
