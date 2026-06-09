# Ambiguity Axes — The 8 Dimensions

When grilling a decision, pick the 2-4 axes most relevant to it. Don't drill all 8 unless the decision is genuinely high-impact across the board (e.g., the core data model).

## 1. Performance

- What's the latency budget for this operation? p50, p95, p99?
- What's the throughput target? Sustained vs burst?
- Where does the budget bind first? (CPU, memory, I/O, network, lock contention)
- What happens at 10x load? At 100x?
- What's the cost per operation? Per request? Per stored byte?
- Is there a slow path you're tolerating? When does it become unacceptable?

## 2. Failure modes

- What can fail? List the specific points (network, dependency, disk, retry exhaustion, bad input).
- What does the user see when it fails? Error message, retry, silent fallback?
- How does the system recover? Automatic vs manual?
- What does the operator see? (Logs, alerts, dashboards)
- What's the blast radius? Single user, single tenant, whole system?
- Is failure detectable? How quickly?

## 3. Scale

- What changes at 10x users / requests / data?
- What changes at 100x? 1000x?
- Where does the architecture stop working? Be specific (e.g., "single Postgres becomes the bottleneck at ~10k concurrent connections").
- What's the migration path past each breakpoint? How long does each take?
- Is the design "scale up" (bigger machines) or "scale out" (more machines)?

## 4. Concurrency

- What if two of these run at the same time? Three? N?
- Is there shared state? Where? How is access mediated (lock, transaction, queue, CRDT)?
- What's the ordering guarantee? (FIFO, causal, eventual, none)
- What happens during partial failure mid-operation? (Half-applied state?)
- Is the operation idempotent? Can it be retried safely?

## 5. Migration

- How do you get from the current state to the target state?
- Can it be done with zero downtime? If not, what's the window?
- How do you roll back if it goes wrong?
- Is there a backfill? How long does it take? How is it verified?
- What's the cutover plan? (Big bang, gradual, dual-write, shadow traffic)
- What signals tell you the migration is safe to proceed / unsafe?

## 6. Reversibility

- If this decision turns out wrong, how do you undo it?
- How expensive is the undo? (Hours of refactor, weeks of customer migration, irreversible data shape)
- Is this a one-way door? If yes, is the rigor of the decision matched to the irreversibility?
- What's the blast radius of being wrong? (Hidden tech debt, customer-visible breakage, data loss)
- Is there a smaller experiment that would reduce uncertainty before committing?

## 7. Observability

- How do you know it's working in production?
- What metrics matter? (Counter, gauge, histogram, ratio)
- What logs do you need? Structured fields, not just messages.
- What traces? (For distributed systems)
- What alerts? On what conditions? Paged vs ticket?
- Dashboards: what's the one chart that tells you "this is healthy"?
- How do you debug a failure case post-hoc? What data do you need persisted?

## 8. Slice shape

Applies to the spec's slice table as one item — the work breakdown is a decision like any other, and it is the execution unit everything downstream consumes. Keep this a conversation: probe and challenge, never score.

- Is each slice vertical — does it cut through every integration layer and demonstrate end-to-end value, or is it a layer ("build the database schema") dressed as a slice?
- Which slice would you deprioritize or throw away first? If the answer is "none," has the decomposition actually separated value from filler?
- Are the slices roughly equal-sized? What makes the biggest one safe to attempt in a single session?
- Is each HITL gate earning its place — what concrete mid-slice input does the human provide? If you can't name it, why isn't the slice AFK?
- What justifies the ordering — does slice N actually unblock slice N+1, or is the dependency speculative?
- Which slices could run concurrently, and what shared file or state makes the rest sequential?

---

## Cross-cutting probes (use sparingly)

These cut across the axes and are useful when the decision feels fundamental:

- **The "what would have to be true" probe** — "What would have to be true about your scale / customers / team for the OPPOSITE choice to be right?" Forces explicit identification of the conditions sustaining the current choice.
- **The "5 whys" probe** — When the user gives a justification, ask "why?" four more times. Often reveals the actual reasoning is one of: "everyone does it," "we did it before," "I read it in a blog," or genuine insight.
- **The "boring backup" probe** — "What's the boring, obviously-correct version of this decision?" Sometimes reveals the chosen approach is more novel than needed.

## Grilling priority

When time is limited, grill in this order:

1. **One-way doors first.** Decisions that are expensive to reverse get the most rigor.
2. **High blast-radius next.** Decisions that affect many parts of the system.
3. **Highest-uncertainty last.** Decisions where you genuinely don't know yet are okay to grill briefly and explicitly defer with a revisit trigger.
