# habeebs-skill — Agent Instructions

This plugin gives Claude a research-grounded engineering methodology. When the user asks to build something non-trivial, the skills in this plugin trigger in a chain. Don't bypass them.

## The chain

```
prior-art-research → draft-spec → socratic-grill → decision-record → write-plan → tdd-loop → release
                                       ↓
                             agent-factors-check (only if the spec is an agent product)
                             devex-review (only if the spec is a developer-facing product)
```

Each skill produces output that the next skill consumes. The handoff lines at the bottom of each skill's output (e.g. `HANDOFF: spec ready`) tell you what to do next.

`write-plan` is skip-able when the slice list is trivial and ordering is obvious; otherwise it runs after `decision-record` to produce the phased delivery doc that `tdd-loop` and `parallel-dev` consume. `agent-factors-check` and `devex-review` are conditional extensions of `socratic-grill` — the first fires when the spec is for an agent / copilot / LLM workflow / RAG / function-calling product, the second when the spec is for a developer-facing product (CLI / SDK / library / plugin / framework); both can fire on the same spec. `release` is the terminal link after `tdd-loop` goes GREEN — `verify-output` gates each tdd-loop commit along the way.

**Every chain run executes at a depth tier — Quick, Balanced, or Deep** (ADR-0016; canonical reference `docs/agents/references/tier-scale.md`). `prior-art-research` Phase 3 picks the tier (auto-detected from residual ambiguity, sub-problem count, and constraint complexity — or a `--quick`/`--balanced`/`--deep` override), writes it into the research report's `Tier:` header, and every downstream skill inherits it. The tier scales how much of each step runs: Quick is terse and skips optional ceremony, Deep runs the full chain with parallel research and a phased plan. Two invariants are non-negotiable — the tier scales *effort*, never *decision quality* (a real open question always reaches `socratic-grill`; a one-way-door decision always gets an ADR, even under a `--quick` override), and tier-related user-facing output stays task-focused (state the tier with a task-based reason — sub-problems, ambiguity, constraints — never a token/cost/time justification).

## Skill routing

When the user's request matches the LEFT column, invoke the RIGHT skill BEFORE anything else. This table is authoritative — it outranks fuzzy-match against competing skill descriptions.

| User signal                                                                          | Skill                  |
|--------------------------------------------------------------------------------------|------------------------|
| "let's build", "I want to add X", "implement", "design this", "architect this"       | `/research`            |
| "this is broken", "fix this bug", "test is failing", "this worked yesterday"         | `/debug`               |
| "refactor this", "this code feels off", "too many small files", "clean this up"      | `/deepen`              |
| "audit this", "security review", "check for vulnerabilities", "threat model"         | `/security-audit`      |
| "do these N things in parallel", "run these batches concurrently"                    | `/parallel`            |
| After `/research` emits `HANDOFF: spec ready`                                         | `/spec` then `/grill`  |
| After `/grill` resolves OQs, before implementation                                    | `/record` then `/plan` |
| "spec is locked", "start building slice N", "let's implement"                        | `/tdd`                 |
| "ready to ship", "cut a release", "bump the version", "tag this"                     | `/release`             |

If the request is ambiguous, ASK before picking a path. Do not skip the chain to vibe-code.

## Triggering principles

- **Trigger `prior-art-research` aggressively.** The user almost never says "research." They say "I want to build X." Read between the lines.
- **Don't skip phases for speed — pick a lighter tier instead.** If you're tempted to jump straight to writing code, you're missing the point of this plugin. The whole methodology is about NOT vibe-coding. On genuinely simple work the Quick tier already trims the ceremony; the tier scale, not impatience, decides depth.
- **Internal precedent first.** For Modie's repos (BeanBot, salahi.app, BOL automation), check local repos before going external. The user's own prior art is Tier 0.
- **Engineering primitives compose.** `parallel-dev`, `deep-modules`, `tdd-loop`, `vertical-slice`, `using-worktrees`, `systematic-debugging` are not standalone — they support the chain. `parallel-dev` is used by `prior-art-research` in the Deep tier AND consumes `write-plan`'s parallelization groups. `tdd-loop` is invoked during implementation. `deep-modules` is invoked during refactor passes. `using-worktrees` isolates non-trivial slices. `systematic-debugging` handles bugs that surface during or after a slice.
- **`parallel-dev` task-class split.** Read-task dispatches (research / extraction / audit — Anthropic-validated, ~15× tokens, no merge surface) and write-task dispatches (artifact-producing — Cognition-restricted: per-worktree isolation + ≤8 concurrent + Phase 2 independence verification, all mandatory) follow different rules. See `parallel-dev` § "Task class — read vs write" before dispatching a write batch.

