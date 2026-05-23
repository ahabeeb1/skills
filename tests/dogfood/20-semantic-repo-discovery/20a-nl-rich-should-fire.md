# Dogfood 20a — NL-rich SHOULD FIRE

**Type:** Positive
**Planted condition:** Feature is NL-shaped — no recognized technology terms, no quoted CLI/API idiom, >6 words.
**Expected fire-decision:** **FIRE** (test (c) trips; tests (a) and (b) also pass-the-skip-test, but only one needs to trip)

---

## Input to `prior-art-research`

**Feature (Phase 1 message 1):**

> I want to build a local AI assistant that remembers what I've been working on across my screen activity, so I can pick up where I left off.

**Phase 1 context (gap-fill answers):**

- Stack: not yet decided ([unknown])
- Scale: single user, local-only
- Constraints: must run offline; macOS preferred
- Existing: greenfield
- Priorities: correctness, operational simplicity

**No steering anchors provided. Tier auto-detected:** Balanced (2 sub-problems expected, 2 [unknown]s, 1 hard constraint).

## Expected fire-decision trace (Phase 4 working notes)

```
fire-decision: FIRE
  test (a): pass-skip — no recognized library/framework name (no react/django/postgres/...)
  test (b): pass-skip — no quoted CLI/API idiom
  test (c): TRIPPED — 23 words (>6)
```

Note: tests (a) and (b) also trip (no tech, no quoted idiom), but only ONE needs to trip; the fire-decision logs them all to make calibration auditable.

## Expected loop output (Phase 4 working notes table)

After Steps 1-5 run with the expanded queries (e.g., `screen activity memory assistant`, `local first AI memory`, `screenshot index personal knowledge base`, `desktop recall agent`, `passive observation work resumption`), candidates like:

```
Repo                       | Score | Why it matches the NL intent
microsoft/recall (or equiv) | 6     | OS-level recall; matches "screen activity memory"
rem (jasonjmcghee)          | 7     | macOS open-source Rewind alt; matches "remembers what I've been working on"; ARCHITECTURE.md present
screenpipe                  | 6     | screen+audio passive index; high activity; matches "pick up where I left off"
```

(Exact repos depend on real-time corpus state; the scoring discipline is what's tested.)

## Pass / fail

- **Pass:** Phase 4 working notes contain a `fire-decision: FIRE` line citing at least one tripped test. The loop's Step 5 table is emitted with at least 3 candidates scored. At least 2 candidates score ≥5 and enter Phase 5 deep-fetch.
- **Fail (false-skip — load-bearing):** `fire-decision: SKIP` emitted, or no fire-decision logged at all. The technique should fire on this scenario; failing to do so means the agent surfaces noise/tutorials instead of reference implementations. This is the **correctness cost** the asymmetric-failure analysis identifies in ADR-0017.
- **Fail (no decision log):** Loop fires but the working notes don't include the trace block. Without the log, OQ1's deferred-with-trigger revisit has no audit base.

## Why this scenario

This is the canonical case the technique was built for. The feature description has no precise technology vocabulary the corpus can match on directly; keyword search would return Rewind-product marketing, ML tutorials, and "best AI assistant 2025" SEO articles — not the reference implementations the chain needs. The semantic-discovery loop bridges the vocabulary mismatch (per RepoRift, cited in ADR-0017).

If 20a passes and 20b passes, the three-test fire-rule's positive arm is calibrated. If 20a passes but 20b fails (false-fire), the fire-rule biases too aggressively and needs tightening per ADR-0017's revisit triggers.
