#!/usr/bin/env bash
# Dogfood scenario 11 — slice 1 assertion (v1.19.0 policy).
# Enforces ADR-0007 description budget policy as amended 2026-05-24.
#
# Exits 0 on pass, 1 on fail. Diagnostic output to stderr.

set -u

# Per ADR-0007 § A (2026-05-24 amendment):
HARD_CAP=1024        # was 1200; matches Anthropic's actual spec
TARGET_AVG=300       # was 600; matches v1.19.0 trim target

# Per ADR-0007 § E (updated keystone list — auto-invocable entry points with widest catchment):
KEYSTONE_SKILLS=(prior-art-research systematic-debugging deep-modules)

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || { echo "Not in a git repo"; exit 1; }

fail=0
total_chars=0
total_skills=0

# Extract description from a SKILL.md frontmatter — handles multi-line descriptions
# by joining all lines between "description:" and the next top-level frontmatter key.
extract_description() {
    awk '
        /^---$/ { fm = !fm; if (!fm) exit; next }
        fm && /^description:[[:space:]]*/ {
            sub(/^description:[[:space:]]*/, "")
            desc = $0
            in_desc = 1
            next
        }
        fm && in_desc && /^[a-z][a-z-]*:[[:space:]]/ { exit }
        fm && in_desc { desc = desc " " $0 }
        END { print desc }
    ' "$1"
}

# Block-scalar regression guard per OQ-4 resolution:
# YAML block scalars (`|` or `>` immediately after `description:`) cause
# Claude Code to truncate the description at line 1 (research Case 7). habeebs
# uses plain scalars only; this assertion prevents a future author accidentally
# introducing the bug.
has_block_scalar_description() {
    grep -qE '^description:[[:space:]]*[|>]' "$1"
}

for skill_file in skills/*/SKILL.md; do
    skill_name=$(basename "$(dirname "$skill_file")")
    desc=$(extract_description "$skill_file")
    char_count=${#desc}

    total_chars=$((total_chars + char_count))
    total_skills=$((total_skills + 1))

    # Block-scalar regression guard
    if has_block_scalar_description "$skill_file"; then
        echo "FAIL: $skill_name description uses YAML block scalar (| or >) — Claude Code truncates these at line 1. Use a plain scalar instead." >&2
        fail=1
    fi

    # Hard cap check (1024 per § A)
    if [[ $char_count -gt $HARD_CAP ]]; then
        echo "FAIL: $skill_name description is $char_count chars (cap $HARD_CAP)" >&2
        fail=1
    fi

    # Directive-imperative check (§ B): must use the v1.19.0 directives.
    # Legacy "Make sure to use this skill" is forbidden going forward.
    if ! echo "$desc" | grep -qiE "(use when|always use|you must use|trigger (on|when))"; then
        echo "FAIL: $skill_name description missing v1.19.0 imperative directive (need 'Use when' / 'ALWAYS use' / 'You MUST use' / 'Trigger on/when')" >&2
        fail=1
    fi
    if echo "$desc" | grep -qi "make sure to use this skill"; then
        echo "FAIL: $skill_name description contains forbidden legacy phrasing 'Make sure to use this skill' — replace with v1.19.0 directive per ADR-0007 § B" >&2
        fail=1
    fi

    # Literal-user-phrase check (§ B): at least one straight-quoted phrase
    # required. The fuzzy-match scorer uses these to locate user-language alignment.
    quote_count=$(echo "$desc" | grep -oE '"[^"]+"' | wc -l)
    if [[ $quote_count -lt 1 ]]; then
        echo "FAIL: $skill_name description has no straight-quoted literal user phrase (need at least 1 per ADR-0007 § B)" >&2
        fail=1
    fi

    # No "Inspired by" in description (move to ## Origins body section per § F)
    if echo "$desc" | grep -qi "inspired by"; then
        echo "FAIL: $skill_name description contains 'Inspired by' — move to ## Origins body section" >&2
        fail=1
    fi

    # Keystone-skill anti-trigger check (§ E): must have ≥2 anti-trigger items.
    is_keystone=0
    for k in "${KEYSTONE_SKILLS[@]}"; do
        if [[ "$skill_name" == "$k" ]]; then
            is_keystone=1
            break
        fi
    done

    if [[ $is_keystone -eq 1 ]]; then
        anti_section=$(echo "$desc" | grep -oiE "(do not (use|trigger).*|not for [^.]*)" | head -1)
        if [[ -z "$anti_section" ]]; then
            echo "FAIL: keystone skill $skill_name missing anti-trigger clause" >&2
            fail=1
        else
            sep_count=$(echo "$anti_section" | grep -oE "(,| or | and )" | wc -l)
            if [[ $sep_count -lt 1 ]]; then
                echo "FAIL: keystone skill $skill_name has too-thin anti-trigger clause ($anti_section)" >&2
                fail=1
            fi
        fi
    fi
done

# Average check (300 per § A)
if [[ $total_skills -gt 0 ]]; then
    avg=$((total_chars / total_skills))
    echo "Description stats: $total_skills skills, $total_chars total chars, avg $avg chars"
    if [[ $avg -gt $TARGET_AVG ]]; then
        echo "FAIL: avg description length is $avg chars (target $TARGET_AVG)" >&2
        fail=1
    fi
fi

if [[ $fail -eq 0 ]]; then
    echo "PASS: all $total_skills skills within description budget"
    exit 0
else
    echo "FAIL: see diagnostics above"
    exit 1
fi
