# Template: Test Case Format

Create test cases in `docs/test-plans/test-cases/[epic-name]/[story-id]-test-cases.md`:

```markdown
# Test Cases — Story [ID]: [Title]

## Story Link
[Link to story artifact]

## Acceptance Criteria → Test Cases Mapping

### AC 1: [Acceptance Criterion]
**Test Case 1.1: [Happy Path]**
- Preconditions: [System state, user role, data]
- Steps:
  1. [Action]
  2. [Action]
  3. [Verify]
- Expected Result: [Outcome]
- Priority: P0/P1/P2

**Test Case 1.2: [Edge Case]**
- Preconditions: [...]
- Steps: [...]
- Expected Result: [...]

### AC 2: [Next Criterion]
[Similar test case structure]

## Integration Test Cases
- **Test: Service A calls Service B with payload X**
  - Preconditions: Service B is running, auth is valid
  - Steps: Trigger Service A operation
  - Expected: Service B API called with correct contract
  - Assertion: Response matches contract spec

## Performance Test Cases
- **Load Test:** 1000 requests/sec for 5 minutes
  - Target: P95 latency < 200ms
  - Target: Error rate < 0.1%

## Test Data Requirements
- User role: [Specify test data]
- Account state: [Specify]
- External API mocks: [List]

## Traceability
| Test Case | Acceptance Criterion | Automated | Owner |
|-----------|----------------------|-----------|-------|
| 1.1 | AC 1 | Yes | [Engineer] |
| 1.2 | AC 1 | No (Manual) | [QE] |
```

