# Hotfix Assessment: [date]-[issue]

**Date:** YYYY-MM-DD
**Incident start:**
**Responder (Tech Lead):**
**Severity:** P0 / P1

---

## Production Symptoms

Describe what is failing in production (error messages, impact on users, affected endpoints).

## Root Cause

Confirmed root cause — be specific about file, function, or data condition.

## Fix Scope

Minimal safe change required:

- **Files to change:**
- **What changes:**
- **What must NOT change:** (list explicitly to prevent scope creep)

## Rollback Plan

How to revert if the fix makes things worse:
1. Step one
2. Step two

## Regression Risk

Components or flows that must be smoke-tested after the fix.

## Fix Implementation Notes

_Filled in by engineer_

- Changed: `[file]` — [what changed] // HOTFIX: [date]-[issue]

## Smoke Test Results

_Filled in by Tester-QE_

- [ ] Critical path unbroken
- [ ] Production symptom resolved
- [ ] No new regressions observed

**Result:** Pass / Fail
