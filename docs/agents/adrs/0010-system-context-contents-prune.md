# ADR-0010: Prune `SYSTEM_CONTEXT.md` contents to non-re-derivable cross-session state

**Status:** Accepted
**Date:** 2026-05-13 (Proposed and Accepted same day — v1.10.0 release slice, no implementation gap)
**Deciders:** Modie (Habeeb)

## Context

ADR-0001 (2026-05-11) made `docs/agents/SYSTEM_CONTEXT.md` load-bearing and established it as the single environment-binding cache that downstream chain skills read on every invocation. ADR-0005 (2026-05-13) split the methodology vocabulary into `GLOSSARY.md` and locked `prior-art-research` Phase 0 as the single writer. As shipped through v1.9.0, the file carries: **Stack**, **Persistence**, **Deployment shape**, **External services**, **Scale envelope**, **Methodology / agent setup**, **Recent hot files**, **Notable absences**, **Open / unknown**, **Project mode**, **Active steering**, and **Last reconciliation outcome**.

The 2026-05-13 ecosystem-alignment audit (prior-art-research run, in-conversation; see `docs/agents/research/v1.10.0-context-engineering-alignment-research.md` once Slice 0 archives it) pulled Anthropic's [Claude Code best-practices](https://code.claude.com/docs/en/best-practices) doc as the canonical source on what to scaffold vs. what to let the model derive. Anthropic's explicit ❌ Exclude list names *"Anything Claude can figure out by reading code"* and *"File-by-file descriptions of the codebase."* Anthropic's prune test is *"Would removing this cause Claude to make mistakes?"* — if no, drop it.

Applying Anthropic's test to the 12 SYSTEM_CONTEXT.md sections revealed five sections that are trivially re-derivable on every fresh chain invocation: Stack (Claude greps `package.json` / equivalent manifests instantly), Persistence (Claude reads `docker-compose.yml` / `.env` / config), Deployment shape (Claude reads CI config + `Dockerfile`), External services (Claude reads imports + env), Recent hot files (`git log --since` runs in milliseconds). Persisting these is duplicative ceremony.

The audit also pulled Google's [ADK Workflow Agents](https://adk.dev/agents/workflow-agents/) doc as positive validation that deterministic workflow scaffolding (the shape `prior-art-research` Phase 0 imposes) is a first-class agent type, not legacy fallback — meaning **the existence of SYSTEM_CONTEXT.md is correct; only its contents need pruning.** This is the key distinction: don't eliminate the Phase 0 file (Google validates the workflow shape); audit what the file carries against Anthropic's prune test (which governs contents).

The decision is needed NOW because v1.10.0 is the natural release boundary, and the audit surfaced the gap concretely. Implementing the prune in any release after v1.10.0 means an additional release that carries the bloat for no reason.

## Decision

We will narrow `SYSTEM_CONTEXT.md`'s contract from "environment-binding cache" to "non-re-derivable cross-session state." Specifically:

- **Sections retained** (cannot be re-derived from `package.json` / git / imports on a fresh invocation):
  1. **Scale envelope** — users / MAU / DAU / RPS / data volume / skill count. Not in code. Anthropic prune test: removing this would let Claude make mistakes about feature scope.
  2. **Methodology / agent setup** — habeebs-skill version + setup status, issue tracker, triage labels, latest ADR pointer, GLOSSARY status. Anchored to user-answered config from `setup-habeebs-skill` (per ADR-0005); not in code.
  3. **Active steering** — opt-in anchors that persist across chain runs (per `steering-hints.md`). Cross-session state by construction.
  4. **Last reconciliation outcome** — dated reconciliation summaries from previous `prior-art-research` runs. Cross-session memory; the value of the file across invocations.
  5. **Notable absences** — explicit "we know this isn't here yet" gaps (no CI, no telemetry, etc.). Inferential prior knowledge; would require synthesizing across files on every read to reconstruct.
  6. **Project mode** — brownfield / greenfield / replacement. Derivable but expensive (requires reading history); Anthropic's prune test admits cached one-line judgments that take >2 reads to re-derive.

