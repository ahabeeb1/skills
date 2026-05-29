# TODO: the commit-block hook slows dev and needs a proper fix

**Status:** the in-repo fix landed in v1.23.0 (`hooks/preventing-commits-to-default.sh`, commit 349bba4) but the INSTALLED plugin copy is still the pre-fix version, so it keeps false-positive-blocking worktree commits during development. Track removing this whole workaround once the release ships and the plugin updates.

## What's wrong with the hook today

`hooks/preventing-commits-to-default.sh` (PreToolUse[Bash]) resolves the current branch from the **hook process's own cwd** — the harness launch dir, which sits on the default branch (`main`). When work happens in a sibling git worktree on a feature branch (the workflow `using-worktrees` *mandates*), the hook misreads the branch as `main` and **blocks every commit**, even though the commit lands on a feature branch. This wall cost real dev time during v1.23.0.

Worse, the documented escapes don't compose:
- The inline `HABEEBS_DISABLE_HOOKS=1 git commit ...` prefix is **inert** — the hook fires before the command's shell runs, so it reads the var from its own (harness) process env, not the inline prefix.
- The `.claude/habeebs-allowed-branches` allowlist matches the branch the hook *resolves* (`main`), so it can't whitelist the feature branch.
- Setting the var at the PowerShell session level works, but the auto-mode classifier flags it as a guardrail bypass.

## The fix (already written in this repo, ships in v1.23.0)

`hooks/preventing-commits-to-default.sh` now:
1. Resolves the branch from the directory the commit/push will ACTUALLY run in — parses a leading `cd <path> &&` or a `git -C <path>` out of the command and resolves via `git -C <dir>`; falls back to the hook's own cwd otherwise.
2. Detects commit/push even with global flags between `git` and the verb (`git -C <path> commit`, `git -c k=v commit`) — the old literal-substring match missed these (a latent false negative).

Regression test: `tests/hooks/commit_block_worktree_test.sh` (8 cases).

## Action items (do after v1.23.0 ships)

- [ ] Reinstall/update the habeebs-skill plugin so the RUNNING hook is the fixed one. Then worktree commits pass with no escape.
- [ ] Remove the `HABEEBS_DISABLE_HOOKS=1 git commit/push` allow-rules from `.claude/settings.local.json` (added 2026-05-29 as a stopgap) — no longer needed once the fixed hook runs.
- [ ] Remove any `HABEEBS_DISABLE_HOOKS` entry from the settings `env` block if one was added as a stopgap.
- [ ] Consider: should the hook read the PreToolUse payload's `cwd` field as an additional signal? (It currently doesn't read the payload cwd at all.)
- [ ] Delete this TODO file once the above are done.

The broader lesson: a guardrail that fires on the team's own sanctioned workflow (worktree-per-feature) is worse than no guardrail — it trains people to disable hooks wholesale. The fix makes the hook precise instead of blunt.
