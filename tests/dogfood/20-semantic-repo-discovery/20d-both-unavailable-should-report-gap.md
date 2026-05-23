# Dogfood 20d — both-unavailable report-the-gap (rung 3)

**Type:** Degradation (rung 3 — full fallback)
**Planted condition:** Fire-rule trips (NL-rich feature), `gh` AND `WebSearch` both unavailable
**Expected behavior:** Tier 2 skipped entirely; gap noted in Phase 6 Sources; chain still produces a useful report from Tier 1 + Tier 3+

---

## Input to `prior-art-research`

Same feature as 20a / 20c (NL-rich):

> I want to build a local AI assistant that remembers what I've been working on across my screen activity, so I can pick up where I left off.

**Planted environment:** `gh --version` fails AND `WebSearch` is unavailable (simulated, e.g., by running the chain in a hermetic sandbox or with all web-tool primitives disabled).

## Expected fire-decision trace (Phase 4 working notes)

```
fire-decision: FIRE
  test (c): TRIPPED — 23 words (>6)
corpus-access: gh unavailable (rung 1 failed); WebSearch unavailable (rung 2 failed); Tier 2 SKIPPED (rung 3)
```

## Expected Phase 6 Sources section

The final report's Sources section MUST include a gap note in the form:

```
Tier 2 (GitHub repos): SKIPPED — neither `gh` CLI nor WebSearch was available in this environment. Tier 2 prior art was not consulted for this research run.
  Implication: case studies in this report draw from Tier 1 (engineering blogs) and Tier 3+ (talks/RFCs/practitioner threads) only. Tier 2 evidence is absent.
  Remediation (out of chain scope): install `gh` (https://cli.github.com) OR enable WebSearch in this environment to upgrade future runs.
```

## Pass / fail

- **Pass:** Fire-decision logged with full rung-1-2-3 failure trace; Phase 6 Sources section contains the explicit gap note; chain continues to Phase 6 and produces a synthesis from Tier 1 + Tier 3+ sources. The synthesis ACKNOWLEDGES the Tier 2 gap in its Open Questions or Caveats section.
- **Fail (hallucinated candidates):** Loop "returns" repos despite having no corpus access. This is the **most dangerous failure mode** — fabricated candidates poison the rest of the chain (draft-spec cites non-existent repos, decision-record references vapor). The decision-log MUST show the rung-3 fall-through; any candidate emission with rung-3 logged is hallucination.
- **Fail (chain halts):** Agent halts the chain entirely on unavailability instead of degrading. Phase 6 report should still be produced from Tier 1; halting wastes the Phase 0/1/2/3/2.5 work already done.
- **Fail (silent gap):** Tier 2 skipped but no gap note emitted in Sources. Downstream consumers (draft-spec, decision-record) don't know Tier 2 was absent, may over-trust the synthesis.
- **Fail (prompts user to install/enable tools):** Same as 20c — chain MUST NOT prompt user to install `gh` or enable WebSearch. Emit the remediation note in the Sources section as documentation, not as a prompt.

## Why this scenario

This is the full failure of the corpus-access primitive. The behavior under this scenario distinguishes a robust degradation ladder from a brittle one that silently fabricates or silently hangs.

The asymmetric-failure analysis in the grill record (2026-05-22) identified false-skip as a correctness cost. Hallucinated Tier 2 candidates are a **worse** correctness cost than false-skip — fabricated repos poison the entire downstream chain, while a SKIP with gap note is honest and recoverable.

ADR-0017's revisit trigger doesn't directly name this scenario, but if 20d fails in production (hallucinated candidates appear in a postmortem), that's a stronger signal than false-fire — it's a falsification of the chain's core "research grounded in real production code" promise.

Secondary purpose: this scenario also exercises the chain's ability to **continue under partial primitive availability**. Phase 4 Tier 2 is one of five tiers; the chain should produce a useful Phase 6 report even without it.
