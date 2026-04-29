# Template: Technical Risk Assessment

Create in `docs/technical-risk-assessment.md` during Analysis phase:

```markdown
# Technical Risk Assessment

## Project Overview
[1-2 sentences on the project]

## High-Risk Areas

### Risk 1: Legacy System Integration
- **Description:** New microservice must integrate with 15-year-old monolith (SOAP API)
- **Likelihood:** High (legacy API is poorly documented)
- **Impact:** High (tight coupling, slow integration, breaks during deployments)
- **Mitigation:**
  1. Run technical spike to map SOAP API surface
  2. Build adapter/facade service to isolate new service from legacy
  3. Create comprehensive contract tests for legacy integration
  4. Plan parallel run testing before cutover
- **Owner:** Tech Lead + Architect
- **Timeline:** 2 weeks for spike, 3 weeks for implementation

### Risk 2: Database Scalability
- **Description:** Current database schema doesn't support multi-tenancy
- **Likelihood:** Medium (will need redesign)
- **Impact:** High (blocks feature launch if not addressed)
- **Mitigation:**
  1. Run data model spike (1 week)
  2. Evaluate tenant isolation strategies (row-level security vs. separate schemas)
  3. Design migration path for existing data
  4. Load test new schema under expected volume
- **Owner:** Data Engineer + Architect

### Risk 3: Microservice Communication Overhead
- **Description:** 8 new services will require synchronous calls; latency could accumulate
- **Likelihood:** Medium (common in distributed systems)
- **Impact:** Medium (affects user experience)
- **Mitigation:**
  1. Design API contracts early (contract tests)
  2. Implement caching strategy
  3. Consider async patterns (events, queues)
  4. Run performance spike on inter-service latency
- **Owner:** Architect + Engineering agents

## Technology Decisions Needed

| Decision | Options | Trade-offs | Recommendation |
|----------|---------|-----------|-----------------|
| API Gateway | Kong vs. AWS API Gateway | Managed vs. self-hosted | AWS API Gateway (managed, cost) |
| Message Broker | RabbitMQ vs. Kafka | Durability vs. simplicity | Kafka (better for event streaming) |
| Cache | Redis vs. Memcached | Features vs. simplicity | Redis (sorted sets, streams) |

## Non-Functional Requirements Risk

| Requirement | Target | Current Baseline | Gap | Mitigation |
|-------------|--------|------------------|-----|-----------|
| API Latency (P95) | <200ms | Unknown | Spike to measure | Performance testing |
| Uptime | 99.99% | 99.5% | Need redundancy | Multi-AZ deployment |
| Data Consistency | Strong (ACID) | Eventual (BASE) | Design challenge | Event sourcing + saga pattern |

## Dependencies & Assumptions
- Assumption 1: Legacy API will remain stable
  - Risk if invalid: Integration breaks monthly
  - Mitigation: Contract tests, dedicated legacy support
- Assumption 2: Database team can allocate 1 engineer for 4 weeks
  - Risk if invalid: Data model spike slips
  - Mitigation: Start spike immediately

## Spike Tasks Recommended
1. **Data Model Spike** (2 weeks): Multi-tenant schema design
2. **Performance Baseline Spike** (1 week): Measure current latency, throughput
3. **Legacy API Integration Spike** (2 weeks): Map SOAP surface, design adapter
4. **Messaging Pattern Spike** (1 week): Compare async approaches

## Technical Debt Impact
Carrying forward:
- [List existing debt that could slow this project]
- Priority: High/Medium/Low for this release

## Success Metrics
- No critical design defects found post-release
- Code review cycle time < 2 hours
- Test coverage > 80%
- Zero unplanned downtime in first 30 days

**Prepared By:** [Tech Lead Name]
**Date:** [YYYY-MM-DD]
**Next Review:** [YYYY-MM-DD]
```

