# Prior-Art Research: Cross-Session Conflict Detection for Concurrent Claude Code Sessions

**Researched on:** 2026-05-22
**Tier:** Deep — 5 sub-problems, ADR-0002 hard constraint, medium ambiguity (auto-detect score 5).
**Sources consulted:** 27 (26 initial + `git-worktree(1)` added in 2026-05-22 amendment)

## TL;DR

Use a **Vim-swap-style session sidecar** placed in `$(git rev-parse --git-common-dir)/habeebs-sessions/<id>.json` (visible across all worktrees of the same repo) embedding PID + hostname + start-time + worktree path + tentative tree SHA, paired with **`git merge-tree --write-tree`** for actual overlap detection, layered across three triggers: `SessionStart` warn-only by default, `pre-push` block-only as the cross-developer backstop, and `PreToolUse` (Edit/Write) opt-in for same-function collisions; configure per repo via `.claude/habeebs-policy.json` mirroring Claude Code's settings hierarchy and exposing a `prefer_worktree: <work_type>` axis that proactively isolates risky work types in their own worktrees; halt via the existing inline-prompt surface with a **five-option menu** (`merge` / `sequence` / `handoff` / `abort` / `worktree-out`) where `worktree-out` invokes `using-worktrees` to branch Session B into its own worktree and continue independently; audit each conflict to `docs/agents/conflicts/<id>.json` as append-once JSON, mirroring ADR-0004's dispatch-record carve-out. The single biggest trade-off: signals are **advisory, not authoritative** — pure filesystem + git-plumbing cannot guarantee mutex across distributed checkouts the way a server-mediated lock (git-lfs) can, but ADR-0002 rules out servers entirely.

## Context

- **Building:** A cross-session conflict detector for habeebs-skill that surfaces overlapping edits between concurrent Claude Code (or AI-dev) sessions before silent overwrite.
- **Scale:** Solo dev with 2-4 concurrent sessions typical; occasional collab on the same checkout; AFK-worktree work already isolated and out of scope.
- **Stack:** habeebs-skill v1.15.0 — markdown + JSON + git hooks plugin; 18 skills, 16 ADRs; brownfield mature.
- **Constraints:** ADR-0002 (no runtime substrate / MCP / daemons / team registry); ADR-0003 (hooks warn-only or block-only, multi-harness, never own state); ADR-0004 (in-repo audit JSON is legal precedent).
- **Existing:** Greenfield mechanism, retrofitted onto existing hook + policy surface.
- **Priorities:** Correctness > operational simplicity. No shipping-speed pressure.

## Sub-problems

1. Session presence signaling + stale-signal recovery (no daemon).
2. Overlap detection mechanism given presence signals exist.
3. Trigger surface, situation-dependent (when does detection fire).
4. Per-repo / per-work policy + cross-machine trust boundary.
5. Halt + diff-surface UX + conflict audit trail.

## Phase 2.5 outcome — Category-completeness critic

**Verdict:** ADDITIONS PROPOSED (5) — 4 accepted, 1 absorbed as scoping note, 0 rejected.

**Critic-surfaced additions and lead's response:**

| Category | Suggested sub-problem | Lead's response | Reason |
|---|---|---|---|
| Liveness | Session presence + stale-signal recovery | Accepted — added as sub-problem 1 | — |
| Forensics | Conflict audit trail | Accepted — folded into sub-problem 5 | — |
| Trust | Cross-machine trust boundary for in-repo signals | Accepted — folded into sub-problem 4 | — |
| Scoping | Worktree-isolated AFK work already eliminates a subset | Accepted as scoping note + amended 2026-05-22 to treat worktrees as workflow material | AFK worktrees are filesystem-isolated by design AND worktrees serve as a resolution action (`worktree-out`) and a proactive policy lever (`prefer_worktree: <work_type>`). The scoping is honored; the workflow lens was added on user push-back |
| Cautionary precedent | Claude Code's stale `index.lock` bug (issues #11005, #28546, #57102) | Accepted — flagged as negative evidence against bare-existence locking | — |

