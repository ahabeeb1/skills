#!/usr/bin/env bash
# habeebs-skill test — SKILL.md frontmatter parity (Slice 1, dual-native parity).
#
# The dual-native ADR (2026-06-25) picks MINIMAL frontmatter — only the keys both
# Claude Code and Codex CLI honor — on the verified premise that Codex's Agent
# Skills schema requires name+description and ignores other keys. This suite
# guards that premise: if a skill ever grows a non-portable frontmatter key, the
# minimal-frontmatter assumption (and the no-dual-key decision) must be revisited.
#
#   (a) every canonical SKILL.md has name + description.
#   (b) the skill `name` matches its parent directory (Codex hard requirement).
#   (c) frontmatter uses ONLY the portable allow-list {name, description,
#       disable-model-invocation}; any other key fails loud.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SRC="$REPO_ROOT/skills"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# Allowed frontmatter keys (portable across Claude Code + Codex CLI).
ALLOWED="name description disable-model-invocation"

# Extract frontmatter top-level keys from a SKILL.md (between the first two ---).
fm_keys() {
  awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---" { exit }
    infm && /^[A-Za-z][A-Za-z0-9_-]*:/ {
      k=$0; sub(/:.*/,"",k); print k
    }
  ' "$1"
}

violations=0
for d in "$SRC"/*/; do
  skill="${d}SKILL.md"
  [ -f "$skill" ] || continue
  name="$(basename "$d")"

  keys="$(fm_keys "$skill")"

  # (a) name + description present
  echo "$keys" | grep -qx "name" || { echo "  $name: missing 'name'" >&2; violations=1; }
  echo "$keys" | grep -qx "description" || { echo "  $name: missing 'description'" >&2; violations=1; }

  # (b) name matches directory
  declared="$(awk 'NR==1&&$0=="---"{infm=1;next} infm&&$0=="---"{exit} infm&&/^name:/{sub(/^name:[[:space:]]*/,"");print;exit}' "$skill")"
  [ "$declared" = "$name" ] || { echo "  $name: frontmatter name '$declared' != dir" >&2; violations=1; }

  # (c) only allow-listed keys
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    case " $ALLOWED " in
      *" $k "*) : ;;
      *) echo "  $name: non-portable frontmatter key '$k' (not in {$ALLOWED})" >&2; violations=1 ;;
    esac
  done <<< "$keys"
done

[ "$violations" -eq 0 ] || fail "frontmatter parity violations found (see above)"
pass "(a) every SKILL.md has name + description"
pass "(b) every skill name matches its directory"
pass "(c) all frontmatter keys are in the portable allow-list"

echo
echo "===CODEX FRONTMATTER-PARITY ALL 3 CASES PASS==="
