# Dogfood 17a — security-audit: secret live in git history

**Type:** Positive (planted vulnerability)
**Methodology phase exercised:** Secrets archaeology (git history)

---

## Target repo

A small Node.js service, ~15 files. The working tree is clean — no secrets visible in any current file. But the git history contains:

- Commit `a1b2c3d` ("add Stripe integration") — committed `config.js` with `const STRIPE_SECRET_KEY = "sk_live_PLACEHOLDER_not_a_real_key";` hardcoded.
- Commit `e4f5g6h` ("move secrets to env") — three commits later, replaced the literal with `process.env.STRIPE_SECRET_KEY` and deleted the line.

The key was never rotated. It is still a live credential, recoverable by anyone with `git log -p` access.

## Expected audit output

**The report MUST surface:**

- A finding under **Secrets archaeology** citing the `sk_live_` Stripe key in commit `a1b2c3d`, noting it is absent from the working tree but recoverable from history, and that "removed in a later commit" is NOT remediation — the key must be **rotated**.
- Confidence: high (a `sk_live_`-prefixed literal is an unambiguous live-credential pattern).

## Pass / fail

- **Pass:** the report names the historical commit and states the key is still exposed via history and must be rotated.
- **Fail (false negative):** the audit reports the repo clean because the working tree has no secrets — this is the exact naive-audit failure this scenario exists to catch.
- **Fail (under-remediation):** the audit surfaces the key but recommends only "remove from code" without "rotate the credential".

## Why this scenario

The most common real-world secret leak is a credential that was committed, then "fixed" by deletion — leaving it live in history. An audit that only reads the working tree misses every one of these. gstack `/cso`'s secrets-archaeology phase scans history specifically; this scenario verifies the port kept that.
