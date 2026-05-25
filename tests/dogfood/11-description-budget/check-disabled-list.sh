#!/usr/bin/env bash
# Dogfood scenario 11 — slice #2 of v1.19.0 assertion.
# Enforces ADR-0007 amendment § C: auto-invocation scope.
#
# 11 chain-internal skills MUST carry `disable-model-invocation: true` in frontmatter.
# 7 auto-invocable skills (4 entry points + 3 support meta) MUST NOT.
#
# Exits 0 on pass, 1 on fail. Diagnostic output to stderr.

set -u

# Per ADR-0007 § C — chain-internal skills (fire on HANDOFF / explicit /slash):
DISABLED_SKILLS=(
    draft-spec
    socratic-grill
    decision-record
    write-plan
    tdd-loop
    verify-output
    release
    vertical-slice
    parallel-dev
    agent-factors-check
    devex-review
)

# Per ADR-0007 § C — auto-invocable skills (4 entry points + 3 support meta):
AUTO_INVOCABLE_SKILLS=(
    prior-art-research
    systematic-debugging
    deep-modules
    security-audit
    using-habeebs-skill
    setup-habeebs-skill
    using-worktrees
)

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || { echo "Not in a git repo"; exit 1; }

fail=0

# Returns 0 if the SKILL.md has `disable-model-invocation: true`, 1 otherwise.
has_disable_flag() {
    local skill_file="$1"
    awk '
        /^---$/ { fm = !fm; if (!fm) exit; next }
        fm && /^disable-model-invocation:[[:space:]]*true[[:space:]]*$/ { found = 1; exit }
        END { exit !found }
    ' "$skill_file"
}

# Check the 11 demoted skills MUST have the flag.
for skill in "${DISABLED_SKILLS[@]}"; do
    skill_file="skills/$skill/SKILL.md"
    if [[ ! -f "$skill_file" ]]; then
        echo "FAIL: $skill SKILL.md not found at $skill_file" >&2
        fail=1
        continue
    fi
    if ! has_disable_flag "$skill_file"; then
        echo "FAIL: $skill is in the chain-internal demoted set per ADR-0007 § C but lacks 'disable-model-invocation: true' in frontmatter" >&2
        fail=1
    fi
done

# Check the 7 auto-invocable skills MUST NOT have the flag.
for skill in "${AUTO_INVOCABLE_SKILLS[@]}"; do
    skill_file="skills/$skill/SKILL.md"
    if [[ ! -f "$skill_file" ]]; then
        echo "FAIL: $skill SKILL.md not found at $skill_file" >&2
        fail=1
        continue
    fi
    if has_disable_flag "$skill_file"; then
        echo "FAIL: $skill is in the auto-invocable set per ADR-0007 § C but carries 'disable-model-invocation: true' (should be absent)" >&2
        fail=1
    fi
done

# Cross-check: total of 18 skills exactly. Catches a new skill that nobody decided on.
declared_count=$(( ${#DISABLED_SKILLS[@]} + ${#AUTO_INVOCABLE_SKILLS[@]} ))
actual_count=$(ls -d skills/*/SKILL.md 2>/dev/null | wc -l)
if [[ $actual_count -ne $declared_count ]]; then
    echo "FAIL: skills/ contains $actual_count SKILL.md files but ADR-0007 § C declares $declared_count (11 disabled + 7 auto-invocable). New skill landed without an auto-invocation decision?" >&2
    fail=1
fi

if [[ $fail -eq 0 ]]; then
    echo "PASS: all $declared_count skills classified per ADR-0007 § C (11 disabled + 7 auto-invocable)"
    exit 0
else
    echo "FAIL: see diagnostics above"
    exit 1
fi
