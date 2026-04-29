# Template: Test Strategy Document

Use this template to create `docs/test-plans/test-strategy.md`:

```markdown
# Test Strategy — [Project Name]

## Executive Summary
[1-2 paragraphs on testing approach, risk profile, quality goals]

## Testing Scope
### In Scope
- Unit testing (all business logic)
- Integration testing (service-to-service APIs)
- Contract testing (microservice boundaries)
- End-to-end testing (critical user paths)
- Performance testing (load, stress, spike)
- Security testing (OWASP Top 10)

### Out of Scope
- [List what is not tested and why]

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| API breaking changes | Medium | High | Contract tests + CDC |
| Database migration failures | Medium | High | Staged rollout + rollback tests |
| Performance degradation | Medium | Medium | Load testing in staging |

## Test Types & Responsibilities

### Unit Testing (Engineers)
- Coverage target: >80% of business logic
- Framework: [specify: Jest, pytest, etc.]
- Automated in CI/CD

### Integration Testing (Engineers + QE)
- Service-to-service API calls
- Database operations
- Cache behavior
- Test environment: Staging or Docker Compose

### API Contract Testing
- Verify microservice contracts don't break
- Consumer-driven contract tests
- Framework: Pact, Spring Cloud Contract, etc.

### End-to-End Testing (QE)
- Critical user journeys
- Cross-service workflows
- Test data: Isolated test database
- Environment: Staging

### Performance Testing
- Load test: [X requests/second, Y concurrent users]
- Stress test: Push until failure
- Soak test: Run for [duration] to detect memory leaks
- Spike test: Sudden traffic increase

### Security Testing
- OWASP Top 10: SQL injection, XSS, CSRF, etc.
- Authentication/authorization checks
- Data sensitivity validation
- Compliance: [PCI-DSS, HIPAA, SOC 2, etc.]

## Test Environment Strategy
- **Local Development:** Docker Compose with mocked external services
- **Staging:** Production-like, with test data and synthetic monitoring
- **Production:** Smoke tests and synthetic monitoring only

## Test Data Management
- Fixtures: [How are they versioned?]
- Seeders: [How is staging data refreshed?]
- Sensitive data: [How is PII handled in test environments?]

## Automation & Tools
- Unit/integration: [Framework + CI tool]
- E2E: Selenium, Cypress, or Playwright
- API contract: Pact or similar
- Performance: JMeter, k6, or Gatling
- Security scanning: SAST, DAST tools

## Quality Gates & Metrics
| Phase | Gate | Criteria |
|-------|------|----------|
| Pre-Merge | Unit tests pass, >80% coverage | [specific thresholds] |
| Pre-Release | E2E tests pass, no high/critical bugs | [specific thresholds] |
| Post-Deployment | Production monitoring, synthetic tests pass | [specific thresholds] |

## Timeline & Effort
[Estimate test automation effort, parallel testing windows, critical path dependencies]
```

