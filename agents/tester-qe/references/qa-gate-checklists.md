# QA Gate Checklists

> Load this reference at each phase gate to verify QA readiness before proceeding.

### Analysis Phase QA Gate
Use this to validate readiness to move to Planning:

```markdown
# QA Gate — End of Analysis Phase

Before the Project Brief is handed to Planning, validate:

- [ ] Test strategy document created and reviewed
- [ ] Integration points identified (microservices, external APIs)
- [ ] Compliance requirements understood (OWASP, PCI, HIPAA, etc.)
- [ ] Test environment strategy sketched (local/staging/prod)
- [ ] High-risk areas flagged for additional testing
- [ ] No obvious testability blockers in the design

**Sign-off:** [QE Agent] — Date: [YYYY-MM-DD]
```

### Planning Phase QA Gate
Use this to validate readiness to move to Solutioning:

```markdown
# QA Gate — End of Planning Phase

Before moving to Solutioning, validate:

- [ ] All user stories have acceptance criteria
- [ ] Test cases created for every acceptance criterion
- [ ] Traceability matrix shows all requirements are testable
- [ ] Non-functional requirements translated to test scenarios
- [ ] Test data requirements defined
- [ ] Integration points between stories identified
- [ ] No missing acceptance criteria from PRD

**Sign-off:** [QE Agent] — Date: [YYYY-MM-DD]
```

### Solutioning Phase QA Gate
Use this to validate readiness to move to Implementation:

```markdown
# QA Gate — End of Solutioning Phase

Before moving to Implementation, validate:

- [ ] API contract tests designed for all microservice boundaries
- [ ] Performance test plan aligns with non-functional requirements
- [ ] Security test checklist covers OWASP Top 10 + compliance
- [ ] Test data strategy finalized (fixtures, factories, seeders)
- [ ] Test framework and tools selected
- [ ] CI/CD test pipeline designed
- [ ] Coverage targets established (unit, integration, E2E)
- [ ] Test environment provisioning automated

**Sign-off:** [QE Agent] — Date: [YYYY-MM-DD]
```

### Implementation Phase QA Gate (Pre-Release)
Use this before deployment to production:

```markdown
# QA Gate — Pre-Release / Pre-Deployment

Before deploying to production, validate:

- [ ] All unit tests pass with >80% coverage
- [ ] All integration tests pass
- [ ] All API contract tests pass (no breaking changes)
- [ ] All E2E tests pass on critical paths
- [ ] Regression test suite passes
- [ ] Performance test targets met (P95 latency, throughput, error rate)
- [ ] Security tests pass (OWASP, dependency scan, secrets scan)
- [ ] Load test successful at 1.5x expected traffic
- [ ] All open defects reviewed and accepted risk documented
- [ ] Deployment runbook reviewed and tested
- [ ] Rollback procedure tested and documented
- [ ] Monitoring and alerting configured

**Sign-off:** [QE Agent] — Date: [YYYY-MM-DD]
**Approved By:** [Tech Lead, Product Manager]
```