## Case studies

### Vim — `.foo.swp` sidecar with embedded process metadata

- **Architecture:** When Vim opens a file, it writes a `.foo.swp` sidecar in the same directory embedding PID, hostname, user, inode, and start-time. A second Vim opening the same file stats the swap, parses the header, and probes liveness.
- **Key decision:** Embed full process identity so peers can distinguish *live* sessions from *stale* (post-crash) ones — quote: *"process ID: 397 (still running)"*.
- **Scale:** 30+ years of production use across every Unix.
- **Trade-off accepted:** Advisory only — a second Vim can override after warning. No mutex guarantee.
- **Source:** Vim `:help swap-file` documentation.

### Git — `merge-tree --write-tree` for in-memory 3-way merge

- **Architecture:** `git merge-tree base ours theirs` performs a full 3-way merge entirely in the object database. Exit 0 = clean; exit 1 = conflict; conflict markers printed to stdout.
- **Key decision:** Pure plumbing — *"does not read from or write to either the working tree or index."* No side effects, sub-second on typical repos.
- **Scale:** Ships with every Git ≥ 2.38.
- **Trade-off accepted:** Requires a commit-tree (or `git stash create` SHA) per session, so untracked working-tree state must be staged-as-stash for the probe to see it.
- **Source:** `git-merge-tree(1)` man page.

### jj — Conflicts as first-class data

- **Architecture:** `jj` stores conflicts in the commit graph as structured data rather than `<<<<<<<` markers in files. Conflicts persist across operations; you can `jj resolve` later or carry them through rebases.
- **Key decision:** Treat a conflict as a *durable artifact* rather than a transient working-tree state — the conflict has identity, history, and resolution metadata.
- **Scale:** Production use at Google and the broader jj community.
- **Trade-off accepted:** Departure from familiar Git mental model; tooling ecosystem still catching up.
- **Source:** `jj` design docs on conflict modeling.

### Claude Code — Inline prompt + permission system

- **Architecture:** Claude Code surfaces blocking events (tool-use approval, hook decisions) as inline prompts in the conversation, not OS dialogs. User responds with a keystroke; decision streamed back to the agent.
- **Key decision:** The agent retains presentation control — hooks return opaque non-zero exit codes; the *skill* renders the user-facing question.
- **Scale:** Every Claude Code session ships this.
- **Trade-off accepted:** Cannot render rich GUI (no merge editor); terminal-text only.
- **Source:** Claude Code hooks + permission docs.

### habeebs-skill ADR-0004 — Dispatch records as in-repo JSON

- **Architecture:** Each `parallel-dev` invocation writes a single `docs/agents/dispatches/<id>.json` capturing the dispatch contract, fan-out IDs, and per-subagent status returns. Single-writer, append-once.
- **Key decision:** In-repo JSON is legal substrate under ADR-0002 because (a) it's diff-able, (b) git is the only runtime, (c) no daemon reads it.
- **Scale:** Used by every `parallel-dev` Deep-tier dispatch since v1.10.
- **Trade-off accepted:** Audit trail is per-event-file, not a queryable log — accepted because grep + jq suffice.
- **Source:** `docs/agents/adrs/0004-parallel-subagent-dispatch-contract.md`.

### pre-commit framework — Per-stage gating + surgical skip env

- **Architecture:** Each hook declares `stages: [pre-commit, manual, ...]` and accepts `SKIP=hookid,hookid` env to disable specific hooks per invocation without disabling all hooks.
- **Key decision:** Per-work-type granularity — distinguish "this is a WIP commit, skip lint" from Husky's nuclear `HUSKY=0` "skip everything".
- **Scale:** ~1M repos; reference implementation for hook policy.
- **Trade-off accepted:** Adds configuration surface; users must learn the stages + skip vocabulary.
- **Source:** pre-commit.com documentation on stages and the `SKIP` env var.

### Git — `worktree add` built-in branch mutex (added 2026-05-22)