- **Sections dropped** (re-derivable from current repo state on fresh invocation; persisting them violates Anthropic's ❌ Exclude rule):
  1. **Stack** (Runtime / Framework / Test runner / Type-checker) — re-derivable from manifests.
  2. **Persistence** (Datastore / ORM / Migrations location) — re-derivable from config + imports.
  3. **Deployment shape** (Topology / Regions / CI/CD / Observability) — re-derivable from CI config + `Dockerfile` + monitoring config.
  4. **External services** — re-derivable from imports + env.
  5. **Recent hot files** — re-derivable via `git log --since`.
  6. **Open / unknown** — folded into Notable absences (collapse two adjacent inferential sections into one).

- **Tracked manifests block dropped.** This was scaffolding for the prior contract; no chain skill reads it as load-bearing.

- **Migration: patch release v1.10.0, auto-migrate via Phase 0 single-writer.** ADR-0005's single-writer invariant means the next time `prior-art-research` Phase 0 runs on a downstream repo, it regenerates the file with the new template — no migration skill needed, no user action required. Existing files with dropped sections continue to work (chain skills tolerate missing sections; they have always been tolerant readers per ADR-0001 § "silent-default on missing fields"). No breaking change to any reader; the change is additive-by-deletion of fields readers never depended on.

- **Template updated at `skills/prior-art-research/references/system-context-template.md`** with the new schema and an explicit "DO NOT persist" comment block listing the dropped sections + the Anthropic prune test as rationale.

- **ADR-0001 status line gets a forward link**: "partially amended by ADR-0010 (scope narrowing — re-derivable structural facts dropped from § Decision)."

The decision narrows ADR-0001's contract without invalidating it. The load-bearing rule (Phase 0 writes; chain skills read), the single-writer invariant (ADR-0005), and the staleness-check protocol (ADR-0009 reference convention) all remain in force. Only what the file *carries* shrinks.

## Consequences

### Positive

- Aligns with Anthropic's canonical Claude Code best-practices: contents pass the prune test ("removing this would cause Claude mistakes" — yes for retained sections, no for dropped).
- Phase 0 writes get shorter (~40% size reduction at typical file size), reducing Phase 0 token spend on every chain invocation.
- Subagent dispatches that inject the SYSTEM_CONTEXT preamble (per ADR-0004 Part 3) carry less ballast — directly reduces parallel-dev token cost at 5× concurrent dispatches.
- The file's *purpose* sharpens — "cross-session state and non-derivable judgments" is one job, not seven.
- ADR-0010 itself becomes Tier 0 prior art for any future research that asks "what should our shared-memory file carry?"

### Negative / Accepted trade-offs

- **Phase 1 first-message context shrinks.** Phase 1 of `prior-art-research` used to skip "what's your stack?" because Phase 0 cached it. Now Claude reads `package.json` (or equivalent) on the fly during Phase 1. Accepted: one cheap read instead of one persisted field. The savings on Phase 0 + subagent preambles dominate.
- **Inferential context (Notable absences) is harder to re-derive than declarative sections.** Risk: future Phase 0 writers under-populate Notable absences because it requires cross-cutting synthesis. Accepted: the section was already inference-heavy under ADR-0001; this ADR doesn't change its character, only its prominence.
- **Downstream repos that depended on dropped sections in their own readers will see them disappear.** Accepted: no chain skill in this repo depends on dropped sections (audited 2026-05-13 grep pass during Slice 1); external consumers are responsible for their own readers per ADR-0002 (habeebs-skill is standalone).

### Operational impact

- **No user action required for existing repos** — Phase 0 single-writer regenerates the file on next research invocation per ADR-0005.
- **`skills/prior-art-research/references/system-context-template.md` is the canonical template** for what a fresh SYSTEM_CONTEXT.md should look like under this ADR.
- **`tests/dogfood/14-system-context-schema/`** (added in Slice 1) asserts the template produces only the 6 retained sections + Project mode flag.
- **v1.10.0 manifest bump is MINOR.** Additive-by-deletion of fields no reader depended on; same rule habeebs-skill has applied through v1.9.x.

## Alternatives considered

### Status quo — keep all 12 sections

Carry the existing contract forward unchanged. **Rejected** because Anthropic's prune test points the other way and the 2026-05-13 audit was driven by a real concern from the user about ceremony-on-top-of-default-behavior. Status quo means Phase 0 keeps persisting fields Claude derives from manifests on every fresh read — directly the *over-specified CLAUDE.md* anti-pattern Anthropic warns against, generalized to SYSTEM_CONTEXT.md.

### v2.0.0 with an explicit `migrate-v1-to-v2` skill

Treat the prune as a breaking change to ADR-0001's contract; force a major version bump and ship a one-shot migration skill that rewrites existing SYSTEM_CONTEXT.md files on downstream repos. **Rejected** because the change is additive-by-deletion — chain skills already tolerate missing sections (silent-default behavior baked into ADR-0001 § Decision bullet 4 from inception). No reader breaks; no migration is needed. v2.0.0 ceremony would buy nothing and would block v1.10.0 on documentation pause for migration runbook.

### Eliminate Phase 0 entirely; let Claude re-derive everything on every invocation

Take Anthropic's prune test to its limit: drop SYSTEM_CONTEXT.md altogether and trust Claude's default codebase-exploration behavior. **Rejected** because Google ADK's Workflow Agents framework explicitly validates deterministic scaffolding shape (the audit's key counter-evidence), AND because cross-session state (Last reconciliation outcome, Active steering) is genuinely not re-derivable from a fresh repo read — these are inferential summaries from past chain runs that have value across invocations. Eliminating Phase 0 throws out the cross-session memory baby with the re-derivable-stack bathwater.

