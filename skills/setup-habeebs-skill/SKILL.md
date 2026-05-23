---
name: setup-habeebs-skill
description: One-time per-repo bootstrap. Configures the issue tracker (GitHub / Linear / local markdown), triage label vocabulary, and domain doc layout (GLOSSARY.md + ADR directory) that other habeebs-skills consume. Writes an "## Agent skills" block to AGENTS.md and/or CLAUDE.md so future invocations know how the repo is configured. Make sure to use this skill before first use of vertical-slice, draft-spec, decision-record, deep-modules, or any skill that publishes issues or reads/writes domain docs. Do NOT use to reconfigure already-configured repos or for global config across multiple repos.
---

# Setup habeebs-skill

Configures a single repository so the other habeebs-skills know how to behave. Run once per new repo. Inspired by mattpocock's `setup-matt-pocock-skills`.

This is a prompt-driven skill, not a deterministic script. Explore, present what you find, confirm with the user, then write.

## When to use this skill

**Trigger on:**

- First time invoking any other habeebs-skill in a repo that has no `## Agent skills` block
- The user explicitly runs `/setup-habeebs-skill`
- Another skill halts because it needs to know "where do ADRs live?" / "which issue tracker?" / "what are the triage labels?"
- The user says "set up habeebs-skill here" / "bootstrap the methodology"

**Do NOT trigger on:**

