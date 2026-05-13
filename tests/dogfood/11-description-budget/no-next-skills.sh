#!/usr/bin/env bash
# Dogfood scenario 11 — slice 2 assertion.
# Enforces ADR-0006: the unrecognized `next-skills:` frontmatter field
# is removed from all SKILL.md files.
#
# Exits 0 on pass, 1 on fail.

set -u

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || { echo "Not in a git repo"; exit 1; }

violators=$(grep -l "^next-skills:" skills/*/SKILL.md 2>/dev/null || true)

if [[ -z "$violators" ]]; then
    echo "PASS: zero SKILL.md files carry next-skills frontmatter"
    exit 0
else
    echo "FAIL: the following SKILL.md files still carry next-skills frontmatter:" >&2
    echo "$violators" >&2
    exit 1
fi
