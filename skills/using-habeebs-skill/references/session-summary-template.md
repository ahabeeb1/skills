# Session summary — <slug>

**Date / time:** YYYY-MM-DD HH:MM
**Reason for flush:** [conversation-length pressure | prompt-cache TTL | repeated re-reads | user-requested | other]
**Branch:** [current branch name]
**Commit SHA at flush:** [short SHA]

Per [ADR-0012](../adrs/0012-compress-at-overflow-protocol.md). Save to `.scratch/session-summary-YYYY-MM-DD-HHMM.md` and start a fresh sub-session that loads this file + the artifacts listed below.

---

## 1. Active artifacts

(File paths the next sub-session MUST read in full before continuing work. Order: spec → grill → ADRs in flight → plan → current slice file → postmortem if any.)

- Spec: `docs/agents/specs/<slug>.md`
- Grill: `docs/agents/specs/<slug>-grill.md`
- Plan: `docs/agents/plans/<NNNN-slug>.md`
- ADRs in flight:
  - `docs/agents/adrs/<NNNN-slug>.md`
  - ...
- Current postmortem (if any): `docs/agents/postmortems/YYYY-MM-DD-<slug>.md`

## 2. Current slice

**Slice ID:** #N
**Slice name:** [from plan]
**Phase:** [from plan, e.g., Phase 1]
**Acceptance criteria status:**

- [x] Criterion 1 — done at commit <SHA>
- [x] Criterion 2 — done
- [ ] Criterion 3 — **in progress at flush time**
- [ ] Criterion 4 — not started
- [ ] Criterion 5 — not started

**The agent was working on:** [one sentence — which criterion, what step, where in the file]

## 3. Last successful action

(The anchor point a fresh sub-session can rewind to. Pick ONE — the most recent verifiable success.)

- **Commit:** `<SHA>` — "<commit message subject>"

OR

- **Test pass:** `<test-path>` — last green run
- **File written:** `<file-path>` — last successful write

## 4. What's blocking

**Immediate next action:** [one sentence — what the agent should do first on resume]

**Blocker:** [one of:]
- Missing input from user — [what to ask for]
- Failing test — [test path + error message]
- Open grill question — [grill-record path + Q-ID]
- Unresolved dependency — [what's missing]
- No blocker — agent can continue directly

## 5. Open grill Qs from this session

(Q-IDs from grill records that drove decisions during this session. Lets the next sub-session re-read the rationale for why something is shaped a certain way.)

- [Grill record path] § Item Q<N> — [one-line summary of resolution]
- ...

(If no grill questions, write `(none — implementation slice, no decisions taken here)`)

## 6. Recent test state

**Last full dogfood run:** YYYY-MM-DD HH:MM
- **Result:** PASS | FAIL
- **Failing scenarios (if any):** [list]
- **Red commits since last green:** [SHAs, or `(none — branch is green)`]

## 7. Branch / worktree pointer

- **Branch:** [name]
- **Worktree path:** [absolute path, or "in-place (current directory)"]
- **Commit SHA at flush:** [short SHA]
- **Origin parent:** [commit SHA from origin/<branch> at last fetch, for divergence detection]

---

## Fresh sub-session resume protocol

After loading this summary, the fresh sub-session should:

1. Read all files in § 1 Active artifacts (in order — spec first, then grill, then ADRs, then plan, then slice file, then postmortem).
2. Verify § 7 branch / worktree pointer matches the resume environment (`git rev-parse HEAD` matches the SHA).
3. Verify § 6 test state matches reality (run the last-known-green test path; confirm pass).
4. Re-read § 4 what's blocking and § 2 current-slice acceptance criteria status.
5. Resume from § 4 immediate next action.

If any verification fails, halt and surface the discrepancy. Do not assume the summary is stale-but-mostly-right.
