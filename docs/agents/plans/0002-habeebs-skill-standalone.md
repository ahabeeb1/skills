# Plan: Lock the standalone-by-design rule and add steering-flush

| Field         | Value                                                     |
|---------------|-----------------------------------------------------------|
| Plan ID       | `plans/0002-habeebs-skill-standalone`                     |
| ADR           | [`adrs/0002-habeebs-skill-standalone`](../adrs/0002-habeebs-skill-standalone.md) |
| Status        | Active                                                    |
| Last updated  | 2026-05-12                                                |
| Owner         | Modie (Habeeb)                                            |

## Goal

Lock the "habeebs-skill is standalone" rule across every discovery surface, and stop `Active steering` from leaking across unrelated chain runs. Ship as v1.5.2.

## Success measure

A fresh agent loading any habeebs-skill chain-intro surface (`CLAUDE.md`, `using-habeebs-skill/SKILL.md`, ADR index, plugin description) reaches the same conclusion within one read: this plugin is one-time-use per feature, has no runtime-substrate dependency, and clears its steering at the end of each chain. Verified by re-running the v1.5.0 self-audit-style prompt ("is this design valuable and best-practice?") on a fresh session and confirming the OMC-composition path is not proposed.

## Phases

### Phase 1 — Lock the standalone rule

**Slices:** #1, #2, #3, #4 (ADR-0002, ADR index update, CLAUDE.md fix, using-habeebs-skill addition)

**Acceptance gate:** Grep across `CLAUDE.md`, `using-habeebs-skill/SKILL.md`, and `docs/agents/adrs/` for the strings `compose with OMC`, `OMC dependency`, `runtime substrate`, `cross-session memory`. Either zero hits, or every hit is inside an explicitly-rejecting context (ADR Alternatives section, "we do NOT compose" sentence). Verified by hand.

**Top risks:**
1. The existing `CLAUDE.md` "Not a replacement for oh-my-claudecode — it composes with OMC's orchestration" wording is the load-bearing contradiction; fixing it without changing the meaning of the surrounding line about OMC being a different domain is a small wording risk.
2. ADR-0002's "Compose with OMC" alternative needs to read as a real alternative (not a strawman) or future readers won't trust the rejection.
3. Risk of over-correcting — habeebs-skill should still acknowledge that orthogonal tools (OMC, claude-mem, Superpowers) can coexist; the rule is "no dependency," not "users should uninstall OMC."

**Rollback hook:** All four files are git-tracked. `git revert` of the v1.5.2 commit restores the v1.5.1 state. ADR-0002 marked `Status: Superseded by ADR-NNNN` if rolled back rather than deleted (ADR convention from `docs/agents/adrs/README.md`).

### Phase 2 — Add steering-flush

**Slices:** #5, #6 (steering-hints.md flush rule, prior-art-research SKILL.md Phase 7 update)

**Acceptance gate:** Reading `steering-hints.md` end-to-end yields a clear answer to "when does `Active steering` clear?" — namely, Phase 7 of `prior-art-research` moves the block from `## Active steering` to `## Last reconciliation outcome` after the handoff lines fire. The `prior-art-research/SKILL.md` Phase 7 description references the flush rule so it's discoverable from the workflow, not just the reference doc.

**Top risks:**
1. The flush could destroy steering that the user wanted to keep for a multi-chain campaign on the same topic (e.g., a v1.6.0 redesign that spans several research passes). Mitigated by making the flush *move* to a `Last reconciliation outcome` section (still discoverable), not delete.
2. `SYSTEM_CONTEXT.md` template currently expects an `Active steering` section; emptying it on flush leaves the section header dangling. Mitigated by writing `(none — flushed YYYY-MM-DD; last outcome below)` as the section body after flush.

