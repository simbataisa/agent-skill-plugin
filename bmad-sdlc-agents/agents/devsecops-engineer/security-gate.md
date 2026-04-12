---
description: "[DevSecOps Engineer] Evaluate all security gate criteria and produce a PASS/FAIL sign-off for release. Checks SAST, DAST, container, IaC, dependency, and secrets scans."
argument-hint: "[sprint or release identifier]"
---

Execute the security gate evaluation and produce a release sign-off decision.

## Steps

1. Parse $ARGUMENTS to extract the sprint or release identifier. If not provided, ask: "Which sprint or release should I gate? (e.g., 'v1.0.0', 'sprint-5')"

2. Read `docs/security/sast-dast-report.md` (required — fail if missing. Run `/security-scan` first if needed).

3. Read the following security scan reports if they exist:
   - `docs/security/container-security.md`
   - `docs/security/iac-security-report.md`
   - `docs/security/dependency-audit.md`

4. Read `../../agents/devsecops-engineer/references/security-pipeline-gates.md` for gate definitions and severity thresholds.

5. Evaluate each security gate criterion:

   **Gate 1: SAST Findings**
   - Critical findings: FAIL
   - High findings: FAIL unless explicitly risk-accepted
   - Medium/Low: PASS with advisory

   **Gate 2: Dependency Audit**
   - Critical/High vulnerabilities: FAIL unless risk-accepted
   - Medium/Low: PASS with advisory

   **Gate 3: Secrets Detection**
   - Any hardcoded secrets found: FAIL (must remediate and remove from git history)

   **Gate 4: IaC Security**
   - Critical/High misconfigurations: FAIL unless risk-accepted
   - Medium/Low: PASS with advisory

   **Gate 5: Container Image Security**
   - Critical/High vulnerabilities in base image: FAIL unless risk-accepted
   - Medium/Low: PASS with advisory

6. For any finding marked "FAIL", check for a risk acceptance record:
   - Risk owner: who approved accepting this risk?
   - Justification: why is this risk acceptable?
   - Remediation date: when will this be fixed?
   - If not documented, gate fails on that criterion.

7. Determine overall gate status:
   - All gates PASS with no deferred findings: **PASS — all clear**
   - Passes with documented risk acceptances: **PASS — [N] risks accepted**
   - Any gate fails with no risk acceptance: **FAIL**

8. Fill the security gate results template with: Gate Criteria (PASS/FAIL per criterion), Risk Acceptances (if any), Final Decision, Next Steps.

9. Save to `docs/security/security-gate-results.md`.

10. If gate PASSES, create sentinel file: `touch .bmad/signals/devsecops-done`

11. Confirm: "Security Gate: PASS — all clear" or "Security Gate: FAIL — [N] blocking findings"
