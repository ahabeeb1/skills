#!/usr/bin/env bash
# habeebs-skill test — Codex hook registration parity (Slice 4, dual-native parity).
#
# Codex's hooks engine mirrors Claude's hooks.json event schema. .codex/config.toml
# must register the SAME hook scripts as hooks/hooks.json so guardrails (default-
# branch block, peer scan, chain-state validator) fire identically on both harnesses.
#
#   (a) .codex/config.toml exists.
#   (b) the set of hook scripts referenced in config.toml == the set in hooks.json.
#   (c) every referenced script exists on disk and is non-empty.
#   (d) Codex regex matchers are anchored AND match Codex's ACTUAL reported
#       tool_name: ^Bash$ for shell, ^(apply_patch|Edit|Write)$ for edits.
#       Critically, the edit matcher MUST match "apply_patch" — Codex's canonical
#       edit tool_name — or the hook silently no-ops on real Codex edits.
#   (e) the Bash-matched commit-block hook emits Codex's deny shape
#       (hookSpecificOutput.permissionDecision = "deny"), not exit 2 alone.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TOML="$REPO_ROOT/.codex/config.toml"
JSON="$REPO_ROOT/hooks/hooks.json"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# (a)
[ -f "$TOML" ] || fail "(a) .codex/config.toml missing"
[ -f "$JSON" ] || fail "(a) hooks/hooks.json missing (parity baseline)"
pass "(a) .codex/config.toml present"

# (b) script-set parity. Extract referenced hook script basenames from each file.
scripts_in() { grep -oE 'hooks/[a-z-]+\.sh' "$1" | sed 's#hooks/##' | sort -u; }
json_scripts="$(scripts_in "$JSON")"
toml_scripts="$(scripts_in "$TOML")"

if [ "$json_scripts" != "$toml_scripts" ]; then
  echo "  hooks.json scripts:" >&2; echo "$json_scripts" | sed 's/^/    /' >&2
  echo "  config.toml scripts:" >&2; echo "$toml_scripts" | sed 's/^/    /' >&2
  fail "(b) Codex config does not register the same hook scripts as Claude"
fi
pass "(b) config.toml registers the identical hook-script set ($(echo "$toml_scripts" | wc -l | tr -d ' ') scripts)"

# (c) every referenced script exists and is non-empty
while IFS= read -r s; do
  [ -n "$s" ] || continue
  [ -s "$REPO_ROOT/hooks/$s" ] || fail "(c) referenced script missing/empty: hooks/$s"
done <<< "$toml_scripts"
pass "(c) every referenced hook script exists and is non-empty"

# (d) matcher correctness. Both matchers must be present and match Codex's
# ACTUAL reported tool_name (apply_patch for edits, Bash for shell).
grep -qE 'matcher[[:space:]]*=[[:space:]]*"\^Bash\$"' "$TOML" || fail "(d) missing anchored ^Bash\$ matcher"
grep -qE 'matcher[[:space:]]*=[[:space:]]*"\^\(apply_patch\|Edit\|Write\)\$"' "$TOML" \
  || fail "(d) missing anchored ^(apply_patch|Edit|Write)\$ edit matcher"

# Behavioral check of the regex dialect (POSIX ERE stands in for Codex's engine).
edit_matcher='^(apply_patch|Edit|Write)$'
echo "Bash"        | grep -qE '^Bash$' || fail "(d) ^Bash\$ should match Bash"
echo "Bashx"       | grep -qE '^Bash$' && fail "(d) ^Bash\$ must NOT match Bashx"
# THE property the suite exists to guarantee: Codex reports tool_name=apply_patch
# for edits — the matcher MUST match it, or the hook never fires on Codex.
echo "apply_patch" | grep -qE "$edit_matcher" || fail "(d) edit matcher MUST match Codex's canonical tool_name 'apply_patch'"
for t in Edit Write; do
  echo "$t" | grep -qE "$edit_matcher" || fail "(d) edit matcher should match Claude alias $t"
done
echo "Read"        | grep -qE "$edit_matcher" && fail "(d) edit matcher must NOT match Read"
pass "(d) anchored matchers match Codex's real tool_name (apply_patch + Bash) and Claude aliases"

# (e) the commit-block hook denies via Codex's documented JSON shape, not exit 2 alone.
BLOCK_HOOK="$REPO_ROOT/hooks/preventing-commits-to-default.sh"
[ -f "$BLOCK_HOOK" ] || fail "(e) commit-block hook missing"
grep -q '"permissionDecision"' "$BLOCK_HOOK" \
  || fail "(e) commit-block hook does not emit permissionDecision (Codex deny path)"
grep -q '"deny"' "$BLOCK_HOOK" \
  || fail "(e) commit-block hook permissionDecision is not 'deny'"
grep -q 'hookEventName' "$BLOCK_HOOK" \
  || fail "(e) commit-block deny JSON missing hookEventName"
pass "(e) commit-block hook emits Codex's permissionDecision=deny JSON (+ exit 2 fallback)"

echo
echo "===CODEX HOOK-PARITY ALL 5 CASES PASS==="
