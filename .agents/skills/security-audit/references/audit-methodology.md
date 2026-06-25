# Security-audit methodology — per-phase procedure

The full procedure behind the five audit phases in `SKILL.md`. Read this when running an audit; `SKILL.md` is the summary, this is the detail.

The audit is **static**: it reads source, configuration, and git history. It never sends a request to a running system. Every finding must be traceable to a specific line, file, or commit.

## Phase 1 — Attack-surface census

Build the map first; the later phases walk it. Enumerate, by reading the code:

- **HTTP / RPC entry points** — every route, its method, its path/query/body parameters, the middleware chain in front of it.
- **CLI entry points** — argument and flag parsing; anything that reaches `exec`/`spawn`/`system`.
- **File and upload inputs** — multipart uploads, file reads driven by user-supplied paths, archive extraction.
- **Environment and config** — env vars, config files, feature flags that change a trust decision.
- **Deserialization** — JSON/YAML/XML/pickle parsing of untrusted bytes; prototype-pollution-prone merges.
- **Message consumers** — queue/stream/webhook handlers; their payloads are untrusted input too.
- **Outbound calls** — external APIs, SSRF-reachable URL fetches, database connections.

Group entry points into **components** (e.g. "invoices API", "auth", "file export"). Note for each component what trust boundary it sits on. Output: a bulleted component list — this becomes the report's Attack-surface section and the iteration target for Phases 3–4.

## Phase 2 — Secrets archaeology

Two passes — working tree, then history.

**Working tree:** grep tracked files for credential-shaped literals. Skip `.gitignore`d paths.

**Git history (the load-bearing pass):** a secret committed and later "removed" is still live for anyone with clone access. Probe:

```bash
git log -p --all -S '<pattern>' -- .          # pickaxe: commits that added/removed the pattern
git log --all --diff-filter=D -p -- '*.env*' '*secret*' '*config*'   # deleted sensitive files
git log --all --oneline -- '*.pem' '*.key' '*.p12'                   # key material ever committed
```

High-signal patterns:

| Pattern | Indicates |
|---|---|
| `sk_live_…`, `sk_test_…` | Stripe secret key |
| `AKIA…` + a 40-char secret nearby | AWS access key pair |
| `-----BEGIN … PRIVATE KEY-----` | Private key material |
| `xoxb-`, `xoxp-`, `xoxa-` | Slack tokens |
| `ghp_`, `github_pat_` | GitHub tokens |
| `postgres://user:password@…`, `mongodb+srv://…:…@` | Connection string with inline password |
| long base64/hex literal assigned to a `*_KEY`, `*_SECRET`, `*_TOKEN` name | Generic credential |

For every hit, record the commit SHA, the file, and whether it is still in the working tree. **Remediation is always: rotate the credential**, then remove from history if feasible (`git filter-repo`). "Deleted in a later commit" is explicitly NOT remediation — call that out.

## Phase 3 — OWASP Top 10 pass

Walk the OWASP Top 10 (2021). For each category, ask: does an entry point from the Phase 1 census reach a dangerous sink without a mitigation in between? Trace the taint — name the variable, the path, the sink.

| # | Category | What to trace |
|---|---|---|
| A01 | Broken Access Control | Object lookups by user-supplied ID without an ownership/tenant check; missing role checks; path traversal |
| A02 | Cryptographic Failures | Plaintext secrets, weak hashing (MD5/SHA1 for passwords), missing TLS, hardcoded IVs/keys |
| A03 | Injection | User input concatenated into SQL, shell, NoSQL queries, template strings, `eval` |
| A04 | Insecure Design | Missing rate limits on auth, no lockout, trust placed in client-supplied values |
| A05 | Security Misconfiguration | Debug mode in prod, permissive CORS (`*` with credentials), default credentials, verbose errors |
| A06 | Vulnerable Components | Note the need for a dependency scan; do not reproduce one (out of scope) |
| A07 | Identification & Auth Failures | Weak session handling, missing MFA on sensitive ops, predictable tokens |
| A08 | Software/Data Integrity Failures | Unsigned updates, untrusted deserialization, CI consuming unpinned inputs |
| A09 | Logging & Monitoring Failures | Sensitive data in logs; absence of an audit trail on security-relevant actions |
| A10 | SSRF | User-controlled URLs fetched server-side without an allowlist |

A03 and A01 are the highest-yield in practice. For injection, distinguish sink types — a parameterized query fixes SQL injection; `execFile` with an argument array fixes command injection; they are not interchangeable advice.

## Phase 4 — STRIDE per-component

For each component from the Phase 1 census, walk the six STRIDE threats. STRIDE catches design-level threats the OWASP checklist can miss because it forces per-component reasoning.

| Threat | Question for the component |
|---|---|
| **S**poofing | Can an actor claim an identity that isn't theirs? Is authentication enforced on every path in? |
| **T**ampering | Can data be modified in transit or at rest by someone who shouldn't? |
| **R**epudiation | Can a security-relevant action be denied later because nothing recorded it? |
| **I**nformation disclosure | Can data leak to a party not authorized for it? **Check object-level authorization on every lookup.** |
| **D**enial of service | (Note only — depth is out of the trimmed-core scope.) |
| **E**levation of privilege | Can a low-privilege actor gain higher privilege? Missing role/tenant checks on a privileged route? |

The single highest-yield STRIDE check: **authentication is not authorization.** A route behind a valid-session middleware that loads `findById(req.params.id)` and returns it — with no check that the object belongs to the caller's tenant/user — is broken access control. It looks protected; it is not. Frame such findings as authorization gaps, and recommend the concrete scope check (`WHERE tenant_id = session.tenantId`).

## Phase 5 — Confidence gate

Before anything reaches the report, rate and code-trace it:

1. **Code-trace it.** Open the file. Confirm the taint path actually exists — no intervening sanitizer, validator, or framework escaping. An un-traced finding is a guess, and guesses are how audits lose credibility.
2. **Rate confidence** — High / Medium / Low per the table in `SKILL.md`.
3. **Filter.** High + Medium → confirmed findings. Low → Observations section, explicitly labelled as not-confirmed. Below Low → drop.
4. **Reject category errors.** A long function, a `TODO`, an inconsistent name — these are not security findings. They do not belong in the report at all.

If, after this gate, there are zero confirmed findings: that is a valid and correct outcome. Report it plainly. Do not manufacture findings to fill the template.

## Optional verifier pass

For a high-stakes audit, the lead may dispatch a single subagent to independently re-trace the confirmed findings before the report is written, guarding against anchoring bias. This is optional and additive — it does not gate the audit. (Subagent dispatch follows the ADR-0004 contract; one subagent is within bounds.)
