# Implementation Spec: Dual-native Claude Code + Codex parity

**Slug:** `codex-dual-native-parity`
**Status:** Grilled
**Version:** v1.29.0
**Release:** v1.29.0
**Tier:** Deep
**Spec'd from:** [ADR — dual-native Claude/Codex parity](../adrs/2026-06-25-dual-native-claude-codex-parity.md)
**Spec'd on:** 2026-06-25

## TL;DR

Make habeebs-skill a first-class bundle under BOTH Claude Code and Codex CLI from a single canonical `skills/` source, with a generated `.agents/skills/` Codex tree, a `.codex/config.toml` hook registration reusing the same scripts, full subagent parity, and a CI drift-check. Seven slices, additive (no Claude breakage), shipping as v1.29.0.

## Architecture

One canonical skill tree (`skills/`) is authored as today. A sync script generates the Codex discovery tree (`.agents/skills/`) and a drift-check test fails CI on divergence. Hook scripts gain a harness-agnostic path shim and are registered twice — `hooks/hooks.json` (Claude) and `.codex/config.toml` (Codex) — pointing at one script set. The `agents/*.md` subagent prompts are dispatched natively on both harnesses.

```
            authored once
              skills/  ──────────────► Claude Code plugin (skills/, hooks/hooks.json, .claude-plugin/)
                 │
        bin/sync-codex.sh
                 │
                 ▼
          .agents/skills/  ──────────► Codex CLI (skills + .codex/config.toml hooks)
                 ▲
         CI drift-check (parity test)
```

## Concrete picks (from research + grill)

| Decision | Choice | Reason |
|---|---|---|
| Source topology | Single canonical `skills/` + generated `.agents/skills/` | Single-writer discipline; drift becomes a CI failure (ADR) |
| Drift safety | `bin/sync-codex.sh` + CI drift-check test | Forgetting to regenerate fails loud, not silent |
| Hook reconciliation | One script set, two registrations + path shim | Codex mirrors `hooks.json` schema; no script fork needed |
| Path resolution | `CLAUDE_PLUGIN_ROOT` → `CURSOR_PLUGIN_ROOT` → `git rev-parse --show-toplevel` | One body runs under both harnesses (extends ADR-0003 multi-harness) |
| Matcher dialect | Anchored forms valid as both literal + regex (`^Bash$`) | Satisfies Claude and Codex matcher engines |
| Frontmatter | Minimal (`name`/`description`/`disable-model-invocation`), verify-gated | Lowest surface area; gate falls back to dual-key if Codex rejects foreign key |
| Subagents | Full parity (Codex `SubagentStart`/`SubagentStop`) | 100% feature parity day one (grill decision) |
| Release type | Minor v1.29.0 | Additive; Claude layout untouched |

## Trade-offs accepted

- A generation step sits between authoring and the Codex tree (mitigated by drift-check).
- Three sync surfaces for hooks (`hooks.json`, `.codex/config.toml`, scripts) reduced to one script set + a parity test.
- Larger v1.29.0 (full subagent parity) over a faster degraded ship.

## Open questions (feed `socratic-grill`)

All resolved in the 2026-06-25 grill — none open:

- [x] Source topology → single canonical + generated (Option A)
- [x] Frontmatter dialect → minimal + verify gate
- [x] Subagent parity → full now
- [x] Release scope → all 7 slices in v1.29.0

---

## Vertical slices

Numbered in dependency order. HITL = human-in-the-loop required; AFK = autonomous-friendly.

### Slice 1 — ADR + spec locked, frontmatter verification gate (HITL)

**Description:** Land the ADR + this spec, and empirically confirm Codex ignores the `disable-model-invocation` frontmatter key against a live Codex CLI (or its published schema validator).

**Acceptance criteria:**
- [x] ADR + spec committed on the feature branch; ADR index row appended.
- [x] A `SKILL.md` with `disable-model-invocation` loads in Codex without error; result recorded in the spec. If it errors, switch the frontmatter pick to dual-key and update the ADR's frontmatter line.

