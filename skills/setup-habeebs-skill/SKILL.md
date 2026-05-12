---
name: setup-habeebs-skill
description: One-time per-repo bootstrap. Configures the issue tracker (GitHub / Linear / local markdown), the triage label vocabulary, and the domain doc layout (CONTEXT.md + ADR directory) that the other habeebs-skills consume. Writes an "## Agent skills" block to AGENTS.md and/or CLAUDE.md at the repo root so future habeebs-skill invocations know how this repo is configured. Make sure to use this skill before first use of vertical-slice, draft-spec, decision-record, deep-modules, or any skill that publishes issues or reads/writes domain docs. Also use when those skills appear to be missing context about the issue tracker, triage labels, or domain docs. Do NOT use to reconfigure already-configured repos (just edit the relevant files), to set up Claude Code itself (that's an install task), or for global config across multiple repos.
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

> Press Enter (or say `y` / `accept`) to take the canonical 5 as-is.

Wait for answer. Write `docs/agents/triage-labels.md` mapping the canonical 5 to the user's chosen strings.

### Phase 4 — Section C: Domain doc layout

Present:

> **What's the domain doc layout?**
>
> Two files the methodology depends on:
>
> - **`CONTEXT.md`** — your domain glossary. Names of concepts in your problem space (`User`, `Order`, `Invoice`, `Document`, `BOL`). `deep-modules` reads this to use the right vocabulary in proposals.
> - **`adrs/` directory** — where decision records live. `decision-record` writes here; `prior-art-research` reads here as Tier 0 internal precedent.
>
> Default location is `docs/agents/`. Customize if your team has another convention (`docs/architecture/`, `adr/`, `.adr/`).

> Press Enter (or say `y` / `accept`) to take the `docs/agents/` default.

Wait for answer. Create the directory if needed.

### Phase 5 — Write the three docs

Write or update:

1. **`docs/agents/issue-tracker.md`** — from the corresponding `issue-tracker-*.md` reference template, customized
2. **`docs/agents/triage-labels.md`** — from `triage-labels.md` reference template, with the user's mappings
3. **`docs/agents/CONTEXT.md`** — from `domain.md` reference template (skeleton — user fills in concepts later)
4. **`docs/agents/adrs/README.md`** — index file for ADRs (empty list initially)

For "other" issue trackers, write `docs/agents/issue-tracker.md` from scratch using the user's description.

### Phase 6 — Add the `## Agent skills` block

Append (or create) `AGENTS.md` and `CLAUDE.md` at the repo root with this block:

```markdown
## Agent skills

This repo is configured for habeebs-skill v1.0+. The methodology files are:

- **Issue tracker:** `docs/agents/issue-tracker.md`
- **Triage labels:** `docs/agents/triage-labels.md`
- **Domain glossary:** `docs/agents/CONTEXT.md`
- **ADRs:** `docs/agents/adrs/` (see `README.md` for index)

When invoking habeebs-skills in this repo, read these files first. They define how `vertical-slice` publishes issues, what labels to use, what vocabulary to apply, and where decision records live.
```

If `AGENTS.md` / `CLAUDE.md` already exist with the block, update its contents rather than duplicating.

### Phase 7 — Confirm

Tell the user the setup is complete. List the files written. Say which skills will now read from these files:

```
Setup complete. Files written:
  - docs/agents/issue-tracker.md
  - docs/agents/triage-labels.md
  - docs/agents/CONTEXT.md
  - docs/agents/adrs/README.md
  - AGENTS.md (## Agent skills block)
  - CLAUDE.md (## Agent skills block)

Skills that will now read from these files:
  - vertical-slice (publishes to your issue tracker with your label vocab)
  - draft-spec (uses CONTEXT.md vocabulary)
  - decision-record (writes ADRs to docs/agents/adrs/)
  - deep-modules (reads CONTEXT.md + existing ADRs)
  - prior-art-research (treats existing ADRs as Tier 0 internal precedent)
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
- `references/domain.md` — CONTEXT.md skeleton template
- `vertical-slice` — primary consumer (publishes to the configured tracker)
- `decision-record` — writes to the configured ADR directory
- `deep-modules` — reads from CONTEXT.md and ADR directory
