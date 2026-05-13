# 12a — Planted moderate slop

**Tests:** H1 (feature creep), H2 (impossible-scenario error handling), H3 (unjustified comments), H4 (backward-compat shim for unshipped code), H5 (repeated boilerplate), H6 (defensive validation past trusted boundaries).

**Expected status (ANNOTATE mode):** `DONE_WITH_CONCERNS` with ≥4 concerns surfaced.
**Expected status (GATE mode):** `BLOCKED` with ≥4 concerns surfaced.

## Planted diff (paste into a scratch repo on a fresh branch, then `git add` and invoke `verify-output`)

```diff
diff --git a/src/user_service.ts b/src/user_service.ts
new file mode 100644
--- /dev/null
+++ b/src/user_service.ts
@@ -0,0 +1,42 @@
+import { Database } from "./db";
+import { Logger } from "./logger";
+
+// User service for managing users in the database
+export class UserService {
+  constructor(private db: Database, private logger: Logger) {}
+
+  // Get a user by their ID
+  async getUser(id: string): Promise<User | null> {
+    if (typeof id !== "string") {
+      throw new Error("id must be a string");
+    }
+    return this.db.query("SELECT * FROM users WHERE id = ?", id);
+  }
+
+  // Get a post by its ID
+  async getPost(id: string): Promise<Post | null> {
+    return this.db.query("SELECT * FROM posts WHERE id = ?", id);
+  }
+
+  // Get a comment by its ID
+  async getComment(id: string): Promise<Comment | null> {
+    return this.db.query("SELECT * FROM comments WHERE id = ?", id);
+  }
+
+  async createUser(input: CreateUserInput, currentUser: User): Promise<User> {
+    if (!currentUser) {
+      throw new Error("currentUser is required");
+    }
+    const user = await this.db.insert("users", input);
+    return user;
+  }
+}
+
+// Backward-compat alias for legacy callers
+export const UserService_v1 = UserService;
+
+// Email validation helper added for the new phone field feature
+export function validateEmail(email: string): boolean {
+  return /\S+@\S+\.\S+/.test(email);
+}
```

## Expected concerns (verify-output should surface at least these)

1. **[H3]** `src/user_service.ts:4` — comment `// User service for managing users in the database` restates the class name; remove.
2. **[H3]** `src/user_service.ts:8,16,21` — three `// Get a X by its ID` comments restate the method names; remove.
3. **[H2]** `src/user_service.ts:9-11` — TypeScript already guarantees `id: string`; the runtime typeof check is redundant.
4. **[H5]** `src/user_service.ts:8-22` — three near-identical `get*` methods differ only in the table name. Suggested: extract `getById(table, id)` helper. Rule of three triggers.
5. **[H6]** `src/user_service.ts:26-28` — `currentUser` is non-null by the route handler's auth middleware (trusted boundary); the guard in the service layer is over-validation.
6. **[H4]** `src/user_service.ts:35` — `UserService_v1` alias for "legacy callers" but there are no existing callers (the file is new). Backward-compat shim for unshipped code.
7. **[H1]** `src/user_service.ts:38-40` — `validateEmail` added "for the new phone field feature". Task was to add a phone field; an email validator is feature creep.

## Output format check

The skill output should:

- Begin with `STATUS: DONE_WITH_CONCERNS` (ANNOTATE mode) or `STATUS: BLOCKED` (GATE mode).
- List each concern with `[H<N>] <path>:<line>` prefix.
- Suggest a resolution per concern.
- End with the appropriate handoff line.

## Pass criteria

- Surfaces ≥4 of the 7 expected concerns (not all 7 — some are interpretation-dependent, e.g., H1 requires inferring "the task was the phone field").
- Returns the correct status for the invocation mode.
- Does NOT return `BLOCKED` in ANNOTATE mode (no H7 severe-slop hits in this fixture).

## Fail criteria

- Returns `DONE` (missing all the planted slop).
- Returns `BLOCKED` in ANNOTATE mode (false positive on H7 — there are no half-finished impls / unreachable code / declared-and-unused in this fixture).
- Surfaces fewer than 4 of the planted concerns.
