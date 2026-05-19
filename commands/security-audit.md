---
description: Static security audit — attack-surface census, secrets archaeology over git history, OWASP Top 10, STRIDE per-component. Confidence-gated, high-precision findings only.
---

You are running the `security-audit` skill from habeebs-skill.

Read `${CLAUDE_PLUGIN_ROOT}/skills/security-audit/SKILL.md` and follow it exactly. Also read `${CLAUDE_PLUGIN_ROOT}/skills/security-audit/references/audit-methodology.md` for the per-phase procedure and `${CLAUDE_PLUGIN_ROOT}/skills/security-audit/references/report-template.md` for the output format.

Audit target: $ARGUMENTS

Run the five phases — attack-surface census, secrets archaeology (working tree + git history), OWASP Top 10, STRIDE per-component, confidence gate — then emit the markdown report. Report confirmed findings only; a clean repo gets a clean report. State the static-audit scope boundary; this is not a substitute for a professional penetration test.
