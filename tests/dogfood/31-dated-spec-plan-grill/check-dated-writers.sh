#!/usr/bin/env bash
# Dogfood scenario 31 — dated naming for specs / plans / grill-records (v1.23.0)
# Per spec slice #4 (v1.23.0-dated-artifact-naming) + the superseding dated ADR.
#
# Slice 4 extends the dated YYYY-MM-DD-<slug>.md convention from ADRs to specs,
# plans, and grill-records, moving the version identifier into a frontmatter
# Version:/Release: field so spec->plan->release traceability survives losing
# the version from the filename.
#
# Cases:
#   (a) draft-spec instructs a dated YYYY-MM-DD-<slug>.md spec write target.
#   (b) write-plan instructs a dated YYYY-MM-DD-<slug>.md plan write target.
#   (c) socratic-grill instructs a dated grill-record write target.
#   (d) the spec template carries a Version:/Release: header field (the version
#       that left the filename).
#   (e) the plan template carries a Version:/Release: frontmatter field.
#   (f) traceability simulation — a spec frontmatter Version: + a plan that links
#       back to that spec resolves the version through frontmatter, not filename.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SPEC_SKILL="$REPO_ROOT/skills/draft-spec/SKILL.md"
PLAN_SKILL="$REPO_ROOT/skills/write-plan/SKILL.md"
GRILL_SKILL="$REPO_ROOT/skills/socratic-grill/SKILL.md"
SPEC_TMPL="$REPO_ROOT/skills/draft-spec/references/design-template.md"
PLAN_TMPL="$REPO_ROOT/skills/write-plan/references/plan-template.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

for f in "$SPEC_SKILL" "$PLAN_SKILL" "$GRILL_SKILL" "$SPEC_TMPL" "$PLAN_TMPL"; do
  [ -f "$f" ] || fail "expected file missing: $f"
done

# ---------------------------------------------------------------------------
# (a) draft-spec instructs the dated Design write target (the spec is now the
#     plain-language Design, written to YYYY-MM-DD-<slug>-design.md)
# ---------------------------------------------------------------------------
grep -Eq 'YYYY-MM-DD-<(feature-)?slug>-design\.md' "$SPEC_SKILL" \
  || fail "(a) draft-spec/SKILL.md does not instruct a dated 'YYYY-MM-DD-<slug>-design.md' Design write target"
pass "(a) draft-spec instructs dated Design write target"

# ---------------------------------------------------------------------------
# (b) write-plan instructs the dated plan write target
# ---------------------------------------------------------------------------
grep -Eq 'YYYY-MM-DD-<slug>\.md' "$PLAN_SKILL" \
  || fail "(b) write-plan/SKILL.md does not instruct a dated 'YYYY-MM-DD-<slug>.md' plan write target"
pass "(b) write-plan instructs dated plan write target"

# ---------------------------------------------------------------------------
# (c) socratic-grill writes resolutions into the dated Design (no separate
#     grill record on the common path — the grill record folds into the Design)
# ---------------------------------------------------------------------------
grep -Eq 'YYYY-MM-DD-<slug>-design\.md' "$GRILL_SKILL" \
  || fail "(c) socratic-grill/SKILL.md does not reference the dated Design write target"
grep -Eqi 'no separate grill record|do not write a separate grill record' "$GRILL_SKILL" \
  || fail "(c) socratic-grill/SKILL.md does not state the grill record folds into the Design"
pass "(c) socratic-grill writes into the dated Design (no separate grill record)"

# ---------------------------------------------------------------------------
# (d) Design template carries a Version:/Release: header field (traceability)
# ---------------------------------------------------------------------------
grep -Eq '(\*\*Version:\*\*|\*\*Release:\*\*|^Version:|^Release:)' "$SPEC_TMPL" \
  || fail "(d) design-template.md does not carry a Version:/Release: field"
pass "(d) Design template carries a Version:/Release: field"

# ---------------------------------------------------------------------------
# (e) plan template carries a Version:/Release: frontmatter field
# ---------------------------------------------------------------------------
grep -Eq '(^Version:|^Release:|Version:|Release:)' "$PLAN_TMPL" \
  || fail "(e) plan-template.md does not carry a Version:/Release: frontmatter field"
pass "(e) plan template carries a Version:/Release: field"

# ---------------------------------------------------------------------------
# (f) traceability simulation — version survives in frontmatter, link resolves
#
# Build a dated spec carrying `Version: v9.9.0` in frontmatter and a dated plan
# that links back to that spec by filename. Prove (1) the version is recoverable
# from the spec frontmatter (not the filename), and (2) the plan->spec link
# resolves to a real file. This is the spec->plan->release traceability that
# must survive moving the version out of the filename.
# ---------------------------------------------------------------------------
SIM=$(mktemp -d)
mkdir -p "$SIM/specs" "$SIM/plans"
SPEC_NAME="2026-05-29-some-feature.md"
PLAN_NAME="2026-05-29-some-feature.md"
cat > "$SIM/specs/$SPEC_NAME" <<'EOF'
# Implementation Spec: Some Feature

**Slug:** `some-feature`
**Status:** Grilled
**Version:** v9.9.0
**Release:** v9.9.0
**Tier:** Balanced
EOF
cat > "$SIM/plans/$PLAN_NAME" <<EOF
---
Status: Active
Version: v9.9.0
---
# Plan: Some Feature

Spec: [specs/$SPEC_NAME](../specs/$SPEC_NAME)
EOF

# (1) version recoverable from the spec frontmatter, not the filename
VER=$(grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' "$SIM/specs/$SPEC_NAME" | head -1)
[ "$VER" = "v9.9.0" ] || fail "(f) version not recoverable from spec frontmatter (got '$VER')"
# the filename itself carries NO version
case "$SPEC_NAME" in *v9.9.0*) fail "(f) spec filename unexpectedly carries the version" ;; esac

# (2) the plan->spec link resolves to a real file
LINK_TARGET=$(grep -Eo '\.\./specs/[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z-]+\.md' "$SIM/plans/$PLAN_NAME" | head -1)
[ -n "$LINK_TARGET" ] || fail "(f) plan does not contain a resolvable spec link"
RESOLVED="$SIM/plans/$LINK_TARGET"
[ -f "$RESOLVED" ] || fail "(f) plan->spec link does not resolve to a real file: $LINK_TARGET"
# (3) plan frontmatter version matches spec frontmatter version (traceability)
PLAN_VER=$(grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' "$SIM/plans/$PLAN_NAME" | head -1)
[ "$PLAN_VER" = "$VER" ] || fail "(f) plan version ($PLAN_VER) does not match spec version ($VER)"
rm -rf "$SIM"
pass "(f) traceability: version in frontmatter recoverable + spec<->plan link resolves through dated filenames"

echo
echo "===SCENARIO 31 ALL 6 CASES PASS==="
