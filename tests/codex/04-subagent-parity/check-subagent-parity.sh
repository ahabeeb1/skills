#!/usr/bin/env bash
# habeebs-skill test — subagent dispatch parity (Slice 5, dual-native parity).
#
# Deep-tier research and parallel-dev fan out to subagents. For full Codex parity
# the dispatch machinery must be harness-NEUTRAL: expressed against the subagent
# abstraction both Claude Code and Codex provide, with a sequential fallback for
# harnesses that lack one. This suite guards that neutrality so a future edit
# can't silently re-couple dispatch to a single harness.
#
#   (a) parallel-dev documents harness portability, naming BOTH Claude Code and Codex.
#   (b) parallel-dev specifies a sequential fallback when no subagent primitive exists.
#   (c) the agents/ subagent prompts carry NO harness-exclusive assumption (no "Claude"-only).
#   (d) every agents/ prompt is dispatch-contract-driven (cites the ADR-0004 4-status contract),
#       so dispatch is governed by the contract, not by a specific runtime.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PD="$REPO_ROOT/skills/parallel-dev/SKILL.md"
AGENTS_DIR="$REPO_ROOT/agents"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f "$PD" ] || fail "parallel-dev SKILL.md missing"

# (a) portability note naming both harnesses
grep -qi "harness portability" "$PD" || fail "(a) parallel-dev has no 'Harness portability' note"
grep -qi "Claude Code" "$PD" || fail "(a) portability note must name Claude Code"
grep -qi "Codex" "$PD"      || fail "(a) portability note must name Codex"
pass "(a) parallel-dev documents dual-harness dispatch (Claude Code + Codex)"

# (b) sequential fallback documented
grep -qiE "fall back to sequential|sequential (execution|fallback)" "$PD" \
  || fail "(b) parallel-dev must specify a sequential fallback for no-subagent harnesses"
pass "(b) sequential fallback documented for harnesses without a subagent primitive"

# (c) no harness-exclusive assumption in subagent prompts
shopt -s nullglob
prompts=("$AGENTS_DIR"/*.md)
[ "${#prompts[@]}" -gt 0 ] || fail "(c) no agent prompts found under agents/"
for p in "${prompts[@]}"; do
  # A subagent prompt must not hard-bind to one harness. "Claude"/"Codex" naming
  # in a prompt body would couple it; the prompts are written runtime-neutral.
  if grep -qiE '\bClaude\b|\bCodex\b' "$p"; then
    echo "  $(basename "$p"): names a specific harness" >&2
    fail "(c) agent prompt is not harness-neutral"
  fi
done
pass "(c) all ${#prompts[@]} agent prompts are harness-neutral"

# (d) every prompt is dispatch-contract-driven (ADR-0004)
for p in "${prompts[@]}"; do
  grep -qE 'ADR-0004|0004-parallel-subagent' "$p" \
    || { echo "  $(basename "$p"): no ADR-0004 dispatch-contract reference" >&2; fail "(d) prompt not contract-driven"; }
done
pass "(d) every agent prompt cites the harness-neutral ADR-0004 dispatch contract"

echo
echo "===CODEX SUBAGENT-PARITY ALL 4 CASES PASS==="
