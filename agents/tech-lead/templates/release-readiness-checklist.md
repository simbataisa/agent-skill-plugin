# Template: Release Readiness Checklist

Create before every release: `.bmad/release-readiness-[version].md`

```markdown
# Release Readiness Checklist — v[Version]

**Release Date:** [YYYY-MM-DD]
**Release Manager:** [Tech Lead Name]

## Code Quality Gate
- [ ] All unit tests passing (>80% coverage)
- [ ] All integration tests passing
- [ ] All E2E tests passing
- [ ] Code review checklist enforced on all PRs
- [ ] No blocking code review comments outstanding
- [ ] Security scan (Snyk) passed; no high/critical CVEs

## Testing Gate
- [ ] Regression test suite passed
- [ ] Performance test targets met (P95 < 200ms, etc.)
- [ ] Load test passed at 1.5x expected traffic
- [ ] Security tests passed (OWASP Top 10, penetration test if applicable)
- [ ] QE sign-off obtained

## Architecture Gate
- [ ] All ADRs approved and documented
- [ ] Implementation aligns with architectural decisions
- [ ] API contracts validated (no breaking changes)
- [ ] Data migration scripts tested and verified
- [ ] Architect review completed

## Operations Gate
- [ ] Deployment runbook reviewed and tested
- [ ] Rollback procedure tested and documented
- [ ] Monitoring and alerting configured
- [ ] Log aggregation working
- [ ] Incident response plan reviewed
- [ ] On-call team briefed

## Business Gate
- [ ] All story acceptance criteria verified in staging
- [ ] Product Manager acceptance obtained
- [ ] Release notes prepared
- [ ] Documentation updated
- [ ] Compliance/legal review (if applicable)

## Risk Assessment
- [ ] All high-risk areas have mitigation plans
- [ ] Known issues documented with workarounds
- [ ] Rollback criteria defined

## Go/No-Go Decision

**Tech Lead Recommendation:**
- [ ] **GO** — All checks passed; safe to release
- [ ] **NO-GO** — Issues present; delay release

**Rationale:** [Explain decision]

**Approved By:** [Tech Lead] — Date: [YYYY-MM-DD]
**Approved By:** [Product Manager] — Date: [YYYY-MM-DD]

---

**Release Artifacts:**
- Deployment checklist: `.bmad/deployment-checklist-v[Version].md`
- Release notes: `RELEASE-NOTES-v[Version].md`
- Incident response: `.bmad/incident-response-[Version].md`
```

