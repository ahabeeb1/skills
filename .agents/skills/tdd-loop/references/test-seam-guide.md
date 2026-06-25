# Test Seam Guide — Where to put the test

The spec specifies a test seam per slice. This reference helps you pick the right one when it isn't obvious.

## The seam hierarchy

```
Manual smoke ← UI / visual
       ↑
End-to-end (E2E)   ← full stack against real-ish system
       ↑
Integration   ← multi-component, real I/O or near-real
       ↑
Unit   ← pure logic, deterministic, in-process
```

Default to the **lowest seam that still verifies the behavior you care about.** Lower seams are faster, more deterministic, easier to debug.

## Unit tests

**Use when:**
- The slice is pure logic (a function, a parser, a domain calculation)
- The behavior is deterministic given inputs
- You can test without I/O or with trivial mocks

**Examples:**
- "Calculate tax for an invoice line item"
- "Parse user input into a query object"
- "Resolve a permission grant given user + resource"

**Don't unit test:**
- Behavior whose meaning lives in the integration (e.g., "the endpoint returns 200 when authenticated" — that's the seam between auth and routing, not unit logic)

## Integration tests

**Use when:**
- The slice cuts across module boundaries (auth + DB, service + cache)
- Real I/O or near-real (in-memory SQLite, testcontainers Postgres, ephemeral HTTP server)
- The behavior depends on actual library / framework behavior, not just your code

**Examples:**
- "Hocuspocus persists Y.Doc state to Postgres on update"
- "Auth middleware rejects unauthorized requests with 401"
- "Cache invalidation propagates correctly when a record updates"

**Setup pattern:**
- Spin up real Postgres / Redis / service via testcontainers or docker-compose
- Truncate / reset between tests
- Acceptable to be slower than unit (1-2 seconds per test fine; 30 seconds is too slow)

## End-to-end (E2E) tests

**Use when:**
- The slice spans the full stack: client → API → DB → response
- Multi-user / multi-tab behavior matters
- The UI matters to the verification

**Tools:**
- Playwright / Cypress for web UIs
- Real (or test-mode) deployed environment for backend chains

**Examples:**
- "Two browser tabs editing the same doc see each other's changes within 200ms"
- "User logs in → creates a doc → reloads → sees the doc"

**Cost considerations:**
- E2E tests are slow and flaky if not careful — invest in stability
- Don't E2E what you can integration-test
- One E2E per slice's golden path is often enough

## Manual smoke tests

**Use when:**
- UI / visual behavior that's hard to assert programmatically (animations, layout)
- Behaviors with subjective acceptance ("the editor feels responsive")
- One-off verifications during a slice that wouldn't carry value as automated tests

**Always:** capture the smoke procedure in the slice's spec so it's repeatable.

## Choosing for the chain's typical slices

| Slice shape | Default seam |
|---|---|
| New pure function / domain logic | Unit |
| New API endpoint | Integration |
| New UI component | Unit (snapshot/render) + Manual smoke |
| New end-to-end user flow | E2E |
| New database table / schema | Integration |
| New background job | Integration |
| New authentication/authorization rule | Integration |
| New observability metric | Integration (verify it's emitted) |
| Migration of existing behavior | Integration + before/after snapshot |

## Anti-patterns

- **Testing the framework.** Don't test that React renders or Postgres SELECTs. Test YOUR logic.
- **Too-low seam.** Unit-testing what only matters as integration (e.g., the wiring between layers).
- **Too-high seam.** E2E-testing pure logic. Wasteful and slow.
- **Mocking the unit under test.** Defeats the purpose.
- **Snapshot tests for everything.** Use snapshots for UI rendering, not for logic. Logic deserves explicit assertions.
