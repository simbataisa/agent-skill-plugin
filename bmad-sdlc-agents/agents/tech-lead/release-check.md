---
description: "[Tech Lead] Pre-release readiness check. Verifies all agents have completed, quality gates pass, security sign-off exists, and documentation is current."
argument-hint: "[release version, e.g. 'v1.0.0']"
---

Execute a comprehensive pre-release readiness check verifying all teams have completed their deliverables.

## Steps

1. Parse $ARGUMENTS to extract the release version. If not provided, ask: "What is the release version? (e.g., v1.0.0)"

2. Check all sentinel signals in `.bmad/signals/`:
   - `po-done` (Product Owner completed BRD/PRD)
   - `ba-done` (Business Analyst completed requirements)
   - `infosec-done` (InfoSec completed threat model and risk register)
   - `ea-done` (Enterprise Architect completed architecture review)
   - `ux-done` (UX Designer completed wireframes and design system)
   - `sa-done` (Solution Architect completed solution architecture)
   - `tl-plan-done` (Tech Lead completed sprint planning)
   - `E2-be-done` (Backend engineers completed implementation)
   - `E2-fe-done` (Frontend engineers completed implementation)
   - `E2-me-done` (Mobile engineers completed implementation, if applicable)
   - `devsecops-done` (DevSecOps completed security gate)
   - Mark each as ✅ Present or ❌ Missing

3. Read `docs/security/security-gate-results.md` (required — fail if missing. DevSecOps sign-off must exist).

4. Check test results:
   - Read `docs/testing/qa-gate-results-*.md` for latest test execution results
   - Verify: all tests passed, coverage >= threshold (typically 80%), no critical/high bugs open

5. Verify documentation completeness:
   - ✅ BRD exists: `docs/brd.md`
   - ✅ PRD exists: `docs/prd.md`
   - ✅ Solution architecture exists: `docs/architecture/solution-architecture.md`
   - ✅ Enterprise architecture exists: `docs/architecture/enterprise-architecture.md`
   - ✅ Threat model exists: `docs/security/threat-model.md`
   - ✅ Test strategy exists: `docs/testing/test-strategy.md`
   - ✅ Release notes drafted: `docs/release-notes-[version].md`

6. Produce release readiness report with format:
   - **Agent Readiness**: table of signals (po-done through devsecops-done)
   - **Quality Gates**: test coverage, test results, bug backlog status
   - **Security Sign-off**: security gate PASS/FAIL status
   - **Documentation**: completion checklist
   - **Overall Status**: READY FOR RELEASE / BLOCKED: [reason]

7. Save to `docs/reviews/release-check-[version].md`.

8. Confirm: "Release [version] is READY FOR RELEASE" or "BLOCKED: [list blocking issues]"
