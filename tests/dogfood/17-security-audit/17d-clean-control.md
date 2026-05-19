# Dogfood 17d — security-audit: clean control (false-positive gate)

**Type:** Negative (no planted vulnerability)
**Methodology phase exercised:** Confidence-gated false-positive filter

---

## Target repo

A small, competently-written Node.js + Express + Postgres service, ~18 files:

- All SQL uses parameterized queries (`$1` placeholders).
- Every route behind session middleware; object lookups scope by `tenant_id`.
- No secrets in the working tree or in git history (`.env` is gitignored; history is clean).
- Shell calls use `execFile` with argument arrays.
- Dependencies are current; no known-vulnerable versions.

The repo is not perfect — it has ordinary code-quality smells (a long function, a TODO comment, a slightly inconsistent naming style). None of these are security vulnerabilities.

## Expected audit output

**The report MUST:**

- Conclude with **no high-confidence security findings**.
- NOT report code-quality smells (long function, TODO, naming) as security findings — those are out of scope for a security audit.
- It is acceptable to note low-confidence *observations* explicitly labelled as such (e.g., "no rate limiting on the login route — informational, not a confirmed vulnerability"), provided they are not presented as confirmed findings and do not inflate the headline result.

## Pass / fail

- **Pass:** the audit returns a clean result — zero high-confidence findings, zero code-quality issues miscategorized as security issues.
- **Fail (false positive):** the audit surfaces one or more confirmed security findings on this repo, OR presents code-quality smells as vulnerabilities, OR pads the report with low-confidence items dressed as findings to look thorough.

## Why this scenario

This is the load-bearing scenario. gstack `/cso`'s defining property is "zero-noise, high-precision findings only" — a security audit that cries wolf trains its users to ignore it, which is worse than no audit. 17d catches the failure mode where the skill, given a clean repo, manufactures findings to appear productive. The confidence gate must hold here.
