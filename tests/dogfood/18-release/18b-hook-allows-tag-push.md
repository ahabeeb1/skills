# Dogfood 18b — hook: tag-only pushes are ALLOWED on the default branch

**Type:** Positive (hook carve-out)
**Tested:** `hooks/preventing-commits-to-default.sh` — ADR-0015 tag-push carve-out

---

## Context

Before ADR-0015, the hook matched `*"git push"*` without distinction and blocked all push commands on the default branch, including release tag-pushes. ADR-0015 narrows the block predicate to allow unambiguous tag-only push forms. This scenario verifies the carve-out works for the forms the `release` skill uses and recommends.

## Test inputs

Each row is a simulated PreToolUse `tool_input.command` value, delivered to the hook on the default branch (`main`). The hook should exit 0 (allow) for all of them.

| Command | Form | Expected exit |
|---|---|---|
| `git push origin refs/tags/v1.14.0` | Unambiguous refspec (preferred — used by `release` skill) | 0 (allow) |
| `git push origin tag v1.14.0` | Explicit `tag` keyword | 0 (allow) |
| `git push --tags` | All local tags | 0 (allow) |
| `git push origin --tags` | All local tags to named remote | 0 (allow) |

## How to simulate

Construct a JSON payload matching the Claude Code PreToolUse hook format and pipe it to the script with `current_branch = main` and `default_branch = main`:

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"git push origin refs/tags/v1.14.0"}}' \
  | bash hooks/preventing-commits-to-default.sh
echo "exit: $?"
```

Repeat for each command in the table. All should print `exit: 0` (allow) and no BLOCKED message on stderr.

## Pass / fail

- **Pass:** All four commands exit 0. No "BLOCKED by habeebs-skill" message appears on stderr for any of them.
- **Fail:** Any of the four exits 2 with a BLOCKED message — the carve-out is not matching that form. Fix the case clause in `preventing-commits-to-default.sh`.

## Why this scenario

18b is the direct test of ADR-0015's decision: tag-only pushes on the default branch are allowed. If this scenario fails, the `release` skill cannot push its tag on `main` and the recurring release-tag pain (documented in `feedback_release_tag_hook_misfire`) is not resolved. This scenario is load-bearing for the v1.14.0 release.

---

## Additional negative check (within this scenario)

The following forms should still be blocked (exit 2) — they are ambiguous or are branch pushes, not tag pushes:

| Command | Reason | Expected exit |
|---|---|---|
| `git push origin v1.14.0` | Ambiguous — could be branch or tag | 2 (block) |
| `git push origin main` | Branch push on default | 2 (block) |

These are covered more thoroughly in scenario 18c. They are listed here to document the boundary of the carve-out.
