# Dogfood 38a — Mental-model probes: Balanced tier asks exactly two

**Type:** LLM behavior (count + echo)

---

## Input to `socratic-grill`

A spec with `Tier: Balanced`, two open questions, and a slice table. The user answers all grill questions cooperatively.

## Expected grill behavior

1. Phase 1 asks exactly **two** mental-model probes (Balanced count): the premortem first, then the door-classification challenge on the spec's highest-impact decision. The concrete-example demand is reserved for Deep.
2. If the user labels the challenged decision "two-way," the grill asks exactly one follow-up — the concrete undo cost — and accepts the answer without piling on.
3. The grill record contains a **User mental model** section echoing: the success criteria implied by the premortem answer (stated in the positive), the door classification with its recorded undo cost, and the premortem risks worth tracking.

A run that asks zero probes, asks all three at Balanced, interrogates the door label beyond the single follow-up, or omits the record section FAILS the scenario.

## Failure mode this guards against

Probe ceremony drifting out of its tier budget (probe fatigue) and probe answers evaporating instead of landing where `write-plan` and `decision-record` read them.
