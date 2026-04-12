---
description: "[Mobile Engineer] Implement a user story following the solution architecture, coding conventions, and acceptance criteria. Works for Backend, Frontend, or Mobile engineer."
argument-hint: "[story ID, e.g. 'STORY-3'] [role: 'be' | 'fe' | 'me']"
---

Implement a user story with proper testing and adherence to architecture and conventions.

## Steps

1. Parse $ARGUMENTS to extract story ID (e.g., 'STORY-3') and role ('be'=backend, 'fe'=frontend, 'me'=mobile).

2. Read the story file: `docs/stories/[story-id].md` (required).

3. Read `docs/architecture/solution-architecture.md` for architecture context and service boundaries.

4. Read `.bmad/tech-stack.md` for technology constraints applicable to the role.

5. Read `.bmad/team-conventions.md` for naming conventions, folder structure, and coding style.

6. Read `docs/security/security-architecture.md` if it exists (for security requirements).

7. If role is 'fe' or 'me', read `docs/ux/wireframes/` for the feature's visual design.

8. Plan the implementation:
   - List files to create/modify
   - Map acceptance criteria to implementation tasks
   - Identify dependencies (other stories, third-party APIs, databases)
   - Note security requirements (input validation, auth, encryption)

9. Ask: "Here is my implementation plan for [story-id]. Proceed with implementation?"

10. Upon approval, implement:
    - Write code following team conventions
    - Create unit tests (target 80%+ coverage)
    - For BE: implement endpoints, data models, validation, error handling
    - For FE: implement components, state management, UI behavior
    - For ME: implement screens, navigation, data binding
    - Run: linting, unit tests, integration tests if applicable

11. Verify all acceptance criteria are satisfied by the implementation.

12. Run tests: `npm test` / `pytest` / `go test ./...` (depending on tech stack)
    - Report test results: [N] passed, [M] failed, coverage [X]%

13. If all tests pass, confirm: "Story [story-id] implemented and tested. [N] files created/modified. All acceptance criteria satisfied."

14. If tests fail, report the failures and ask: "Should I fix the failing tests?"
