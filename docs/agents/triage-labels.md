# Triage Labels

The five canonical roles `habeebs-skills` use, with this repo's chosen label strings.

| Canonical role | Label string (this repo) | What it means |
|---|---|---|
| Research needed | `needs-research` | Open question; route to `prior-art-research` |
| Grill needed | `needs-grill` | Ambiguous decisions; route to `socratic-grill` |
| AFK ready | `afk-ready` | Fully spec'd, agent-implementable, no human required |
| Human needed | `needs-human` | HITL slice — agent must pause and ask |
| Done | `done` | Completed |

This repo uses the canonical defaults verbatim — no custom mapping.

## Optional additional labels

These may be added per-PR or per-slice without affecting core skill behavior:

- Release labels: `v1.6.0`, `v1.7.0`, `v1.8.0` (one per release tag)
- Area labels: `setup`, `research`, `tdd`, `parallel-dev`, `hooks` (the skill area being modified)
- Type labels: `bug`, `feature`, `chore`, `docs`

These are added as needed and not required by any habeebs-skill.

## Customization

If a fork or downstream repo needs different label strings, edit the table above. `vertical-slice` reads the right column when publishing.
