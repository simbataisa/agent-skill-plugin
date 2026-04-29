---
description: "[InfoSec Architect] Map security controls to compliance framework requirements (SOC2, GDPR, HIPAA, PCI-DSS, ISO 27001). Identifies gaps."
argument-hint: "[framework: 'soc2' | 'gdpr' | 'hipaa' | 'pci-dss' | 'iso27001' | 'all']"
---

Map security controls to compliance framework requirements and identify gaps in control coverage.

## Steps

1. Parse $ARGUMENTS to extract the framework. If empty or 'all', map to all applicable frameworks.

2. Read `docs/security/risk-register.md` and `docs/security/threat-model.md` (should exist; warn if missing).

3. Read `docs/security/security-architecture.md` if it exists to understand implemented controls.

4. Read `../../agents/infosec-architect/templates/compliance-mapping-template.md` for the template.

5. Read `../../agents/infosec-architect/references/compliance-frameworks.md` for control families and requirements.

6. Ask the user (if frameworks not yet identified):
   - "Which compliance frameworks apply to your organization? (SOC2, GDPR, HIPAA, PCI-DSS, ISO 27001, others?)"
   - "Are you currently compliant with any of these, or is this a gap assessment?"

7. For each selected framework:
   - List applicable control IDs and requirements (e.g. SOC2 CC6.1, GDPR Article 5, HIPAA §164.312)
   - Map each to existing security controls from the risk register or security architecture
   - Identify gaps: requirements with no mapped control
   - Note evidence requirements (artifacts needed for audit: policies, test results, certifications)

8. Fill the compliance mapping template with: Framework Overview, Control Mapping Table (Control ID, Requirement, Mapped Security Control, Status (Implemented/Planned/Gap), Evidence), Gap Analysis, Timeline for Gap Remediation.

9. Save to `docs/security/compliance-mapping.md`.

10. Confirm: "Compliance mapping created → `docs/security/compliance-mapping.md`. [N] frameworks analyzed, [M] gaps identified."
