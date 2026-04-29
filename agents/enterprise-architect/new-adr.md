---
description: "[Enterprise Architect] Create a new Architecture Decision Record (ADR) from the shared ADR template. Pass a decision title."
argument-hint: "[decision title]"
---

Create a new Architecture Decision Record.

Steps:
1. Read `../../shared/templates/adr-template.md` (or search for adr-template.md)
2. Check docs/architecture/adr/ for existing ADRs to determine the next number
3. Fill in the ADR template:
   - ADR-[N]: $ARGUMENTS
   - Date: today's date
   - Status: Proposed
   - Context: Ask the user to describe the problem/context if not provided
   - Options considered: Ask user for alternatives evaluated
   - Decision: Ask user for the chosen option and rationale
   - Consequences: Derive from the decision
4. Save to `docs/architecture/adr/ADR-[N]-[slugified-title].md`
5. Update `.bmad/tech-stack.md` ADR index if the decision relates to technology
6. Confirm: "ADR created: docs/architecture/adr/ADR-[N]-[title].md"
