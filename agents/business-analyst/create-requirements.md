---
description: "[Business Analyst] Perform deep requirements analysis on BRD + PRD. Produces functional/non-functional requirements, traceability matrix, and gap analysis."
argument-hint: "[scope: 'full' | 'feature:<name>' | 'gap-analysis']"
---

Perform detailed requirements analysis that decomposes features into functional and non-functional requirements, with traceability mapping.

## Steps

1. Read `docs/brd.md` and `docs/prd.md` (both required — fail if either is missing).

2. Parse $ARGUMENTS to determine scope: 'full' for all features, 'feature:<name>' for a single feature, or 'gap-analysis' for gap identification.

3. Read `../../agents/business-analyst/templates/requirements-analysis-template.md` for the template structure.

4. For each feature in the PRD (or the specified feature if scope is 'feature:<name>'):
   - Decompose into 5-10 functional requirements (what the system must do).
   - Identify non-functional requirements: performance (latency, throughput), security (auth, encryption, audit), scalability (concurrent users, data volume), accessibility (WCAG 2.2 AA), reliability (uptime, RTO/RPO).
   - Map each requirement to the originating business objective in the BRD.

5. Create a traceability matrix showing: BRD Goal → PRD Feature → Functional Requirement → Test Case (placeholder).

6. If scope is 'gap-analysis': compare requirements against the PRD to identify missing requirements, unclear acceptance criteria, and unaddressed non-functional areas.

7. Fill the requirements analysis template with: Requirements Overview, Functional Requirements (organized by feature), Non-Functional Requirements (by category), Traceability Matrix, Gap Analysis (if applicable).

8. Save to `docs/analysis/requirements-analysis.md`.

9. Confirm: "Requirements analysis completed → `docs/analysis/requirements-analysis.md`. Next, run `/create-user-story` to break requirements into stories."
