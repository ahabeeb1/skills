# ADR-0014: Adopt three gstack capabilities as markdown idea-ports; reject the runtime-coupled half

**Status:** Accepted
**Date:** 2026-05-18
**Deciders:** Modie (via the habeebs-skill chain: prior-art-research → draft-spec → socratic-grill → decision-record)

## Context

A prior-art-research run (2026-05-17, Deep mode, 19 sources) evaluated [garrytan/gstack](https://github.com/garrytan/gstack) — a 31-skill Claude Code "software factory" — to decide which of its 23+ capabilities are worth bringing into habeebs-skill. gstack is a direct comparator: also a Claude Code skill collection imposing an engineering methodology, but far broader and built on a runtime substrate (a Playwright browser daemon, GBrain knowledge-graph memory, a stateful `~/.gstack/` CLI) — exactly what ADR-0002 forbids habeebs-skill from having.

The research found gstack's value splits cleanly on a substrate test: capabilities that are a prompt over Bash/Read/Grep are portable; capabilities that need a process (browser, DB, external API, hook interception) are not. Of the portable subset, habeebs-skill has one glaring hole — no security review (`verify-output` explicitly disclaims it) — plus two worthwhile additions. The decision is needed now because the methodology is mature (v1.12.0) and these are the first capability gaps a peer project has surfaced that habeebs-skill cannot dismiss as already-covered.

## Decision

We will adopt **three** gstack capabilities, each re-implemented as a pure-markdown skill written from scratch (methodology is portable; gstack's MIT-licensed skill text is not copied):

- **`security-audit`** — a standalone slash-invokable skill (`/security-audit`) ported from gstack `/cso`, trimmed to a markdown-only core: attack-surface census, secrets archaeology over git history, OWASP Top 10, STRIDE per-component, confidence-gated false-positive filter, markdown report. Ships **v1.13.0**.
- **`release`** — a new terminal chain link after `tdd-loop`, ported from gstack `/ship` with `/document-release` doc-sync folded in. Ships **v1.14.0**. (The hook change it requires is recorded separately as ADR-0015.)
- **`devex-review`** — a conditional extension of `socratic-grill` ported from gstack `/plan-devex-review`, mirroring `agent-factors-check`; fires when the spec's product is consumed primarily by developers (CLI / SDK / library API / plugin / framework). Ships **v1.14.0**.

We will **reject gstack's entire runtime-coupled half** — the browser engine, `/qa`, `/qa-only`, `/design-review`, `/canary`, `/benchmark`, `/land-and-deploy`, `/codex` (external API), and the GBrain graph index. We will **not** add a learnings ledger (gstack `/learn`): cross-session learnings are already covered by ADRs, `postmortems/`, and the SYSTEM_CONTEXT reconciliation log.

**ADR-0002 stands unamended — and that is recorded here as an explicit finding, not a default.** The research actively looked for a runtime-coupled capability worth a revisit and found none: a markdown methodology plugin has no UI surface for the browser engine, no deploy target for canary/benchmark, and no retrieval-scale problem for the graph memory. The standalone constraint costs habeebs-skill nothing it actually needs.

Portfolio ceiling: **3 new skills, 0 new conventions** — the chain grows from 15 to 18 skills and stops there. gstack's 31-skill sprawl stays coherent only because a CLI substrate threads it; habeebs-skill must not import the sprawl without the substrate.

## Consequences

### Positive

- Closes habeebs-skill's single clearest gap — no security review existed before `security-audit`.
- Closes the chain at both ends: `release` gives `tdd-loop` a terminal link instead of a manual `gh release create`.
- `devex-review` gives habeebs-skill — itself a developer-facing product — a DX lens it lacked.
- Every adoption is substrate-free; ADR-0002 holds, no new operational surface.

### Negative / Accepted trade-offs

- No browser-driven QA or visual/design review — acceptable: habeebs-skill has no UI surface.
- No cross-model (Codex) review — only in-model adversarial passes.
- No deploy/canary/benchmark automation — `release` stops at PR + tag.
- No cross-session learnings ledger — by design; the capability is not a real gap.
- The chain is three skills heavier; the portfolio ceiling is the mitigation.

### Operational impact

- Staggered release: v1.13.0 (`security-audit` alone) then v1.14.0 (`release` + `devex-review`), isolating the hook/ADR-0015 change from the new skills.
- Three new dogfood scenarios: `tests/dogfood/17-security-audit/`, `18-release/`, `19-devex-review/`.

## Alternatives considered

### Full gstack adoption (port the runtime substrate too)

Adopt the browser engine, GBrain memory, and continuous automation. Rejected: directly violates ADR-0002, and the research found no capability whose value justifies the substrate for a markdown methodology plugin.

### Adopt nothing — gstack is just a bigger, different toolkit

Treat gstack as out of scope. Rejected: security review is a genuine, uncovered gap that `verify-output` explicitly disclaims; declining it on principle would be dogmatic.

### Also adopt a learnings ledger (gstack `/learn`)

Add a curated cross-session learnings file. Rejected during socratic-grill: it duplicates ADRs/`postmortems/`, decays without the `/learn prune` automation ADR-0002 forbids, and reverses ADR-0010's doc-weight reduction.

### Adopt the multi-role review lenses (`/plan-ceo-review`, `/plan-eng-review`, `/autoplan`)

Port gstack's role-based review topology. Rejected: redundant — scope/architecture grilling is already `socratic-grill`; the gauntlet-runner is already `groundwork`.

## Revisit triggers

This ADR should be reopened if any of:

- habeebs-skill ships a UI/dashboard surface — the gstack browser engine then becomes a real ADR-0002 revisit candidate.
- A third independent skill collection surfaces the same missing capability twice — treat as a confirmed gap regardless of this ADR.
- A destructive-command incident appears in a `postmortems/` entry — reconsider a `/careful`-style guard (deferred here).
- 3+ chain runs that, in hindsight, should have been killed before research as not-worth-building — reconsider an upstream demand-validation gate (deferred here).

## References

- Research: prior-art-research "Adopting capabilities from gstack into habeebs-skill" (2026-05-17, in-conversation Phase 6 report)
- Spec: `docs/agents/specs/v1.13.0-gstack-capability-adoption.md`
- Grill: `docs/agents/specs/v1.13.0-gstack-capability-adoption-grill.md`
- Related: ADR-0002 (standalone — no runtime substrate), ADR-0015 (the hook amendment `release` requires)
- External sources:
  - [garrytan/gstack](https://github.com/garrytan/gstack) — the evaluated skill collection (MIT); source of the adopted `/cso`, `/ship`, `/document-release`, `/plan-devex-review` patterns
  - [garrytan/gbrain](https://github.com/garrytan/gbrain) — gstack's graph-memory substrate; rejected

### Reference implementations cited

- **Security-audit methodology:** gstack [`/cso`](https://github.com/garrytan/gstack) — OWASP Top 10 + STRIDE-per-component static audit with confidence-gated false-positive filtering. Cited because `security-audit`'s trimmed core is a direct idea-port of this.

---

## Changelog

- 2026-05-18 — Initial ADR, status Proposed
- 2026-05-18 — Status → Accepted; implementation started with v1.13.0 Slice 1 (`security-audit` skill)