- Repos already configured (just edit the relevant files; don't re-bootstrap)
- Global / cross-repo configuration (this skill is per-repo)
- Installing the plugin itself (use `/plugin install`)

## Core workflow

This is prompt-driven. The user walks through 3 decisions, one at a time. Don't dump all 3 at once — present a section, get the answer, move to the next. Assume the user may not know what these terms mean; each section starts with a short explainer.

### Phase 1 — Look at what's there

Before asking, check:

```bash
ls AGENTS.md CLAUDE.md 2>/dev/null
ls docs/ 2>/dev/null
ls .scratch/ 2>/dev/null
```

Note what exists:
- Does AGENTS.md or CLAUDE.md exist? Is there already an `## Agent skills` section?
- Is there a `docs/` directory? Is there `docs/agents/`?
- Is there an ADR directory anywhere? (`docs/adr/`, `docs/agents/adrs/`, `docs/architecture/decisions/`)

Summarize to the user: "Here's what I found. Here's what's missing."

### Phase 2 — Section A: Issue tracker

Present:

> **What's the "issue tracker"?**
>
> Where issues live for this repo. Skills like `vertical-slice`, `draft-spec`, and `decision-record` need to know whether to run `gh issue create`, write a markdown file under `.scratch/`, talk to Linear, or follow some other workflow you describe. Pick where you actually track work for this repo.

Then the choices:

- **GitHub** (default) — uses `gh issue create` to publish slices as issues
- **Linear** — uses Linear MCP or API (if available)
- **Local markdown** — writes slice issues to `.scratch/slices/` in the repo
- **Other** — describe; I'll write a custom adapter doc

> **When the default isn't right:** if your team tracks work in Linear/Jira across multiple repos, the GitHub default fragments your backlog — pick Linear. If this repo is solo or pre-product (no shared backlog, no API tokens you want to manage), local markdown beats both.
>
> Press Enter (or say `y` / `accept`) to take the GitHub default.

Wait for answer. Read the corresponding reference file (`issue-tracker-github.md` / `issue-tracker-linear.md` / `issue-tracker-local.md`) and copy its template into `docs/agents/issue-tracker.md`, customized with the user's answer.

### Phase 3 — Section B: Triage label vocabulary

Present:

> **What are triage labels?**
>
> Tags applied to issues to indicate workflow state. The habeebs-skills use five canonical roles:
>
> - **`needs-research`** — open question; route to `prior-art-research`
> - **`needs-grill`** — has ambiguous decisions; route to `socratic-grill`
> - **`afk-ready`** — fully spec'd, agent-implementable, no human needed
> - **`needs-human`** — HITL slice; agent must pause and ask
> - **`done`** — completed
>
> What label strings does your team actually use? (Defaults: same as above. Or map to your existing vocab — e.g., if you use `🟢 in-progress` already.)
>
> **When the default isn't right:** if your team already enforces a label vocabulary via PR templates, CI checks, or org-level conventions, map only the labels that conflict — fighting an enforced vocab causes drift between what skills publish and what humans triage.
>
> Press Enter (or say `y` / `accept`) to take the canonical 5 as-is.

Wait for answer. Write `docs/agents/triage-labels.md` mapping the canonical 5 to the user's chosen strings.

### Phase 4 — Section C: Domain doc layout

Present:

> **What's the domain doc layout?**
>
> Two files the methodology depends on:
>
> - **`GLOSSARY.md`** — your domain glossary. Names of concepts in your problem space (`User`, `Order`, `Invoice`, `Document`, `BOL`). `deep-modules` reads this to use the right vocabulary in proposals.
> - **`adrs/` directory** — where decision records live. `decision-record` writes here; `prior-art-research` reads here as Tier 0 internal precedent.
>
> Default location is `docs/agents/`. Customize if your team has another convention (`docs/architecture/`, `adr/`, `.adr/`).
>
> **When the default isn't right:** if the repo already has `docs/architecture/decisions/` or `docs/adr/` populated, type that path instead — fragmenting ADRs across two directories defeats Tier 0 prior-art lookups, and a second canon is harder to retire than to never create.
>
> Press Enter (or say `y` / `accept`) to take the `docs/agents/` default.

Wait for answer. Create the directory if needed.

### Phase 5 — Write the three docs

Write or update:

1. **`docs/agents/issue-tracker.md`** — from the corresponding `issue-tracker-*.md` reference template, customized
2. **`docs/agents/triage-labels.md`** — from `triage-labels.md` reference template, with the user's mappings
3. **`docs/agents/GLOSSARY.md`** — from `domain.md` reference template (skeleton — user fills in concepts later)
4. **`docs/agents/adrs/README.md`** — index file for ADRs (empty list initially)

For "other" issue trackers, write `docs/agents/issue-tracker.md` from scratch using the user's description.

### Phase 6 — Add the `## Agent skills` block

Append (or create) `AGENTS.md` and `CLAUDE.md` at the repo root with this block:

```markdown
## Agent skills

This repo is configured for habeebs-skill v1.0+. The methodology files are:

- **Issue tracker:** `docs/agents/issue-tracker.md`
- **Triage labels:** `docs/agents/triage-labels.md`
- **Domain glossary:** `docs/agents/GLOSSARY.md`
- **ADRs:** `docs/agents/adrs/` (see `README.md` for index)

When invoking habeebs-skills in this repo, read these files first. They define how `vertical-slice` publishes issues, what labels to use, what vocabulary to apply, and where decision records live.
```

If `AGENTS.md` / `CLAUDE.md` already exist with the block, update its contents rather than duplicating.

### Phase 7 — Trigger Phase 0 reconnaissance

**Goal:** populate `docs/agents/SYSTEM_CONTEXT.md` so downstream chain skills don't halt on first invocation. ADR-0005 mandates this chain: setup is the bootstrap entry point that *invokes* Phase 0; Phase 0 is the sole *writer* (ADR-0001 single-writer invariant preserved by construction).

Invoke `prior-art-research` Phase 0 reconnaissance now. Phase 0 walks `references/recon-checklist.md`, probes every applicable manifest, and writes (or refreshes) `docs/agents/SYSTEM_CONTEXT.md`.

**Idempotency** — Phase 0's existing cache-check logic decides what to do:

- If `SYSTEM_CONTEXT.md` does not exist → Phase 0 writes it from probe results.
- If it exists and no tracked manifest has changed since its mtime → Phase 0 skips the write (cache hit).
- If it exists but manifests have changed → Phase 0 emits the staleness banner and refreshes.

Re-running `/setup` on an already-configured repo is therefore a no-op for `SYSTEM_CONTEXT.md` whenever the file is fresh.

**Forked failure handling** — Phase 0 has two distinct outcomes that look like "problems" but are different:

1. **`[unknown]` tags in the written file** (common; Phase 0 couldn't infer a field — e.g., scale envelope on a new repo). NOT a failure. Phase 0 successfully wrote `SYSTEM_CONTEXT.md` with self-documenting `[unknown]` markers. Proceed to Phase 8 and let the confirm message report the count: *"SYSTEM_CONTEXT.md written with N fields tagged `[unknown]` — review and fill in when ready."*
2. **Write failure** (rare; permission denied, disk full, sandbox blocks the write, git uninitialized). Halt-loud at end of setup with a `SETUP_INCOMPLETE` banner that names the specific error and the recovery command: *"SETUP_INCOMPLETE — Phase 7 (reconnaissance) failed: \<error\>. SYSTEM_CONTEXT.md was not written. Re-run /setup once \<cause\> is fixed, OR run /research directly to populate the file."* Existing writes from Phases 5–6 (GLOSSARY.md, issue-tracker.md, triage-labels.md, adrs/README.md, `## Agent skills` block) are preserved — they are independently valid, and re-running `/setup` is idempotent.

**Single-writer invariant** — `setup-habeebs-skill` MUST NOT write `SYSTEM_CONTEXT.md` directly. It invokes Phase 0. The reconnaissance logic lives in `prior-art-research/SKILL.md` § Phase 0 and stays the single source of truth for environment-binding writes. The canonical staleness/freshness check that Phase 0 enforces is documented at [`docs/agents/references/system-context-staleness-check.md`](../../docs/agents/references/system-context-staleness-check.md).

### Phase 8 — Confirm

Tell the user the setup is complete. List the files written. Say which skills will now read from these files:

```
Setup complete. Files written:
  - docs/agents/GLOSSARY.md
  - docs/agents/issue-tracker.md
  - docs/agents/triage-labels.md
  - docs/agents/adrs/README.md
  - docs/agents/SYSTEM_CONTEXT.md  (written by prior-art-research Phase 0)
  - AGENTS.md (## Agent skills block)
  - CLAUDE.md (## Agent skills block)

If Phase 0 tagged any fields [unknown] in SYSTEM_CONTEXT.md, count them here:
  - "N fields tagged [unknown] — review and fill in when ready."

Skills that will now read from these files:
  - vertical-slice (publishes to your issue tracker with your label vocab)
  - draft-spec (uses GLOSSARY.md vocabulary)
  - decision-record (writes ADRs to docs/agents/adrs/)
  - deep-modules (reads GLOSSARY.md + existing ADRs)
  - prior-art-research (treats existing ADRs as Tier 0 internal precedent; refreshes SYSTEM_CONTEXT.md on every /research invocation)
  - socratic-grill, write-plan, parallel-dev (read SYSTEM_CONTEXT.md as load-bearing per ADR-0001)
```

## Anti-patterns this skill guards against

- **Dumping all 3 questions at once.** Walk one at a time. Each starts with a short explainer.
- **Assuming the user knows the terms.** Don't assume. Each section explains "what is an issue tracker / triage label / domain glossary."
- **Overwriting existing config silently.** If `## Agent skills` already exists, ask before changing.
- **Skipping the look-around phase.** Always check what's there first; don't write blindly.
- **Forcing the defaults.** Defaults are reasonable but customizable. The user might already have an issue tracker convention; respect it.
- **Bootstrapping in a partially-configured repo.** If some files exist, only fill the gaps; don't rewrite working config.

## See also

- `references/issue-tracker-github.md` — GitHub Issues template
- `references/issue-tracker-linear.md` — Linear template
- `references/issue-tracker-local.md` — Local markdown template
- `references/triage-labels.md` — canonical label vocabulary
- `references/domain.md` — GLOSSARY.md skeleton template
- `vertical-slice` — primary consumer (publishes to the configured tracker)
- `decision-record` — writes to the configured ADR directory
- `deep-modules` — reads from GLOSSARY.md and ADR directory
