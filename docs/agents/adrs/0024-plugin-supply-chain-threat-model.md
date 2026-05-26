---
Status: Accepted
Date-Created: 2026-05-26
Last-Reviewed: 2026-05-26
Superseded-By: null
Tier: Deep
Deciders: Modie (Habeeb)
---

# ADR: Acknowledge plugin supply-chain threat-model gap; defer hardening to v1.23.0+

**Status:** Accepted
**Date:** 2026-05-26
**Deciders:** Modie (Habeeb)
**Tier:** Deep

> Note: This ADR is filed as `adr-plugin-supply-chain-threat-model.md` (no integer prefix) per the late-binding convention adopted by [ADR-0020](./0020-late-binding-and-changesets.md). The `release` skill assigns the next sequential integer + renames at v1.22.0 release time.

> Note: Status is **Accepted**, not Proposed. The deferral IS the decision. Acknowledging a gap and naming concrete research targets is shipped methodology, not a placeholder.

## Context

habeebs-skill ships as a Claude Code plugin that installs four shell hooks on every user's machine (per `hooks/hooks.json` v1.21.0):

- `SessionStart` × 2 — ghost-commit detection + cross-session peer-scan
- `PreToolUse[Bash]` — block commits to default branch
- `PreToolUse[Edit|Write|NotebookEdit]` — peer-scan

