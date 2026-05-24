#!/usr/bin/env bash
# Cross-session conflict detection — overlap probe primitive (slice-26, v1.16.0).
#
# Wraps `git merge-tree` (pre-2.38 three-tree form) to detect file-level
# conflicts between the current HEAD and a peer's tree SHA. Returns JSON.
#
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 4)
#
# Subcommands:
#   probe  --peer-sha <sha>    returns {"conflicted": bool, "files": [paths]}

set -u

cmd=${1:-}
shift || true

do_probe() {
  local peer_sha=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --peer-sha) peer_sha="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  [ -n "$peer_sha" ] || { echo "probe requires --peer-sha" >&2; exit 2; }

  local our_sha
  our_sha=$(git rev-parse HEAD)

  if [ "$our_sha" = "$peer_sha" ]; then
    echo '{"conflicted":false,"files":[]}'
    return 0
  fi

  local base_sha
  base_sha=$(git merge-base "$our_sha" "$peer_sha" 2>/dev/null) || base_sha=""

  local base_tree our_tree peer_tree
  if [ -n "$base_sha" ]; then
    base_tree=$(git rev-parse "$base_sha^{tree}")
  else
    base_tree=$(git hash-object -t tree /dev/null 2>/dev/null || echo "4b825dc642cb6eb9a060e54bf899d15363d7ed7d")
  fi
  our_tree=$(git rev-parse "$our_sha^{tree}")
  peer_tree=$(git rev-parse "$peer_sha^{tree}")

  if [ "$our_tree" = "$peer_tree" ]; then
    echo '{"conflicted":false,"files":[]}'
    return 0
  fi

  local merge_output
  merge_output=$(git merge-tree "$base_tree" "$our_tree" "$peer_tree" 2>&1) || true

  # Pre-2.38 `git merge-tree` outputs blocks with headers:
  #   "changed in both"    — content conflict
  #   "added in both"      — add/add conflict
  #   "removed in remote"  — modify/delete (we modified, they deleted)
  #   "removed in local"   — modify/delete (they modified, we deleted)
  #   "merged"             — clean merge (NOT a conflict)
  # Each block has indented lines: base/our/their/result + sha + filename.
  # We only extract filenames from conflict blocks, not "merged" blocks.

  local conflict_files
  conflict_files=$(node -e "
    const output = process.argv[1];
    const files = new Set();
    let inConflict = false;
    for (const line of output.split('\\n')) {
      if (/^(changed in both|added in both|removed in (remote|local))/.test(line)) {
        inConflict = true;
      } else if (/^[a-z]/.test(line)) {
        inConflict = false;
      } else if (inConflict) {
        const m = line.match(/^\\s+(?:base|our|their|result)\\s+\\d+\\s+[0-9a-f]+\\s+(.+)/);
        if (m) files.add(m[1]);
      }
    }
    process.stdout.write([...files].sort().join('\\n'));
  " "$merge_output")

  if [ -z "$conflict_files" ]; then
    echo '{"conflicted":false,"files":[]}'
  else
    local json_files
    json_files=$(node -e "
      const lines = process.argv[1].split('\\n').filter(Boolean);
      process.stdout.write(JSON.stringify(lines));
    " "$conflict_files")
    echo "{\"conflicted\":true,\"files\":$json_files}"
  fi

  return 0
}

case "$cmd" in
  probe) do_probe "$@" ;;
  *) echo "usage: overlap.sh {probe} --peer-sha <sha>" >&2; exit 2 ;;
esac