- **Architecture:** `git worktree add <path> <branch>` refuses to attach a worktree to a branch already checked out in another worktree of the same repo. The check is filesystem-only — Git inspects `.git/worktrees/<name>/HEAD` for every linked worktree and short-circuits with `fatal: <branch> is already checked out at <path>` if a peer claims it. No daemon, no central registry — pure filesystem state under the shared `.git/` directory.
- **Key decision:** Treat branch ownership as filesystem-resident state in `$(git rev-parse --git-common-dir)/worktrees/` so peers discover ownership via stat-and-read, not via coordination. This is the load-bearing precedent that the shared `.git/`-common-dir is the right namespace for cross-worktree presence signals.
- **Scale:** Ships with every Git ≥ 2.5; used by millions of repos with linked worktrees.
- **Trade-off accepted:** Mutex is scoped to *branches* not to *line ranges* — two worktrees on different branches can still touch the same file. That's exactly the gap habeebs-skill's session sidecar fills, on top of Git's existing primitive.
- **Source:** `git-worktree(1)` man page; `lock` / `unlock` subcommands document the persistence model.

---

## Patterns

### Pattern A — PID-embedded sidecar for advisory presence

A small, per-session file co-located with (or scoped to) the protected resource, embedding **PID + hostname + start-time + tentative state SHA**. Peers stat-glob, parse the header, probe liveness via `kill(0)` (Unix) or process-table query (Windows). Vim's swap files are the 30-year reference; PID-files in Unix daemons are the underlying primitive. Used by sub-problems 1 + 2.

**Fits when:** Single filesystem visible to all participants, advisory semantics acceptable, and the resource being protected has an obvious anchor (a file path, a working-tree root, a repo root).

### Pattern B — Pure-git overlap probe (merge-tree)

Use `git merge-tree --write-tree base ours theirs` for *actual* 3-way merge conflict detection rather than coarse "both edited the file" co-edit detection. Exit code is the answer; no working-tree mutation. Cited above in the Git case study.

**Fits when:** Both sessions can produce a commit-tree SHA (real or `git stash create`) for their current state, and you want true conflict signal rather than file-presence signal.

### Pattern C — Layered, scenario-keyed trigger mix

Rather than picking one trigger, layer them by scenario: a low-cost default at session boundary, a strong block at push, a precise targeted check on the edit itself. Vim (open-time check), pre-commit (per-stage gates), Claude Code (PreToolUse) each contribute. Sub-second is mandatory — Thoughtworks documented 2.5-min hooks normalizing the `--no-verify` workaround.

**Fits when:** False-positive cost varies by scenario and a single trigger cannot satisfy all of them.

### Pattern D — Layered config with surgical skip

Mirror Claude Code's 4-scope settings hierarchy (Managed / Local / Project / User) + pre-commit's `stages` + `SKIP=hookid` env for per-work-type granularity. Existing habeebs precedent: `.claude/habeebs-allowed-branches` + `HABEEBS_DISABLE_HOOKS=1` (ADR-0003 + S7) — two-tier, missing the per-task-type axis.

**Fits when:** Users have multiple roles per repo (solo, collab, AFK dispatch) and need to enable/disable specific checks per role without touching the others.

### Pattern E — Inline-prompt halt + append-once JSON audit

The halt is a *skill-emitted* prompt, not a hook-blocking event — the skill retains full presentation control while the hook merely exits non-zero to gate. The audit is one JSON file per conflict at `docs/agents/conflicts/<id>.json`, mirroring ADR-0004's dispatch carve-out: single-writer, append-once, in-repo, diff-able. Honors jj's "conflict-as-data" lesson without adopting jj's commit-graph storage.

**Fits when:** You want terminal-text-native UX, full text-pager freedom (delta, difftastic), and a forensics trail that survives across sessions and machines.

### Pattern F — Worktree as resolution path + proactive policy lever (added 2026-05-22)

Worktrees play **three** roles in this mechanism, not just the original "scoped-out precondition":

