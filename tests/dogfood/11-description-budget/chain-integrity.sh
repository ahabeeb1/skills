#!/usr/bin/env bash
# Dogfood scenario 11 — slice 2 assertion.
# Enforces ADR-0006: chain relationships must survive in SKILL.md body via
# HANDOFF: line, ## See also section, or explicit prose mention.
#
# Reads (source_skill, target_skill) pairs from chain-pairs.txt (snapshotted
# from pre-removal next-skills frontmatter). For each pair, greps the source
# SKILL.md body for the target name. Exits 0 on pass, 1 on fail with diagnostics.

set -u

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || { echo "Not in a git repo"; exit 1; }

PAIRS_FILE="tests/dogfood/11-description-budget/chain-pairs.txt"
if [[ ! -f "$PAIRS_FILE" ]]; then
    echo "Missing fixture: $PAIRS_FILE" >&2
    exit 1
fi

fail=0
total=0
matched=0

while IFS=',' read -r source target; do
    [[ -z "$source" || -z "$target" ]] && continue
    total=$((total + 1))

    skill_file="skills/$source/SKILL.md"
    if [[ ! -f "$skill_file" ]]; then
        echo "FAIL: source skill file missing: $skill_file" >&2
        fail=1
        continue
    fi

    # Search the body (skip frontmatter — everything after the second --- line)
    body=$(awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2{print}' "$skill_file")

    # Search for target name in:
    # (a) HANDOFF: line — "invoke `target`" or similar
    # (b) ## See also section — list item with backticks-target or plain target
    # (c) prose — any mention of the target name with word boundary
    if echo "$body" | grep -qE "(\`${target}\`|[[:space:]]${target}[[:space:][:punct:]]|^${target}[[:space:][:punct:]])"; then
        matched=$((matched + 1))
    else
        echo "FAIL: chain pair ($source -> $target) not found in body of $skill_file" >&2
        fail=1
    fi
done < "$PAIRS_FILE"

echo "Chain integrity: $matched / $total pairs found in body"

if [[ $fail -eq 0 ]]; then
    echo "PASS: all chain relationships survive in skill bodies"
    exit 0
else
    echo "FAIL: see diagnostics above"
    exit 1
fi
