# Grill Record: Cross-Session Conflict Detection

**Spec:** [`docs/agents/research/2026-05-22-cross-session-conflict-detection.md`](../research/2026-05-22-cross-session-conflict-detection.md)
**Tier:** Deep (inherited from research)
**Grilled on:** 2026-05-22
**Items resolved:** 7 decided / 1 deferred-with-trigger / 3 absorbed (no grill needed)

## TL;DR

All 7 user-focus items resolved. The ADR-0002 carve-out is shaped as a four-sub-clause guard in a new ADR-0019, the worktree-out resolution flow uses stash-and-pop with auto-derived branch names, PreToolUse ships default-off and annotate-only when enabled, `prefer_worktree` is deferred to v1.1 in favor of the reactive `[w]orktree-out` action alone, the menu accepts letters and numbers (`[1/m] [2/s] [3/t] [4/a] [5/w]`, with `transfer` replacing `handoff` to dodge the help-key shadow), audit logs are tracked forever with revisit at 1000, and Windows liveness uses Node's `process.kill(pid, 0)` with a 24h TTL fallback. No architectural rethink needed — the grill tightened the recommendation rather than overturning it.

---

## Grilling agenda

User's focus list, ordered by one-way-door + blast radius:

1. ADR-0002 carve-out clause shape
2. `worktree-out` stash semantics
3. Opt-in vs default for `PreToolUse`
4. `prefer_worktree` default list
5. Action-menu keystroke set (5 options now)
6. Audit log retention
7. Windows liveness probe portability

