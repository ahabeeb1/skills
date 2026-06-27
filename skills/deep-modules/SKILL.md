---
name: deep-modules
description: Find and deepen shallow modules using the deletion test. ALWAYS use when user says "refactor this", "this code feels off", "too many small files", "this abstraction earns nothing", or at the refactor step inside tdd-loop. Do not use to rewrite already-deep modules, or to add abstractions not yet earned.
---

# Deep Modules

**DEEP MODULES, SIMPLE INTERFACES. IF THE INTERFACE IS AS COMPLEX AS THE GUTS, IT'S SHALLOW.**

The codebase's architectural conscience. Identifies shallowness and proposes deepening — but only when the deepening is earned by real friction, not by aesthetic preference.

The core principle: **the best modules are deep — they let a lot of functionality be accessed through a simple interface.** Shallow modules — where the interface is nearly as complex as the implementation — pay the cost of an abstraction without delivering the value.

This skill is informed by the project's domain model. The domain language gives names to good seams; ADRs record decisions the skill should not re-litigate.

## When to use this skill

**Trigger on:**

- The REFACTOR step of every `tdd-loop` cycle (mandatory — even if the answer is "no changes needed")
- The user says "this code feels off", "I keep bouncing between files", "too many small files", "what's the right abstraction here?"
- After a feature ships that touched many modules — periodic codebase health pass
- Code review where reviewer flags structural concerns
- The user invokes `/deepen` explicitly

**Do NOT trigger on:**

- Modules that are already deep — don't rewrite for sport
- Re-litigating decisions captured in ADRs — if a deepening contradicts a locked ADR, surface it but mark clearly ("contradicts the X ADR — only worth reopening because…")
- Adding abstractions before friction exists (this is YAGNI's other half)
- Renaming/restructuring without functional benefit

## Core workflow

### Pre-flight — GLOSSARY check

Before Phase 1, verify `docs/agents/GLOSSARY.md` exists. If missing, halt with:

> **SETUP REQUIRED:** `docs/agents/GLOSSARY.md` missing. Run `/setup` to populate the domain glossary stub. GLOSSARY.md is the domain-vocabulary half of the two-file context layout; `deep-modules` cannot propose names without it.

This skill cannot produce good deepenings without the domain vocabulary. Do not proceed to Phase 1.

### Phase 1 — Read the domain context

`GLOSSARY.md` is now guaranteed to exist (pre-flight). Read:

- `docs/agents/GLOSSARY.md` — get the vocabulary
- `docs/agents/adrs/` — note which architectural decisions are already settled

Use this vocabulary in everything you propose. If `GLOSSARY.md` defines "Order," talk about "the Order intake module" — not "FooBarHandler," not "the Order service."

### Phase 2 — Walk the area organically

Don't follow rigid heuristics. Walk the relevant area of the codebase and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules shallow — interface nearly as complex as the implementation?
- Where do callers have to know things about the implementation that the interface should have hidden?
- Where does a layer add zero conceptual value — just delegates to the next layer?
- Where do similar concepts have wildly different shapes across the codebase?

If you're invoked from `tdd-loop`, the area is the slice you just implemented + its immediate neighbors. If you're invoked standalone, the user names the area (or you ask).

### Phase 3 — Apply the deletion test

For each candidate shallow module:

**Imagine deleting it.** Trace each caller. What happens?

- **Complexity vanishes** — the module was a pass-through. Callers can just call the next layer directly. Strong candidate for deletion or merger.
- **Complexity reappears across N callers** — the module was earning its keep, even if it looks shallow. KEEP.
- **One adapter is using it** — it's a hypothetical seam, not a real one. Probably delete; let the seam emerge when there's a real need.
- **Two or more adapters are using it** — real seam. KEEP.

### Phase 4 — Surface deepening candidates

Present a numbered list. For each candidate:

```
### Candidate N — [Module / area name]

**Friction observed:** [Specific, with file paths or pseudo-code]
**Deletion-test result:** [Pass-through | Real seam | Hypothetical seam]
**Proposed deepening:** [What to combine / where the new abstraction lives]
**Cost:** [How invasive — touches N files, M callers]
**Conflicts with ADRs:** [None | ADR-NNNN — and why worth reopening]
```

Don't propose interfaces yet. Don't write code yet. Surface the candidates.

### Phase 5 — Ask, then design

Ask: "Which of these would you like to explore?"

When the user picks a candidate, drop into a design conversation. Walk the design tree:

- What does the deep abstraction's interface look like? (Smallest surface that captures all callers' needs)
- What sits behind the seam?
- What tests survive the change? (None should be deleted — they should adapt or refactor)
- What's the migration plan? (Big-bang vs incremental; how to verify nothing broke)

