# Dogfood 18c — hook: branch commits and bare pushes are still BLOCKED on the default branch

**Type:** Negative (control — regression check)
**Tested:** `hooks/preventing-commits-to-default.sh` — ADR-0001 never-commit-to-default protection still intact after ADR-0015 carve-out

---

## Context

ADR-0015 narrows the hook's block predicate to allow unambiguous tag-only pushes. The carve-out must not widen the predicate for anything else. This scenario is the regression control: it verifies that `git commit` and branch-advancing `git push` commands are still blocked on the default branch, exactly as before ADR-0015.

A failing 18c means the carve-out logic has a bug — the case clause is matching commands it shouldn't. That is a blocking defect: ADR-0001's never-commit-to-default protection would be silently disabled.

## Test inputs

Each row is a simulated PreToolUse `tool_input.command` value on the default branch (`main`). The hook should exit 2 (block) for all of them, with a BLOCKED message on stderr.

| Command | Why it must be blocked | Expected exit |
|---|---|---|
| `git commit -m "fix: update README"` | Direct branch commit on default — ADR-0001 | 2 (block) |
| `git commit --amend` | Amending a commit on default — ADR-0001 | 2 (block) |
| `git push` | Bare push — advances the default branch | 2 (block) |
| `git push origin main` | Explicit branch push on default | 2 (block) |
| `git push origin v1.14.0` | Ambiguous — matches neither tag form; treated as branch | 2 (block) |
| `git push origin HEAD` | Branch HEAD push on default | 2 (block) |
| `git commit && git push origin main` | Chained commit + push — still blocked on `git commit` | 2 (block) |

## How to simulate

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"fix: update README\""}}' \
  | bash hooks/preventing-commits-to-default.sh
echo "exit: $?"
# Expected: "BLOCKED by habeebs-skill: ..." on stderr, exit: 2
```

Repeat for each command in the table.

## Pass / fail

- **Pass:** All commands exit 2 with a BLOCKED message on stderr. No command slips through.
- **Fail (regression):** Any command exits 0 (allowed) when it should be blocked. The ADR-0001 protection has been weakened by the carve-out. Fix the case clause ordering or pattern in `preventing-commits-to-default.sh`.
- **Fail (wrong message):** The hook exits 2 but with no message on stderr — the block is silent. The user gets no guidance on what to do (create a feature branch, use the disable env var).

## Why this scenario

18c is the load-bearing control for the entire ADR-0015 amendment. The carve-out is a surgical change to a security-relevant hook. A case clause that accidentally catches more than the intended tag-only forms would silently disable ADR-0001's protection for anyone running the `release` skill. Running 18c immediately after 18b — allowed forms then blocked forms — gives the full picture of the carve-out boundary.

The scenario for `git push origin v1.14.0` (ambiguous form, row 5) is especially important: the `release` skill documents that callers should use `refs/tags/` form precisely because the bare `v1.14.0` form is ambiguous. If the hook were to allow `git push origin v1.14.0`, it would have been accepting branch pushes disguised as tag pushes. The ADR-0015 decision explicitly keeps this form blocked.