**Rollback hook:** Same as Phase 1 — `git revert`. Worst case the flush rule never fires (it's documentation, not executable), so a botched rollout fails silent rather than destructive.

### Phase 3 — Wire and release

**Slices:** #7, #8, #9 (CHANGELOG v1.5.2 entry, plugin.json + marketplace.json bump, commit + tag)

**Acceptance gate:** `git tag v1.5.2` exists; CHANGELOG renders cleanly above v1.5.1 entry; `jq .version .claude-plugin/plugin.json` returns `"1.5.2"`; same for marketplace.json.

**Top risks:**
1. Minor risk of CHANGELOG-format drift; v1.5.1 set the recent style. Mitigation: read v1.5.1 entry side-by-side while drafting.
2. Risk of forgetting one of the two manifests (plugin.json vs marketplace.json) — recurring footgun in past releases. Mitigation: edit both in same tool call.

**Rollback hook:** Pre-tag, anything is `git reset --soft HEAD~1` away. Post-tag, `git tag -d v1.5.2` locally and (if pushed) `gh release delete v1.5.2`. Marked as one-way after `gh release create v1.5.2` because release notes mirror this CHANGELOG and downstream consumers may already have pulled.

## Slice table

| ID  | Name                                              | Label           | Phase | pgroup     | Blocked by | Est   | Rollback hook                       |
|-----|---------------------------------------------------|-----------------|-------|------------|------------|-------|-------------------------------------|
| #1  | Write ADR-0002 (`adrs/0002-habeebs-skill-standalone.md`) | AFK:full-auto | 1     | pgroup-1A  | —          | 0.25d | `git revert`                        |
| #2  | Update ADR index README (`adrs/README.md`)        | AFK:full-auto   | 1     | pgroup-1A  | #1         | 0.05d | `git revert`                        |
| #3  | Fix CLAUDE.md OMC line                            | AFK:full-auto   | 1     | pgroup-1A  | —          | 0.05d | `git revert`                        |
| #4  | Add "Standalone by design" to `using-habeebs-skill/SKILL.md` | AFK:full-auto | 1     | pgroup-1A | —          | 0.1d  | `git revert`                        |
| #5  | Add Phase 7 flush rule to `steering-hints.md`     | AFK:full-auto   | 2     | pgroup-2A  | —          | 0.1d  | `git revert`                        |
| #6  | Update `prior-art-research/SKILL.md` Phase 7 to reference flush | AFK:full-auto | 2 | pgroup-2A  | #5         | 0.05d | `git revert`                        |
| #7  | CHANGELOG v1.5.2 entry                            | AFK:full-auto   | 3     | pgroup-3A  | #1–#6      | 0.1d  | `git revert`                        |
| #8  | Bump `plugin.json` + `marketplace.json` to 1.5.2  | AFK:full-auto   | 3     | pgroup-3A  | #1–#6      | 0.05d | `git revert`                        |
| #9  | Commit, tag `v1.5.2`, push, release               | HITL:inline     | 3     | pgroup-3B  | #7, #8     | 0.1d  | `git tag -d v1.5.2` (one-way after release publish) |

**Label legend:**
- `AFK:full-auto` — no human in the loop; safe for `parallel-dev` autonomous dispatch
- `HITL:inline` — human reviews/decides in the chat session mid-slice (slice #9 — the user confirms before tagging and releasing)

**Estimate convention:** **d** = ideal engineer-days. Estimates are illustrative for sequencing; gates are contractual.

## Dependency DAG

```
#1 ── #2 ──┐
#3 ────────┤
#4 ────────┼─→ #7 ──┐
#5 ── #6 ──┘        ├─→ #9
                #8 ─┘
```

## Parallelization map

- `pgroup-1A` = {#1, #2, #3, #4} — Phase 1, no inter-file overlap (different files), AFK → `parallel-dev` eligible. Note #2 reads #1's filename but doesn't read its content, so the dependency is name-only.
- `pgroup-2A` = {#5, #6} — Phase 2, two files; #6 references #5's new flush rule but the reference is by name, not content. Sequenceable as #5 then #6 if `parallel-dev` is conservative; otherwise dispatch in parallel.
- `pgroup-3A` = {#7, #8} — Phase 3, no inter-file overlap.
- `pgroup-3B` = {#9} — Phase 3, single HITL slice.

**Independence sanity:** all pgroup-1A members touch different files (`adrs/0002-…`, `adrs/README.md`, `CLAUDE.md`, `using-habeebs-skill/SKILL.md`). No file overlap. No shared state. No implicit ordering beyond the trivial "#2 references #1's filename." Verified against `parallel-dev` Phase 2 checklist.

## Risk register

| #   | Phase | Risk                                                                     | Likelihood | Impact | Mitigation                                                                 |
|-----|-------|--------------------------------------------------------------------------|------------|--------|----------------------------------------------------------------------------|
| R1  | 1     | CLAUDE.md fix removes nuance ("OMC is a different domain") readers found useful | Medium     | Low    | Replace with explicit standalone rule; preserve the "different domain" framing as "orthogonal, not coupled"                  |
| R2  | 1     | ADR-0002 Alternatives section reads as strawman                          | Low        | Medium | Use the actual v1.5.0 audit recommendation verbatim as the rejected alternative — receipts exist |
| R3  | 2     | Flush rule wipes useful steering on multi-chain campaigns                | Medium     | Low    | Move to `Last reconciliation outcome` rather than delete; user can copy back if needed |
| R4  | 3     | Manifest version drift (plugin.json vs marketplace.json mismatch)        | Medium     | High   | Edit both in same tool call; verify with `jq` post-edit                    |
| R5  | 3     | Tag pushed before CHANGELOG reviewed                                     | Low        | Medium | Slice #9 labeled `HITL:inline` — user gates the tag                        |

## Revisit triggers

- A future v1.6.x or v2.x audit revisits whether standalone is still the right posture (e.g., if Claude Code adds a multi-harness state mechanism that's both portable and markdown-reviewable).
- `parallel-dev` accumulates user-confusion reports about long-running coordination that the in-chain primitive can't model.
- Steering flush turns out to clear too aggressively in practice (user feedback indicates anchors disappearing mid-multi-chain).
- ADR-0002 status flips to Deprecated or Superseded.

If a trigger fires, halt at the current phase gate and re-run `socratic-grill` on the affected sections before continuing.

## Change log

- 2026-05-12 — Initial plan written from ADR-0002.

## References

- ADR: [`adrs/0002-habeebs-skill-standalone`](../adrs/0002-habeebs-skill-standalone.md)
- Sister ADR: [`adrs/0001-environment-binding-via-system-context`](../adrs/0001-environment-binding-via-system-context.md)
- SYSTEM_CONTEXT: [`SYSTEM_CONTEXT.md`](../SYSTEM_CONTEXT.md)
- Steering-hints reference (target of slice #5): `skills/prior-art-research/references/steering-hints.md`
- prior-art-research SKILL.md (target of slice #6): `skills/prior-art-research/SKILL.md`
