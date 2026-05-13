# SYSTEM_CONTEXT.md staleness-check protocol

Canonical protocol for verifying that the environment-binding cache at `docs/agents/SYSTEM_CONTEXT.md` is fresh before any habeebs-skill consumes it. Shared by every chain skill that reads SYSTEM_CONTEXT.md.

Established by [ADR-0001](../adrs/0001-environment-binding-via-system-context.md) (load-bearing protocol) and [ADR-0005](../adrs/0005-lifecycle-split-glossary-and-system-context.md) (single-writer invariant). Lifted out of `prior-art-research` Phase 0 into this shared reference by [ADR-0009](../adrs/0009-docs-agents-references-convention.md) so all consumers invoke the same check.

## When this runs

Every habeebs-skill that reads `docs/agents/SYSTEM_CONTEXT.md` MUST run this check first. As of v1.9.0, that's 10 skills:

- `prior-art-research` — Phase 0 (writer; also reads)
- `setup-habeebs-skill` — Phase 7 (invokes prior-art-research Phase 0 inline)
- `draft-spec`, `socratic-grill`, `decision-record`, `write-plan` — Pre-flight environment check
- `agent-factors-check`, `parallel-dev`, `tdd-loop` — Pre-flight environment check
- `using-habeebs-skill` — read on auto-load to surface chain state

## The protocol

1. **Check file existence.** Does `docs/agents/SYSTEM_CONTEXT.md` exist?

2. **If it exists, run the freshness check.** Compare the file's mtime against the manifests tracked by SYSTEM_CONTEXT.md's `**Tracked manifests:**` block. Default tracked manifests:

   ```
   .claude-plugin/plugin.json
   .claude-plugin/marketplace.json
   README.md
   CHANGELOG.md
   CLAUDE.md
   skills/*/SKILL.md
   ```

   Command:

   ```bash
   git log --since "<file_mtime>" -- <manifest_paths>
   ```

   Interpret the output:

   - **Empty output** → no manifest changed since the file was written. Cache is fresh. **Load it; proceed.**
   - **Non-empty output** → manifests changed. Cache is stale. **Emit the staleness banner** and proceed per the consuming skill's policy (most halt with `Refresh? (Y/n)`; `prior-art-research` Phase 0 may refresh inline).

   **Staleness banner format:**

   ```
   ⚠ SYSTEM_CONTEXT.md is stale (X changed since YYYY-MM-DD). Refresh? (Y/n)
   ```

   Replace `X` with the count of changed manifests, `YYYY-MM-DD` with the file mtime as date.

3. **Never overwrite silently.** Only `prior-art-research` Phase 0 writes SYSTEM_CONTEXT.md (ADR-0005 single-writer invariant). Other skills MUST NOT modify the file even on staleness — they emit the banner and halt or proceed-with-warning per their own policy.

## Failure-mode fallbacks

Per the v1.9.0 grill (item 10), the protocol must degrade gracefully when its primitives fail. Never halt the chain on a tooling failure that isn't user-actionable.

### Case A: `git log --since` returns non-zero or empty unexpectedly

Causes: shallow clone (git history missing for the manifest paths), non-git context (the chain is running outside a git repo), missing manifest paths (the repo doesn't have all the tracked manifests yet — e.g., a fresh setup).

Behavior:

- Emit one advisory line: `⚠ Could not verify SYSTEM_CONTEXT.md freshness (git history unavailable). Proceeding — context may be stale.`
- Load the file as-is.
- Continue with the consuming skill's Phase 1.
- Do NOT halt the chain.

### Case B: `docs/agents/SYSTEM_CONTEXT.md` does not exist

Causes: first-ever chain run on a new repo; the file was deleted; the chain is running before `setup-habeebs-skill` Phase 7 has executed.

Behavior:

- Emit one advisory line: `⚠ docs/agents/SYSTEM_CONTEXT.md not found. Proceeding with empty cache.`
- Continue with an empty cache (the consuming skill's Phase 1 absorbs full responsibility for context capture).
- Do NOT halt the chain.

**Exception:** `prior-art-research` Phase 0 SHOULD write the file fresh from probe results on Case B (this is the canonical creation path per ADR-0001). Other consumers MUST NOT write; they only read or proceed empty.

### Case C: File exists but is malformed (parse error)

Causes: hand-edited frontmatter, partial write that left a half-flushed file.

Behavior:

- Emit one advisory line: `⚠ docs/agents/SYSTEM_CONTEXT.md is malformed at <line/section>. Proceeding without parsing.`
- Continue with an empty cache.
- Surface the malformation to the user at the end of the skill's output so they can repair.

## Why this lives in `docs/agents/references/`

[ADR-0009](../adrs/0009-docs-agents-references-convention.md) establishes the directory convention: helpers consumed by 3+ skills live under `docs/agents/references/`. This protocol is consumed by 10 skills, so it qualifies cleanly. Skill-specific helpers continue to live under `skills/<name>/references/`.

## See also

- [ADR-0001 — Make SYSTEM_CONTEXT.md the load-bearing environment-binding protocol](../adrs/0001-environment-binding-via-system-context.md)
- [ADR-0005 — Lifecycle-split GLOSSARY and SYSTEM_CONTEXT](../adrs/0005-lifecycle-split-glossary-and-system-context.md)
- [ADR-0009 — `docs/agents/references/` directory convention](../adrs/0009-docs-agents-references-convention.md)
- `skills/prior-art-research/SKILL.md` Phase 0 — the canonical writer of SYSTEM_CONTEXT.md (this protocol covers the read side)
