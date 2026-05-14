# ADR-0001: Make SYSTEM_CONTEXT.md the load-bearing environment-binding protocol

**Status:** Accepted — partially superseded by [ADR-0005](./0005-lifecycle-split-glossary-and-system-context.md) (2026-05-13); partially amended by [ADR-0006](./0006-remove-next-skills-frontmatter.md) (2026-05-13); scope-narrowed by [ADR-0010](./0010-system-context-contents-prune.md) (2026-05-13). The load-bearing rule and single-writer invariant for `SYSTEM_CONTEXT.md` (§ Decision bullets 1–4) remain in force. The undefined relationship between `CONTEXT.md` and `SYSTEM_CONTEXT.md`, and the "Notable absences" line under § Context, are superseded — see ADR-0005 § Supersedes. The implicit load-bearing assumption around `next-skills:` frontmatter — never explicitly required here but tacitly relied on by early chain documentation — is amended by ADR-0006: chain-relationship surfaces are body-level (HANDOFF / `## See also` / prose), never frontmatter. The contents the file carries are narrowed by ADR-0010: re-derivable structural facts (Stack / Persistence / Deployment shape / External services / Recent hot files) drop; non-re-derivable cross-session state (Scale envelope / Methodology / Active steering / Last reconciliation outcome / Notable absences / Project mode) retained. The contract shape from this ADR — load-bearing, single-writer, tolerant readers — is unchanged.
**Date:** 2026-05-11
**Deciders:** Modie (Habeeb)

## Context

habeebs-skill v1.4.x ships 14 skills. `prior-art-research` Phase 0 writes `docs/agents/SYSTEM_CONTEXT.md` — a markdown digest of stack, deploy, scale, external services, and (since v1.3.0) active steering. Downstream chain skills read it when available. The problem: nothing *requires* it. Skills silent-default when the file is absent, which means most users never run `setup-habeebs-skill`, which means triage labels, issue tracker, and domain glossary stay unconfigured. The file was advertised as "the chain's shared memory primitive" (per v1.1.0 CHANGELOG) but in practice was decorative.

A self-audit driven by `prior-art-research` on the question "are our skills well-integrated with environments, working for greenfield + brownfield, and not redundant?" surfaced the gap and forced a decision on what the environment-binding protocol actually is. The audit also revealed that the chain already detects brownfield-ness imperatively from artifacts (existing ADRs, code, tests) — making a declarative project-mode field a duplicate source of truth that decays. The decision is needed NOW because v1.4.0 just shipped two new skills (`write-plan`, `agent-factors-check`) that compound the silent-defaults problem if not addressed in v1.5.0.

## Decision

We will make `docs/agents/SYSTEM_CONTEXT.md` load-bearing. Specifically:

- The 5 downstream chain skills (`draft-spec`, `socratic-grill`, `decision-record`, `write-plan`, `tdd-loop`) halt with a clear redirect if the file is missing. The halt message names both recovery paths: `/groundwork` (preferred — runs `setup-habeebs-skill` with one-keystroke default-accept on each section) and `/research` (writes the file via Phase 0 reconnaissance).
- `prior-art-research` Phase 0 remains the sole *writer*. `setup-habeebs-skill` is the bootstrap entry point but defers the actual write of the recon digest to Phase 0 when invoked through the chain.
- Engineering primitives (`parallel-dev`, `deep-modules`, `vertical-slice`, `using-worktrees`, `systematic-debugging`) do NOT halt on missing file. They are invoked from inside the chain (already gated) or standalone (e.g., `systematic-debugging` for a production bug — halting would hurt more than help).
- `parallel-dev` documents the single-writer invariant explicitly: SYSTEM_CONTEXT.md is read-only for subagents; only the parent agent's Phase 0 writes.

The choice reflects two principles. First, environment binding belongs in a *file* the agent can read, not in frontmatter (static at install time) or in session state (per-host). Second, project context detection is *iterative* — the chain looks at actual artifacts as it runs — rather than declarative upfront via a project-mode field. This matches Anthropic's published guidance and the convergent pattern across Superpowers, mattpocock/skills, and OMC.

## Consequences

### Positive

