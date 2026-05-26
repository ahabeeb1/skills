---
name: verify-output
description: Anti-slop pass on a staged code diff. Use when tdd-loop reaches GREEN before commit, when user types "verify this code", "check this diff for slop", "review before commit", or via /verify-output. Do not use for pre-implementation design review or style/security checks.
disable-model-invocation: true
---

# Verify Output

<!-- Inspired by oh-my-claudecode's ai-slop-cleaner + ultraqa skills. -->

Post-generation anti-slop pass. Runs between `tdd-loop` GREEN (tests passing) and the commit. Scans the staged diff against the seven heuristics in [`references/slop-heuristics.md`](references/slop-heuristics.md) and returns a 4-status verdict.

This is the post-implementation review pass. It is NOT a refactor pass (that's [`deep-modules`](../deep-modules/SKILL.md), invoked earlier at the `tdd-loop` refactor step). It is NOT a linter (that's the project's static analysis). It is NOT a security review. Its scope is narrow: detect slop, surface it, and let the user decide whether to ship.

## When to use this skill

**Trigger on:**

- `tdd-loop` reaches GREEN (all tests passing) and is about to commit
- The user says "verify this", "check this for slop", "review before commit", or "deslop this"
- A long agent run produces a large diff and the user wants a sanity check before merging
- The user explicitly invokes `/verify-output`

**Do NOT trigger on:**

- Refactor concerns (use [`deep-modules`](../deep-modules/SKILL.md))
- Code style or formatting (the project's linter / formatter)
- Security review (a dedicated security pass)
- Pre-implementation review (that's [`socratic-grill`](../socratic-grill/SKILL.md))

## Core workflow

### Pre-flight — Environment check

Before Phase 1, verify `docs/agents/SYSTEM_CONTEXT.md` exists. If missing, halt with:

> **SETUP REQUIRED:** `docs/agents/SYSTEM_CONTEXT.md` missing. Run `/groundwork` or `/research` first.

**Staleness check:** Before reading SYSTEM_CONTEXT.md, run the staleness-check protocol per [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md). This skill is a READER — only `prior-art-research` Phase 0 writes SYSTEM_CONTEXT.md.

### Phase 1 — Read the staged diff

Run:

```bash
git diff --staged
```

If the staged diff is empty, halt with `STATUS: NEEDS_CONTEXT — nothing staged. Stage the changes you want to verify, then re-run.`

If the staged diff is enormous (>2,000 lines), halt with `STATUS: NEEDS_CONTEXT — staged diff is too large for one verify pass (N lines). Split into smaller commits or invoke with --large-ok.`

### Phase 2 — Parse mode

Default mode is **ANNOTATE**. Check for the explicit `--gate` arg (in slash-command invocation or skill invocation args). If `--gate` is present, switch to **GATE** mode.

| Mode | Moderate slop (H1-H6) | Severe slop (H7) |
|---|---|---|
| **ANNOTATE** (default) | `DONE_WITH_CONCERNS` (warns, does not block) | `BLOCKED` |
| **GATE** (`--gate`) | `BLOCKED` | `BLOCKED` |

### Phase 3 — Scan against the 7 heuristics

Read [`references/slop-heuristics.md`](references/slop-heuristics.md) and apply each heuristic to the staged diff:

- **H1** — Feature creep beyond task scope
- **H2** — Error handling for impossible scenarios
- **H3** — Unjustified comments
- **H4** — Backwards-compatibility hacks for unshipped code
- **H5** — Repeated boilerplate suggesting a missed abstraction (rule of 3+)
- **H6** — Defensive validation past trusted boundaries
- **H7** — Severe slop (half-finished impl / unreachable code / declared-and-unused)

For each hit, capture:

- Heuristic ID and short label
- File path and line number(s)
- One-sentence rationale
- Suggested resolution (delete the line, extract the helper, justify the comment, etc.)

For each potential hit that's ambiguous (could be legitimate per the counter-examples in the heuristics doc): mark it as `NEEDS_CONTEXT` rather than guessing.

### Phase 4 — Determine status

| Conditions | Status |
|---|---|
| No hits | `DONE` |
| Only ambiguous hits (no clear slop, can't decide) | `NEEDS_CONTEXT` |
| Moderate hits only (H1-H6), ANNOTATE mode | `DONE_WITH_CONCERNS` |
| Moderate hits only (H1-H6), GATE mode | `BLOCKED` |
| Any severe hit (H7), ANY mode | `BLOCKED` |

### Phase 5 — Output

Use this exact format:

```
STATUS: <DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT>

<If DONE>
No slop detected in <N> changed files. OK to commit.

<If DONE_WITH_CONCERNS or BLOCKED>
Concerns (M total):
  [H<N>] <path>:<line> — <one-sentence rationale>. Suggested: <resolution>.
  [H<N>] <path>:<line> — ...

<If BLOCKED, append>
Commit blocked. Resolve the listed concerns above (or invoke with --override <ticket-ref> to commit anyway, recording the override in the commit message).

<If NEEDS_CONTEXT>
Ambiguous case(s):
  [H<N>] <path>:<line> — <what's ambiguous>. Need: <one specific question>.

Returning control to caller. Resolve the questions above and re-run.
```

### Phase 6 — Hand off

```
HANDOFF: commit ready — verify-output passed (DONE or DONE_WITH_CONCERNS in ANNOTATE).
  Next: commit the staged changes per tdd-loop Phase 6.
HANDOFF: resolve concerns — verify-output BLOCKED.
  Next: fix the listed concerns or invoke --override <ref> to proceed.
HANDOFF: context needed — verify-output NEEDS_CONTEXT.
  Next: surface the ambiguous case(s) to the user and re-run.
```

## Integration with tdd-loop

`tdd-loop`'s refactor-and-review phase invokes `verify-output` between the two-stage review (spec compliance + code quality) and the commit step. The slot is:

```
[tdd-loop GREEN] → two-stage review → verify-output → commit
                                       ↑
                                    this skill
```

If `verify-output` returns `BLOCKED`, `tdd-loop` halts the commit and surfaces the concerns to the user. The user resolves (typically by editing and re-staging) and `tdd-loop` re-runs `verify-output` until it returns `DONE` or `DONE_WITH_CONCERNS`.

`tdd-loop` does NOT automatically invoke `--gate` mode. Projects that want GATE-mode verification configure it explicitly in their setup.

## The `--override` escape hatch

Severe slop occasionally has a legitimate reason: a stub committed intentionally with a follow-up ticket, an unused parameter required by a callback signature. `--override <ref>` lets the commit proceed but records the override in the commit message:

```
<commit message>

verify-output: --override TICKET-123 (intentional stub: <reason>)
```

The override is auditable in `git log`. Reviewers can search `git log --grep="verify-output: --override"` to find every overridden case.

The override is NOT a way to silence false positives — those should produce a `NEEDS_CONTEXT` from the skill and an update to `references/slop-heuristics.md` if the heuristic is misfiring systematically.

## Anti-patterns this skill guards against

- **Treating ANNOTATE as a rubber stamp.** `DONE_WITH_CONCERNS` is a warning, not a success. Read the concerns; decide deliberately.
- **Auto-applying suggested resolutions.** Resolutions are suggestions. Some are wrong for the specific context. The user / agent must choose, not blindly apply.
- **Running verify-output before refactor.** The slop heuristics target post-refactor code. Running pre-refactor produces noise (real refactor needs surface as fake slop).
- **Using verify-output for security or correctness.** It's a slop detector. A diff can be slop-free and still wrong / insecure.
- **Hand-tuning heuristics per-diff.** If a heuristic systematically misfires, fix `references/slop-heuristics.md` once. Don't patch around it per-commit.

## 4-status return contract

This skill's return contract matches the parallel-dev dispatch contract:

| Status | Meaning | Caller action |
|---|---|---|
| `DONE` | Clean diff, zero concerns | Proceed to commit |
| `DONE_WITH_CONCERNS` | Slop found but not blocking (ANNOTATE mode, H1-H6 only) | Read concerns, commit or fix |
| `BLOCKED` | Severe slop (H7), OR moderate slop in GATE mode | Fix concerns, or invoke --override |
| `NEEDS_CONTEXT` | Ambiguous case can't be decided without user input | Answer the question, re-run |

## See also

- [`tdd-loop`](../tdd-loop/SKILL.md) — primary caller; invokes verify-output between GREEN and commit
- [`deep-modules`](../deep-modules/SKILL.md) — adjacent; fires at the refactor step (earlier in tdd-loop), targets interface shape rather than code shape
- [`references/slop-heuristics.md`](references/slop-heuristics.md) — the 7 heuristics this skill applies
- [`docs/agents/postmortems/`](../../docs/agents/postmortems/) — when verify-output keeps missing a failure class, postmortems are the canonical place to document the new category and propose a rule for the next release. Static pre-commit check (this skill) and post-incident error analysis (postmortems) are complementary loops, not peers.
- `CLAUDE.md` at repo root — canonical source for H1-H4