The v1.22.0 methodology bundle (this release's [`adr-methodology-bundle-v1.22.md`](./adr-methodology-bundle-v1.22.md) Piece 3) adds a fifth: `PostToolUse[Edit|Write|NotebookEdit]` chain-state validator. These hooks execute with the user's full shell privileges on every applicable Claude Code tool invocation.

The Deep-tier prior-art-research run (archived at [`docs/agents/research/2026-05-26-v1.22.0-methodology-overhaul-research.md`](../research/2026-05-26-v1.22.0-methodology-overhaul-research.md) § SP6) was scoped to surface what Anthropic and peer plugins document about plugin-marketplace threat models, hook provenance, untrusted-input boundaries, and supply-chain hygiene. The category-completeness-critic flagged this sub-problem for extra scrutiny because the Claude Code plugin ecosystem is less than one year old and threat-model documentation might be thin.

**The research findings, verbatim:**

- **Anthropic's official hooks reference** ([code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks)) documents 31 hook events and the JSON contract. It documents no threat model. No provenance verification scheme. No untrusted-input boundary for hooks that read repo files. The only governance primitive shipped is enterprise-only `allowManagedHooksOnly` which blocks user-installed hooks entirely.
- **Anthropic's plugins announcement blog** ([claude.com/blog/claude-code-plugins](https://claude.com/blog/claude-code-plugins)) names no security framing whatsoever. The absence is the finding — plugin distribution prioritizes ease-of-install over verification.
- **The Shai-Hulud npm worm** (Palo Alto Unit 42 report) demonstrates the threat shape is actual, not theoretical. The worm escalated from `post-install` hook (September 2025) to `pre-install` hook (November 2025 "2.0") to the "Mini" variant (May 2026). Approximately 350 maintainer accounts compromised across the cycle; 170+ npm packages plus 2 PyPI packages affected in the May 2026 variant alone; 404 malicious versions published. Quote from the report explaining the pre-install escalation: "bypassed static code analysis tools and guaranteed execution on virtually every build system." Claude Code plugin hooks have identical execution semantics — they run on the user's machine when the tool fires, before any user gating.
- **Trail of Bits' `skills-curated` marketplace** ([github.com/trailofbits/skills-curated](https://github.com/trailofbits/skills-curated)) explicitly admits, in its README, that "published skills have been found with backdoors" — incidents documented in the Claude Code plugin ecosystem specifically. ToB's mitigation is human review by ToB staff. There is no cryptographic provenance, no signature verification, no SHA pinning at install time.
- **The community has already noticed the gap.** `slavaspitsyn/claude-code-security-hooks` exists as a seven-layer defensive hook bundle authored by an independent contributor specifically BECAUSE Anthropic guidance is absent. Its core principle: "If the AI is compromised, it cannot disable its own guardrails."
- **OWASP CICD-SEC-8 (Ungoverned Usage of 3rd Party Services)** is the closest analogous framework. It names the third-party-plugin attack surface category and recommends scoping + ingress/egress filters, but punts on mechanism — "marketplace apps, plugins, OAuth applications" are all listed without prescriptive signature/pinning guidance. Direct quote: "Organizations are only as secure as the 3rd parties they implement."

This decision is needed now because v1.22.0 adds a fifth hook (Piece 3 PostToolUse validator) — every new hook is a new attack surface, and the methodology should acknowledge the gap before adding more surface. Deferring would mean the methodology bundle ships without confronting the implicit trust model habeebs-skill carries.

Existing partial defenses live in [ADR-0003](./0003-hooks-scope.md) (hooks must be warn-only OR block-only, stateless, multi-harness aware, never own state) and [ADR-0004 Part 5](./0004-parallel-subagent-dispatch-contract.md) (fetched web content is treated as untrusted in subagent dispatches). Both address hook-internals discipline but not hook-script provenance or marketplace verification.

## Decision

We will land a methodology ADR that:

1. **Names the gap explicitly.** habeebs-skill v1.22.0 ships five hooks executing with user privileges and inherits the Anthropic-plugin-ecosystem implicit trust model: "install from the repo you trust, run with the privileges you grant." There is no signature verification. There is no hook sandboxing. There is no marker for file content read by hooks being treated as data versus code-evaluatable strings.

2. **Cites OWASP CICD-SEC-8 as the upstream framing.** Third-party-plugin attack surface — the same category as GitHub Actions marketplace risks, npm install hooks, VS Code extension marketplace incidents. The category exists in published security literature even if the specifically-Claude-Code threat model does not.

3. **Cites Shai-Hulud as evidence the threat is actual.** The September 2025 → May 2026 escalation cadence is the public-record proof that hook-execution attack surfaces are actively exploited in adjacent ecosystems. Trail of Bits' "backdoors have been found" statement is the public-record proof that the Claude Code plugin ecosystem specifically has experienced compromises.

4. **Inherits existing partial defenses.** ADR-0003 (hook scope) and ADR-0004 Part 5 (untrusted-content rule for subagent dispatches) are the strongest hook-internals discipline habeebs-skill currently carries. Neither addresses provenance or marketplace verification; both reduce blast radius if a hook IS compromised.

5. **Defers hardening to v1.23.0+ with three concrete research targets:**

   - **Signature verification for hook scripts.** Research target: when (or if) `anthropics/claude-code-plugins` ships a marketplace signature-verification primitive, habeebs-skill adopts it. Until then, there is no primitive to verify against — we cannot invent crypto in isolation.
   - **Hook sandboxing.** Research target: container isolation (Docker, nsjail, bwrap) for hook execution, opt-in via plugin manifest. Substrate-coupling risk — must respect [ADR-0002](./0002-habeebs-skill-standalone.md) (no runtime substrate). Research must surface whether opt-in sandboxing is achievable via existing harness primitives or requires a new dependency.
   - **File-content-as-data marker.** Research target: a documented convention for hooks that read repo files — file content must be treated as data, never `eval`'d or interpolated into shell commands. Audit habeebs-skill's five hooks against this rule; v1.22.0 Piece 3 PostToolUse validator follows it by construction (reads frontmatter for `Status:` field, never executes file content), but the convention should be codified before more hooks ship.

6. **Records the deferral as the decision.** Status: Accepted. The methodology DECIDES not to invent crypto in v1.22.0; the methodology DECIDES to acknowledge the gap publicly via this ADR; the methodology DECIDES to name three research targets for v1.23.0+. These are three explicit yes-decisions, not a postponement.

This dogfoods the v1.22.0 Piece 5 telemetry frontmatter: `Status: Accepted`, `Last-Reviewed: 2026-05-26`, `Superseded-By: null`. When v1.23.0+ research lands the first concrete hardening, this ADR's `Superseded-By:` field points at the successor ADR; this ADR's Status becomes `Superseded by ADR-NNNN`.

## Consequences

### Positive

- **Honest acknowledgment of what habeebs-skill can and cannot defend.** Users installing habeebs-skill v1.22.0 see this ADR and know the implicit trust model. Methodology shipped opaquely would be worse than methodology shipped with a named gap.
- **Positions for future hardening.** The three research targets are concrete enough to act on when the ecosystem matures. If Anthropic ships a marketplace signature primitive in 2026, habeebs-skill adopts it via a v1.23.0+ ADR that supersedes this one.
- **Respects ADR-0002 (standalone, no runtime substrate).** No daemon, no MCP server, no external service introduced. The ADR itself is markdown.
- **Reduces blast radius of any compromise** via existing ADR-0003 + ADR-0004 Part 5 partial defenses, named explicitly here.
- **Documents the ecosystem state.** Future habeebs-skill contributors (and adjacent plugin authors) inherit a research-backed survey of what Anthropic, peers, and OWASP say about plugin supply-chain — the absence of guidance is now documented, not just implicit.

### Negative / Accepted trade-offs

- **Hooks remain unsigned and unsandboxed in v1.22.0.** Five shell scripts execute with user privileges on every applicable Claude Code tool invocation. A compromised habeebs-skill repo (account takeover, dependency hijack) could ship hooks that exfiltrate session data, credentials, or repository contents. There is no in-band mitigation for this in v1.22.0.
- **User trust model is implicit.** "Install habeebs-skill from `ahabeeb1/skills` because you trust ahabeeb1" is the de facto contract. There is no out-of-band verification (PGP signing, hash pinning, transparency log) habeebs-skill participates in.
- **Ecosystem-wide compromise of Claude Code marketplace would affect habeebs-skill users.** If Anthropic's plugin distribution mechanism itself is compromised (analogous to npm's Shai-Hulud route), habeebs-skill has no defense beyond Anthropic's own incident response. This is true of every plugin in the ecosystem today; habeebs-skill is not differentially exposed but is not differentially protected either.
- **Documenting a gap without filling it can read as security theater.** This ADR is honest about that risk. The mitigation is the concrete research targets and the explicit revisit triggers — this is not a one-time acknowledgment; it is the start of an iterative hardening track.

