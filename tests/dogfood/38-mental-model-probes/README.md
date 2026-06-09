# Dogfood 38 — Mental-model probes

Verifies spec slice #2 of `grill-2.0-alignment`: grill Phase 1 verifies the human's expectations — not just the artifact's clarity — via three indirect probes, tier-scaled in count, with answers landing in a section two downstream skills consume.

| File | Type | Asserts |
|---|---|---|
| `check-mental-model-probes.sh` | Executable (bash) | Three probes named; Quick 1 / Balanced 2 / Deep 3 count rule; undo-cost follow-up rule; template section covers success criteria + doors + premortem; write-plan and decision-record both read it |
| `38a-balanced-two-probes.md` | LLM behavior | Balanced run asks exactly 2 probes; answers echoed into the record section |

Run the executable half: `bash tests/dogfood/38-mental-model-probes/check-mental-model-probes.sh`
