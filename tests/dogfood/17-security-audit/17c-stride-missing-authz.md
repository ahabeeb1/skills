# Dogfood 17c — security-audit: STRIDE broken access control

**Type:** Positive (planted vulnerability)
**Methodology phase exercised:** STRIDE per-component

---

## Target repo

A multi-tenant SaaS API, ~25 files. Authentication works — every route is behind a valid-session-token middleware. The planted vulnerability is in **authorization**, not authentication:

- `routes/invoices.js` — `GET /invoices/:id` loads the invoice by `:id` and returns it:
  ```js
  app.get('/invoices/:id', requireSession, async (req, res) => {
    const invoice = await db.invoices.findById(req.params.id);
    res.json(invoice);
  });
  ```
  There is no check that the invoice belongs to the requesting user's tenant. Any authenticated user can read any invoice by guessing or enumerating IDs.

## Expected audit output

**The report MUST surface, under STRIDE (Information Disclosure / Elevation of Privilege) for the invoices component:**

- An Insecure Direct Object Reference (IDOR) / broken-access-control finding on `GET /invoices/:id` — the finding must distinguish that authentication is present but **object-level authorization is absent**, and recommend an ownership/tenant check (`WHERE tenant_id = req.session.tenantId`).
- Confidence: high.

## Pass / fail

- **Pass:** the finding names the missing tenant/ownership check on the invoice lookup and correctly frames it as authorization, not authentication.
- **Fail (false negative):** the audit reports the route safe because `requireSession` is present — conflating authentication with authorization.
- **Fail (miscategorized):** the finding recommends "add authentication" when authentication already exists.

## Why this scenario

STRIDE per-component forces the audit to reason about *who can do what to which object*, not just *is there a login wall*. Broken object-level authorization is the most-shipped real-world access-control bug precisely because the route looks protected. This scenario verifies the port reasons at the component+threat granularity STRIDE demands.
