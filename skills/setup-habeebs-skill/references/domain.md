# CONTEXT.md — Domain Glossary Template

Copy this skeleton to `docs/agents/CONTEXT.md` and fill it in as the codebase grows.

```markdown
# Domain Glossary

This is the vocabulary the codebase uses. `deep-modules`, `draft-spec`, and other habeebs-skills read this when proposing names, refactors, and decisions.

When two terms are interchangeable in everyday English but distinct in this domain, pick ONE and document why. Inconsistency in domain vocabulary is the leading cause of confused code.

## Core concepts

### [Concept name]

[1-2 sentence definition. Include: what it is, what it is NOT, key relationships to other concepts.]

**Examples in code:** [Where this concept appears — file paths, class names]

**Synonyms to AVOID:** [Words that mean roughly the same thing but should not be used — e.g., "User vs Account vs Member"]

### [Next concept]

...

## Aggregates and bounded contexts

[If applicable — DDD-style boundaries. What concepts belong together vs separately.]

## Common operations

[Verbs that act on the concepts. E.g., "We `archive` a document; we never `delete` it (deletion is reserved for compliance flows).]

## Vocabulary that has CHANGED

If we used to call X "Y" and now we call it "Z," note it here so old code/comments can be re-read with context.
```

## Why CONTEXT.md matters

- `deep-modules` uses these names when proposing module names. "the Order intake module" not "the FooBarHandler."
- `draft-spec` uses these names in slice descriptions
- `decision-record` uses these names in ADR titles and bodies
- `socratic-grill` can challenge decisions that use vocabulary not in CONTEXT.md ("you called this an 'Account' but our glossary says 'User' — which is it?")

The doc starts small. It grows as the team makes naming decisions. Every clarifying conversation about "what should we call this?" should end with a one-line update to CONTEXT.md.
