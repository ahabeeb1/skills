# Dogfood 17 — `security-audit` skill (4-scenario adversarial suite)

**Date:** 2026-05-18
**Skill under test:** `skills/security-audit/SKILL.md`
**Slice:** v1.13.0 #1 (gstack-capability-adoption spec)
**Spec:** [`docs/agents/specs/v1.13.0-gstack-capability-adoption.md`](../../../docs/agents/specs/v1.13.0-gstack-capability-adoption.md) Slice 1
**ADR:** [ADR-0014](../../../docs/agents/adrs/0014-adopt-gstack-capabilities-markdown-idea-port.md)

## Why a directory, not a single file

`security-audit` is a markdown-only port of gstack `/cso`, trimmed to a substrate-free core: attack-surface census, secrets archaeology over git history, OWASP Top 10, STRIDE per-component, and a confidence-gated false-positive filter. A single-scenario dogfood would let the skill pattern-match one planted vulnerability shape rather than exercise the methodology. **Four scenarios — three positive (planted vulnerability) and one negative (clean control) — make the test adversarial**: the audit must surface real findings AND must not hallucinate findings that aren't there. The negative control (17d) is load-bearing: gstack `/cso`'s defining feature is "zero-noise, high-precision findings only", and a security skill that cries wolf is worse than none.

## The scenarios

| File | Type | Methodology phase exercised | Expected verdict |
|---|---|---|---|
| [17a-secrets-in-git-history.md](./17a-secrets-in-git-history.md) | Positive | Secrets archaeology (git history) | Surfaces the leaked credential still live in history |
| [17b-owasp-injection.md](./17b-owasp-injection.md) | Positive | OWASP Top 10 | Surfaces SQL injection + command injection |
| [17c-stride-missing-authz.md](./17c-stride-missing-authz.md) | Positive | STRIDE per-component | Surfaces broken access control (IDOR) |
| [17d-clean-control.md](./17d-clean-control.md) | **Negative** (false-positive gate) | Confidence-gated false-positive filter | Reports no high-confidence findings; zero hallucinations |

## Acceptance bar

Slice 1 is not complete unless all four scenarios produce the expected verdict against `skills/security-audit/SKILL.md`. 17d is the load-bearing scenario — it catches a low-precision audit that pads findings to look thorough. 17a is the scenario most likely to be missed by a naive "read the working tree" audit, because the leaked secret is no longer in the working tree — only in history.

## How to run

These are illustrative scenarios, not automated tests (consistent with dogfood 09). Run each manually:

1. Set up (or mentally model) the scenario's described target repo.
2. Invoke `/security-audit` against it.
3. Inspect the skill's markdown report against the scenario's "Expected audit output".
4. Pass / fail per the scenario's "Pass / fail" section.

## Revisit triggers

- A real-world vulnerability class is missed post-merge — add it as a new scenario (17e, 17f).
- 17d false-positive control fails (audit invents findings) — tune the confidence gate; the zero-noise rule is load-bearing.
- All four pass too easily across 3+ unrelated target repos (>30 days post-merge) — the skill may be pattern-matching scenario structure; add fresh adversarial targets.
