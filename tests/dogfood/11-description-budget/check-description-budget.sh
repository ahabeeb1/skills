#!/usr/bin/env bash
# Dogfood scenario 11 — slice 1 assertion.
# Enforces ADR-0007 description budget policy.
#
# Exits 0 on pass, 1 on fail. Diagnostic output to stderr.

set -u

HARD_CAP=1200
TARGET_AVG=600
KEYSTONE_SKILLS=(prior-art-research socratic-grill tdd-loop)

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

for skill_file in skills/*/SKILL.md; do
    skill_name=$(basename "$(dirname "$skill_file")")
    desc=$(extract_description "$skill_file")
    char_count=${#desc}

    total_chars=$((total_chars + char_count))
    total_skills=$((total_skills + 1))

    # Hard cap check
    if [[ $char_count -gt $HARD_CAP ]]; then
        echo "FAIL: $skill_name description is $char_count chars (cap $HARD_CAP)" >&2
        fail=1
    fi

    # Pushy-trigger check
    if ! echo "$desc" | grep -qiE "(make sure to use this skill|use when|trigger (on|when))"; then
        echo "FAIL: $skill_name description missing pushy-trigger phrase (need 'Make sure to use this skill' or 'Use when' or 'Trigger on/when')" >&2
        fail=1
    fi

    # No "Inspired by" in description (move to ## Origins body section)
    if echo "$desc" | grep -qi "inspired by"; then
        echo "FAIL: $skill_name description contains 'Inspired by' — move to ## Origins body section" >&2
        fail=1
    fi

    # Keystone-skill anti-trigger check: must have at least 2 anti-trigger clues
    is_keystone=0
    for k in "${KEYSTONE_SKILLS[@]}"; do
        if [[ "$skill_name" == "$k" ]]; then
            is_keystone=1
            break
        fi
    done

    if [[ $is_keystone -eq 1 ]]; then
        # Count anti-trigger items — split on common separators (commas, "or", semicolons)
        # in the "Do NOT use" / "do not trigger" / "not for" clauses
        anti_section=$(echo "$desc" | grep -oiE "(do not (use|trigger).*|not for [^.]*)" | head -1)
        if [[ -z "$anti_section" ]]; then
            echo "FAIL: keystone skill $skill_name missing anti-trigger clause" >&2
            fail=1
        else
            # Count commas + "or" + "and" separators in the anti-trigger clause
            # Threshold: ≥2 distinct items means ≥1 separator (since 2 items joined by 1 separator)
            sep_count=$(echo "$anti_section" | grep -oE "(,| or | and )" | wc -l)
            if [[ $sep_count -lt 1 ]]; then
                echo "FAIL: keystone skill $skill_name has too-thin anti-trigger clause ($anti_section)" >&2
                fail=1
            fi
        fi
    fi
done

# Average check
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
