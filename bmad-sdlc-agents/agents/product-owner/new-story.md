---
description: "[Product Owner] Create a new BMAD implementation story from the shared story template. Pass a story title or brief description."
argument-hint: "[story title or description]"
---

Create a new implementation story using the BMAD story template.

Steps:
1. Read `../../shared/templates/story-template.md` (relative to agents/ — or search for story-template.md in the project)
2. Read `.bmad/PROJECT-CONTEXT.md` to understand the project context
3. Read `.bmad/tech-stack.md` to know the confirmed technology stack
4. Ask the user for any missing details: Epic name, story acceptance criteria, dependencies
5. Fill in the template with:
   - Story ID: STORY-[next number based on existing stories in docs/stories/]
   - Title: $ARGUMENTS
   - Context from PROJECT-CONTEXT.md
   - Tech stack from tech-stack.md
6. Save the filled story to `docs/stories/STORY-[N]-[slugified-title].md`
7. Confirm: "Story created: docs/stories/STORY-[N]-[title].md"