### Move retained sections to a different file (e.g., `RECONCILIATION_LOG.md`)

Split SYSTEM_CONTEXT.md by content type: a short cross-session-memory file + an environment-binding file (or eliminate the latter per the previous alternative). **Rejected** because two files create discovery and maintenance overhead for negligible benefit at this scale (6 sections, ~3KB target). The audit's principle is *what* the file carries, not *whether* the file is split. ADR-0005 already governs splits-by-writer-lifecycle and didn't surface a new lifecycle axis here.

## Revisit triggers

This ADR should be reopened if any of:

- A chain skill ever needs a dropped section to do its job correctly → re-evaluate which section deserves to come back, and amend ADR-0010 explicitly rather than silently re-adding fields to the template.
- Anthropic publishes Skills 2.0 v2 (or new Claude Code best-practices guidance) that changes the prune-test framing → revisit which sections still pass the test under the new guidance.
- The repo grows past ~50 skills or ~30 ADRs and `Latest ADR pointer` in Methodology / agent setup becomes load-bearing for navigation → consider promoting it to its own section or splitting Methodology into setup-config vs. methodology-pointers.
- Two or more downstream repos report regressions traceable to a dropped section → re-evaluate; the dropped sections may have been load-bearing in patterns not surfaced in this repo's audit.
- SYSTEM_CONTEXT.md size grows past ~5KB even with the prune applied → the Notable absences / Last reconciliation outcome sections likely accumulated too many dated entries; introduce a retention policy.

## References

- Research: prior-art-research run 2026-05-13 (in-conversation; archived as [`docs/agents/research/v1.10.0-context-engineering-alignment-research.md`](../research/v1.10.0-context-engineering-alignment-research.md) in Slice 0)
- Spec: [`specs/v1.10.0-context-engineering-alignment`](../specs/v1.10.0-context-engineering-alignment.md) § Slice 1
- Grill: [`specs/v1.10.0-context-engineering-alignment-grill`](../specs/v1.10.0-context-engineering-alignment-grill.md) § Item Q2
- Sister ADRs:
  - [`adrs/0001-environment-binding-via-system-context`](./0001-environment-binding-via-system-context.md) — narrowed in scope by this ADR; load-bearing rule and single-writer invariant remain in force
  - [`adrs/0002-habeebs-skill-standalone`](./0002-habeebs-skill-standalone.md) — preserved (markdown-only contents)
  - [`adrs/0005-lifecycle-split-glossary-and-system-context`](./0005-lifecycle-split-glossary-and-system-context.md) — single-writer invariant unchanged; this ADR governs *what* the writer writes
- External sources:
  - [Anthropic — Best practices for Claude Code](https://code.claude.com/docs/en/best-practices) — canonical source for the prune test (*"Would removing this cause Claude to make mistakes?"*) and the ❌ Exclude list (*"Anything Claude can figure out by reading code"*)
  - [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — supports cross-session continuity scaffolding (validation for retained sections)
  - [Google ADK — Workflow Agents](https://adk.dev/agents/workflow-agents/) — positive validation that the *shape* (Phase 0 file) is a first-class agent pattern; only contents need pruning
  - [LangChain — Context Engineering for Agents](https://blog.langchain.com/context-engineering-for-agents/) — Write/Select moves justify cross-session memory retention

---

## Changelog

- 2026-05-13 — Initial ADR, Accepted same day (v1.10.0 release; implementation lands in Slice 1).