### Phase 6 — Capture the result

If the deepening is significant, it deserves an ADR. Hand off:

```
HANDOFF: record ready — invoke `decision-record` to capture the deepening as an ADR. Context: shallow module(s) X, Y, Z; Decision: combined into deep module W; Trade-offs: ...
```

If it's a minor refactor, no ADR needed — just commit the change with a clear message.

## The deletion test in more detail

The single most useful tool in this skill. Some examples:

**Example A — Pass-through (delete)**

```python
# UserService — only wraps the repository
class UserService:
    def __init__(self, repo): self.repo = repo
    def get_user(self, id): return self.repo.find_user(id)
    def save_user(self, user): return self.repo.save(user)
```

Delete UserService. Callers call repo directly. No complexity reappears anywhere — the service was pure delegation.

**Example B — Earning its keep (keep)**

```python
# AuthService — wraps user lookup with rate-limiting, lockout, and audit logging
class AuthService:
    def authenticate(self, email, password):
        if self.rate_limiter.is_locked(email): raise LockedOut()
        user = self.user_repo.find_by_email(email)
        if not user or not self.password.verify(password, user.hash):
            self.audit.log_failed_attempt(email)
            self.rate_limiter.record_failure(email)
            return None
        return user
```

Delete AuthService and that logic spreads across every login site. Module earns its keep.

**Example C — Hypothetical seam (probably delete)**

```typescript
// EmailProvider abstract base — only one implementation in the codebase
abstract class EmailProvider { abstract send(...) }
class SendGridProvider extends EmailProvider { ... }

// Used by:
const provider = new SendGridProvider()
provider.send(...)
```

One adapter = hypothetical seam. Just use SendGrid directly. Add the abstraction when a SECOND provider arrives.

## Architectural vocabulary

See `references/LANGUAGE.md` for the full vocabulary. Key terms used throughout the skill:

- **Deep module** — small interface, large implementation, hides complexity from callers
- **Shallow module** — interface nearly as complex as implementation; abstraction taxes without value
- **Pass-through** — module that delegates to the next layer with no added value
- **Information leakage** — implementation details bleed through the interface; callers depend on internals
- **Different layers, different abstractions** — anti-pattern when adjacent layers have nearly the same interface (each adds no value)
- **Hypothetical seam** — abstraction introduced for a future use case that doesn't exist yet

## Anti-patterns this skill guards against

If you find yourself thinking the left column, STOP — the right column is the reality.

| Thought | Reality |
|---|---|
| "This file is too long, so it's shallow." | Length isn't shallowness. A 500-line cohesive module is deep. Apply the deletion test. |
| "I'll add an abstraction for future flexibility." | YAGNI. Add a seam when two real callers want different behavior there — not before. |
| "This decided architecture seems wrong — I'll just contradict it." | Don't re-litigate decided architecture casually. Surface honestly; mark clearly when a candidate conflicts. |
| "`Handler` would read better as `Processor`." | Cosmetic rename, no functional benefit. Skip. |
| "The user is reluctant, so I'll drop the refactor." | State the friction with concrete evidence; if they still defer, capture it as tech debt. |
| "I'll refactor the whole codebase while I'm here." | If you're rewriting everything, the slice was wrong. Keep refactors local and reversible. |

## When the result is "no changes needed"

This is a valid outcome. Sometimes the area is already healthy. State explicitly:

"Checked area [X]. Modules are appropriately deep, deletion test confirms each layer earns its keep, names match domain glossary. No changes proposed."

Capturing this is valuable — it confirms the check ran, which prevents the "nobody actually does the refactor step" failure mode.

## Integration with the chain

- **Invoked from `tdd-loop`** at the REFACTOR step on every cycle
- **Invoked standalone** periodically or on user request via `/deepen`
- **Hands off to `decision-record`** when the deepening is architecturally significant
- **Reads `setup-habeebs-skill` outputs** for domain vocabulary and ADR history

## See also

- `tdd-loop` — invokes this skill at the REFACTOR step
- `decision-record` — captures significant deepenings as ADRs
- `setup-habeebs-skill` — sets up GLOSSARY.md and ADR directory this skill reads
- `references/LANGUAGE.md` — architectural vocabulary
- § The deletion test in more detail (above) — worked examples of the deletion test