1. **Resolution action.** When Session B halts on overlap with Session A, the action menu's `[w]orktree-out` option invokes `using-worktrees` to branch Session B onto a new branch in its own worktree (`git worktree add ../<repo>-<slug> <branch>`), leaving Session A undisturbed on the shared tree. Both sessions ship in parallel; merge happens later via normal PR flow. This is the right answer to "bug-fix session vs. refactor session on the same function" because it preserves both intents without forcing serial sequencing.
2. **Proactive policy lever.** The policy file declares `prefer_worktree: <work_type>` (e.g. `prefer_worktree: refactor`); the mechanism creates a worktree *before* the conflict surfaces for work types that empirically collide often. Eliminates the conflict class rather than resolving it after the fact.
3. **Namespace for the presence sidecar.** Sidecars live in `$(git rev-parse --git-common-dir)/habeebs-sessions/<id>.json` — the *common* dir, shared across every worktree of the same repo. That makes session discovery work uniformly whether Session A is on the main checkout, in an AFK worktree, or anywhere else, without re-litigating ADR-0002 (all worktrees share the same `.git/` already).

**Fits when:** The user is on a single machine across multiple sessions (the dominant scenario), and the work split is sustainable as independent branches rather than entangled edits.

**Doesn't fit:** Truly entangled edits where both sessions must agree on the same lines in the same branch (use `[m]erge` instead); or one-machine collab where worktree proliferation overwhelms the user's mental model.

### Patterns explicitly rejected

