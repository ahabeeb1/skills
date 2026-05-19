# Security-audit report — output template

The audit emits one markdown report in this shape. The headline count is **confirmed findings only** (High + Medium confidence). Low-confidence items live in Observations and never inflate the headline.

---

# Security Audit — [target name]

**Date:** YYYY-MM-DD
**Scope:** [working tree + git history | diff <range>] — N components, M entry points
**Method:** static audit (security-audit skill) — attack-surface census, secrets archaeology, OWASP Top 10, STRIDE per-component

## Summary

[One line. E.g. "3 confirmed findings (2 high, 1 medium) — one live credential in history, two injection sinks." OR "No confirmed findings. The reviewed surface is sound." Be plain; do not hedge a clean result and do not dramatise a dirty one.]

| Confirmed findings | High | Medium |
|---|---|---|
| N | H | M |

## Attack surface

[The Phase 1 census — components and their entry points, bulleted. This is context for the findings; keep it terse.]

- **[Component]** — [entry points; trust boundary]
- ...

## Findings

[One block per confirmed finding (High + Medium only). If none, write: "No confirmed findings." and keep the section.]

### F1 — [short title] · [High | Medium]

- **Category:** [OWASP A0N <name> | STRIDE <threat> | Secret exposure]
- **Location:** `path/to/file.ext:LINE` [or commit `<sha>` for history findings]
- **What:** [the vulnerability, with the tainted variable / object / credential named]
- **Impact:** [what an attacker achieves]
- **Remediation:** [the concrete fix — the parameterized query, the `execFile` arg array, the ownership check, "rotate the credential". Never "validate input".]

### F2 — ...

## Observations (low-confidence — not confirmed findings)

[Hardening suggestions and unconfirmed concerns. Explicitly NOT findings. Omit the section entirely if there are none — do not pad it.]

- [Observation — labelled as informational]

## Scope boundary

This was a static audit. It did NOT cover: dynamic/live testing, denial-of-service, dependency CVE scanning, CI/CD or cloud-infra configuration. It is not a substitute for a professional penetration test.

[If relevant: "Run `npm audit` / `pip-audit` for dependency CVEs."]
