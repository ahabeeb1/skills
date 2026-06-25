# LANGUAGE.md — Architectural Vocabulary

Architectural vocabulary built around the deep-modules principle. Use these terms consistently in proposals and ADRs.

## Core duality: depth vs shallowness

### Deep module

A module is **deep** when its implementation is large relative to its interface. It hides significant complexity behind a small, stable interface. Callers see only what they need.

Examples:
- Unix file I/O: `open`, `read`, `write`, `close` interface; vast implementation
- Postgres: SQL interface; immense implementation
- A well-designed React component: props interface; complex rendering/state

Why depth is good: the cost of an abstraction is the interface (cognitive load on every caller, training documentation, churn risk). The value is the hidden implementation. Deep modules deliver more value per unit cost.

### Shallow module

A module is **shallow** when its interface is nearly as complex as its implementation. The abstraction takes more cognitive overhead to use than implementing directly would.

Examples:
- `class UserRepository { findById(id) { return db.users.find({id}) } }` — interface tax with no hidden complexity
- A 200-line file that only re-exports things from 10 other files
- A wrapper around `console.log` that adds nothing

Why shallowness is bad: every caller pays the abstraction tax (one more name to remember, one more file to navigate) without benefit. Shallow modules also tend to LEAK implementation details (see information leakage below).

## Related concepts

### Pass-through module

A specific shallow shape: the module delegates to one other module without adding value. Often appears as service classes that just wrap a repository, or "Manager" classes that just call other managers.

Test: if you delete this module and inline its calls, does anything else change? If no, it was a pass-through.

### Information leakage

Implementation details leak through the interface when callers must know things they shouldn't have to know.

Examples:
- Caller has to know to call `prepare()` before `execute()` (lifecycle leaking through)
- Caller has to handle three different return types depending on input (interface should normalize)
- Caller has to know to release a lock manually (resource management leaking)

The cure: make the interface express only what the caller actually needs to know. Hide lifecycle, error variants, resource management.

### Hypothetical seam

An abstraction introduced for a future use case that doesn't yet exist. Common shapes:

- An abstract base class with one concrete implementation
- A factory function for "future" alternative implementations
- A configuration setting that's never been anything but the default

Hypothetical seams are not necessarily bad — but they should be marked as such, and they should be removed if the future use case fails to materialize within a reasonable horizon.

### Real seam

An abstraction with two or more callers/implementations that genuinely differ. Worth keeping. The interface is justified by the divergence.

### Strategic vs tactical programming

- **Tactical:** ship the feature; deal with cleanup later. Optimizes for short-term velocity.
- **Strategic:** invest in clean design; ship slightly slower but cumulatively faster. Compounds over time.

The claim: a small investment (5-10% time) in strategic design pays back many-fold over the life of the codebase. The agentic age accelerates code generation, which makes strategic discipline MORE important, not less — entropy is now also accelerated.

### Different layer, different abstraction

Adjacent layers should provide different abstractions. If layer A and layer B have nearly the same interface, layer A is probably a pass-through.

Example anti-pattern:

```
UserController.create_user(...) →
  UserService.create_user(...) →
    UserManager.create_user(...) →
      UserRepository.create_user(...)
```

Each layer has the same shape. The chain provides one abstraction; the rest are tax. Collapse to two layers (controller, repository) and the codebase gets simpler.

## Process vocabulary

### Complexity (three symptoms)

A codebase is complex when changes are hard. Three signs:

1. **Change amplification** — a conceptually small change requires touching many places
2. **Cognitive load** — understanding a piece requires holding too many things in your head
3. **Unknown unknowns** — it's not clear what code you need to change to safely modify a behavior

Most architectural pain reduces to one of these. The goal of `deep-modules` is to reduce all three.

### Incremental investment

You don't fix architecture in one big refactor. You fix it 5-10% at a time, on every change, by leaving each module a little better than you found it. `deep-modules` invocations on every TDD cycle are the mechanism.

## Anti-vocabulary (words to avoid)

These words are sometimes used as if they're architectural assessments but are actually vague or aesthetic:

- "Clean" — what does clean mean? Usually means "I like the shape."
- "Elegant" — even vaguer.
- "Overengineered" — sometimes accurate, often used to dismiss legitimate abstraction.
- "Spaghetti" — descriptive of pain, but not actionable. What specifically is shallow / leaking / pass-through?

Use concrete language: "shallow module," "pass-through layer," "information leakage at the X interface," "duplicate concept across N callers."