- **Bare-existence locks (git's `index.lock`).** No embedded PID — Claude Code's documented stale-`index.lock` bugs (anthropics/claude-code issues #11005, #28546, #57102) prove the failure mode. habeebs-skill MUST embed PID + hostname + start-time.
- **Continuous file-watcher daemon.** Violates ADR-0002 outright — no daemons.
- **Pre-commit-as-default trigger.** jyn.dev and Thoughtworks both document pre-commit as *"fundamentally broken"* for slow / blocking checks; 50% dev-time loss observed; `--no-verify` normalization is the failure mode habeebs's own `feedback_release_tag_hook_misfire.md` already validates.
- **Server-mediated locking (git-lfs).** Solves the mutex problem authoritatively but requires a server — ADR-0002 forbids.
- **GUI merge editor (VS Code).** Vocabulary borrowed (4-option menu) but Claude Code is terminal-text; rendering a GUI is out of scope.
- **VS Code Live Share-style relay.** Requires Azure relay — not daemon-free; dropped.
- **Pre-receive hook.** Strongest legal cross-developer trigger, but unavailable on GitHub.com — dropped.

---

## Recommendation

**For Modie's solo-multi-session dominant scenario with explicit per-repo escape for collab, use the PID-embedded sidecar + `git merge-tree` overlap probe, gated by a layered SessionStart-default / pre-push-backstop / PreToolUse-opt-in trigger mix, configured via `.claude/habeebs-policy.json`, halted via Claude Code's inline-prompt surface with a four-option menu, and audited as append-once `docs/agents/conflicts/<id>.json`.**

The 30-year track record of Vim's swap-file pattern, paired with the in-memory accuracy of `git merge-tree`, gives habeebs-skill a substrate-free mechanism that satisfies ADR-0002, ADR-0003, and ADR-0004 simultaneously. The layered trigger mix means correctness-critical paths (collab same-remote) get strong gating at `pre-push` without paying the false-positive tax of per-edit checks on solo work. The four-scope policy file lets a single user run different policies across BeanBot (solo), salahi.app (solo), and any future collab repo. Halt-as-skill-prompt (not hook-block) preserves the presentation surface Modie already trusts and keeps the action menu under the skill's control rather than the hook's opaque non-zero exit.

### Concrete picks

| Decision | Choice | Reason |
|---|---|---|
| Presence signal | `$(git rev-parse --git-common-dir)/habeebs-sessions/<id>.json` with PID + hostname + start-time + worktree path + `git stash create` SHA | Vim swap pattern; ADR-0004 JSON precedent; shared `.git/`-common-dir makes sidecars visible across every worktree of the same repo |
| Stale-signal recovery | `kill(0)` liveness probe + start-time cross-check; signals older than configurable TTL auto-pruned | Standard Unix daemon pattern |
| Overlap detection | `git merge-tree --write-tree base ours theirs` against the peer's `stash create` SHA | True 3-way conflict, not file co-edit |
| Default trigger | `SessionStart` one-shot warn-only peer scan | Vim's open-time pattern; sub-second; ADR-0003 compliant |
| Backstop trigger | `pre-push` block-only | Strongest legal cross-dev trigger; commits stay free |
| Targeted trigger | `PreToolUse` on Edit/Write, opt-in via per-repo allowlist | Catches Session A/B same-function case; gated until false-positive rate known |
| Excluded triggers | `pre-commit` (frustration); continuous watcher (ADR-0002); `pre-receive` (GitHub.com unavailable) | All three documented above |
| Policy file | `.claude/habeebs-policy.json` + `.claude/settings.local.json` for personal | Mirror Claude Code 4-scope hierarchy |
| Surgical skip env | `HABEEBS_SKIP=hookid,hookid` | Mirror pre-commit `SKIP=` |
| Trust default | Anonymous, trusted-via-PR-review | Matches solo dominant scenario |
| Trust opt-in | `require_signed_signals: true` → `git verify-commit` on signal files | Threat-model floor for collab; CVE-2024-32002 / CVE-2025-65964 surface |
| Halt UX | Inline prompt with one-line summary + `git diff --stat` + full diff piped to `$PAGER` | Terminal-text native; reuses trusted surface |
| Action menu | `[m]erge` / `[s]equence` / `[h]andoff` / `[a]bort` / `[w]orktree-out` | VS Code merge-editor vocabulary in keystrokes + worktree-out option invokes `using-worktrees` to branch Session B into its own worktree |
| Proactive worktree policy | `prefer_worktree: <work_type>` list in `.claude/habeebs-policy.json` (e.g. `[refactor, multi-file-edit]`) — mechanism creates worktree at session start for matching work types | Eliminates the conflict class proactively for work types that empirically collide |
| Audit log | `docs/agents/conflicts/<id>.json`, single-writer, append-once | ADR-0004 dispatch-record blueprint |
| ADR-0002 carve-out | New paragraph mirroring ADR-0004's four substrate-tests | Pre-empts ADR re-litigation |

### What you're explicitly giving up

- **Authoritative mutex across distributed checkouts.** git-lfs's server-mediated lock is rejected by ADR-0002; signals are advisory only. Two collaborators on different machines who both ignore the warning *can* still produce a conflict — it will be caught at `pre-push` but not prevented at edit time.
- **Sub-second guarantee on very large repos.** `git merge-tree` is fast but not free; pathological repos (>1M files, deep history) may exceed the sub-second budget. Acceptable for now; revisit if it bites.
- **Cross-machine real-time signaling.** A peer in another clone won't see your sidecar until they fetch — `SessionStart` and `pre-push` cover the practical surface, but a synchronous "you're about to type in a file I'm typing in" experience requires a server and is off the table.
- **GUI merge UX.** Action menu is keystroke-based; users wanting rich diff/merge editing must compose their own `$EDITOR` + `$PAGER` stack (delta, difftastic, etc).

### When to revisit

- If collab usage grows beyond occasional same-checkout sessions to regular multi-machine real-time editing, the advisory-only model becomes insufficient — at that point evaluate git-lfs-style server-mediated locking and accept the ADR-0002 amendment cost.
- If `PreToolUse` false-positive rate empirically lands below ~1%, promote it from opt-in to default.
- If a Windows-native liveness probe equivalent to `kill(0)` proves brittle across PowerShell vs. WSL vs. Git Bash, revisit the presence-signal format (possibly add a heartbeat-update field).
- If conflict audit volume exceeds practical grep + jq scale (~10k files), revisit storage shape — but ADR-0004 dispatches haven't hit this ceiling, so unlikely.

---

## Steering reconciliation

| Steering slot | Value | Verdict | Reason |
|---|---|---|---|
| Anchor | Navigational policy lens ("all types but navigational") | Honored | Sub-problem 4's `.claude/habeebs-policy.json` produces per-repo per-task-type config matching the navigational intent |
| Anchor | Trigger-surface deferral (user-requested situation-dependent recommendation) | Honored | Recommendation delivers a *layered* trigger mix scenario-keyed by solo / collab / opt-in rather than a single trigger pick |
| Anchor | Halt UX (LOCKED in Phase 1) | Honored | Inline-prompt halt with 4-option menu (merge / sequence / handoff / abort) ships verbatim from the locked Phase 1 spec |
| Anchor | ADR-0002 substrate constraint | Honored | All picks (sidecar JSON, merge-tree, hooks, policy file, audit JSON) are markdown + JSON + git hooks only |
| Anchor | Worktree-isolated AFK scoped out | Honored with refinement (amended 2026-05-22 on user push-back) | Original scoping retained — AFK worktrees stay filesystem-isolated. Additionally, worktrees are now a load-bearing workflow primitive in the mechanism: resolution action (`worktree-out`), proactive policy (`prefer_worktree`), and sidecar namespace (`git-common-dir/habeebs-sessions/`). `using-worktrees` becomes a skill the new mechanism *invokes*, not just adjacent to |

---

## Decisions to make next

These feed `socratic-grill` and `draft-spec`:

1. **Signal file path convention** — RESOLVED 2026-05-22: place sidecars in `$(git rev-parse --git-common-dir)/habeebs-sessions/<id>.json`. This is the *shared* `.git/` dir for the repo's main checkout AND every linked worktree, so cross-worktree session discovery works uniformly. Auto-gitignored (inside `.git/`). Remaining grill question: should the audit log (`docs/agents/conflicts/<id>.json`) follow the same path or stay repo-root tracked artifact (preferred for diff-ability)?
2. **Windows liveness probe** — `kill(0)` is POSIX-only. Options: `tasklist /FI "PID eq N"` shell-out, PowerShell `Get-Process -Id N`, or accept Windows users get start-time-based heuristic only. Modie runs on Windows 11 + WSL; needs to work in both.
3. **Opt-in vs default for `PreToolUse`** — gate behind `.claude/habeebs-policy.json` flag and ship default-off, or default-on with a kill-switch? Default-off is safer; argues for false-positive measurement first.
4. **Audit log retention** — keep all `docs/agents/conflicts/<id>.json` files forever (matches ADR-0004 dispatch pattern), prune after N days, or prune after resolution+90d? ADR-0004 keeps everything; consistency argues forever.
5. **ADR-0002 carve-out clause text** — explicit paragraph in ADR-0002 (amend in place) vs a new ADR that cross-references ADR-0002 + ADR-0004 (the "carve-out family" model)? New ADR is cleaner; precedent favors amendment.
6. **Fallback when `kill(0)` is unavailable** — degrade to start-time-only heuristic (signals older than TTL = stale), require explicit user-prune command, or refuse to install on the platform? Degrade is least friction.
7. **Action-menu keystroke set** — `[m] [s] [h] [a] [w]` as proposed (5 options now including `worktree-out`), or numeric `[1] [2] [3] [4] [5]`? Letters are mnemonic but `[h]` shadows common help-key convention and `[w]` is new; grill which wins.
8. **`prefer_worktree` default work-types** — ship empty list (opt-in per repo), ship `[refactor, multi-file-edit]` as sensible defaults, or auto-learn from observed conflict history? Empty list is conservative; auto-learn is ambitious and probably out of scope for v1.
9. **`worktree-out` interaction with uncommitted state** — when Session B picks `worktree-out`, does the mechanism (a) `git stash` Session B's changes and `git stash pop` in the new worktree, (b) use `git worktree add --detach` then cherry-pick, or (c) require Session B to commit first? Option (a) is least friction but stash-pop conflicts could recurse; (c) is cleanest. Grill it.

## Open questions

Things research didn't resolve. These feed `socratic-grill`:

- **Windows PID-probe portability:** is there a single primitive that works in PowerShell, Git Bash, *and* WSL without three code paths? Research found no clean answer.
- **Two sessions on different branches, same file:** does `git merge-tree` against a common ancestor still produce the right signal, or do we need branch-aware logic? Likely the former (merge-tree handles this natively), but grill it.
- **Worktree-as-precondition interaction:** RESOLVED 2026-05-22 — by placing sidecars in `$(git rev-parse --git-common-dir)/habeebs-sessions/`, all worktrees of a repo share the same sidecar namespace. Session B in an AFK worktree and Session A on the main checkout discover each other via the same glob, no special-casing needed.
- **Migration path for users with custom hooks:** how does the new `PreToolUse` / `pre-push` layer interact with existing per-repo hook customizations? ADR-0003's multi-harness rule applies, but the merge semantics need spelling out.
- **Sidecar lifecycle on Claude Code crash without `SessionEnd`:** does Claude Code reliably emit `SessionEnd` on crash, kill, or terminal-close? If not, stale-signal recovery becomes load-bearing and TTL choice matters more than expected.

---

## Sources

### Sub-problems 1 + 2 — Presence signaling + overlap detection

1. **Vim `:help swap-file` documentation** — https://vimhelp.org/recover.txt.html
   What it gave us: 30-year reference pattern for PID-embedded sidecar with liveness distinction.
2. **`git-merge-tree(1)` man page** — https://git-scm.com/docs/git-merge-tree
   What it gave us: In-memory 3-way merge primitive; *"does not read from or write to either the working tree or index."*
3. **Anthropics/claude-code issue #11005 (stale `index.lock`)** — https://github.com/anthropics/claude-code/issues/11005
   What it gave us: Negative evidence — bare-existence lock without PID fails in practice.
4. **Anthropics/claude-code issues #28546, #57102** — https://github.com/anthropics/claude-code/issues/28546
   What it gave us: Reinforcement of the stale-lock failure mode across reports.
5. **Unix PID-file + `kill(0)` daemon pattern** — https://man7.org/linux/man-pages/man2/kill.2.html
   What it gave us: Liveness-probe primitive (signal 0 doesn't deliver, only checks signalability).
6. **git-lfs locking design** — https://github.com/git-lfs/git-lfs/wiki/File-Locking
   What it gave us: Negative evidence — pure-filesystem locks can't guarantee mutex across distributed teams; advisory ceiling.
7. **JetBrains / VSCode optimistic-concurrency reload dialog** — VS Code docs on file-change detection
   What it gave us: Do-nothing baseline that current Claude Code session state already matches.

### Sub-problem 3 — Trigger surface

8. **jyn.dev — "pre-commit is fundamentally broken"** — https://jyn.dev/pre-commit-is-broken/
   What it gave us: Documented frustration evidence against pre-commit-as-default.
9. **Thoughtworks Technology Radar — slow git hooks** — https://www.thoughtworks.com/radar
   What it gave us: 50% dev-time loss; `--no-verify` normalization as the failure pattern.
10. **Claude Code hooks reference (`SessionStart`, `PreToolUse`)** — https://docs.anthropic.com/en/docs/claude-code/hooks
    What it gave us: Native trigger surface for the SessionStart-default + PreToolUse-opt-in legs.
11. **Git `pre-push` hook docs** — https://git-scm.com/docs/githooks#_pre_push
    What it gave us: Strongest legal cross-developer block trigger.
12. **GitHub.com `pre-receive` availability** — https://docs.github.com/en/enterprise-cloud@latest/admin/policies/enforcing-policy-with-pre-receive-hooks
    What it gave us: Confirms unavailable on github.com (Enterprise only) — dropped.
13. **habeebs-skill `feedback_release_tag_hook_misfire.md`** (internal memory)
    What it gave us: Modie's own pain point validating sub-second / low-false-positive requirement.

### Sub-problem 4 — Policy + trust

14. **Claude Code settings hierarchy (Managed / Local / Project / User)** — https://docs.anthropic.com/en/docs/claude-code/settings
    What it gave us: 4-scope reference model habeebs-skill should mirror.
15. **pre-commit framework `stages` + `SKIP` env** — https://pre-commit.com/#confining-hooks-to-run-at-certain-stages
    What it gave us: Per-stage gate vocabulary and surgical-skip env var pattern.
16. **Husky `HUSKY=0` nuclear skip** — https://typicode.github.io/husky/how-to.html
    What it gave us: Negative evidence — nuclear toggle insufficient for per-work-type granularity.
17. **CVE-2024-32002 (`core.hooksPath` exploitation)** — https://nvd.nist.gov/vuln/detail/CVE-2024-32002
    What it gave us: Threat-model floor — hooks-as-code is actively-exploited attack surface.
18. **CVE-2025-65964 + CISA KEV listing** — https://www.cisa.gov/known-exploited-vulnerabilities-catalog
    What it gave us: Reinforces sign-signals-or-warn-only stance for cross-machine trust.
19. **habeebs-skill ADR-0003 + scope sentinel (S7)** — `docs/agents/adrs/0003-hooks-scope.md`
    What it gave us: Existing two-tier precedent (`.claude/habeebs-allowed-branches` + `HABEEBS_DISABLE_HOOKS=1`); missing per-task-type axis.
20. **`git verify-commit` for signal-as-trust** — https://git-scm.com/docs/git-verify-commit
    What it gave us: Signed-signal validation primitive for `require_signed_signals: true` opt-in.

### Sub-problem 5 — Halt UX + audit

21. **jj conflict-as-data design** — https://github.com/martinvonz/jj/blob/main/docs/conflicts.md
    What it gave us: Lesson — conflicts deserve durable structured representation, even if we don't adopt the commit-graph mechanism.
22. **Claude Code inline prompt + permission UX** — https://docs.anthropic.com/en/docs/claude-code/permissions
    What it gave us: Terminal-text-native halt surface the user already trusts.
23. **VS Code merge-editor 3-way UI vocabulary** — https://code.visualstudio.com/docs/sourcecontrol/overview#_3way-merge-editor
    What it gave us: 4-option action menu vocabulary (accept-current / accept-incoming / both / abort) transposed to keystrokes.
24. **habeebs-skill ADR-0004 dispatch-record contract** — `docs/agents/adrs/0004-parallel-subagent-dispatch-contract.md`
    What it gave us: Direct blueprint for `docs/agents/conflicts/<id>.json` — single-writer, append-once, in-repo JSON.
25. **habeebs-skill `using-worktrees` Phase 6.5 (squash-merge ghost recovery)** — `skills/using-worktrees/SKILL.md`
    What it gave us: Same-philosophy precedent for in-repo no-substrate conflict resolution. ALSO: load-bearing skill the new mechanism *invokes* for the `[w]orktree-out` resolution action and the `prefer_worktree` proactive policy lever (per Pattern F).
27. **`git-worktree(1)` man page — built-in branch mutex** — https://git-scm.com/docs/git-worktree
    What it gave us: Filesystem-only mutex precedent (Git refuses to attach two worktrees to the same branch) — confirms `$(git rev-parse --git-common-dir)/worktrees/` as the right namespace for cross-worktree presence state, and resolves the cross-worktree visibility open question.
26. **habeebs-skill ADR-0015 tag-push carve-out** — `docs/agents/adrs/0015-tag-push-carve-out.md`
    What it gave us: Precedent for narrowing predicate on existing hook rather than adding a new hook (informs ADR-0002 carve-out clause text decision).

---

HANDOFF: spec ready — invoke `draft-spec` to turn this into an implementation spec.
HANDOFF: grill ready — invoke `socratic-grill` to drive ambiguity out of the open questions and decisions above.
HANDOFF: record ready — once spec + grill complete, invoke `decision-record` to capture the chosen architecture as an ADR.

(no active steering to flush)