**Verification result (2026-06-25):** No live Codex CLI is available in this environment, so the gate's documented fallback path was used — verification against Codex's published Agent Skills schema. The schema requires only `name` + `description`; per the spec, "All other frontmatter fields are optional" and unspecified keys are not validated against an allow-list, so `disable-model-invocation` is carried through as an inert extra key (same lenient-frontmatter behavior as Claude Code's own loader). **Outcome: minimal-frontmatter pick holds; no dual-key fallback needed.** Recorded as evidence per the Slice 1 fallback (published-schema validator as evidence source). Revisit trigger added: re-confirm against a live Codex before the next major if Codex tightens frontmatter validation.

**Test strategy:** Schema-evidence check (live Codex unavailable) — a parity test asserts every `SKILL.md` carries exactly the minimal key set so a future schema tightening is caught. Implemented at `tests/codex/01-frontmatter-parity/`.

**Blocked by:** None

### Slice 2 — Harness-agnostic path portability (AFK)

**Description:** Replace bare `${CLAUDE_PLUGIN_ROOT}` resolution in the 6 hook scripts and 17 command files with a shared shim resolving `CLAUDE_PLUGIN_ROOT` → `CURSOR_PLUGIN_ROOT` → `git rev-parse --show-toplevel`.

**Acceptance criteria:**
- [ ] Every hook script resolves its own dir with no harness-specific env var required.
- [ ] Command files reference skills via a path that resolves under both harnesses.
- [ ] Existing hook tests still pass; a new test asserts resolution with each env var unset in turn.

**Test strategy:** Unit — at `tests/hooks/` (extend) + new resolution test.

**Blocked by:** #1

### Slice 3 — Generated Codex skill tree + drift-check (AFK)

**Description:** Add `bin/sync-codex.sh` that generates `.agents/skills/` from `skills/`, plus a CI drift-check test that fails when the generated tree is stale.

**Acceptance criteria:**
- [ ] `bin/sync-codex.sh` regenerates `.agents/skills/` deterministically from `skills/`.
- [ ] Drift-check test exits non-zero when `.agents/skills/` differs from a fresh generation; zero when in sync.
- [ ] `.agents/skills/` discoverable by Codex (manual smoke: `$prior-art-research` resolves).

**Test strategy:** Integration — at `tests/codex/<next-free>-skill-drift/`.

**Blocked by:** #1, #2

### Slice 4 — Codex hook registration (AFK)

**Description:** Add `.codex/config.toml` registering the same six scripts under Codex's hooks engine with both-dialect matchers.

**Acceptance criteria:**
- [ ] `.codex/config.toml` registers SessionStart/PreToolUse/PostToolUse hooks pointing at the existing scripts.
- [ ] Matchers parse under Codex regex and Claude literal engines.
- [ ] Manual smoke: a commit-to-default attempt is blocked under Codex.

**Test strategy:** Integration + manual smoke — at `tests/codex/<next-free>-hooks/`.

**Blocked by:** #2

### Slice 5 — Full Codex subagent parity (HITL)

**Description:** Wire Codex subagent dispatch into `prior-art-research` Deep mode and `parallel-dev` so `agents/*.md` (`source-fetcher`, `pattern-extractor`, `synthesizer`, `category-completeness-critic`) run on both harnesses with the same dispatch contract (ADR-0004).

**Acceptance criteria:**
- [ ] Deep-tier research dispatches the four subagents under Codex.
- [ ] `parallel-dev` write-batch isolation + the 4-status return contract hold under Codex.
- [ ] Behavior matches the Claude path on a shared fixture.

**Test strategy:** Integration — at `tests/codex/<next-free>-subagent-parity/`. Heaviest slice; build on #2–#4.

**Blocked by:** #2, #3, #4

### Slice 6 — Docs reconciliation (AFK)

**Description:** Rewrite the outdated `AGENTS.md` Codex section, correct the README Codex install/feature framing, and sync `CLAUDE.md`.

**Acceptance criteria:**
- [ ] `AGENTS.md` describes native Codex skills (`$skill-name`), Codex hooks, and subagents — no "no plugin system" claim.
- [ ] README Codex section reflects native install, not prose-only fallback.
- [ ] `CLAUDE.md` references the dual-native ADR.

**Test strategy:** Manual review + doc-sync audit.

**Blocked by:** #3, #4, #5

### Slice 7 — Parity test suite + release (HITL)

**Description:** Consolidate `tests/codex/` parity tests into `tests/run-all.sh`, then run the release flow for v1.29.0.

**Acceptance criteria:**
- [ ] `tests/run-all.sh` includes all Codex parity tests and passes.
- [ ] Changeset present; v1.29.0 bump applied to `plugin.json` + `marketplace.json`; CHANGELOG entry; doc-sync audit clean; tag-push.

**Test strategy:** E2E — `tests/run-all.sh` green; release artifacts present.

**Blocked by:** #5, #6

---

## Dependency DAG (5+ slices)

```
1 → 2 → 3 ─┐
        ├──→ 5 → 6 → 7
    2 → 4 ─┘
```

## Parallelization

- Group A (parallel): #3, #4 — both depend on #2, disjoint scopes (`.agents/skills/` vs `.codex/`).
- Sequential: #1, #2, then #5 (needs #3+#4), then #6, then #7.

## Revisit triggers

- Codex changes skill discovery paths, frontmatter schema, or hooks contract.
- Drift-check proves insufficient (≥3 escapes) → escalate to single-tree (Option C).
- Frontmatter verification (Slice 1) fails → switch to dual-key, re-grill the affected picks.

---

HANDOFF: record ready — ADR already captured at `adrs/2026-06-25-dual-native-claude-codex-parity.md`.
HANDOFF: implementation ready — invoke `tdd-loop` per slice in dependency order, starting Slice #1.
