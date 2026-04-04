# Template: Technical Debt Registry

Create in `docs/technical-debt-registry.md`:

```markdown
# Technical Debt Registry

Tracking all known technical debt. Prioritized by impact and effort.

## Active Debt

### Debt 1: Legacy Authentication System
- **Description:** Old JWT implementation doesn't support multi-tenant claims. All services decode JWTs independently instead of using a shared auth service.
- **Severity:** High (blocks multi-tenant feature)
- **Impact:** Code duplication, security risk, maintenance burden
- **Effort to Fix:** 3-4 weeks (extract auth logic, create service, migrate clients)
- **Recommendation:** Create story for Sprint 7; prioritize before multi-tenant launch
- **Owner:** Auth/Platform team
- **Story:** DEBT-142

### Debt 2: Hardcoded Service URLs
- **Description:** Service discovery not implemented. Services hardcode other services' URLs in config. Makes environment configuration brittle and error-prone.
- **Severity:** Medium (operational pain)
- **Impact:** Painful deployments, configuration errors, doesn't scale to 10+ services
- **Effort to Fix:** 1-2 weeks (implement service discovery, update all services)
- **Recommendation:** Implement in Sprint 6; unblocks future service additions
- **Owner:** Infrastructure/Platform team
- **Story:** DEBT-140

### Debt 3: No Integration Tests Between Services
- **Description:** Services have unit tests but no E2E/integration tests. Breaking changes slip through.
- **Severity:** High (quality risk)
- **Impact:** Late discovery of integration bugs, slow feedback loops
- **Effort to Fix:** 2-3 weeks (set up test infrastructure, write contract tests)
- **Recommendation:** Create as spike (SPIKE-18); implement contract tests for all service pairs
- **Owner:** QE + Engineering agents
- **Story:** DEBT-148

### Debt 4: Missing Observability
- **Description:** No structured logging, tracing, or metrics. Debugging production issues is manual and slow.
- **Severity:** Medium (operational pain)
- **Impact:** MTTR for production issues > 2 hours
- **Effort to Fix:** 2 weeks (implement structured logging, distributed tracing, metrics)
- **Recommendation:** Critical for high-availability system. Implement before release to production.
- **Owner:** Infrastructure/Platform team
- **Story:** DEBT-146

## Retired Debt
[Examples of debt that was fixed and no longer relevant]

---

## Debt Prioritization Matrix

| Debt | Severity | Effort | Impact | Priority | Next Action |
|------|----------|--------|--------|----------|-------------|
| Legacy Auth | High | 3-4 wks | Blocks feature | P1 | Story in Sprint 7 |
| Hardcoded URLs | Medium | 1-2 wks | Ops pain | P2 | Story in Sprint 6 |
| No Integration Tests | High | 2-3 wks | Quality risk | P1 | Spike now |
| Missing Observability | Medium | 2 wks | Ops pain | P2 | Critical before prod |

## Debt Prevention Rules
1. No new debt without Tech Lead approval
2. If a story creates debt, document it and add to registry
3. Every sprint, reserve 10-15% capacity for debt reduction
4. Monthly tech debt review: assess priorities, re-estimate effort

---

**Last Updated:** [YYYY-MM-DD]
**Tech Lead:** [Name]
```