- Bootstrap becomes load-bearing. Users who skip setup get a clean, actionable halt instead of silent defaults.
- The chain inherits the recon for free — every downstream skill assumes the file exists, simplifying their workflow text and eliminating "what if the user didn't configure X?" defensive code.
- SYSTEM_CONTEXT.md becomes the canonical answer to "where does this plugin store project facts" — clear precedent for future fields (deployment hints, scale envelope refinements, active steering history).
- Multi-runtime support is preserved — Codex / Cursor / OpenCode users read the same file (it's just markdown).

### Negative / Accepted trade-offs

- **First-install friction.** First chain invocation in a fresh repo halts. Mitigated by the redirect message and by `/groundwork` accepting all defaults via Enter.
- **One required artifact per repo.** `docs/agents/SYSTEM_CONTEXT.md` becomes a hard dependency for the chain. Acceptable because it's human-readable, git-tracked, and editable when wrong.
- **No project-mode field.** Skills cannot conditionally branch on a declared greenfield/brownfield/replacement value because no such value is recorded. Brownfield-aware behavior comes from inspecting artifacts (existing ADRs, existing code, existing tests). Cost: a tiny amount of redundant per-skill detection logic when multiple skills want the same answer. Worth it because a declarative mode field decays and the alternatives (one-time read, occasional re-detect) are cheap.
- **No semantic memory.** Cross-session decision recall stays grep-based via ADRs in `docs/agents/adrs/`. claude-mem / memsearch / equivalent remain optional add-ons, never required.

### Operational impact

- No CI/CD changes. No deploy changes. No runtime cost.
- Halt fires once per fresh-repo first-chain-invocation. Negligible time cost; significant context-quality benefit.
- ADR directory `docs/agents/adrs/` now exists with a starter index — future ADRs increment from 0002.

## Alternatives considered

### tmux session state

Per-pane scrollback + environment variables, durable across SSH disconnects. Rejected: state is per-host (not portable across machines or worktrees), Claude-Code-coupled in practice (Codex / Cursor users don't get it), not reviewable in PRs, and doesn't address the declarative project-facts use case. tmux remains useful as the *runtime* substrate for concurrent multi-agent execution (orthogonal to environment binding) — agents inside tmux panes still read SYSTEM_CONTEXT.md on init.

### Vector store (claude-mem / memsearch)

External persistent memory with semantic search across sessions. Rejected: introduces an opaque dependency (vector index), is plugin-specific (not multi-runtime), and the use case it solves — cross-session recall of past decisions — is already covered in-repo by ADRs + grep. claude-mem can compose with SYSTEM_CONTEXT.md as an optional add-on; it is not load-bearing for the chain.

### Hierarchical AGENTS.md (OMC deepinit style)

Recursive per-directory AGENTS.md files. Rejected: heavy for our use case (we need ~50 facts about the project, not a per-directory codebase walkthrough), brownfield-only (greenfield repos don't have directories to walk yet), and the format duplicates what a single SYSTEM_CONTEXT.md captures more concisely. deepinit-style hierarchies remain a viable add-on for very large codebases where per-directory context matters.

### Declarative project-mode field (greenfield | brownfield | replacement)

Considered as a SYSTEM_CONTEXT.md field that downstream skills would read to conditionally adjust behavior (e.g., `draft-spec` slice-1 shape; `decision-record` Alternatives length). Rejected for three reasons. First, the chain already detects brownfield-ness imperatively from artifacts — a declarative field is a second source of truth that decays after first prod deploy. Second, the proposed differentiations were thin: slice-1 shape is a per-slice `grep` decision, not a global mode flag; ADR Alternatives should always be rigorous regardless of project age. Third, no precedent — Anthropic's "iterative validation" guidance and the convergent pattern across Superpowers, mattpocock, and OMC all favor detection-on-demand over declared-upfront context.

## Revisit triggers

This ADR should be reopened if any of:

- A second runtime (Codex, Cursor, OpenCode) accumulates significant users and surfaces a portability gap in the markdown-based approach — may need multi-harness manifest equivalents.
- claude-mem / memsearch / equivalent achieves de-facto standard adoption — may need to formalize how semantic recall composes with SYSTEM_CONTEXT.md (not replace it).
- The "engineering primitives don't halt" cut becomes a recurring user-confusion source — may need to gate selected primitives (e.g., `vertical-slice` when run as the chain's decomposition step rather than standalone).
- Project context detection drift becomes a recurring pain point (multiple skills detecting the same fact slightly differently) — may revisit the project-mode field rejection.

## References

- Research: prior-art-research output (in-conversation, 2026-05-11) — audit of habeebs-skill v1.4.x integration patterns
- Spec: `docs/agents/specs/v1.5.0-environment-binding.md`
- Grill: socratic-grill output (in-conversation, 2026-05-11) — Q1–Q7 with resolutions, then post-grill scope cut that removed the project-mode field
- External sources:
  - [Anthropic — Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
  - [Anthropic — Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
  - [obra/superpowers](https://github.com/obra/superpowers) — multi-harness manifest + worktree-based brownfield safety
  - [mattpocock/skills — to-issues](https://github.com/mattpocock/skills/blob/main/skills/engineering/to-issues/SKILL.md) — bootstrap-skill + brownfield-by-assumption pattern
  - [OMC deepinit](https://agentskills.so/skills/yeachan-heo-oh-my-claudecode-deepinit) — single brownfield-bootstrap-skill pattern

---

## Changelog

- 2026-05-11 — Initial ADR, status Accepted (implementation landed in slice 1 of v1.5.0)
