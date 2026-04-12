---
description: "[Business Analyst] Create a user story with Given-When-Then acceptance criteria, business rules, and Definition of Done from the requirements analysis."
argument-hint: "[requirement ID or feature name]"
---

Create a detailed user story with acceptance criteria, business rules, dependencies, and Definition of Done.

## Steps

1. Read `docs/requirements/requirements-analysis.md` (required — fail if missing).

2. Parse $ARGUMENTS to extract the requirement ID or feature name. If not provided, ask: "Which requirement or feature should I create a story for?"

3. Read `../../agents/business-analyst/templates/user-story-template.md` for the template.

4. Determine the next story number by running: `ls docs/stories/STORY-*.md 2>/dev/null | sed 's/.*STORY-//;s/-.*//' | sort -n | tail -1`
   - Increment by 1 and zero-pad to 2 digits. If no stories exist yet, start with STORY-1.

5. Ask the user (all at once):
   - "What is the user role or persona for this story?"
   - "What does the user want to accomplish? (user goal)"
   - "Why is this important to them? (business value)"
   - "What acceptance criteria must pass? (list as Given-When-Then format or bullet points)"
   - "Are there any business rules or edge cases?"
   - "What are the dependencies? (other stories or systems)"

6. Generate the story in the template format:
   - Title: [Role] — [goal/action]
   - User Story: "As a [role], I want [action] so that [value]"
   - Acceptance Criteria: minimum 3 GWT scenarios
   - Business Rules: edge cases and constraints
   - Dependencies: blocking stories or external systems
   - Definition of Done: code written, unit tests pass, code review approved, documented, deployed to staging

7. Create a slug from the title (lowercase, hyphens). Save to `docs/stories/STORY-[N]-[slug].md`.

8. Confirm: "Story created → `docs/stories/STORY-[N]-[slug].md`. Assign to an engineer to `/implement-story`."
