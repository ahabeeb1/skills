# Prior-Art Research: SKILL.md body-shape conventions (peer practice for ADR cites, version refs, dated incidents, footers, length)

**Researched on:** 2026-05-25
**Tier:** Balanced (user-locked)
**Sources consulted:** 27 instructional files across 3 independent populations + 7 authoring/spec docs

## TL;DR

**Strip all inline ADR-NNNN citations, "Added in vN.M" version tags, and dated incident references from SKILL.md bodies — they violate a 27/27 cross-population convention and Anthropic's own written prescription ("Don't include information that will become outdated").** Keep cross-skill links as inline `@sibling.md` / `/skill-name` handles in prose; add a forward-only `## See also` footer only where it pays for itself. The headline trade-off: we lose at-a-glance "why does this rule exist" provenance in the skill file itself — but git blame + the ADR index + per-skill CHANGELOG entries already carry that load, and 12-of-18 SKILL.md files currently carry cruft that no peer in the ecosystem ships.

## Context

- **Building:** A cleanup convention for habeebs-skill's own SKILL.md bodies — specifying what stays inline, what moves to footer, and what leaves the file entirely.
- **Scale:** 18 SKILL.md files in this repo; 12 affected by cruft (1-13 hits each, 69 hits total).
- **Stack:** Markdown SKILL.md files under `skills/<name>/SKILL.md`, shipped as a Claude Code plugin (claude.md plugin manifest format); no runtime substrate (ADR-0002).
- **Constraints:** Anthropic's hard cap ~500 lines / 5000 tokens per SKILL.md; auto-trigger correctness depends on description fidelity (frontmatter, out of scope here); body must remain agent-readable instructions, not human-reader prose.
- **Existing:** Retrofit. v1.19.0 (PR #43) trimmed FRONTMATTER descriptions; this run targets BODIES.
- **Priorities:** Correctness (the rule we adopt must hold across all 18 skills) + operational simplicity (cleanup must be mechanical, not per-skill judgement calls).

## Sub-problems

1. **Body-shape conventions in peer instructional .md files** — Do peers cite ADRs inline, embed version refs, include dated incidents, ship "See also" footers, and what length/section norms do they enforce? (Single composite sub-problem, three independent populations sampled: peer Claude Code plugins, Anthropic canon, outside-Claude-Code rule-files.)

## Phase 2.5 outcome — Category-completeness critic

**Verdict:** SKIPPED — Single sub-problem with a tightly-scoped extraction template (5 fixed feature axes: ADR cites / version refs / dated incidents / footers / length). Critic would have no decomposition to critique. Homogeneity caveat (missing regulated/compliance and academic/lab-notebook populations) was instead captured in the pattern-extractor record and is propagated below as both a Pattern-F-adjacent note and a Decision-3 / Open-Question-3 re-research trigger.

## Case studies

### anthropics/skills — `skill-creator/SKILL.md` (the meta-skill)

- **Architecture:** Task-shaped imperative present-tense instructions. `# Title` → short `## Overview` → 3-8 `##` task sections named for what the agent DOES → `## Reference files` footer pointing forward to bundled `REFERENCE.md` / examples.
- **Key decision:** Zero version tags, zero decision provenance, zero dated incidents. Closes with forward-asset pointers only — no backward-citation of why the skill was authored this way.
- **Scale:** Anthropic's most-authoritative meta-skill (the skill that authors skills).
- **Trade-off accepted:** No in-file audit trail of why a given rule exists; that load is carried by git history and ADRs that live outside the SKILL.md.
- **Source:** [anthropics/skills · skill-creator/SKILL.md](https://github.com/anthropics/skills/blob/main/skill-creator/SKILL.md)

### anthropics/claude-code — `plugins/plugin-dev/skills/skill-development/SKILL.md`

- **Architecture:** Anthropic's own prescription to third-party plugin authors. Mandates `## Additional Resources` footer with `### Reference Files` + `### Examples` subsections.
- **Key decision:** Footer is strictly FORWARD asset-pointers ("see REFERENCE.md", "see EXAMPLE.md"), never backward-citation of historical decisions or ADRs.
- **Scale:** First-party guidance for the entire Claude Code plugin ecosystem.
- **Trade-off accepted:** Authors lose a sanctioned slot for "why this rule exists" inside the skill file; spec doc says explicitly that no format restrictions exist, so authors *could* add it — they just don't.
- **Source:** [anthropics/claude-code · skill-development/SKILL.md](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/skill-development/SKILL.md)

### Anthropic platform docs — skill best-practices

- **Architecture:** Authoring guidance, not a SKILL.md. Two load-bearing prescriptions: "Don't include information that will become outdated" and "All 'when to use' info goes here [frontmatter description], not in the body." Prescribes `<details>` "Old patterns" disclosure-fence as the escape valve if legacy info MUST persist.
- **Key decision:** Explicit guidance against time-sensitive content; explicit mechanism (disclosure fence) for the rare case it's unavoidable.
- **Scale:** Canonical published guidance.
- **Trade-off accepted:** Authors trade in-file historical context for body durability across version cycles.
- **Source:** [platform.claude.com — skill best-practices](https://platform.claude.com/docs/en/claude-code/skills/best-practices)

### obra/superpowers — `test-driven-development/SKILL.md` and siblings

- **Architecture:** Heavy instructional bodies (650 lines for some siblings) with rhetorical Iron-Law / Red-Flag / Rationalization structure. `## Supporting Techniques` + `## Related skills` footer present in `systematic-debugging/SKILL.md`.
- **Key decision:** Zero version archaeology in prose even at 650 lines. One sibling (parallel-agents) carries a single opaque "From debugging session (2025-10-03)" stamp with no ticket link — characterized as outlier, not pattern.
- **Scale:** Most-popular community plugin in the Claude Code ecosystem.
- **Trade-off accepted:** Long files reach the body-ceiling band but absorb length via more rules, never via decision provenance.
- **Source:** [obra/superpowers · test-driven-development/SKILL.md](https://github.com/obra/superpowers)

### Cline + Continue + Cursor — `.clinerules` / `.continue/rules` / `.cursor` rule files

- **Architecture:** Compact behavioral rule files. Continue distribution median ~550 bytes; Cursor modal 1-3KB with a hard authoring cap of 500 lines; Copilot caps repo-wide instructions at 2 pages.
- **Key decision:** Git history is the version log; bodies stay behavioral. Cline's `general.md` is the only outlier with one inline PR reference (`#7566`); no ADR citations anywhere across 9 files sampled; zero dated incidents.
- **Scale:** Three independent vendors, 85+ rule files surveyed via distribution data.
- **Trade-off accepted:** No file-local rationale for any individual rule — readers must consult git blame or external docs.
- **Source:** [cline/.clinerules](https://github.com/cline/cline) · [continuedev/continue](https://github.com/continuedev/continue) · [Cursor docs — rules](https://docs.cursor.com/context/rules-for-ai)

---

## Patterns

### Pattern A — Zero inline decision-provenance in body prose

27 of 27 sampled SKILL.md / rule files carry zero inline ADR-NNNN-style citations, decision-record references, or "per [external authority]" stamps in body prose. The strongest signal in the extraction. Anthropic's best-practices doc states the rule explicitly: "All 'when to use' info goes here [frontmatter description], not in the body."

**Fits when:** The SKILL.md is agent-readable behavioral instructions and the provenance trail lives in a parallel system (git history, ADR index, CHANGELOG). Doesn't fit regulated/compliance contexts where inline citations are audit evidence (not sampled — see Open Questions).

### Pattern B — Zero version-archaeology in body prose

27/27. Co-occurs with Pattern A. "Added in vN.M", "v1.X+ candidate", "planned for vN.M" tags are absent across all three populations. Anthropic's authoring guidance is direct: "Don't include information that will become outdated."

**Fits when:** A separate release log (CHANGELOG.md, git tags, plugin.json version) is the canonical version record. Functionally always-fits for habeebs-skill (we ship a CHANGELOG.md + tagged releases).

### Pattern C — Zero dated incident references in body prose

26/27 clean; 1/27 outlier (obra/parallel-agents) carries a single opaque "From debugging session (2025-10-03)" with no ticket link. Across the ecosystem, incidents are converted into Rationalizations / Red Flags / "what NOT to do" clauses with calendar context stripped — the lesson stays, the date does not.

**Fits when:** Postmortems can live in a separate dedicated location (docs/agents/postmortems/) and the SKILL.md restates only the durable rule that survived the incident.

### Pattern D — Forward-only footer convention (when footers exist)

Footers are rare (Fetcher 3: 0/9 instruction files; Fetcher 2: ~3/7 Anthropic SKILL.md files; obra: 1 footer-bearing sibling). Among files that DO carry footers, 100% are forward-only — `## Reference files` / `## Additional Resources` / `## Related skills` — pointing to bundled assets, sibling skills, or examples. Never backward-citing historical decisions.

**Fits when:** The skill ships bundled references (REFERENCE.md, examples/, sibling-skill links) worth a dedicated section. If a skill has nothing to forward-point to, no footer is the norm.

### Pattern E — Body length ceiling in low-hundreds of lines

200-500 lines is the soft band for behavioral content. Hard caps: Cursor 500 lines explicit, Copilot 2 pages for repo-wide instructions, Anthropic ≤500 lines / ≤5000 tokens. Files that exceed are explicitly architecture docs (Cline overview 1050 lines, FastAPI 450 lines), not behavioral rule files. obra/superpowers stretches the band (650 lines) but absorbs length via more rules.

**Fits when:** The skill is behavioral guidance for an agent. If content exceeds, split into a sibling reference file (Pattern D forward-pointer) rather than fattening the SKILL.md.

### Pattern F — Inline cross-skill coupling via lightweight handles

Cross-skill linking happens in prose via `@sibling.md`, `[link](sibling.md)`, `/skill-name` mentions, or paragraph references — never via numbered citation. File-local schemes (FastAPI A1-A8 principle numbering) exist but never extend across documents.

**Fits when:** Always-applicable; composable with Pattern D (a footer-bearing skill can still inline-link in body prose).

**Convergence note.** Patterns A/B/C all hit 27/27 (or 26/27); no competing pattern emerged on the user's three pain categories. Mild non-exclusive composition between Patterns D and F (inline links + optional forward-only footer). Homogeneity caveat: regulated-compliance and academic-lab-notebook populations were not sampled, so the 27/27 figure is `tier-narrow` on technicality but `benign-convergence` for habeebs-skill's deployment context (OSS Claude Code plugin, no regulatory substrate).

---

## Recommendation

**For habeebs-skill v1.21.0 SKILL.md body cleanup, adopt a "behavioral-only body, provenance lives elsewhere" rule modelled on Anthropic's skill-creator + skill-development + best-practices canon.** Strip all inline ADR-NNNN citations, all "Added in vN.M" / "planned for vN.M" version tags, and all dated incident references from the bodies of the 12 affected files. Where a removed citation carried a load-bearing rule, restate the rule itself in present-tense imperative form without the citation. Where cross-skill linking matters, keep it as inline `@sibling.md` / `/skill-name` handles in prose; add a `## See also` forward-only footer only on skills where it pays for itself (multi-asset bundles, ≥3 sibling references). Postmortems and dated incidents move to a new `docs/agents/postmortems/` directory and are linked from ADRs, not from SKILL.md.

The recommendation is defensible because (a) 27/27 convergence across three independent populations is exceptionally strong, (b) the most-authoritative single source — Anthropic's own meta-skill skill-creator — exhibits the convention itself, (c) Anthropic's published best-practices doc states the rule explicitly in prescriptive language, and (d) habeebs-skill already ships the parallel substrates the convention assumes (CHANGELOG.md, ADR index, git tags). The trade-off — losing in-file "why does this rule exist" provenance — is real but cheap to recover via `git blame skills/<name>/SKILL.md` plus the ADR index.

### Concrete picks

| Decision | Choice | Reason |
|---|---|---|
| Inline ADR-NNNN citations (e.g., "per ADR-0004 Part 2") | Remove wholesale; restate the rule itself in imperative form | Pattern A — 27/27; restating preserves the rule, drops the provenance tag |
| Inline version tags ("Added in v1.7.0", "v1.8.0+ candidate") | Remove wholesale; CHANGELOG.md is the canonical version log | Pattern B — 27/27; Anthropic prescription verbatim |
| Dated incident references ("documented 2026-05-12") | Move incident narrative to `docs/agents/postmortems/<date>-<slug>.md`; restate surviving rule in body without date | Pattern C — 26/27; matches how the ecosystem converts incidents to Red Flags / Rationalizations |
| Footer convention | `## See also` forward-only; only on skills with ≥3 sibling-references or a bundled REFERENCE.md; otherwise omit | Pattern D — footers are rare and strictly forward-pointing |
| Cross-skill inline links | Keep `/skill-name` and `@sibling.md` handles in prose; don't convert to numbered cites | Pattern F — lightweight handles are the universal idiom |
| `<details>` "Old patterns" disclosure-fence | DO NOT adopt as a general escape valve; reserve for the genuinely-rare case where an old pattern must remain visible to the agent for migration guidance | Anthropic prescribes it as last-resort, not default; we have no current case requiring it |
| Length ceiling | Enforce ≤500 lines per SKILL.md; if content exceeds, split into `skills/<name>/references/*.md` and forward-point | Pattern E — Cursor + Anthropic hard cap |

### What you're explicitly giving up

- In-file "why does this rule exist" decision provenance. Recovery path: `git blame skills/<name>/SKILL.md` + `docs/agents/adrs/README.md` index.
- Discoverability of ADRs from the skill that implements them. Mitigation: ADRs already list which skills they govern in their `## Affected skills` section; the back-reference exists, just not in the SKILL.md.
- Per-skill version-introduced metadata at the rule level. Mitigation: CHANGELOG.md carries per-version skill deltas; git tag <-> commit-hash chain reconstructs introduction date for any rule.

### When to revisit

- If habeebs-skill is ever distributed into a regulated/compliance substrate (SOC2/HIPAA/FDA) where inline "(per CR-12345, effective 2026-Q2)" stamps become audit evidence rather than cruft — re-research with regulated population sampled.
- If a future ADR introduces a SKILL.md migration where the disclosure-fence escape valve becomes load-bearing (currently no such case).
- If skills routinely exceed 500 lines as a category (currently none do post-cleanup; recheck after v1.21.0 lands).

---

## Steering reconciliation

No formal steering was captured in Phase 1; the prompt itself anchored on the three cruft categories (inline ADR cites, version-history tags, dated incidents). All three anchors are honored — Patterns A, B, and C directly address them with 27/27, 27/27, and 26/27 convergence respectively.

---

## Decisions to make next

These feed `socratic-grill` and `draft-spec`:

1. **Removal vs downgrade for inline ADR cites.** Options: (a) remove wholesale and restate the rule in imperative form (recommended); (b) downgrade to a `## See also` footer entry; (c) move into a per-skill CHANGELOG.md. Recommendation: (a) for the rule itself in body, (c) for version-introduced metadata if useful. The grill should pressure-test whether any specific ADR citation in the worst-offender files (using-habeebs-skill, prior-art-research at 13 hits each) is load-bearing in a way that (a) would break.
2. **Disposition of dated incident narrative.** Recommended: create `docs/agents/postmortems/` directory; move the "2026-05-12 hooks miss" narrative and any sibling incidents; link from ADRs only, never from SKILL.md. Open: does the postmortems/ index also get an `## Affected ADRs` back-reference, mirroring ADRs' `## Affected skills` section?
3. **Footer policy threshold.** Recommended: `## See also` forward-only, present only on skills with ≥3 sibling-references or a bundled REFERENCE.md. Open: does the audit-first report enumerate which of the 18 skills cross this threshold, or does each skill make its own footer call?
4. **`<details>` "Old patterns" disclosure-fence adoption.** Recommended: DO NOT adopt as default; reserve for the rare case. Open: is there a current case (e.g., a skill mid-migration between two patterns) where it would actually pay for itself in v1.21.0?
5. **Audit-first deliverable shape.** User explicitly asked for audit-first-then-decide. The /spec phase needs to produce a line-by-line cleanup report per affected file (12 files, 69 hits) for user review BEFORE any cleanup commit. Open: report format — single markdown table sorted by file, or per-file change-list with before/after snippets?
6. **Restated-rule fidelity check.** When removing "per ADR-0013 single-writer invariant" and restating as "Only Phase 0 of prior-art-research writes SYSTEM_CONTEXT.md", the rule must remain semantically identical. Open: does the audit report include a side-by-side semantic-diff column, or is that a manual review responsibility?

## Open questions

- **Regulated-substrate generalization.** The 27/27 convergence holds across OSS Claude Code plugins, Anthropic canon, and three IDE-rules ecosystems — but NOT regulated/compliance contexts (SOC2/HIPAA/FDA/aviation/finance) where inline "(per CR-12345, effective 2026-Q2)" stamps function as audit evidence rather than cruft. habeebs-skill currently ships zero regulated substrate so the recommendation is sound for today, but a future Modie-on-regulated-codebase invocation would trigger a re-research.
- **Academic / lab-notebook precedent.** Research-code instructional files that intentionally function as a dated lab notebook were not sampled. Likely a different convention applies; out of scope for habeebs-skill's OSS-plugin shape but worth flagging.
- **Localization / translation-lag handling.** Translated SKILL.md files (none currently in habeebs-skill) often carry source-version stamps to flag translation lag. Not a current problem; flag for future i18n consideration.
- **CHANGELOG-per-skill vs single-repo CHANGELOG.md.** Currently habeebs-skill uses a single `CHANGELOG.md` at repo root. Decision 1 option (c) implies per-skill CHANGELOGs for version-introduced metadata — not researched whether peers ship per-skill CHANGELOGs (Anthropic skill-creator: no per-skill changelog; obra: no per-skill changelog). Lean: keep single repo CHANGELOG, don't fragment.
- **Auto-trigger correctness post-cleanup.** Frontmatter `description` field is the auto-trigger surface (out of scope for this research, addressed by v1.19.0). Body cleanup should be auto-trigger-neutral, but the grill should confirm no inline citation is currently load-bearing for a description-resolution edge case.

---

## Sources

1. **anthropics/skills · skill-creator/SKILL.md** — https://github.com/anthropics/skills/blob/main/skill-creator/SKILL.md
   What it gave us: The meta-skill exemplar; zero ADR/version/incident refs; `## Reference files` forward-only footer convention.
2. **anthropics/claude-code · plugins/plugin-dev/skills/skill-development/SKILL.md** — https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/skill-development/SKILL.md
   What it gave us: First-party prescription to plugin authors; `## Additional Resources` → `### Reference Files` + `### Examples` forward-only footer mandate.
3. **Anthropic platform docs — skill best-practices** — https://platform.claude.com/docs/en/claude-code/skills/best-practices
   What it gave us: Two load-bearing direct quotes ("Don't include information that will become outdated"; "All 'when to use' info goes here, not in the body") + `<details>` "Old patterns" disclosure-fence as last-resort escape valve.
4. **Anthropic platform docs — skill overview** — https://platform.claude.com/docs/en/claude-code/skills
   What it gave us: Length norm context (≤500 lines / ≤5000 tokens); confirms no mandatory header structure.
5. **agentskills.io — SKILL.md specification** — https://agentskills.io/specification
   What it gave us: Spec-level confirmation: "There are no format restrictions. Write whatever helps agents perform the task effectively."
6. **anthropics/skills · pdf, docx, claude-api SKILL.md files** — https://github.com/anthropics/skills
   What it gave us: Three additional Anthropic-canon datapoints confirming Patterns A/B/C; docx as the length outlier (~585 lines) where Anthropic bends its own cap.
7. **obra/superpowers** — https://github.com/obra/superpowers
   What it gave us: 5 SKILL.md files with Iron-Law / Red-Flag / Rationalization rhetorical structure; one outlier dated stamp (parallel-agents 2025-10-03); `## Supporting Techniques` + `## Related skills` footer exemplar.
8. **mattpocock/skills** — https://github.com/mattpocock/skills
   What it gave us: 4 terse SKILL.md files (one is 5 lines total) confirming the lower bound of viable body length; zero provenance refs.
9. **Yeachan-Heo/oh-my-claudecode** — https://github.com/Yeachan-Heo/oh-my-claudecode
   What it gave us: ai-slop-cleaner + ultraqa (mid-length 35-145 line files); third-population confirmation of Patterns A/B/C.
10. **cline/cline · .clinerules** — https://github.com/cline/cline
    What it gave us: 5 rule files; one outlier inline PR ref (#7566) in general.md; otherwise zero cites/dates/versions.
11. **continuedev/continue · .continue/rules** — https://github.com/continuedev/continue
    What it gave us: 3 sampled + distribution data across 24 total; median ~550 bytes; most files 5-50 lines; terse-outlier programming-principles.md at 11 lines total.
12. **Cursor docs + sampled rules** — https://docs.cursor.com/context/rules-for-ai
    What it gave us: Hard 500-line cap quote ("Keep rules under 500 lines"); authoring quote ("Start simple. Add rules only when you notice Agent making the same mistake repeatedly."); 52+ rule distribution 280B-16KB modal 1-3KB.
13. **GitHub Copilot — custom instructions docs** — https://docs.github.com/en/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot
    What it gave us: 2-page hard cap for repo-wide instructions; confirms behavioral-only norm.
14. **github/awesome-copilot meta-template** — https://github.com/github/awesome-copilot
    What it gave us: Only sampled artifact with explicit `## Maintenance` + `## Additional Resources` footer pattern — but it's authoring guidance about how to write rules, not a rule itself; reinforces Pattern D rarity.
15. **Aider conventions docs** — https://aider.chat/docs/usage/conventions.html
    What it gave us: Outside-CC confirmation of behavioral-rule norm; no provenance tags.

---

HANDOFF: spec ready — invoke `draft-spec` to turn this into an implementation spec for v1.21.0 SKILL.md body cleanup (12 files); audit-first per user instruction — produce line-by-line cleanup report for user review BEFORE applying any change.
HANDOFF: grill ready — invoke `socratic-grill` to pressure-test Decisions 1-6 above, especially Decision 1 (removal vs downgrade) against the worst-offender files (using-habeebs-skill, prior-art-research at 13 hits each) and Open Question 1 (regulated-substrate generalization).
HANDOFF: record ready — once spec + grill complete, invoke `decision-record` to capture the "behavioral-only body" convention as an ADR (becomes Tier 0 prior art for future authoring decisions; supersedes any prior implicit convention).
HANDOFF: archive at docs/agents/research/2026-05-25-skill-md-body-shape.md
HANDOFF: SYSTEM_CONTEXT.md drift NOT fixed in this run — will be addressed by the lead post-synthesis (drift: claims 20 ADRs, disk has 22; claims 18 skills, disk has 19; this run is NOT a SYSTEM_CONTEXT writer per ADR-0005 single-writer invariant).