### Operational impact

- **No runtime changes.** habeebs-skill v1.22.0 ships with the same hook count + 1 (PostToolUse validator). No new dependencies. No new build steps.
- **No CI changes.** All dogfood scenarios pass; no security scanner introduced.
- **Distribution unchanged.** Install via `/plugin marketplace add ahabeeb1/skills` works identically; trust ceremony unchanged.
- **PR review burden lightly increased.** Reviewers of v1.23.0+ ADRs are expected to check whether they trigger this ADR's revisit conditions; reasonable since most ADR PRs already touch one ADR.

## Alternatives considered

### Ship hooks-as-mitigation (slavaspitsyn pattern)

Adopt or fork `slavaspitsyn/claude-code-security-hooks`' seven-layer defensive hook bundle — block reads of `~/.ssh`, `~/.aws`, `~/.config/gcloud`; enforce "AI cannot disable its own guardrails" by running guards in PreToolUse before Claude can countermand. Rejected because the seven-layer bundle requires a substantial new hook surface (each layer is a hook) that habeebs-skill doesn't currently own, AND because adopting a community defensive bundle does not address the upstream gap — it patches symptoms (block bad reads) without addressing causes (untrusted hook execution itself). The user could install slavaspitsyn's bundle independently if they want layered defense; habeebs-skill's job is not to bundle competing security models.

### Invent a signature verification scheme in v1.22.0

Define a SHA pinning convention or PGP-signed manifest for habeebs-skill releases, requiring users to verify signatures at install time. Rejected because the Anthropic plugin ecosystem doesn't yet have a primitive to verify against — there is no marketplace signature scheme to align with, no transparency log to publish to, no canonical signing key infrastructure. habeebs-skill inventing a scheme in isolation would create user friction (manual signature verification) without providing meaningful defense against the realistic threat (account takeover at GitHub, where the published artifact lives anyway). When/if Anthropic ships marketplace verification, habeebs-skill adopts it — that's the v1.23.0+ research target.

### Wait silently — defer the ADR

Don't write an ADR until habeebs-skill has a concrete hardening to ship. Rejected because the gap is real today, the threat is documented today (Shai-Hulud, Trail of Bits' backdoor admission), and writing this ADR is itself the v1.22.0 work — it costs little, it documents the state of the world for future contributors and researchers, and it positions the v1.23.0+ research with concrete targets instead of "we should look at security someday."

### Adopt OWASP CICD-SEC-8 mitigations verbatim

OWASP CICD-SEC-8 recommends scoping + ingress/egress filters + integration-method controls for third-party plugins. Rejected as immediately actionable because the OWASP guidance is CI-pipeline-shaped (network egress filters, OAuth scope controls) and habeebs-skill is a user-machine plugin with no CI pipeline of its own to scope. The framing is borrowed; the specific mitigations don't transfer directly. Future research targets may adapt them.

## Revisit triggers

This ADR should be reopened — and a new ADR likely written to supersede it — if any of:

