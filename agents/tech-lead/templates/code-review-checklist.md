# Template: Code Review Checklist

Create in `docs/code-review-checklist.md`:

```markdown
# Code Review Checklist

Use this checklist when reviewing pull requests. All items should pass before approval.

## Functionality & Correctness
- [ ] Code does what the story asks (acceptance criteria met)
- [ ] No obvious bugs or logic errors
- [ ] Error handling covers all failure paths
- [ ] Edge cases handled (null, empty, boundary conditions)
- [ ] Performance acceptable (no unnecessary loops or queries)

## Code Quality
- [ ] Follows coding standards (naming, structure, patterns)
- [ ] No unused imports or variables
- [ ] Functions are focused and do one thing well
- [ ] Complexity is reasonable (cyclomatic complexity < 10)
- [ ] DRY principle applied (no obvious duplication)
- [ ] Code is readable; naming is clear
- [ ] Comments explain "why," not "what"

## Testing
- [ ] Unit tests added for new logic
- [ ] Tests are meaningful (not just coverage %)
- [ ] Tests cover happy path and error cases
- [ ] No mocking internals; test behavior
- [ ] Test names describe what is being tested
- [ ] Coverage maintained or improved

## Security & Privacy
- [ ] No hardcoded secrets, credentials, API keys
- [ ] Input validation present on user-facing code
- [ ] Authorization checks enforced (not just authentication)
- [ ] No sensitive data logged
- [ ] Dependencies checked for known CVEs (Snyk)
- [ ] SQL/query injection mitigations in place

## Architecture & Design
- [ ] Aligns with ADRs (Architecture Decision Records)
- [ ] Design patterns consistent with codebase
- [ ] No shortcuts or "hacky" solutions
- [ ] Coupling is minimal; modules are loosely coupled
- [ ] External APIs (if added) are abstracted behind interfaces

## Integration & Data
- [ ] Database migrations (if any) are backward-compatible
- [ ] No breaking changes to public APIs
- [ ] Data models align with domain language
- [ ] Transactions used where atomicity is needed
- [ ] Indexes appropriate for query patterns

## Documentation
- [ ] Public functions have JSDoc/TSDoc
- [ ] Complex logic has explanation comments
- [ ] README updated if setup/running instructions changed
- [ ] Database schema changes documented

## Deployment & Operations
- [ ] Feature flags used for incomplete features
- [ ] Configuration externalized (no hardcoded env values)
- [ ] Monitoring/logging instrumentation in place
- [ ] Graceful error handling (no loud failures)
- [ ] Rollback path considered

## Observations & Feedback
- [ ] Code style/patterns consistent (nitpicks vs. standards)
- [ ] Constructive feedback if changes needed
- [ ] Praise specific good patterns or solutions

---

## Review Decision
- [ ] **APPROVE** — All checks pass
- [ ] **REQUEST CHANGES** — Issues must be fixed before merge
- [ ] **COMMENT** — Feedback for author but not blocking

**Reviewed By:** [Engineer Name]
**Date:** [YYYY-MM-DD]
**Review Time:** [X hours]

---

If approving, check that any previously-requested changes are addressed.
If requesting changes, be specific and actionable. Link to standards documents.
```

