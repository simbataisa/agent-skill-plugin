---
description: Create or update the security risk register from the threat model. Scores risks, assigns owners, and tracks mitigations.
argument-hint: "[action: 'create' | 'update' | 'review']"
---

Create or update the security risk register with risk scoring, residual risk calculation, and mitigation tracking.

## Steps

1. Parse $ARGUMENTS to determine action: 'create' (new register), 'update' (refresh existing), or 'review' (audit current risks).

2. If action is 'create' or 'update': Read `docs/security/threat-model.md` (required for create; check if it exists for update).

3. Read `../../agents/infosec-architect/templates/risk-register-template.md` for the template.

4. Read `../../agents/infosec-architect/references/risk-assessment-methodology.md` for scoring guidance.

5. For each threat in the threat model:
   - **Likelihood**: rate 1-5 (1=rare, 5=almost certain)
   - **Impact**: rate 1-5 (1=negligible, 5=catastrophic)
   - **Inherent Risk Score** = Likelihood × Impact (scale to 1-25)
   - **Existing Controls**: list security controls already in place
   - **Residual Risk Score** = (Likelihood × Impact) / (1 + Control Effectiveness)
   - **Risk Owner**: assign a team member responsible for mitigation
   - **Mitigation Plan**: remediation action and target completion date

6. Create a risk heat map (text-based table) showing risk distribution (High/Medium/Low).

7. Identify risks where Residual Risk > Acceptable Threshold (define threshold with user if not known).

8. Fill the risk register template with: Risk Overview, Risk Table (ID, Threat, Likelihood, Impact, Inherent Score, Controls, Residual Score, Owner, Mitigation), Heat Map, Summary Statistics.

9. Save to `docs/security/risk-register.md`.

10. Confirm: "Risk register created/updated → `docs/security/risk-register.md`. [N] risks identified, [M] require mitigation."
