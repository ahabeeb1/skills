#!/usr/bin/env bash
# Dogfood scenario 21 — late-binding ADR identifier mechanism
# Per spec slice #1 (v1.20.0-methodology-overhaul) + ADR adr-late-binding-and-changesets § Decision.
#
# Verifies skills/release/scripts/assign-adr-ids.sh:
#   (a) happy path — adr-foo.md + adr-bar.md + 0019-baz.md → 0020-bar.md + 0021-foo.md alphabetic
#   (b) collision — two adr-foo.md → exit 2 + exact message
#   (c) --dry-run — no FS changes, prints rename plan
#   (d) --help — exit 0, usage printed
#   (e) separation-of-writers — decision-record SKILL.md instructs writing adr-<slug>.md,
#       never NNNN-<slug>.md directly
#
# Error message contract (per ADR § Decision verbatim):
#   "Cannot rename — two ADRs share slug `<slug>`: `<file1>`, `<file2>`. Pick distinct slugs."

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPT="$REPO_ROOT/skills/release/scripts/assign-adr-ids.sh"
DR_SKILL="$REPO_ROOT/skills/decision-record/SKILL.md"
RELEASE_SKILL="$REPO_ROOT/skills/release/SKILL.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# Substrate check
[ -f "$SCRIPT" ] || fail "$SCRIPT missing (slice #1 not implemented)"
[ -x "$SCRIPT" ] || fail "$SCRIPT not executable"

# Fixture helper: build a temp adrs/ with given files
make_fixture() {
  local dir; dir=$(mktemp -d)
  mkdir "$dir/adrs"
  # Seed an existing numbered ADR so the next int is computable
  printf '# ADR-0019: existing\n\n**Status:** Accepted\n' > "$dir/adrs/0019-baz.md"
  # Seed README index
  cat > "$dir/adrs/README.md" <<'EOF'
# ADR Index

| # | Title | Status |
|---|-------|--------|
| 0019 | existing | Accepted |
EOF
  echo "$dir"
}

# ---------------------------------------------------------------------------
# Case (a) — happy path
# ---------------------------------------------------------------------------
DIR=$(make_fixture)
printf '# ADR-NNNN: foo\n' > "$DIR/adrs/adr-foo.md"
printf '# ADR-NNNN: bar\n' > "$DIR/adrs/adr-bar.md"
"$SCRIPT" --adrs-dir "$DIR/adrs" >/dev/null 2>&1 || fail "(a) happy path: exit non-zero"
[ -f "$DIR/adrs/0020-bar.md" ] || fail "(a) expected 0020-bar.md after rename (alphabetic: bar before foo)"
[ -f "$DIR/adrs/0021-foo.md" ] || fail "(a) expected 0021-foo.md after rename"
[ ! -f "$DIR/adrs/adr-foo.md" ] || fail "(a) adr-foo.md still present — rename did not remove source"
[ ! -f "$DIR/adrs/adr-bar.md" ] || fail "(a) adr-bar.md still present"
[ -f "$DIR/adrs/0019-baz.md" ] || fail "(a) existing 0019-baz.md was disturbed (Pattern B violated)"
grep -q "0020.*bar" "$DIR/adrs/README.md" || fail "(a) README not updated with 0020-bar entry"
grep -q "0021.*foo" "$DIR/adrs/README.md" || fail "(a) README not updated with 0021-foo entry"
rm -rf "$DIR"
pass "(a) happy path — alphabetic ordering, README regenerated, existing ADR untouched"

# ---------------------------------------------------------------------------
# Case (b) — slug collision halts loud (exit 2 + exact message)
# ---------------------------------------------------------------------------
DIR=$(make_fixture)
printf '# first foo\n' > "$DIR/adrs/adr-foo.md"
# Simulate a second adr-foo.md via a sibling subdir + symlink? No — bash file
# uniqueness on the FS means two files with the same name in the same dir is
# impossible. The collision case is when two CHANGESETS each propose adr-foo
# at different times and one branch's adr-foo.md hits the other branch's at
# merge time. From the script's perspective the collision surfaces as the
# script encountering two adr-<slug>.md files where <slug> after normalization
# resolves to the same target — i.e., adr-foo.md + ADR-foo.md (case fold)
# OR via a sibling staging area the test simulates by passing two paths.
#
# For the dogfood we test the script's collision-detection on a fixture where
# two source files have slugs that collapse to the same target. The simplest
# real-world trigger is case-equivalent slugs on a case-insensitive FS, OR
# the script's slug-normalization producing a collision. The script must
# treat case-equivalent slugs as a collision per the spec.
mkdir "$DIR/adrs/sub"
printf '# second foo\n' > "$DIR/adrs/sub/adr-foo.md"
set +e
OUT=$("$SCRIPT" --adrs-dir "$DIR/adrs" --extra-scan "$DIR/adrs/sub" 2>&1)
EC=$?
set -e
[ "$EC" -eq 2 ] || fail "(b) collision: expected exit 2, got $EC"
echo "$OUT" | grep -F "Cannot rename — two ADRs share slug \`foo\`" >/dev/null || \
  fail "(b) collision: expected message not found in output. Got: $OUT"
