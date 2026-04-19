---
description: "[Solution Architect] Create the solution architecture document. Defines service decomposition, API contracts, data models, integration patterns, and ADRs."
argument-hint: "[scope: 'full' | 'service:<name>' | 'api-design' | 'data-model']"
---

Create the solution architecture defining service boundaries, API contracts, data models, and integration patterns.

## Steps

1. Read `docs/analysis/requirements-analysis.md` (required).

2. Read `docs/architecture/enterprise-architecture.md` if it exists (EA constraints and infrastructure).

3. Read `docs/security/security-architecture.md` if it exists (security controls and requirements).

4. Read `.bmad/tech-stack.md` for approved technologies.

5. Parse $ARGUMENTS to determine scope: 'full' (complete solution), 'service:<name>' (single service), 'api-design' (API contracts only), or 'data-model' (ERD and data flow only).

6. For 'full' or 'service' scope:
   - Identify service boundaries using Domain-Driven Design (bounded contexts).
   - For each service: define responsibility, dependencies, API contracts, data stores, synchronous/asynchronous communication patterns.
   - Create service topology diagram showing services and their interactions.

7. For 'full' or 'api-design' scope:
   - Design API contracts (REST or AsyncAPI patterns):
     - REST: HTTP methods, endpoint paths, request/response schemas, status codes, error handling, authentication.
     - AsyncAPI: channels, message schemas, bindings, error handling.
   - Ensure APIs conform to enterprise API standards from `.bmad/tech-stack.md`.

8. For 'full' or 'data-model' scope:
   - Create Entity Relationship Diagram (ERD) showing tables/collections, relationships, and cardinality.
   - Document data flow: sources → transformation → sinks.
   - Identify data at rest (databases) and in motion (caches, queues).

9. For 'full' scope:
   - Document ADRs for key architectural decisions (technology choices, patterns, trade-offs).

10. Fill the solution architecture template with: Overview, Service Decomposition, API Contracts, Data Model, Integration Patterns, Technology Choices, ADR References, Deployment Topology.

11. Save to `docs/architecture/solution-architecture.md`.

12. Confirm: "Solution architecture created → `docs/architecture/solution-architecture.md`. [N] services, [M] APIs defined."
