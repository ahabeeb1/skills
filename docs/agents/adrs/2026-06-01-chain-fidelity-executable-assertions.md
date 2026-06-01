---
Status: Accepted
Date-Created: 2026-06-01
Last-Reviewed: 2026-06-01
Superseded-By: null
Tier: Balanced
Deciders: [Modie (Habeeb)]
---

# Encode methodology conventions as corpus-tested bash assertions

**Status:** Accepted
**Date:** 2026-06-01
**Deciders:** Modie (Habeeb)
**Tier:** Balanced

## Context

Running the chain end-to-end during the v1.23.0 implementation surfaced three recurring friction modes, each a methodology convention that depended on a human or agent remembering to follow it — with no executable guard. (1) Migration/transition archaeology kept creeping back into SKILL.md bodies ("this skill used to write `adr-<slug>.md`", "X are NOT renamed") even though [the behavioral-only-body convention](./0022-behavioral-only-skill-body.md) (ADR-0022) bans version-archaeology; the existing dogfood lints (26/27/28) catch inline ADR cites, version tags, and dated incidents, but not migration prose. (2) A spec hard-coded a dogfood scenario number (`29`) that was already taken, because nothing forced the author to confirm fixture identifiers against the live tree. (3) ADR-0020's partial supersession by [the dated-naming decision](./2026-05-28-decouple-decision-identity-from-releases.md) relied on a human correctly stating which half survived — an error-prone shape with no integrity check.

A Balanced-tier `prior-art-research` run confirmed the convergent pattern: industry encodes conventions as executable assertions that run on every change (Semgrep custom rules, commitlint, Vale prose linting, Conftest). The constraint is [no runtime substrate](./0002-habeebs-skill-standalone.md) (ADR-0002) — so the assertion mechanism must be the existing bash dogfood harness, not a new linter dependency. The decision is needed now because all three friction modes will recur every release cycle until they are mechanically guarded.

## Decision

We will encode each of the three conventions as a corpus-tested bash dogfood assertion, following the existing scenario-28 idiom (awk body-extractor excluding frontmatter / HTML-comments / footer / code-fences; `mktemp -d` fixtures; single-source-of-truth guidance string; final pass-banner). Specifically:

- **SP2 — self-referential-archaeology lint** (`tests/dogfood/34-no-migration-archaeology/`). The lint targets sentences narrating *the methodology's own evolution*, not bare verb phrases. Banned shapes require a self/skill subject: `this skill used to`, `previously (this|we)`, `was renamed`, `replaces the old <X>`, `(in|set in) vN this changed`, `formerly`, `no release step <verb>s it`, `<X> are NOT renamed`. It is blocking (joins the regression suite like 26/27/28).
- **SP3 — fixture-ID late-binding rule.** `draft-spec`, `write-plan`, and `tdd-loop` instruct that test-fixture identifiers (dogfood scenario numbers, ADR slugs, file indices) are confirm-at-implementation values, never hard-coded literals in a spec or plan; `tdd-loop` Phase 1 globs the live tree for the next free identifier before creating a fixture. Enforced by `tests/dogfood/35-fixture-id-late-binding/`.
- **SP4 — supersession-link integrity check** (`tests/dogfood/36-supersession-link-integrity/`, referenced as a release doc-sync gate). For any ADR whose status is Superseded, a forward link to the superseding record must be present; for partial supersession, both records must name which half survives.

Two findings from the grill are load-bearing and shape how these assertions are written. **First, the archaeology discriminator is the sentence subject, not the verb phrase.** A corpus test run during the grill scored the naive phrase set (`no longer`, `used to`, `replaces the old`, …) at 4 hits across the 19 live SKILL.md bodies — all 4 false positives (e.g. "a test that used to pass now fails" is present-tense behavioral prose, not archaeology). Real archaeology narrates the skill's own past; a false positive describes a domain scenario in present tense. The regex must encode subject-awareness, not phrase-matching. **Second, corpus-first is regex *design* input, not just rollout hygiene** — measuring before writing changed the lint's fundamental shape from broad to narrow. The discipline is: corpus-test before finalizing the regex, then drive live offenders to zero before the lint is allowed to block.

## Consequences

### Positive

- Three human-reliant conventions become mechanically guarded; each recurs no more.
- Zero new dependency — the assertions are bash in the existing dogfood harness, honoring ADR-0002.
- The subject-aware archaeology lint has no measured false positives on the live corpus, so it can block without a growing allowlist.
- The supersession check fills an ecosystem gap — log4brains/adr-tools link superseded ADRs but do not validate the links.
- The "corpus-first as design input" discipline is reusable for every future lint.

### Negative / Accepted trade-offs