## What this plugin is NOT

- **Standalone by design (ADR-0002).** habeebs-skill has no runtime dependency on any external substrate — no shared memory store, vector store, MCP server, or session-state directory. The chain is one-time-use per feature: it runs once (`research → spec → grill → record → plan → tdd`), produces durable in-repo artifacts (`docs/agents/SYSTEM_CONTEXT.md`, ADRs, plans, code + tests), then ends.
- Not a replacement for Context7 — it uses Context7 as a documentation source during `prior-art-research`
- Not an automatic code writer — implementation still happens through TDD
- Not a survey tool — the research phase makes opinionated recommendations
- Not for trivial CRUD — let trivial things stay trivial

## Anti-patterns

If you find yourself doing any of these, stop and re-read the relevant skill:

- Surveying multiple options without recommending one
- Skipping the context-capture questions to "save time"
- Researching after deciding (research is upstream of decisions, not downstream)
- Recommending FAANG-scale solutions to non-FAANG-scale problems
- Letting the chain stall in research without producing a spec
- Letting a lighter tier skip a triggered quality gate (open questions still grill; one-way doors still get an ADR)
- Justifying the chosen tier to the user with token, cost, or time-budget language instead of task-based reasons

## Quote and copyright discipline

When researching:
- One quote per source maximum, under 15 words, in quotes
- Paraphrase everything else
- Never reconstruct an article's structure with detailed paraphrase
- Cite every claim that follows from a search result

## Agent skills

This repo is self-dogfooded by the habeebs-skill chain. The methodology files are:

- **Domain glossary:** `docs/agents/GLOSSARY.md` — habeebs-skill's own vocabulary (skill, slice, chain, ADR, harness, dispatch group, etc.). Written by `setup-habeebs-skill`; edited as the codebase evolves.
- **System context:** `docs/agents/SYSTEM_CONTEXT.md` — stack, scale envelope, deployment shape, recent hot files, last reconciliation outcomes. Written exclusively by `prior-art-research` Phase 0 (load-bearing per ADR-0001; single-writer invariant per ADR-0005).
- **Issue tracker:** `docs/agents/issue-tracker.md` (GitHub for this repo).
- **Triage labels:** `docs/agents/triage-labels.md` (canonical 5).
- **ADRs:** `docs/agents/adrs/` (see `README.md` for the authoritative index and current count).
- **Chain-shared references:** `docs/agents/references/` (cross-cutting helpers per ADR-0009 — e.g. `tier-scale.md`, `system-context-staleness-check.md`).
- **Specs:** `docs/agents/specs/` (one per release).
- **Plans:** `docs/agents/plans/` (one per release that warranted phased delivery).
- **Dispatches:** `docs/agents/dispatches/` (parallel-dev audit records).

**Directory classification:** `docs/agents/dispatches/` and `docs/agents/conflicts/` are *runtime writer paths* (written by `parallel-dev` and `cross-session-detect`), not authored methodology directories — they stay on disk with `.gitkeep` regardless of file count, governed by their writer's ADR (ADR-0004 Part 2, ADR-0018 Part A, ADR-0019). The "earn existence by file count" rule applies only to authored dirs (`adrs/`, `specs/`, `plans/`, `postmortems/`, `research/`, `references/`). See [ADR-0021](./docs/agents/adrs/0021-methodology-folder-cuts.md) for the distinction.

When invoking habeebs-skills in this repo, read these files first. Per ADR-0005, GLOSSARY and SYSTEM_CONTEXT split by writer lifecycle — GLOSSARY is human-authored and domain-stable; SYSTEM_CONTEXT is tool-authored and environment-bound.

## When the user pushes back

The user (Modie) prefers:
- Bullet points and structured output
- Precise metrics over vague claims
- Direct tone — no hedging, no excessive caveats
- Citations with links
- Concrete recommendations, not "it depends"

If you find yourself hedging, stop and commit to a recommendation. The chain has `socratic-grill` to challenge it later — you don't need to pre-empt criticism in the research phase.
