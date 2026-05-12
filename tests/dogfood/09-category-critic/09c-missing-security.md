# Dogfood 09c — Category critic: missing security

**Type:** Positive (planted gap)
**Planted missing category:** `Security / auth / permissions`

---

## Input to `prior-art-research`

**Feature (Phase 1 message 1):**

> Build a feature where users can upload PDFs and we extract the text + run OCR on scanned pages, then return the structured text + a summary.

**Phase 1 context (gap-fill answers):**

- Stack: Node.js 20 + Express + S3 for blob storage, single Fargate task on AWS
- Scale: Public-facing SaaS, ~10k users, ~50 uploads/hour at launch
- Constraints: must handle PDFs up to 50MB; OCR via Tesseract container; must work for both digital-native and scanned PDFs
- Existing: greenfield feature on an existing multi-tenant product
- Priorities: correctness, cost (OCR is expensive)

**No steering anchors provided.**

## Synthetic Phase 2 decomposition (input to Phase 2.5 critic)

The planner produced:

```json
{
  "proposed_decomposition": [
    "PDF text extraction (digital-native vs scanned detection)",
    "OCR pipeline (Tesseract config, layout detection)",
    "Summarization (LLM choice and prompt design)",
    "Result storage (where to put extracted text + how long to retain)"
  ]
}
```

## Expected critic output

**Verdict:** ADDITIONS PROPOSED

**Categories the critic MUST surface:**

- `Security / auth / permissions` — public-facing SaaS accepting user-uploaded files is a high-surface threat vector. The decomposition is silent on file-type validation (PDFs can carry executable payloads), tenant isolation in result storage (multi-tenant product), authn/authz on the upload endpoint, and PDF-content-driven attacks (e.g., embedded JS, oversized recursive structures, decompression bombs). Missing this category means the feature ships with at least 3 named vulnerability classes.

**Acceptable additional surfacings (bonus, not required):**

- `Cost / token budget / rate limits` — at 50 uploads/hour × OCR per page, cost is a real category, and OCR per-tenant rate limiting is a likely concern
- `Observability / metrics / alerting` — OCR failure rate, summary quality drift
- `Failure injection / chaos / resilience` — Tesseract container OOM on large PDFs

**Forbidden (would indicate hallucination):**

- `Hooks / event handlers` — N/A at this layer (this is a service feature, not a plugin)
- `Subagent / multi-agent orchestration` — overkill for a single-pipeline pass; summary uses one LLM call
- `Schema evolution / API versioning` — possibly relevant but lower-priority than security; if it surfaces, that's fine, but not a required catch

## Pass / fail

- **Pass:** `Security / auth / permissions` appears in `Proposed additions` with rationale citing user-uploaded files OR multi-tenant isolation OR specific PDF-attack vectors
- **Fail (false negative):** critic returns APPROVED
- **Fail (false positive):** critic surfaces 2+ forbidden categories above

## Why this scenario

Security is the most-skipped category in feature decomposition because it's perceived as "ops work" — surface-level decomposition focuses on the happy-path data flow and leaves auth/authz/validation to the implementation. For public-facing SaaS with user uploads, this miss has shipped real CVEs at real companies. The critic must catch it.
