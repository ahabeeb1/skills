# Slop heuristics

Seven heuristics for detecting AI-generation slop in a staged diff. Used by [`verify-output`](../SKILL.md) between `tdd-loop` GREEN and commit.

Four heuristics are lifted verbatim from this repo's `CLAUDE.md` (user-authored canon). Three are paraphrased from oh-my-claudecode's `ai-slop-cleaner` and `ultraqa` skills (≤10 words quoted per source).

Each heuristic carries a **positive example** (what slop looks like) and a **counter-example** (legitimate code that resembles slop but isn't).

---

## H1 — Feature creep beyond task scope (CLAUDE.md verbatim)

> "Don't add features, refactor, or introduce abstractions beyond what the task requires. A bug fix doesn't need surrounding cleanup; a one-shot operation doesn't need a helper. Don't design for hypothetical future requirements."

**Positive example (slop):** Task was "add a `phone` field to the User model." Diff also renames `email` to `emailAddress`, extracts a `ContactDetails` value object, and refactors three call sites. The rename and abstraction are out of scope.

**Counter-example (not slop):** Task was "add a `phone` field." Diff adds the field, a validator for it, and a unit test. All three are scope-aligned.

**Severity:** Moderate. Returns `DONE_WITH_CONCERNS` in ANNOTATE mode; `BLOCKED` in GATE mode.

---

## H2 — Error handling for impossible scenarios (CLAUDE.md verbatim)

> "Don't add error handling, fallbacks, or validation for scenarios that can't happen. Trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs)."

**Positive example (slop):** A pure function `add(a: number, b: number)` includes `if (typeof a !== 'number') throw new Error(...)`. TypeScript already guarantees `a` is a number.

**Counter-example (not slop):** An HTTP handler validates `req.body.email` against a schema before passing it downstream. That's the system boundary — validation is correct.

**Severity:** Moderate. Returns `DONE_WITH_CONCERNS`.

---

## H3 — Unjustified comments (CLAUDE.md verbatim)

> "Default to writing no comments. Only add one when the WHY is non-obvious: a hidden constraint, a subtle invariant, a workaround for a specific bug, behavior that would surprise a reader."

**Positive example (slop):** `// Set user to admin\nuser.role = "admin"`. The comment restates the code.

**Counter-example (not slop):** `// Lambda cold-start: this DB connection must be lazy; pre-init breaks Vercel's edge runtime.` Captures a non-obvious constraint that would surprise a reader.

**Severity:** Moderate. Returns `DONE_WITH_CONCERNS`.

---

## H4 — Backwards-compatibility hacks for unshipped code (CLAUDE.md verbatim)

> "Avoid backwards-compatibility hacks like renaming unused _vars, re-exporting types, adding // removed comments for removed code, etc. If you are certain that something is unused, you can delete it completely."

**Positive example (slop):** A new internal function `computeTax(...)` is added. The diff also exports `computeTax_v1` as an alias "for backward compatibility." There are no existing callers — nothing to be backward-compatible with.

**Counter-example (not slop):** A library being released externally adds a deprecation shim for a public API that consumers depend on. Real backward compatibility, real callers, real shim.

**Severity:** Moderate. Returns `DONE_WITH_CONCERNS`.

---

## H5 — Repeated boilerplate suggesting a missed abstraction (OMC-paraphrased)

OMC's `ai-slop-cleaner` flags "repeated boilerplate" — three or more near-identical code blocks in the same diff that share structure but differ in trivial parameters. Suggests the agent should have introduced one helper instead of copy-pasting three times.

**Positive example (slop):**

```python
def get_user(id): return db.query("SELECT * FROM users WHERE id = ?", id)
def get_post(id): return db.query("SELECT * FROM posts WHERE id = ?", id)
def get_comment(id): return db.query("SELECT * FROM comments WHERE id = ?", id)
```

Three near-identical functions differing only in table name. A `get_by_id(table, id)` helper would collapse them.

**Counter-example (not slop):** Three test cases that look similar because they're testing parallel cases (e.g., one for each error type). Tests intentionally repeat structure to keep each test independently readable.

**Severity:** Moderate. Returns `DONE_WITH_CONCERNS`. **Caveat:** rule of three only — two repetitions is too small a sample.

---

## H6 — Defensive validation past trusted boundaries (OMC-paraphrased)

OMC flags "over-validation" — guards that re-check invariants the calling layer already enforced. Symmetric to H2 but framed at the architecture-boundary level rather than the type-system level.

**Positive example (slop):** A `services/` layer function receives a `User` object from the route handler. The route handler already validated the user is authenticated and non-null. The service function adds `if (!user) throw new Error(...)`. Redundant guard past a trusted boundary.

**Counter-example (not slop):** An external webhook handler validates the payload signature before trusting any field. The webhook IS the boundary; validation is the boundary check.

**Severity:** Moderate. Returns `DONE_WITH_CONCERNS`.

---

## H7 — Severe slop: half-finished implementation, unreachable code, declared-and-unused

This is the only category that returns `BLOCKED` in ANNOTATE mode. Each sub-condition is binary and mechanically detectable. OMC's `ultraqa` cites "the agent stopped mid-thought" as the canonical pattern.

**Sub-conditions** (any one triggers `BLOCKED`):

1. **Half-finished implementation:** function bodies containing `TODO`, `pass`, `throw new NotImplementedError`, `// implement me`, `raise NotImplementedError`, or any equivalent stub-placeholder.
2. **Unreachable code:** code paths the compiler/linter would flag as dead (e.g., `return x; foo();`). Includes branches where the condition is statically impossible.
3. **Declared-and-unused:** imports, variables, parameters, or types declared in the staged diff but never referenced in the diff or in the existing file. Excludes intentional `_underscore` parameter naming for required-but-unused arguments.

**Positive example (severe slop):**

```python
def compute_tax(income, jurisdiction):
    # TODO: handle non-US jurisdictions
    if jurisdiction != "US":
        pass
    return income * 0.22
```

Tax computation silently returns wrong values for any non-US jurisdiction. The `pass` and the `TODO` together mark this as a stub shipped as production code.

**Counter-example (not severe slop):**

```python
def compute_tax(income, jurisdiction):
    if jurisdiction != "US":
        raise NotImplementedError(f"Only US tax supported (got {jurisdiction!r}) — see TICKET-123")
    return income * 0.22
```

Explicit halt with a referenced ticket. Not "I stopped mid-thought" — it's "I deliberately don't support this case, here's why."

**Severity:** Severe. Returns `BLOCKED` in ANNOTATE mode AND GATE mode.

---

## Heuristics NOT in scope

Out of scope for `verify-output`:

- **Code style** (formatting, naming conventions). That's the project's linter/formatter.
- **Architecture concerns** (shallow modules, pass-through layers). That's [`deep-modules`](../../deep-modules/SKILL.md), invoked earlier at the `tdd-loop` refactor step.
- **Test coverage** (whether a function is tested). That's the test runner.
- **Performance** (whether code is fast enough). That's profiling.
- **Security review** (auth flows, secrets handling). That's a dedicated security pass.

`verify-output`'s scope is narrow: detect slop in a staged diff against the 7 heuristics above. Nothing else.

## Origins

- Lifted verbatim from this repo's `CLAUDE.md` (user-authored canon): H1, H2, H3, H4. Single source of truth — if `CLAUDE.md` updates, this doc updates.
- Inspired by oh-my-claudecode's `ai-slop-cleaner` and `ultraqa` skills (≤10 words per source per repo quote policy): H5, H6, H7 framing.

## See also

- [`verify-output/SKILL.md`](../SKILL.md) — the consuming skill
- `CLAUDE.md` at repo root — canonical source for H1-H4
- [ADR-0008](../../../docs/agents/adrs/0008-verify-output-skill-scope.md) — scope, default mode, blocking criteria
