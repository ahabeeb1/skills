# DX Gap Catalog

The six dimensions `devex-review` checks against every developer-facing product spec. Each entry describes what's at stake, the scoring bias, and concrete question templates.

Customize question templates with actual entity names from the spec — a generic template produces a generic answer.

---

## D1 — Onboarding friction / time-to-first-success

**What's at stake:** Developers form their first impression of a tool in the first 5 minutes. High onboarding friction causes abandonment before the developer has seen the product's value. The bar is a working output in under 5 minutes with zero prior knowledge.

**Scoring bias:** Mark ~ if the spec describes installation and configuration but doesn't define "working output." Mark ✗ if the spec skips onboarding entirely.

**Question templates:**

- "What is the exact sequence of commands a developer runs from a fresh machine to see the first successful output? List every step, including any config file they must write."
- "The spec describes `<install step>`. What does the developer see if they run `<first command>` before `<required prerequisite>`? Is the error message enough to recover from alone?"
- "What is the minimal working example — the fewest lines that produce a real (not mocked) result? Does it fit in a README code block?"

---

## D2 — First-time-developer roleplay

**What's at stake:** Specs are written by people who understand the domain. First-time developers don't share that context. Roleplaying the first encounter surfaces assumptions that the spec's author couldn't see.

**Scoring bias:** Mark ✗ if the spec contains no mention of beginner or first-time experience. Mark ~ if the spec has a quickstart but it wasn't reviewed by someone who hadn't seen the product before.

**Question templates:**

- "Walk through the first error a developer hits if they copy the README example verbatim. What does the error say, and what should they do? Is that self-evident from the error message alone?"
- "A developer reads the `<first command>` docs. What is the one thing they most commonly misunderstand about `<concept>` that causes their first run to fail? How does the error message correct that misunderstanding?"
- "Is there a concept the spec assumes the reader knows (e.g., `<domain term>`) that a developer from a different language ecosystem might not know? Where in the onboarding path is it introduced?"

---

## D3 — API & CLI ergonomics

**What's at stake:** API surface shapes long-term adoption. Bad names are permanent if the API is public; sensible defaults reduce required config. An oversized surface is a maintenance burden and a cognitive load on the user.

**Scoring bias:** Mark ~ if the spec names APIs but doesn't justify naming choices or define which arguments have defaults. Mark ✗ if the spec describes functionality without defining the public interface at all.

**Question templates:**

- "The spec names `<method/command>`. Is the name consistent with the existing API surface? If a developer has used `<related method>`, will they predict this one's name?"
- "Which arguments to `<method/command>` are required, and which have sensible defaults? If all arguments are required, should any have defaults?"
- "The spec describes `<N>` public methods/commands. Which ones cover the 80% use case? Could any be removed without reducing that coverage (deletion test)?"
- "Are there two public methods that do similar things under different names? Could they be unified?"

---

## D4 — Error-message quality

**What's at stake:** Developer tools that emit opaque errors produce Stack Overflow questions, GitHub issues, and abandoned integrations. A good error message names what went wrong, where, and what to do next — in one line.

**Scoring bias:** Mark ✗ if the spec doesn't mention error handling for the public interface. Mark ~ if the spec mentions error types but doesn't describe message text or recovery guidance.

**Question templates:**

- "When `<method/command>` fails because `<most common failure cause>`, what does the error message say? Does it include the offending value, the expected format, and the fix?"
- "Are error codes defined for the public interface? If yes, where are they documented? If no, how does a developer distinguish `<error type A>` from `<error type B>` programmatically?"
- "Does the spec define separate error messages for 'developer did something wrong' vs. 'the underlying service is unavailable'? If not, how does a developer tell them apart?"

---

## D5 — Documentation-as-experienced

**What's at stake:** Documentation written in the author's mental model (concept-first) often doesn't match the reader's journey (task-first). A developer reads docs in usage order: install → first example → common task → reference. If the docs aren't ordered that way, they fail at each step.

**Scoring bias:** Mark ✗ if the spec includes no doc plan. Mark ~ if the spec plans docs but doesn't specify the order or verify that the first example is independently runnable.

**Question templates:**

- "The spec plans a `<doc section>`. Does the doc order match the usage order — install, first working example, common task, reference? Or is it organized by concept?"
- "Does the first code example in the planned docs actually run on a fresh install with no undocumented prerequisites? What would a developer need that the example doesn't show?"
- "Is any part of the API documented only by reference (full API listing) without a task-based example? Which task-based examples are missing?"

---

## D6 — Upgrade / migration friction

**What's at stake:** Breaking changes in a public API force every downstream developer to update their code. If the migration path isn't documented at the time of the breaking change, developers hit a wall. The best time to design the migration path is before shipping the API, not after.

**Scoring bias:** Mark ✗ if the spec introduces a new public API without a versioning or breaking-change policy. Mark ~ if versioning is mentioned but the migration path for future breaking changes is undefined.

**Question templates:**

- "When a major version introduces a breaking change to `<method/command>`, what is the migration path? Is there a codemod, a compatibility shim, or a migration guide? Who authors it?"
- "Does the spec define what constitutes a breaking change vs. a non-breaking change? For example, is adding a required argument a breaking change?"
- "If a developer pins `<package>@<version>` today and upgrades in 12 months, what is the worst-case manual migration? Has the spec accounted for that surface?"