- **Anthropic ships a signature-verification primitive in the Claude Code marketplace.** Action: research the primitive's contract, draft a v1.23.0+ ADR adopting it, set this ADR's `Superseded-By:` field to the successor.
- **habeebs-skill exceeds a meaningful adoption threshold.** Quantitative trigger: if Anthropic publishes plugin install counts and habeebs-skill exceeds 100 installs per month, the methodology graduates from "single-author OSS, implicit trust" to "small-scale distribution, explicit trust ceremony required." Action: prioritize the hardening research targets in v1.23.0 or v1.24.0.
- **Claude Code marketplace hits a documented compromise.** Action: emergency v1.23.0 hardening — promote the deferred research targets from "v1.23.0+ candidate" to "v1.23.0 critical." Audit habeebs-skill's hooks for compromise, communicate via CHANGELOG + GitHub release notes.
- **A second Claude Code plugin in the broader ecosystem is found with a backdoor.** Trail of Bits already documents one such finding; a second would signal a pattern rather than an isolated incident. Action: research target #3 (file-content-as-data marker) becomes load-bearing — codify the convention; audit habeebs-skill's hooks.
- **OWASP publishes Claude-Code-specific or AI-plugin-specific guidance.** Action: reconcile this ADR's framing with the new authoritative guidance; supersede if substantial.
- **A user reports a security concern about habeebs-skill specifically.** Action: invoke `/security-audit` skill on the relevant surface; if confirmed, emergency hardening + this ADR superseded.
- **Hook count exceeds 10.** v1.22.0 ships 5 hooks; if growth continues past 10, the per-hook threat surface aggregates faster than the partial defenses scale. Action: research hook sandboxing (target #2) seriously, not just as a deferred candidate.

## References

- Research: [`docs/agents/research/2026-05-26-v1.22.0-methodology-overhaul-research.md`](../research/2026-05-26-v1.22.0-methodology-overhaul-research.md) § SP6 — six sources surveyed; "absence of guidance" is the dominant finding.
- Spec: [`docs/agents/specs/v1.22.0-methodology-overhaul.md`](../specs/v1.22.0-methodology-overhaul.md) Piece 6 — deferred-hardening ADR scope.
- Grill: [`docs/agents/specs/v1.22.0-methodology-overhaul-grill.md`](../specs/v1.22.0-methodology-overhaul-grill.md) — Piece 6 was not load-bearing-ambiguous; no OQs grilled here, but the grill confirmed the deferral framing is honest.
- Sibling ADR (this release): [`adr-methodology-bundle-v1.22.md`](./adr-methodology-bundle-v1.22.md) — adds the fifth hook (Piece 3 PostToolUse validator) that motivates the timing of this ADR.
- ADR-0002: [`0002-habeebs-skill-standalone.md`](./0002-habeebs-skill-standalone.md) — markdown-only constraint that rules out runtime-substrate mitigations in v1.22.0.
- ADR-0003: [`0003-hooks-scope.md`](./0003-hooks-scope.md) — inherited as partial defense (warn/block-only, stateless, multi-harness aware).
- ADR-0004: [`0004-parallel-subagent-dispatch-contract.md`](./0004-parallel-subagent-dispatch-contract.md) — Part 5 untrusted-content rule for subagent dispatches; inherited as partial defense for hook content boundaries.
- ADR-0020: [`0020-late-binding-and-changesets.md`](./0020-late-binding-and-changesets.md) — this ADR uses `adr-*.md` filename per late-binding.

### External sources cited

- [Anthropic Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) — 31 hook events documented; no threat model.
- [Anthropic Claude Code Plugins announcement](https://claude.com/blog/claude-code-plugins) — distribution mechanism without security framing.
- [Palo Alto Unit 42 — Shai-Hulud npm supply-chain attack report](https://unit42.paloaltonetworks.com/npm-supply-chain-attack/) — September 2025 → May 2026 escalation; ~350 compromised maintainer accounts; 170+ packages in the May 2026 Mini variant.
- [Trail of Bits skills-curated](https://github.com/trailofbits/skills-curated) — "published skills have been found with backdoors"; human-review-as-mitigation.
- [slavaspitsyn/claude-code-security-hooks](https://github.com/slavaspitsyn/claude-code-security-hooks) — community defensive hook bundle filling the Anthropic-guidance gap.
- [OWASP CICD-SEC-8 — Ungoverned Usage of 3rd Party Services](https://owasp.org/www-project-top-10-ci-cd-security-risks/CICD-SEC-08-Ungoverned-Usage-of-3rd-Party-Services) — closest analogue framework for third-party-plugin attack surfaces.
- [obra/superpowers-marketplace](https://github.com/obra/superpowers-marketplace) — peer marketplace with no documented threat model; reputation-based trust.

---

## Changelog

- 2026-05-26 — Initial ADR, status Accepted (the deferral IS the decision; not Proposed). Will be renamed to `NNNN-plugin-supply-chain-threat-model.md` at v1.22.0 release time by `skills/release/scripts/assign-adr-ids.sh` per ADR-0020 late-binding convention.
