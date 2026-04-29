---
description: "[Tester / QE] Execute the TQE quality gate checklist. Verifies test coverage, test results, security scan status, and documentation completeness."
argument-hint: "[sprint or release identifier]"
---

Execute the comprehensive quality assurance gate for sprint or release sign-off.

## Steps

1. Parse $ARGUMENTS to extract the sprint or release identifier (e.g., 'sprint-5', 'v1.0.0').

2. Read `../../agents/tester-qe/references/qa-gate-checklists.md` for the quality gate checklist.

3. Execute each gate criterion:

   **Gate 1: All Tests Pass**
   - Run test suite: `npm test` / `pytest` / `go test ./...` (depending on tech stack)
   - Verify: 0 failed tests, 0 skipped tests
   - Status: ✅ Pass or ❌ Fail

   **Gate 2: Code Coverage**
   - Extract coverage report from test run (typically 80%+ target)
   - Verify coverage meets threshold
   - Status: ✅ Pass or ⚠️ Warning (if < 80%) or ❌ Fail (if < 60%)

   **Gate 3: No Critical/High Bugs Open**
   - Check bug tracker (Linear, GitHub Issues, Jira, etc.)
   - Count open bugs by severity
   - Critical/High: FAIL gate
   - Medium/Low: advisory only
   - Status: ✅ Pass or ❌ Fail

   **Gate 4: Security Scan Passes**
   - Read `docs/security/security-gate-results.md` (required)
   - Verify: security gate status is PASS
   - Status: ✅ Pass or ❌ Fail

   **Gate 5: Documentation Current**
   - Verify test strategy exists: `docs/testing/test-strategy.md`
   - Verify release notes drafted (if release): `docs/release-notes-[version].md`
   - Status: ✅ Pass or ⚠️ Warning (incomplete) or ❌ Fail (missing)

   **Gate 6: E2E Tests Pass**
   - If E2E tests exist, run them (Playwright, Cypress, etc.)
   - Verify all pass
   - Status: ✅ Pass or ❌ Fail

4. Compile results into a gate report showing:
   - Criterion, Status (✅/⚠️/❌), Details
   - Test count passing/failing
   - Code coverage percentage
   - Bug count by severity
   - Security scan status
   - Documentation completeness

5. Determine overall QA gate status:
   - All gates ✅ Pass: **QA GATE PASSED**
   - Some gates ⚠️ Warning: **QA GATE PASSED WITH ADVISORIES**
   - Any gate ❌ Fail: **QA GATE FAILED**

6. Save to `docs/testing/qa-gate-results-[identifier].md`.

7. Confirm: "QA Gate: [PASSED | PASSED WITH ADVISORIES | FAILED]. [Summary of blockers if any]"
