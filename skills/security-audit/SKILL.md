---
name: security-audit
description: Static security audit of a repo or diff — attack-surface census, secrets archaeology, OWASP Top 10, STRIDE threat model. Use when user says "security review", "audit this", "check for vulnerabilities", "threat model this", or before shipping a security-sensitive feature. Do not use as a substitute for a live penetration test.
---

# Security Audit

**NO FINDING WITHOUT CODE-TRACED EVIDENCE. NEVER CRY WOLF.**

A static, substrate-free security audit. Reads source and git history, models the threat surface, and emits a markdown report of **confirmed, code-traced findings** — nothing else. The defining property is precision: a security audit that cries wolf trains its readers to ignore it.

This is a standalone skill, invoked on demand via `/security-audit`. It is not a chain phase. It runs on any repo — it does not require habeebs-skill setup or `docs/agents/SYSTEM_CONTEXT.md`.

It is **not** a penetration test, **not** a live/dynamic scan, and **not** a dependency-CVE scanner — see [Scope boundary](#scope-boundary).

## When to use this skill

**Trigger on:**

- The user says "security review", "audit for vulnerabilities", "check for security issues", "threat model this", or "is this safe to ship"
- A security-sensitive feature (auth, payments, file upload, user input, multi-tenant data) is about to ship
- The user explicitly invokes `/security-audit`

**Do NOT trigger on:**

- Pre-implementation design review (use [`socratic-grill`](../socratic-grill/SKILL.md))
- Refactor / module-shape concerns (use [`deep-modules`](../deep-modules/SKILL.md))
- Generic anti-slop review of a diff (use [`verify-output`](../verify-output/SKILL.md))
- A request for a professional penetration test or a live dynamic scan — this skill is static analysis; say so and recommend a real pentest

## Core workflow

### Pre-flight — Scope

Confirm the audit target with the user if ambiguous: a whole repo, or a single diff/branch. Default to the whole working tree plus git history.

If `docs/agents/SYSTEM_CONTEXT.md` exists, read it for stack context — it sharpens the census. If it is absent, proceed anyway; this skill does not depend on it.

The five phases below are the audit. Full per-phase procedure is in [`references/audit-methodology.md`](references/audit-methodology.md); the report shape is in [`references/report-template.md`](references/report-template.md).

### Phase 1 — Attack-surface census

Enumerate every point where untrusted input enters the system: HTTP routes and their parameters, CLI arguments, file/upload inputs, environment variables, deserialization sites, message-queue consumers, and outbound calls to external services. Group them into components. This census is the spine — Phases 3 and 4 walk it.

### Phase 2 — Secrets archaeology

Scan for committed credentials in **both the working tree and git history**. A secret deleted from the working tree but still reachable via `git log -p` is still live. Probe history:

```bash
git log -p --all -S 'sk_' -- . | head -200   # repeat for likely prefixes / patterns
git log --all --diff-filter=D -p -- '*.env*' '*config*'
```

Look for high-signal patterns: `sk_live_`, `AKIA…` (AWS), `-----BEGIN … PRIVATE KEY-----`, `xox[bap]-` (Slack), connection strings with inline passwords, long base64/hex literals assigned to key-shaped names. For any hit in history, the remediation is **rotate the credential** — deletion is not remediation.

### Phase 3 — OWASP Top 10 pass

Walk the OWASP Top 10 (2021). For each category, taint-trace: does untrusted input from the Phase 1 census reach a dangerous sink without sanitization? The highest-yield categories: A01 Broken Access Control, A02 Cryptographic Failures, A03 Injection (SQL, OS command, NoSQL, template), A05 Security Misconfiguration, A08 Software/Data Integrity. Cite the tainted variable and the sink, not just the file.

### Phase 4 — STRIDE per-component

For each component from the census, walk the six STRIDE threats: Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege. The highest-yield question: for every object lookup, is there **object-level authorization**, not just authentication? A route behind a login wall that returns any record by ID is broken access control (IDOR) even though it looks protected.

### Phase 5 — Confidence gate (false-positive filter)

Every candidate finding gets a confidence rating, and must be **code-traced** before it is reported:

| Confidence | Bar | Goes in report as |
|---|---|---|
| **High** | Untrusted input provably reaches a sink with no mitigation; or an unambiguous secret pattern | Confirmed finding |
| **Medium** | A real weakness, but exploitability depends on context the audit can't fully confirm | Confirmed finding |
| **Low** | A hardening suggestion or unconfirmed concern | Observation — explicitly labelled, NOT a finding |

Drop anything below Low. **Never report a code-quality smell (long function, TODO, naming) as a security finding.** If the repo is clean, the correct report has zero confirmed findings — say so plainly. Padding the report to look thorough is the failure mode this gate exists to prevent.

### Phase 6 — Emit the report

Write the markdown report per [`references/report-template.md`](references/report-template.md). The headline count is **confirmed findings only** (High + Medium). Low-confidence items live in a separate, clearly-labelled Observations section and never inflate the headline.

## Scope boundary

This trimmed port deliberately does NOT cover:

- **Dynamic / live testing** — no requests against a running system; static analysis only.
- **Denial-of-service, race conditions, memory-safety** — excluded to keep the signal high.
- **Dependency CVE scanning** — that is `npm audit` / `pip-audit` / Dependabot's job; mention it, don't reproduce it.
- **CI/CD and cloud-infra configuration** — out of the substrate-free core.
- **Cross-run trend tracking** — each audit is self-contained; no persisted baseline.

State this boundary in the report. The audit is not a substitute for a professional penetration test.

## Anti-patterns this skill guards against

If you find yourself thinking the left column, STOP — the right column is the reality.

| Thought | Reality |
|---|---|
| "Auditing the working tree is enough." | Secrets and removed-but-reachable code live in history. Phase 2 is not optional. |
| "There's a login wall, so access is controlled." | Authentication isn't authorization. Phase 4 reasons about who can touch which object. |
| "A short report looks lazy — I'll add findings." | A clean repo produces a clean report. Inventing findings destroys the skill's value. |
| "'Validate user input' is a fine remediation." | Name the parameterized query, the `execFile` argument array, the ownership check. |
| "This code smell is a vulnerability." | Style and module shape are `deep-modules`' domain, not security. |

## See also

- [`verify-output`](../verify-output/SKILL.md) — adjacent; anti-slop diff review, explicitly NOT a security pass — this skill is that pass
- [`socratic-grill`](../socratic-grill/SKILL.md) — pre-implementation design review; security-audit is post-implementation
- [`systematic-debugging`](../systematic-debugging/SKILL.md) — if the audit surfaces a finding that needs a reproduction to confirm
- [`references/audit-methodology.md`](references/audit-methodology.md) — full per-phase procedure
- [`references/report-template.md`](references/report-template.md) — the markdown report format
