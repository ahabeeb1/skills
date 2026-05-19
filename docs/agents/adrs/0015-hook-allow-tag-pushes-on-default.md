# ADR-0015: Amend the commit-block hook to allow tag-only pushes on the default branch

**Status:** Accepted
**Date:** 2026-05-18
**Deciders:** Modie (via the habeebs-skill chain: prior-art-research → draft-spec → socratic-grill → decision-record)

**Amends:** ADR-0003 (habeebs-skill hooks scope).

## Context

ADR-0003's PreToolUse hook (`hooks/preventing-commits-to-default.sh`) blocks `git commit` and `git push` on the default branch, enforcing ADR-0001's never-commit-to-default rule mechanically. The hook's command matcher is `*"git commit"*|*"git push"*` — it does not distinguish *what* is being pushed.

A release tag is pushed with `git push origin <tag>` (or `git push --tags`), and release tagging happens on `main` after the feature PR has merged. So the matcher fires on every release tag-push and blocks it. This is a documented, recurring pain (`feedback_release_tag_hook_misfire` memory): the current mitigation is a chore-branch workaround the user explicitly dislikes. The decision is needed now because ADR-0014's new `release` skill (v1.14.0) automates release tagging and would hit this block on every single run.

A grill investigation (2026-05-18) confirmed the precise mechanism: it is not `git tag` (local tag creation, unmatched) but `git push origin <tag>` matching the `*"git push"*` case while `current_branch == default_branch`.

## Decision

We will refine `hooks/preventing-commits-to-default.sh` so a **tag-only push is distinguished from a branch-commit push** and allowed on the default branch. Specifically:

The following **unambiguous** tag-only push forms are permitted on the default branch:

- `git push origin refs/tags/<name>` — unambiguous refspec; **preferred form** (used by the `release` skill)
- `git push <remote> tag <name>` — explicit `tag` keyword
- `git push --tags` / `git push <remote> --tags` — all local tags

The following forms **remain blocked** on the default branch:

- `git push origin <name>` — ambiguous; git resolves this to a branch or a tag depending on what exists locally; the hook cannot safely distinguish without running `git show-ref`, so it is kept blocked. Callers should use the unambiguous `refs/tags/` form.
- `git push` (bare) — advances the branch ref
- `git commit` — unchanged

The hook stays warn/block-only, multi-harness aware, and stateless — ADR-0003's three rules are untouched; only the block predicate is narrowed. The PreToolUse hook dogfood scenario is updated to cover both the now-allowed tag-push and the still-blocked branch-commit-push.

This is correct because ADR-0001's rule is "no direct *branch commits* on the default branch." An annotated tag is an append-only pointer to an already-pushed commit; it modifies no branch. Blocking it was always an over-broad matcher, not an intended policy.

**Implementation note:** the carve-out is a `case "$command_text" in` block inserted immediately after the initial `git commit | git push` filter, before any branch-resolution logic. Its first arm declines the carve-out for any command that also contains `git commit`; the remaining arms match the three allowed tag-only patterns and exit 0. Unmatched push commands fall through to the existing default-branch block logic unchanged. A command that pushes a branch and tags in one invocation (`git push origin main --tags`) is an accepted residual — this hook is a guardrail against accidental default-branch commits, not an adversary boundary.

## Consequences

### Positive

- The `release` skill's tag-push step works on `main` with no workaround — the recurring release-tag pain is eliminated permanently.
- The hook now blocks exactly what ADR-0001 intends (branch commits), nothing more.

### Negative / Accepted trade-offs

- The matcher is slightly more complex — it must parse the push refspec, not just grep for `git push`. Mitigated by the updated dogfood scenario.
- A tag pointing at an unreviewed commit could still be pushed to the default branch — accepted: tags don't change branch state, and habeebs-skill releases are tags on already-merged commits by construction.

### Operational impact

- Ships in the v1.14.0 bundle alongside the `release` skill (ADR-0014 Slice 2).
- The chore-branch workaround in the `feedback_release_tag_hook_misfire` memory becomes obsolete once v1.14.0 ships.

## Alternatives considered

### Codify the chore-branch workaround in the `release` skill

Have `release` check out a throwaway branch before the tag-push so the hook sees a non-default branch. Rejected during socratic-grill: bakes a workaround the user already dislikes into the methodology, and leaves the hook bug in place for every manual tag-push.

### Wrap the tag-push in `HABEEBS_DISABLE_HOOKS=1`

Disable the hook for just the tag-push command. Rejected: normalizes switching the guardrail off, and trains the agent to reach for the disable flag.

### Leave the hook as-is

Accept the block and keep using the workaround. Rejected: the pain recurs every release and the new `release` skill would hit it on every run.

## Revisit triggers

This ADR should be reopened if any of:

- A tag-based attack vector emerges where a tag push to the default branch is itself harmful — then the carve-out needs re-scoping.
- The Claude Code hook API changes such that the refspec is no longer available in `tool_input.command`.
- ADR-0001's never-commit-to-default policy is itself revised.

## References

- Amends: ADR-0003 (`docs/agents/adrs/0003-hooks-scope.md`)
- Related: ADR-0001 (never-commit-to-default), ADR-0014 (the `release` skill that requires this change)
- Spec: `docs/agents/specs/v1.13.0-gstack-capability-adoption.md` — Slice 2
- Grill: `docs/agents/specs/v1.13.0-gstack-capability-adoption-grill.md` — item D2
- Hook file: `hooks/preventing-commits-to-default.sh`

---

## Changelog

- 2026-05-18 — Initial ADR, status Proposed
- 2026-05-18 — Status → Accepted; Decision block tightened to match implemented predicate: `git push origin <tagname>` (ambiguous) remains blocked; unambiguous forms (`refs/tags/`, `tag <name>`, `--tags`) are the approved carve-out. Implementation lands in v1.14.0 Slice 2.
