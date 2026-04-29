# Template: Defect Report

Create a defect report when a bug is found: `docs/reviews/defect-report-[BUG-ID].md`

```markdown
# Defect Report: [BUG-ID]

## Summary
[1-sentence description]

## Severity
- **Critical:** System down or data loss risk
- **High:** Core functionality broken, blocks progress
- **Medium:** Feature partially broken, workaround exists
- **Low:** Minor UI/UX issue, cosmetic

## Affected Component
- Service: [Microservice name]
- Feature: [User story or functionality]
- Environment: [Dev/Staging/Prod]

## Reproduction Steps
1. [Step-by-step to reproduce]
2. [...]
3. [Verify problem]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Test Case
[Reference the test case that caught this bug]

## Environment Details
- OS: [Windows/Mac/Linux]
- Browser: [If applicable]
- Service version: [Build/commit hash]
- Database state: [Any relevant data]

## Screenshots/Logs
[Attach error logs, stack traces, screenshots]

## Root Cause (Optional, after triage)
[If investigated, describe root cause]

## Impact Assessment
- User impact: [Number of users affected]
- Business impact: [Revenue loss, compliance violation, etc.]
- Frequency: [Always, intermittent, under load, etc.]

## Assigned To
[Engineering agent responsible for fix]

## Status
- Open / In Progress / Fixed / Verified / Closed
```

