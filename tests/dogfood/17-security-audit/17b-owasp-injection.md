# Dogfood 17b — security-audit: OWASP injection

**Type:** Positive (planted vulnerability)
**Methodology phase exercised:** OWASP Top 10

---

## Target repo

A Node.js + Express API over Postgres, ~20 files. Two planted vulnerabilities in the working tree:

1. **SQL injection** — `routes/search.js`:
   ```js
   const q = `SELECT * FROM products WHERE name LIKE '%${req.query.term}%'`;
   db.query(q);
   ```
   User-controlled `req.query.term` is string-concatenated into SQL.

2. **OS command injection** — `routes/export.js`:
   ```js
   exec(`zip -r /tmp/export.zip ${req.body.dir}`);
   ```
   User-controlled `req.body.dir` is interpolated into a shell command.

## Expected audit output

**The report MUST surface, under OWASP Top 10 (A03:2021 — Injection):**

- The SQL injection in `routes/search.js` — finding cites the concatenated `req.query.term`, recommends a parameterized query (`$1` placeholder).
- The command injection in `routes/export.js` — finding cites the interpolated `req.body.dir`, recommends `execFile` with an argument array, or strict allowlist validation.
- Confidence: high for both (user input reaching a sink with no sanitization is unambiguous).

## Pass / fail

- **Pass:** both injections appear as separate findings under the Injection category, each with the file, the tainted variable, and a concrete remediation.
- **Fail (false negative):** either injection is missed.
- **Fail (vague):** findings say "validate user input" without naming the parameterized-query / `execFile` fix.

## Why this scenario

Injection is OWASP's perennial top-tier category and the clearest test of taint tracing — user input flowing to a sink. Two different sink types (SQL, shell) verify the audit reasons about data flow, not just grep for `db.query`.
