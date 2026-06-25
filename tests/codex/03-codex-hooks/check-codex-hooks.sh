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
#   (d) Codex regex matchers are anchored AND match exactly the Claude tool set
#       (^Bash$ matches "Bash" not "Bashx"; ^(Edit|Write|NotebookEdit)$ matches all three).

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

# (d) matcher correctness. The two matchers must be present and behave correctly.
grep -qE 'matcher[[:space:]]*=[[:space:]]*"\^Bash\$"' "$TOML" || fail "(d) missing anchored ^Bash\$ matcher"
grep -qE 'matcher[[:space:]]*=[[:space:]]*"\^\(Edit\|Write\|NotebookEdit\)\$"' "$TOML" \
  || fail "(d) missing anchored ^(Edit|Write|NotebookEdit)\$ matcher"

# Behavioral check of the regex dialect (POSIX ERE stands in for Codex's engine).
echo "Bash"          | grep -qE '^Bash$'                    || fail "(d) ^Bash\$ should match Bash"
echo "Bashx"         | grep -qE '^Bash$'                    && fail "(d) ^Bash\$ must NOT match Bashx"
for t in Edit Write NotebookEdit; do
  echo "$t" | grep -qE '^(Edit|Write|NotebookEdit)$' || fail "(d) tool matcher should match $t"
done
echo "Read" | grep -qE '^(Edit|Write|NotebookEdit)$' && fail "(d) tool matcher must NOT match Read"
pass "(d) anchored matchers present and match exactly the Claude tool set"

echo
echo "===CODEX HOOK-PARITY ALL 4 CASES PASS==="
