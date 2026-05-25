#!/usr/bin/env bash
# Dogfood scenario 25 — release-skill path audit + 5 named error messages
# Per spec slice #3 (v1.20.0-methodology-overhaul) + ADR adr-late-binding-and-changesets § Decision.
#
# Verifies skills/release/scripts/check-changeset-required.sh:
#   (a) REQUIRED path classes: skills/, hooks/, .claude-plugin/, plugin.json, marketplace.json
#       — without changeset → exit 1 + path-required error message
#   (b) OPTIONAL path classes: docs/, CLAUDE.md, AGENTS.md, README.md, CHANGELOG.md
#       — without changeset → exit 0 + INFO note
#   (c) NEVER classes: tests/, .gitignore, .github/, .gitattributes
#       — without changeset → exit 0, silent
#   (d) With changeset present → exit 0 regardless of which paths touched
#   (e) 5 named error messages present in script output (asserted via grep against
#       --print-messages mode that prints all message templates):
#         - Missing bump
#         - Invalid bump value
#         - Empty why
#         - Two identical-slug ADRs
#         - Required path without changeset

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPT="$REPO_ROOT/skills/release/scripts/check-changeset-required.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f "$SCRIPT" ] || fail "$SCRIPT missing (slice #3 not implemented)"
[ -x "$SCRIPT" ] || fail "$SCRIPT not executable"

# Fixture: a temp dir simulating git diff output via --changed-files-from <file>
# Avoids needing a real git repo for the test.
make_fixture() {
  mktemp -d
}

# ---------------------------------------------------------------------------
# Case (a) — REQUIRED paths without changeset → exit 1 + named error
# ---------------------------------------------------------------------------
DIR=$(make_fixture)
printf 'skills/foo/SKILL.md\nhooks/bar.sh\n' > "$DIR/changed.txt"
mkdir "$DIR/.changeset"  # empty .changeset (no real changesets)
set +e
OUT=$("$SCRIPT" --changed-files "$DIR/changed.txt" --changeset-dir "$DIR/.changeset" 2>&1)
EC=$?
set -e
[ "$EC" -eq 1 ] || fail "(a) REQUIRED path without changeset: expected exit 1, got $EC"
echo "$OUT" | grep -F "PR modifies skill files but contains no" >/dev/null || \
  fail "(a) missing required-path error message. Got: $OUT"
echo "$OUT" | grep -F "See \`.changeset/README.md\`" >/dev/null || \
  fail "(a) missing remediation pointer. Got: $OUT"
rm -rf "$DIR"
pass "(a) REQUIRED path without changeset halts with exit 1 + named message"

# ---------------------------------------------------------------------------
# Case (b) — OPTIONAL paths without changeset → exit 0 + INFO note
# ---------------------------------------------------------------------------
DIR=$(make_fixture)
printf 'docs/agents/research/foo.md\nCLAUDE.md\n' > "$DIR/changed.txt"
mkdir "$DIR/.changeset"
OUT=$("$SCRIPT" --changed-files "$DIR/changed.txt" --changeset-dir "$DIR/.changeset" 2>&1)
EC=$?
[ "$EC" -eq 0 ] || fail "(b) OPTIONAL path: expected exit 0, got $EC"
echo "$OUT" | grep -qi "info\|optional" || fail "(b) OPTIONAL: expected INFO/optional note. Got: $OUT"
rm -rf "$DIR"
pass "(b) OPTIONAL path without changeset: exit 0 with INFO note"

# ---------------------------------------------------------------------------
# Case (c) — NEVER paths → exit 0 silent
# ---------------------------------------------------------------------------
DIR=$(make_fixture)
printf 'tests/dogfood/foo/check.sh\n.gitignore\n.github/workflows/foo.yml\n' > "$DIR/changed.txt"
mkdir "$DIR/.changeset"
"$SCRIPT" --changed-files "$DIR/changed.txt" --changeset-dir "$DIR/.changeset" >/dev/null 2>&1 || \
  fail "(c) NEVER path: expected exit 0"
rm -rf "$DIR"
pass "(c) NEVER paths without changeset: exit 0 (silent)"

# ---------------------------------------------------------------------------
# Case (d) — REQUIRED path WITH changeset → exit 0
# ---------------------------------------------------------------------------
DIR=$(make_fixture)
printf 'skills/foo/SKILL.md\n' > "$DIR/changed.txt"
mkdir "$DIR/.changeset"
cat > "$DIR/.changeset/my-change.md" <<'EOF'
---
bump: minor
why: example change
---
EOF
"$SCRIPT" --changed-files "$DIR/changed.txt" --changeset-dir "$DIR/.changeset" >/dev/null 2>&1 || \
  fail "(d) REQUIRED + changeset: expected exit 0"
rm -rf "$DIR"
pass "(d) REQUIRED path WITH changeset: exit 0"

# ---------------------------------------------------------------------------
# Case (e) — All 5 named error messages present in --print-messages output
# ---------------------------------------------------------------------------
OUT=$("$SCRIPT" --print-messages 2>&1)
EC=$?
[ "$EC" -eq 0 ] || fail "(e) --print-messages: expected exit 0, got $EC"
echo "$OUT" | grep -F "missing required \`bump\` frontmatter field" >/dev/null || \
  fail "(e) missing message: 'missing required bump frontmatter field'"
echo "$OUT" | grep -F "has invalid \`bump:" >/dev/null || \
  fail "(e) missing message: 'has invalid bump:'"
echo "$OUT" | grep -F "missing \`why:\` line" >/dev/null || \
  fail "(e) missing message: 'missing why: line'"
echo "$OUT" | grep -F "Cannot rename — two ADRs share slug" >/dev/null || \
  fail "(e) missing message: 'Cannot rename — two ADRs share slug'"
echo "$OUT" | grep -F "PR modifies skill files but contains no" >/dev/null || \
  fail "(e) missing message: 'PR modifies skill files but contains no'"
pass "(e) all 5 named error messages present in --print-messages output"

echo
echo "===SCENARIO 25 ALL 5 CASES PASS==="
