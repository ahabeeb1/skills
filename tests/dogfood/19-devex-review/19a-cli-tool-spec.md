# Dogfood Scenario 19a — Developer-facing CLI (positive trigger)

**Scenario type:** Positive — `devex-review` MUST trigger
**DX dimensions exercised:** D1 (onboarding), D3 (ergonomics), D4 (errors), D6 (upgrade)

---

## Spec under test (excerpt)

> **Product:** `querytool` — a CLI for querying a multi-tenant analytics database.
>
> **Commands:**
> - `querytool connect <connection-string>` — establish a connection
> - `querytool run <sql>` — run a SQL query and print results
> - `querytool export <format>` — export last query result to CSV or JSON
>
> **Installation:** `npm install -g querytool`
>
> **Authentication:** API token passed via `--token` flag or `QUERYTOOL_TOKEN` env var.
>
> **Error handling:** The tool returns a non-zero exit code on failure. Error messages are standard Node.js error objects logged to stderr.
>
> **Versioning:** Follows semver. Breaking changes in major versions.
>
> **Open questions:**
> - Should `querytool connect` persist the connection string or require it on every `run`?
> - Do we need a `--dry-run` flag?

---

## Phase 1 — Confirm trigger

**Trigger test:** "Is a developer — not an end-user — the primary consumer of this product's interface?"

**Answer from spec:** Yes. `querytool` is installed via `npm install -g` and invoked from the terminal. The primary consumers are developers querying an analytics database in their workflow. The spec describes a CLI with named commands, a flag interface, and env var configuration — all developer-facing interface surface. ✓ — developer-facing product. Run the review.

---

## Expected run output

### Phase 2 — DX dimension scores

| #  | Dimension                          | Status | Spec evidence / gap note |
|----|------------------------------------|--------|--------------------------|
| D1 | Onboarding / time-to-first-success | ~      | Install is one line (`npm install -g querytool`) but the spec doesn't define what a successful first run looks like. Does `querytool connect` produce visible output confirming the connection? What does the developer do next? |
| D2 | First-time-developer roleplay      | ✗      | Spec is silent on the beginner experience. No quickstart example. No mention of what happens if the developer runs `querytool run "SELECT 1"` without first calling `connect`. |
| D3 | API & CLI ergonomics               | ~      | Three commands are named. `connect`/`run`/`export` are consistent. But `export <format>` is ambiguous — does format go before or after a file path? Is `--output` a flag or a positional? |
| D4 | Error-message quality              | ✗      | "Standard Node.js error objects logged to stderr" is not a message format. When `connect` fails because the connection string is malformed, does the error name the invalid part? When `run` fails because the token is expired, does the error distinguish "auth failure" from "query failure"? |
| D5 | Documentation-as-experienced       | ✗      | No doc plan in the spec. No mention of a README, quickstart, or reference docs. |
| D6 | Upgrade / migration friction       | ~      | "Follows semver" is noted but the spec doesn't define what constitutes a breaking change. Is adding a required flag to `connect` breaking? Is changing `export`'s positional argument order breaking? |

### Phase 3 — Socratic questions

**Must-grill (D1, D3):**

- **[D1]** The spec says `npm install -g querytool` installs the tool. What does a developer type next? Walk through the exact three-command sequence from fresh install to a working query result, including where the connection string comes from and what output they see at each step.
- **[D3]** `querytool export <format>` — where does the export file go? Is the output path a positional argument after `<format>`, a `--output` flag, or stdout? If stdout, how does a developer pipe to a file without capturing error output too?

**Should-grill (D4, D6):**

- **[D4]** When `querytool connect` fails because the connection string is wrong, what does the error message say? Does it name the invalid field (e.g., "missing port in connection string `db://localhost/analytics`") or emit a generic Node.js stack trace?
- **[D6]** "Follows semver" — is adding a required argument to an existing command a breaking change? Is renaming `export` to `dump` a breaking change? Define what triggers a major bump so developers can assess upgrade risk before running `npm update`.

**Nice-to-grill (D2, D5 — deferred):**

- **[D2]** Deferred: address after D1 is resolved. If onboarding is explicit, D2 follows naturally.
- **[D5]** Deferred: no doc plan exists yet; add to backlog after core API is locked.

### Phase 5 — Handoff

```
HANDOFF: grilling agenda updated — 4 new questions added from devex-review.
  Must-grill: 2 questions on D1 (onboarding) and D3 (ergonomics).
  Should-grill: 2 questions on D4 (error quality) and D6 (upgrade friction).
  Deferred (Nice-to-grill): 2 questions on D2, D5 — surface only if user opts in.

  Resume socratic-grill with these questions interleaved into the existing agenda.
```

**Status:** `DONE_WITH_CONCERNS` — D4 (error-message quality) is ✗ Missing, not merely Partial. Opaque Node.js stack traces as the public error interface are a real adoption risk; recommend treating D4 as Must-grill rather than Should-grill if the user has bandwidth.

---

## Pass / fail criteria

| # | Criterion | Pass condition |
|---|---|---|
| 1 | Phase 1 trigger fires | devex-review identifies `querytool` as developer-facing and runs the review |
| 2 | All 6 dimensions scored | D1–D6 table populated; no dimension skipped without a reason |
| 3 | At least 2 questions generated | Grilling agenda receives ≥ 2 Socratic questions |
| 4 | At least 1 Must-grill question | D1 or D3 appears in Must-grill bucket |
| 5 | Questions are spec-specific | Questions name `querytool`, `connect`, `run`, `export` — not generic |
| 6 | Status is DONE or DONE_WITH_CONCERNS | Not BLOCKED or NEEDS_CONTEXT (spec is thin but scorable) |
| 7 | Control returns to socratic-grill | HANDOFF line is present; skill does not absorb the grilling itself |
