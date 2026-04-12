---
description: "[InfoSec Architect] Create a STRIDE threat model for the system or a specific feature. Produces threat analysis with DFD, threat table, and mitigations."
argument-hint: "[scope: 'full-system' | 'feature:<name>' | 'component:<name>']"
---

Create a formal STRIDE threat model identifying trust boundaries, data flows, and threats with mitigations.

## Steps

1. Read `docs/brd.md`, `docs/prd.md`, and `docs/requirements/requirements-analysis.md` for context (at least one required).

2. Read `docs/architecture/solution-architecture.md` and `docs/architecture/enterprise-architecture.md` if they exist.

3. Read `../../agents/infosec-architect/templates/threat-model-template.md` for the template.

4. Read `../../agents/infosec-architect/references/threat-modeling-guide.md` for STRIDE methodology guidance.

5. Parse $ARGUMENTS to determine scope: 'full-system', 'feature:<name>', or 'component:<name>'.

6. Create a Data Flow Diagram (DFD) identifying:
   - External entities (users, external systems, APIs)
   - Trust boundaries (where privilege/trust level changes)
   - Data stores (databases, caches, files)
   - Processes (services, handlers)
   - Data flows (between elements)

7. For each trust boundary, apply STRIDE:
   - **S**poofing: can an attacker impersonate someone/something?
   - **T**ampering: can data be modified in transit or at rest?
   - **R**epudiation: can actions be denied or hidden?
   - **I**nformation Disclosure: can data be exposed?
   - **D**enial of Service: can availability be disrupted?
   - **E**levation of Privilege: can an attacker gain higher privileges?

8. For each threat identified: assign a severity score (Critical/High/Medium/Low using CVSS or likelihood × impact), document the threat, and suggest mitigations.

9. Fill the threat model template with: System Overview, DFD, Threat Table (threat ID, description, STRIDE category, severity, mitigation), Risk Summary.

10. Save to `docs/security/threat-model.md`.

11. Confirm: "Threat model created → `docs/security/threat-model.md`. Next, run `/risk-register` to create the formal risk register."