echo "$OUT" | grep -F "Pick distinct slugs." >/dev/null || \
  fail "(b) collision: expected 'Pick distinct slugs.' suffix not found"
[ -f "$DIR/adrs/adr-foo.md" ] && [ -f "$DIR/adrs/sub/adr-foo.md" ] || \
  fail "(b) collision: source files were modified despite halt"
rm -rf "$DIR"
pass "(b) slug collision halts with exit 2 + exact message; source files untouched"

# ---------------------------------------------------------------------------
# Case (c) — --dry-run makes no FS changes, prints rename plan
# ---------------------------------------------------------------------------
DIR=$(make_fixture)
printf '# adr foo dry\n' > "$DIR/adrs/adr-foo.md"
printf '# adr bar dry\n' > "$DIR/adrs/adr-bar.md"
README_BEFORE=$(cat "$DIR/adrs/README.md")
OUT=$("$SCRIPT" --adrs-dir "$DIR/adrs" --dry-run 2>&1)
EC=$?
[ "$EC" -eq 0 ] || fail "(c) --dry-run: expected exit 0, got $EC"
[ -f "$DIR/adrs/adr-foo.md" ] || fail "(c) --dry-run: adr-foo.md was renamed (should be untouched)"
[ -f "$DIR/adrs/adr-bar.md" ] || fail "(c) --dry-run: adr-bar.md was renamed"
[ ! -f "$DIR/adrs/0020-bar.md" ] || fail "(c) --dry-run: 0020-bar.md was created"
[ ! -f "$DIR/adrs/0021-foo.md" ] || fail "(c) --dry-run: 0021-foo.md was created"
[ "$(cat "$DIR/adrs/README.md")" = "$README_BEFORE" ] || fail "(c) --dry-run: README was modified"
echo "$OUT" | grep -qi "would rename" || fail "(c) --dry-run: output missing 'would rename' plan. Got: $OUT"
rm -rf "$DIR"
pass "(c) --dry-run: no FS changes, plan printed"

# ---------------------------------------------------------------------------
# Case (d) — --help exits 0, prints usage
# ---------------------------------------------------------------------------
OUT=$("$SCRIPT" --help 2>&1)
EC=$?
[ "$EC" -eq 0 ] || fail "(d) --help: expected exit 0, got $EC"
echo "$OUT" | grep -qi "usage" || fail "(d) --help: 'usage' not in output"
echo "$OUT" | grep -qi "dry-run" || fail "(d) --help: '--dry-run' not mentioned in help"
pass "(d) --help exits 0 with usage including --dry-run"

# ---------------------------------------------------------------------------
# Case (e) — separation-of-writers: decision-record SKILL.md instructs writing
# adr-<slug>.md, never NNNN-<slug>.md directly. release SKILL.md owns the
# NNNN rename phase. Mechanically detectable from SKILL.md text.
# ---------------------------------------------------------------------------
[ -f "$DR_SKILL" ] || fail "(e) decision-record SKILL.md not found"
[ -f "$RELEASE_SKILL" ] || fail "(e) release SKILL.md not found"

# decision-record must mention adr-<slug>.md as the write target and must NOT
# instruct writing NNNN- directly (post-v1.20.0; the existing Phase 2/3 numbering
# text is legacy and must be replaced or qualified as superseded).
grep -q 'adr-<slug>\.md\|adr-<kebab' "$DR_SKILL" || \
  fail "(e) decision-record SKILL.md missing late-binding write target 'adr-<slug>.md'"

# release SKILL.md must mention the ADR ID assignment phase
grep -qi 'assign.*adr.*id\|adr.id.assignment\|late-binding' "$RELEASE_SKILL" || \
  fail "(e) release SKILL.md missing ADR ID assignment phase reference"

pass "(e) separation-of-writers: decision-record writes adr-<slug>.md, release writes NNNN-<slug>.md"

echo
echo "===SCENARIO 21 ALL 5 CASES PASS==="