Three additional items flagged at agenda time but absorbed without separate grilling:
- Audit-log file location (resolved by item 6)
- Cross-branch overlap behavior (handled natively by `git merge-tree`; research finding holds)
- Sidecar lifecycle on crash without `SessionEnd` (covered by item 7's TTL fallback)

---

## Per-item resolutions

### Item 1 — ADR-0002 carve-out clause shape

- **Starting state:** Research recommended "ADR-0002 carve-out clause text" but didn't specify what the clause must guarantee or whether to amend ADR-0002 in place vs write a new ADR.
- **Axes grilled:** Reversibility (ADRs are one-way doors), Failure modes (which substrate-test does the mechanism actually challenge), Migration (cross-references from ADR-0001/0005/0006/0010 set the precedent for new-ADR-over-amendment).
- **Key questions asked:**
  - Does the session sidecar pass ADR-0004's four substrate-tests? (Test 4 — no in-flight reads — fails cleanly; the mechanism requires in-flight reads by design.)
  - What's the minimum clause that prevents future drift?
  - New ADR or amend in place?
- **Resolution:** DECIDED
- **Decision:**
  - **Clause shape:** Four-sub-clause guard amending substrate-test 4 — "In-flight reads permitted when (a) advisory not authoritative, (b) reader has defined contract for stale/torn/missing data, (c) per-writer-unique artifact, (d) read-only — peers never modify each other's artifacts."
  - **Location:** New ADR-0019, cross-referencing ADR-0002 + ADR-0004. ADR-0002 status updated to "Amended by 0018."
- **Spec update:** Spec should reference ADR-0019 (forthcoming) as the substrate-rule authority.

### Item 2 — `worktree-out` stash semantics

- **Starting state:** Research listed three options (stash/pop, WIP-commit/reset, require-commit-first) but did not pick.
- **Axes grilled:** Failure modes (stash-pop recursion risk), Reversibility (state preservation), Concurrency (per-repo stash vs per-worktree).
- **Key questions asked:**
  - Can stash-pop conflict in the new worktree? (No — both worktrees start from the same commit; new worktree has no diff to conflict with.)
  - What branch does the new worktree check out? (New branch needed; old branch occupied by Session A.)
  - Where does the branch name come from?
- **Resolution:** DECIDED
- **Decision:**
  - **Dirty-tree flow:** `git stash` + `git worktree add` + `git stash pop` in new worktree. Per-repo stash means cross-worktree pop works.
  - **Clean-tree flow:** Skip stash; just `git worktree add`.
  - **`pre-push` trigger flow:** Branch already committed; `git worktree add <existing-branch>`.
  - **Branch name:** Auto-derive `worktree-out/<8-char-uuid>`. User can `git branch -m` later for meaningful names. UUID logged in conflict audit.
- **Spec update:** Add an explicit case-table to the spec mapping trigger source → tree state → flow.

### Item 3 — Opt-in vs default for `PreToolUse`

- **Starting state:** Research recommended opt-in but flagged the "no telemetry under ADR-0002 means we never flip the default" trap.
- **Axes grilled:** Failure modes (false-positive blast radius), Observability (how to ever measure FP rate), Reversibility (per-repo policy flip is cheap).
- **Key questions asked:**
  - Three-filter false-positive analysis: how low is the rate when sidecar + liveness + merge-tree all pass?
  - Without telemetry, what's the exit-from-opt-in path?
  - If enabled, should the halt block the Edit or annotate-and-allow?
- **Resolution:** DECIDED
- **Decision:**
  - **Default:** `pretool_use: false` in `.claude/habeebs-policy.json`. Opt-in via `pretool_use: true`.
  - **When enabled:** Annotate-and-allow. Surface overlap warning + diff in agent transcript; Edit proceeds. Matches ADR-0019's "advisory not authoritative" principle.
  - **Discovery path:** `SessionStart` prints a hint when ≥1 peer detected: "PreToolUse can catch in-session collisions too — enable in `.claude/habeebs-policy.json`."
- **Spec update:** Add the `pretool_use` flag to the policy schema; add the SessionStart hint text.

### Item 4 — `prefer_worktree` default list

- **Starting state:** Research proposed a proactive policy lever with a default list ambiguity. User pushed back during grilling: didn't see the link to their original change.
- **Axes grilled:** Scope (does v1 need this at all), Reversibility (deferral is fully reversible), Migration (reactive `[w]orktree-out` already covers the bug-fix-vs-refactor case).
- **Key questions asked:**
  - Does the reactive `[w]orktree-out` action already solve the user's literal scenario? (Yes.)
  - Is the proactive lever additive or load-bearing? (Additive.)
  - What revisit trigger justifies adding it later?
- **Resolution:** DEFERRED (with trigger)
- **Decision:**
  - **v1:** Ship only the reactive `[w]orktree-out` action menu option. Drop `prefer_worktree` from v1 policy schema.
  - **v1.1 revisit trigger:** If reactive halts feel annoying after a few weeks of use (subjective; user reports as the trigger).
- **Spec update:** Remove `prefer_worktree` axis from policy schema for v1. Strike from concrete-picks table. Add a `## Deferred to v1.1` section that documents the lever and its revisit trigger.

### Item 5 — Action-menu keystroke set

- **Starting state:** Proposed `[m] [s] [h] [a] [w]`. Two concerns: `[h]andoff` shadows the universal help-key convention; `[w]orktree-out` is non-obvious mnemonic.
- **Axes grilled:** Reversibility (muscle-memory cost of changing keystrokes later), Failure modes (accidental help-key invocation on `[h]`), Observability (discoverability for new users).
- **Key questions asked:**
  - Is the help-key shadow an actual problem? (Yes, on Unix CLIs `h` is universal.)
  - Letters vs numbers vs both?
  - Should `[h]andoff` be renamed regardless of letter/number choice?
- **Resolution:** DECIDED
- **Decision:**
  - **Final menu:** `[1/m] Merge / [2/s] Sequence / [3/t] Transfer / [4/a] Abort / [5/w] Worktree-out`
  - **`transfer` replaces `handoff`** to dodge help-key shadow.
  - **Both keystrokes accepted** — apt/pacman/npm-init pattern.
- **Spec update:** Update halt-UX section with the final menu vocabulary and keystroke contract.

### Item 6 — Audit log retention

- **Starting state:** Research suggested "consistency argues forever" but didn't commit.
- **Axes grilled:** Scale (1000-record ceiling), Migration (ADR-0004 precedent), Failure modes (collab sensitivity of diff content).
- **Key questions asked:**
  - Are dispatches tracked or gitignored? (Tracked — checked via `git check-ignore`.)
  - Does ADR-0004's revisit-at-1000 trigger transfer cleanly? (Yes.)
  - Is collab diff sensitivity a v1 blocker? (No — solo is dominant scenario; document opt-out for collab.)
- **Resolution:** DECIDED
- **Decision:**
  - **Storage:** `docs/agents/conflicts/<id>.json`, tracked, never pruned by default.
  - **Revisit trigger:** 1000 conflict records (matches ADR-0004).
  - **Collab opt-out:** ADR-0019 notes that collab repos with sensitivity concerns can `.gitignore docs/agents/conflicts/`.
- **Spec update:** Lock the audit-log location + retention contract.

### Item 7 — Windows liveness probe portability

- **Starting state:** Research left this as highest-uncertainty open question; `kill(0)` is POSIX-only.
- **Axes grilled:** Failure modes (PID reuse, cross-shell process namespaces), Performance (one-line shell-out budget), Reversibility (probe choice is easy to swap).
- **Key questions asked:**
  - Does Claude Code's bundled Node give us a cross-platform primitive? (Yes — `process.kill(pid, 0)`.)
  - What about WSL ↔ PowerShell process-namespace boundaries? (Real edge case; mitigate via embedded env string in sidecar.)
  - What's the fallback when the probe is inconclusive?
- **Resolution:** DECIDED
- **Decision:**
  - **Primary probe:** `node -e "try{process.kill(<PID>,0);process.exit(0)}catch{process.exit(1)}"`. Exit 0 = alive, exit 1 = dead. Cross-platform via Node's built-in.
  - **Sidecar adds environment field:** `env: "wsl-debian" | "powershell" | "git-bash" | "posix"`. If probing session's env differs from sidecar's, treat probe as inconclusive.
  - **Fallback:** Start-time + TTL. TTL = **24h default** (accommodates idle sessions; conservative).
- **Spec update:** Add `env` field to sidecar schema. Lock the Node-shell-out as the probe primitive. Add TTL constant to policy schema (`liveness_ttl_seconds: 86400` default, override per repo).

---

## New decisions surfaced during grilling

Decisions the research didn't anticipate but the grill revealed:

1. **`[h]andoff` rename to `[t]ransfer`** — discovered via the help-key-shadow probe; not in original research output.
2. **Sidecar `env` field** — required by item 7's cross-shell mitigation; adds one field to the sidecar JSON schema.
3. **`liveness_ttl_seconds: 86400` policy field** — surfaced by item 7's TTL fallback; needs to live in `.claude/habeebs-policy.json`.
4. **`SessionStart` peer-detected hint text** — surfaced by item 3's discovery-path question; documents the opt-in path in-context.
5. **Conflict audit `.gitignore` opt-out documented in ADR-0019** — surfaced by item 6's collab-sensitivity probe.

---

## Spec updates required

Push these back into the spec when `draft-spec` runs:

- [ ] Replace "ADR-0002 carve-out clause text" decision with the locked four-sub-clause guard + new ADR-0019 location.
- [ ] Add `worktree-out` flow case-table (trigger source × tree state).
- [ ] Add `pretool_use: false` default + annotate-and-allow semantic + SessionStart hint text.
- [ ] **Remove `prefer_worktree` from v1 policy schema.** Add a `## Deferred to v1.1` section documenting the lever and its revisit trigger.
- [ ] Update halt-UX section with final menu `[1/m] [2/s] [3/t] [4/a] [5/w]` and the `transfer` rename.
- [ ] Lock audit-log location (`docs/agents/conflicts/<id>.json`, tracked, never pruned, revisit at 1000).
- [ ] Add `env` field to sidecar schema; lock Node-based liveness probe; add `liveness_ttl_seconds` policy field with 86400 default.

---

## ADR candidates

High-impact decisions that should be captured in `decision-record`:

1. **ADR-0019 — In-repo session state carve-out for cross-session conflict detection.** Four-sub-clause guard (a)-(d) amending ADR-0002 substrate-test 4. Cross-references ADR-0002 + ADR-0004. The load-bearing ADR for the entire feature.
2. **Halt UX menu vocabulary lock-in** — `transfer` over `handoff`, dual letter+number keystrokes. Likely a section *inside* ADR-0019 rather than its own ADR (it's a corollary of the carve-out, not an independent decision).
3. **`prefer_worktree` v1.1 deferral with explicit revisit trigger** — captured in ADR-0019's "Deferred" section so future research doesn't re-propose it cold.

---

HANDOFF: spec update ready — apply the updates listed above (or invoke `draft-spec` to produce the v1 implementation spec).
HANDOFF: record ready — invoke `decision-record` to author ADR-0019 (carve-out clause + menu vocabulary + v1.1 deferral).
