# Triage Labels — Canonical Vocabulary

The five labels habeebs-skills use. Customize the strings to match your team's existing convention.

| Canonical role | Default string | What it means |
|---|---|---|
| Research needed | `needs-research` | Open question; route to `prior-art-research` |
| Grill needed | `needs-grill` | Ambiguous decisions; route to `socratic-grill` |
| AFK ready | `afk-ready` | Fully spec'd, agent-implementable, no human required |
| Human needed | `needs-human` | HITL slice — agent must pause and ask |
| Done | `done` | Completed |

## Customization examples

If your team already uses different label strings, map them here:

```
needs-research  →  research
needs-grill     →  question
afk-ready       →  ready
needs-human     →  blocked
done            →  closed
```

`vertical-slice` will use the mapped strings when publishing.

## Optional additional labels

You can also configure these without affecting core skill behavior:

- Priority labels: `p0`, `p1`, `p2`
- Type labels: `bug`, `feature`, `chore`
- Area labels: `frontend`, `backend`, `infra`

These are added as needed and not required by any skill.
