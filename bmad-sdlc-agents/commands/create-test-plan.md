---
description: Create a test plan/strategy for a sprint or feature with test cases, coverage matrix, and execution strategy.
argument-hint: "[scope: 'sprint:<N>' | 'feature:<name>' | 'regression']"
---

Create a comprehensive test plan with test cases, coverage matrix, and execution strategy.

## Steps

1. Parse $ARGUMENTS to determine scope:
   - 'sprint:<N>': all stories in that sprint
   - 'feature:<name>': all stories for that feature
   - 'regression': full regression test suite

2. If scope is 'sprint:<N>':
   - Read `docs/architecture/sprint-[N]-kickoff.md` for story list
   - Gather all story files from `docs/stories/STORY-*.md` in that sprint

3. If scope is 'feature:<name>':
   - Search `docs/stories/` for stories matching the feature name
   - Read all matching story files

4. For each story in scope:
   - Read the story file to extract acceptance criteria
   - Convert GWT acceptance criteria into test cases

5. Read `docs/architecture/solution-architecture.md` to identify integration test boundaries (service-to-service, external APIs).

6. Read `docs/security/threat-model.md` to extract security test cases (auth, authorization, input validation, encryption).

7. Read `../../agents/tester-qe/references/testing-pyramid-guide.md` for test type classification.

8. For each story, create test cases organized by test type:
   - **Unit Tests**: function/method behavior (80% coverage target)
   - **Integration Tests**: service interactions, API contracts
   - **E2E Tests**: full user workflows
   - **Security Tests**: auth/authz, injection prevention, sensitive data handling

9. Create a coverage matrix showing:
   - Requirement (from story acceptance criteria)
   - Test Case ID
   - Test Type (unit/integration/E2E/security)
   - Status (planned/in-progress/passed/failed)

10. Fill the test plan template with: Scope, Test Cases (organized by story), Coverage Matrix, Test Execution Strategy (manual vs. automated), Timeline, Resource Requirements.

11. If Playwright MCP is available, generate E2E test skeleton code for user workflows.

12. Save to `docs/testing/test-strategy.md` (for ongoing) or `docs/testing/test-plan-sprint-[N].md` (for specific sprint).

13. Confirm: "Test plan created → [file]. [N] test cases designed across unit/integration/E2E/security."