- Each new lint widens the false-positive surface as the skill corpus grows. Mitigated by the subject-aware narrowing + the corpus-first discipline; the cost is real and accepted (revisit trigger below).
- We give up a general prose linter (Vale/CI). Rejected because it is a runtime tool ADR-0002 forbids and the bash harness already covers the need.
- SP4 fires rarely (supersession is infrequent). Accepted: the check is near-free when no Superseded status is present, and the one historical case (ADR-0020) is exactly the error mode it guards.
- The dogfood suite grows to 39 scenarios. Accepted now; the suite-as-product maintainability concern is deferred to a revisit trigger.

### Operational impact

- Three new dogfood scenarios (34/35/36) join the regression suite; 34 and 36 carry a live-corpus scan that must pass.
- The release doc-sync audit references scenario 36 as a release-time gate.
- The [Changesets version-bump machinery](./2026-05-28-decouple-decision-identity-from-releases.md) is untouched — these are additive regression guards, a MINOR bump.
- No runtime substrate change; markdown + bash only by construction.

## Alternatives considered

### Broad phrase-match lint + per-line allowlist

Keep the naive banned-phrase set and allowlist the known-good lines (like ADR-0022's HTML-comment exclusion). Rejected: the corpus test showed 4 false positives on day one with a 100% FP rate; the allowlist would grow every release and the signal would rot.

### Warn-only lint, promote to blocking later

Ship scenario 34 advisory-only for a release cycle, then promote. Rejected: the narrowed regex hits zero on the clean corpus, so there is no false-positive risk to de-risk by warning first; and an advisory lint inconsistent with its blocking siblings (26/27/28) gets ignored.

### A general prose linter (Vale) integrated into CI

Adopt the de-facto docs-as-code prose linter. Rejected: Vale is a runtime tool dependency that ADR-0002 forbids, and the bash dogfood harness already does subject-aware regex at zero new dependency.

### One ADR per convention (three ADRs)

Give SP2, SP3, SP4 separate dated ADRs. Rejected as over-ceremony: the three share one decision shape ("encode a convention as a corpus-tested bash assertion") and ship together; one ADR captures the unifying insight better than three fragments.

## Revisit triggers

This ADR should be reopened if any of:

- Scenario 34 produces >1 false positive per release cycle — re-evaluate the subject-aware regex or codify a new carve-out (mirrors ADR-0022's existing trigger).
- A third "resolve-from-target" or similar context-resolution bug appears — promote the related ADR-0003 Rule 4 amendment to a standalone hook-authoring reference.
- The dogfood suite crosses ~50 scenarios — the suite-as-product maintainability concern (rule-catalog dedup, conflict detection) becomes a real project warranting its own research.
- A future convention needs an assertion that genuinely cannot be expressed in bash regex over markdown — revisit the no-runtime-linter stance against that specific need.

## References

- Research: [`docs/agents/research/2026-06-01-v1.24.0-chain-fidelity-hardening-research.md`](../research/2026-06-01-v1.24.0-chain-fidelity-hardening-research.md)
- Spec: [`docs/agents/specs/2026-06-01-v1.24.0-chain-fidelity-hardening.md`](../specs/2026-06-01-v1.24.0-chain-fidelity-hardening.md)
- Grill: [`docs/agents/specs/2026-06-01-v1.24.0-chain-fidelity-hardening-grill.md`](../specs/2026-06-01-v1.24.0-chain-fidelity-hardening-grill.md)
- [Behavioral-only SKILL.md body](./0022-behavioral-only-skill-body.md) (ADR-0022) — the body convention SP2's lint extends.
- [habeebs-skill standalone — no runtime substrate](./0002-habeebs-skill-standalone.md) (ADR-0002) — the constraint forcing bash-over-Vale.
- [Dated artifact naming](./2026-05-28-decouple-decision-identity-from-releases.md) — the partial-supersession case SP4's check guards.
- External sources:
  - [Semgrep — Writing rules: a methodology](https://semgrep.dev/blog/2020/writing-semgrep-rules-a-methodology/) — `pattern-not` carve-outs + corpus-test-before-enable.
  - [Vale prose linter](https://vale.sh/docs) + [GitLab Vale rules](https://docs.gitlab.com/development/documentation/testing/vale/) — tense/time linting prior art (the pattern, not the tool).
  - [log4brains](https://github.com/thomvaill/log4brains) + [adr-tools](https://github.com/npryce/adr-tools) — supersession is link-but-don't-validate (the gap SP4 fills).

---

## Changelog

- 2026-06-01 — Initial ADR, status Accepted. Implementation starts in v1.24.0 slices #1-#3 per the spec.
