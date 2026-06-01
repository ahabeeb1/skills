# Doc-sync procedure

Expanded procedure for Phase 2 of the `release` skill — the doc-sync audit that runs before the CHANGELOG is written. The goal: ensure every shipped feature has traceable documentation before the tag goes out.

## What doc-sync covers

Doc-sync is NOT a full docs review. It is a **coverage check** — a diff-driven audit of what was shipped vs. what is documented. It runs against the branch diff, not the whole repo.

For every file changed on this branch (`git diff --name-only main...HEAD`), check the appropriate doc surface:

| Changed artifact | Doc surface to check |
|---|---|
| `skills/<name>/SKILL.md` (new skill) | `commands/<name>.md` exists; `## See also` cross-references callers; `## Origins` present if idea-ported |
| `skills/<name>/SKILL.md` (modified skill) | If contract changed (output template, handoff, phase added): ADR exists or is proposed |
| `docs/agents/adrs/<n>-<slug>.md` (new ADR) | Referenced from at least one skill's `## See also`; added to `docs/agents/adrs/README.md` index |
| `docs/agents/adrs/<n>-<slug>.md` (Status → Superseded) | Forward markdown link to the superseding record present; for a PARTIAL supersession, both records name the surviving half (see Supersession-link integrity below) |
| `hooks/<name>.sh` (modified hook) | ADR for the hook's scope (ADR-0003 or amendment) updated; dogfood scenario updated |
| `commands/<name>.md` (new command) | Corresponding `skills/<name>/SKILL.md` exists |
| `docs/agents/plans/<slug>.md` (new plan) | Referenced from the corresponding spec |
| `tests/dogfood/<N>-<slug>/` (new suite) | README.md present; scenario files numbered and cross-reference the skill/ADR under test |

## Severity levels

| Severity | Definition | Action |
|---|---|---|
| **WARN** | A shipped feature lacks a required doc surface (e.g., a new skill has no command file) | Surface to user; should be fixed before the release commit or noted as a follow-up PATCH |
| **INFO** | A doc surface exists but is thin or missing a cross-reference | Surface to user; can follow up in a patch; does not block the release |

Do not block the release on `INFO` findings. Do block (or surface as `WARN`) any missing required surface.

## Supersession-link integrity

When an ADR's Status flips to `Superseded` on this branch, doc-sync asserts the supersession record is navigable and self-describing. A Superseded ADR without a forward link strands a reader on a stale decision; a partial supersession without a surviving-half statement leaves the corpus ambiguous about what is still binding.

The dogfood scenario is the mechanism (it runs every PR); doc-sync references it as the release-time gate so a human observes the result before tagging:

```bash
bash tests/dogfood/36-supersession-link-integrity/check-supersession-integrity.sh
```

The scenario scans `docs/agents/adrs/*.md` for every record whose Status line names a Superseded state and enforces:

- **Forward link.** The Superseded record carries a forward markdown link (`](./<file>.md)`) to the superseding record.
- **Surviving half (partial supersession only).** When the Status text names a "half" / "partial" / "part", the Superseded record names which half survives (in force / retained / unchanged), and the superseding record re-states the same half as retained.

Exit 0 = the gate passes (a corpus with no Superseded ADR passes cleanly — the check is near-free when no supersession is present). Exit nonzero = halt the release, add the missing forward link or surviving-half statement, and re-run.

## CHANGELOG sell-test

For each item in the draft CHANGELOG entry, apply this test:

> "Can a reader who hasn't seen the PR understand (a) what changed and (b) why it matters?"

Concrete failure modes:
- "Updated `SKILL.md`" — fails both (a) and (b)
- "Added Phase 3 to `release`" — passes (a), fails (b)
- "Added Phase 3 (doc-sync audit) to `release` — ensures every shipped feature has traceable documentation before the tag goes out" — passes both

The **Why** line in each sub-item is the sell-test in practice. A Why line that says "Why: added per ADR-0015" fails the sell-test. A Why line that says "Why: the release-tag-push was blocked by the commit-block hook on every release run; this carve-out eliminates the recurring pain without widening the block predicate" passes it.

## Running the audit

```bash
# Step 1: get the diff list
git diff --name-only main...HEAD

# Step 2: for each new/modified file, check the doc table above
# Step 3: list findings by severity
# Step 4: apply the sell-test to each draft CHANGELOG item
```

No tooling required — this is a read-and-reason pass, not a linter.

## What doc-sync does NOT cover

- Full prose quality review of existing docs (that's `verify-output`'s territory for code, and manual review for prose)
- API or interface documentation for runtime code (habeebs-skill is markdown-only; there is no runtime API)
- Third-party documentation or external link freshness
