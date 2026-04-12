---
description: Run an architecture governance review against the Enterprise Architect's governance checklist. Evaluates solution intake, tech adoption, integration, and data governance.
argument-hint: "[scope: 'full' | 'tech-adoption' | 'integration' | 'data']"
---

Run a formal architecture governance review evaluating solution design against enterprise standards and policies.

## Steps

1. Read `docs/architecture/solution-architecture.md` and/or `docs/architecture/enterprise-architecture.md` (at least one required).

2. Parse $ARGUMENTS to determine review scope: 'full' for all checkpoints, or specific area: 'tech-adoption', 'integration', 'data'.

3. Read `../../agents/enterprise-architect/references/governance-checklist.md` for the full checklist.

4. Based on scope, evaluate the following checkpoint groups:

   **Solution Intake:**
   - Is there a documented business case (BRD)?
   - Does the solution conform to enterprise technology standards?
   - Are security requirements identified and signed off?
   - Is data governance addressed (data classification, retention)?
   - Is operational readiness planned (monitoring, runbooks, SLAs)?

   **Technology Adoption:**
   - What is the lifecycle stage of key technologies (Adopt/Trial/Assess/Hold)?
   - Is the team trained and experienced with the technology?
   - Is there adequate ecosystem support and documentation?
   - What is the operational cost (licensing, infrastructure)?

   **Integration Governance:**
   - Do APIs conform to enterprise API standards (REST, GraphQL, AsyncAPI)?
   - Are event schemas registered and documented?
   - Is there a contract testing strategy in place?

   **Data Governance:**
   - Is data classification applied (public, internal, confidential, restricted)?
   - Are retention policies defined and enforced?
   - Is there a data flow diagram showing sensitive data handling?

5. For each checkpoint: mark as ✅ Pass, ⚠️ Warning (minor issue), or ❌ Fail (blocking issue). Document remediation steps for warnings/failures.

6. Fill the review report template with: Review Scope, Checkpoints Evaluated, Status Summary (pass/warning/fail counts), Detailed Findings, Remediation Plan, Approval Decision.

7. Save to `docs/reviews/architecture-review-[date].md`.

8. Confirm: "Architecture review completed → [file]. Status: APPROVED / APPROVED WITH CONDITIONS / REJECTED."
