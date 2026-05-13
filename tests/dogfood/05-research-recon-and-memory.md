# Prior-Art Research: Reconnaissance + memory layer for habeebs-skill

**Researched on:** 2026-05-10
**Mode:** Quick
**Sources consulted:** 4 (claude-mem, graphify, zilliztech/claude-context, Anthropic's Claude Code Explore)

## TL;DR

Add an **in-repo `docs/agents/SYSTEM_CONTEXT.md`** populated by a new Phase 0 in `prior-art-research`, with staleness detection via `git log` against tracked manifest files. **Do not** delegate to `claude-mem` or `graphify` for this; both are excellent tools for adjacent problems but introduce mandatory dependencies, opaque storage, and duplicate work that doesn't pencil out at our scale. Headline trade-off: the in-repo file goes stale silently if no one runs the chain for a while — mitigated by a staleness banner the skill emits when manifests have changed since the file was written.

## Context

- **Building:** Reconnaissance and decision-memory layer for the habeebs-skill chain
- **Scale:** ~10 skills compose; each chain run produces 1 ADR + 1 spec + 1 grill; <100 ADRs expected per repo lifetime
- **Stack:** Markdown skills inside a Claude Code plugin; users may also have `graphify`, `claude-mem`, or `claude-context` installed separately
- **Constraints:** Plugin manifest can't bundle MCP servers; can't assume any specific MCP is present
- **Existing:** Greenfield within the plugin; Claude Code's built-in Explore agent + `setup-habeebs-skill`'s `GLOSSARY.md` pattern are the closest precedents
- **Priorities:** Composability with existing tools, operational simplicity

## Sub-problems

1. **Structure recon** — slow-changing, small, plain-text artifacts (stack, schema, deployment shape)
2. **Behavior recon** — semantic understanding of the running system (architecture, seams, hot files)
3. **Memory of past decisions** — cross-session retention of ADRs and grilled trade-offs

## Case studies

### claude-mem (thedotmack) — auto-captured cross-session memory via SQLite + ChromaDB

- **Architecture:** Captures tool usage observations at session end, compresses to semantic summaries, stores in SQLite + Chroma vectors. Progressive-disclosure retrieval (search → review IDs → fetch details) gives ~10x token savings.
- **Key decision:** Session-end auto-compression with vector-indexed retrieval, on the bet that cross-session continuity is worth the storage tax.
- **Scale:** Personal-developer scale; works on Claude Code, Codex, Gemini, etc.
- **Trade-off accepted:** No documented expiration / staleness model — entries appear permanent. Eventually requires manual pruning.
- **Source:** https://github.com/thedotmack/claude-mem

### graphify — knowledge graph with persistent `graph.json`

- **Architecture:** Builds a navigable knowledge graph (HTML + JSON + Markdown audit) from any folder of files. Supports `--update` for incremental re-indexing of changed files and `--watch` for filesystem-event-driven auto-rebuild.
- **Key decision:** Every edge tagged EXTRACTED / INFERRED / AMBIGUOUS so the agent can tell what was *found* vs *invented* — the only tool surveyed with explicit epistemic provenance.
- **Scale:** Folder-of-files scale; suited for unfamiliar codebases / research corpora.
- **Trade-off accepted:** Initial build cost (LLM calls per file); `--watch` mode reduces it for ongoing work but it's still heavier than a plain-text snapshot.
- **Source:** local `SKILL.md` + `https://github.com/karpathy/...` workflow inspiration

### zilliztech/claude-context — Merkle-tree incremental code indexing

- **Architecture:** AST-chunked embeddings in Milvus / Zilliz Cloud. Merkle trees detect changed files; only those are re-embedded.
- **Key decision:** Incremental indexing via Merkle trees rather than full re-index OR continuous watching.
- **Scale:** Designed for whole-codebase semantic search.
- **Trade-off accepted:** Adds a vector DB (Milvus or managed Zilliz) — a real new dependency.
- **Source:** https://github.com/zilliztech/claude-context

### Anthropic Claude Code — built-in `Explore` subagent (no caching)

- **Architecture:** Parallel-dispatchable file-search subagents. Each invocation does fresh recon for its goal; nothing persisted between invocations.
- **Key decision:** No cache, full freshness, full cost. Bet is that fresh recon is more reliable than cached.
- **Scale:** Any repo size; cost scales with each invocation.
- **Trade-off accepted:** Repeated recon for the same questions across sessions; LLM tokens are the recurring cost.
- **Source:** https://code.claude.com/docs/en/plugins-reference + observed behavior

---

## Patterns

### Pattern A — No cache, fresh recon every time (Explore baseline)

Each chain invocation re-runs reconnaissance from scratch via Explore subagents. Simplest mental model; highest recurring cost.

**Fits when:** Repo is small AND chain runs infrequently AND token cost is irrelevant.

### Pattern B — Plain-text in-repo cache + staleness check (`setup-habeebs-skill` style)

Two markdown files split by writer lifecycle: `docs/agents/SYSTEM_CONTEXT.md` (tool-written by `prior-art-research` Phase 0, auto-refreshed when a tracked manifest changes) and `docs/agents/GLOSSARY.md` (human-written by `setup-habeebs-skill`, edited as the codebase evolves). Both version-controlled, human-reviewable, load in any agent for ~free.

**Fits when:** Structure recon is slow-changing (package files, schema, deploy shape) and the team values "human can edit the cache" over "machine maintains the cache."

### Pattern C — Vector-DB-backed persistent memory (claude-mem / claude-context)

Embeddings + semantic search in a vector store, optionally with auto-compression at session end. High retrieval power; introduces a mandatory dependency on a vector DB.

**Fits when:** Cross-session continuity is the primary need, the repo is large enough that fresh recon is genuinely expensive, AND the user is already running a vector backend.

### Pattern D — Knowledge graph with explicit provenance (graphify)

Persistent graph with EXTRACTED/INFERRED/AMBIGUOUS edge tags; great for "I don't know this codebase yet."

**Fits when:** Onboarding to an unfamiliar codebase or research corpus; less load-bearing once you live in the code.

---

## Recommendation

**For the habeebs-skill plugin, use Pattern B for structure recon, Pattern A for behavior recon, and skip dedicated memory tooling — the in-repo ADR directory already IS the durable decision memory.**

Concretely: add a Phase 0 to `prior-art-research` that probes manifest files and writes `docs/agents/SYSTEM_CONTEXT.md` on first run. Subsequent runs `git log --since "<file_write_date>" -- <manifests>` to detect staleness and emit a banner if stale; otherwise just load the cached file. Behavior questions delegate to Claude's built-in Explore subagent on demand — no point caching what's better re-derived. ADRs in `docs/agents/adrs/` are already Tier-0 cross-session memory (the `prior-art-research` SKILL.md says so explicitly); duplicating that into `claude-mem` is pure storage tax.

This is the right call because every constraint points to it: (1) the plugin can't ship MCP dependencies, (2) `setup-habeebs-skill` already establishes the "in-repo markdown is the source of truth" pattern, and (3) the user can correct/edit a plain-text cache, which they cannot do for an opaque vector store. `claude-mem` and `graphify` are genuinely good tools for problems we don't have at the plugin level — leaving them as optional installs that compose if present, but not required.

### Concrete picks

| Decision | Choice | Reason |
|---|---|---|
| Structure recon storage | `docs/agents/SYSTEM_CONTEXT.md` in the repo | Versioned, reviewable, cheap to load |
| Recon trigger | `prior-art-research` Phase 0 (new) | Single skill owns the recon discipline; rest of chain consumes the file |
| Staleness detection | `git log --since "<file_mtime>" -- package.json prisma/ migrations/ Dockerfile fly.toml` | Manifests are the canary; if they changed, the file is suspect |
| Stale banner | Skill emits "⚠ SYSTEM_CONTEXT may be stale; refresh? (Y/n)" | User-in-the-loop, not silent overwrite |
| Behavior recon | Delegate to Claude's built-in Explore subagent on demand | Don't cache what's reliably re-derivable |
| Decision memory | `docs/agents/adrs/` (already there) | The chain's existing mechanism; no separate store |
| `claude-mem` integration | Optional, opt-in via env var | If the user has it installed and wants chain decisions echoed there, fine — but never required |
| `graphify` integration | None at the plugin level | Recommend it in docs as a one-time tool for new contributors onboarding to an unfamiliar codebase |

### What you're explicitly giving up

- **Semantic search across ADRs.** A vector store would make "find the ADR about retries" smarter than `grep`. Acceptable at <100 ADRs/repo; revisit if a repo accumulates 500+.
- **Auto-captured session context.** Anything not written to the repo evaporates. The chain enforces "if it matters, it goes in spec/grill/ADR," so this is by design.
- **Auto-updating behavior cache.** If the codebase is huge and Explore is expensive, this trade gets worse. Out of scope today.

### When to revisit

- ADR count in a single repo exceeds ~100 (grep starts losing)
- Repo exceeds ~50k LOC AND Explore costs become a real chain bottleneck
- Multiple repos need cross-repo decision search (where the `claude-mem` integration earns its keep)
- The user reports that the staleness banner fires too often or too rarely (signal that the manifest list is mis-tuned)

---

## Decisions to make next

These feed `socratic-grill` and `draft-spec`:

1. **Manifest list for staleness detection** — fixed list (`package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `prisma/schema.prisma`, `migrations/`, `Dockerfile`, `fly.toml`, `vercel.json`, `serverless.yml`)? Detect by language ecosystem? Configurable?
2. **What goes IN `SYSTEM_CONTEXT.md`** — strict schema (stack, deploy, datastores, scale envelope) or freeform?
3. **Refresh policy** — auto-rewrite on stale-detect, or always prompt the user?
4. **Multi-repo / monorepo handling** — one `SYSTEM_CONTEXT.md` per workspace? Per package? Per app?
5. **Opt-in surfaces** — env var (`HABEEBS_SKILL_CLAUDE_MEM=1`) for echoing chain decisions to `claude-mem`?

## Open questions

- Does Phase 0 belong only in `prior-art-research`, or should `draft-spec` and `decision-record` also run a lighter recon pass (e.g., "do CI configs already exist?")?
- How does this interact with worktrees? (If the chain runs in a worktree, the cached file may not exist there until the recon runs.)

---

## Sources

1. **claude-mem (thedotmack)** — https://github.com/thedotmack/claude-mem
   What it gave us: vector + SQLite memory model and its lack of staleness story.
2. **graphify SKILL.md** — local `~/.claude/skills/graphify/SKILL.md`
   What it gave us: explicit provenance tagging (EXTRACTED/INFERRED/AMBIGUOUS) and `--watch` auto-rebuild pattern.
3. **zilliztech/claude-context** — https://github.com/zilliztech/claude-context
   What it gave us: Merkle-tree incremental indexing as a middle ground between fresh recon and full re-embedding.
4. **Claude Code plugin reference** — https://code.claude.com/docs/en/plugins-reference
   What it gave us: the Explore-subagent baseline and the fact that plugins can't bundle MCP servers.

---

HANDOFF: spec ready — invoke `draft-spec` to slice the Phase 0 reconnaissance addition into implementation slices (suggested first slice: write `SYSTEM_CONTEXT.md` template + Phase 0 SKILL.md changes; second slice: staleness detection via `git log`; third slice: optional `claude-mem` echo).
HANDOFF: grill ready — open questions 1-5 above and the two below all need socratic resolution before implementing.
HANDOFF: record ready — once decided, capture as `docs/agents/adrs/0001-recon-and-memory-strategy.md`.
