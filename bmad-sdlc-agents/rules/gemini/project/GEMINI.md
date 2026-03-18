# Project-Specific Gemini CLI Instructions

Place at `.gemini/GEMINI.md` in your project.

## Project Information

**Project Name**: [FILL IN]

**Description**: [FILL IN - what this project does]

## Current BMAD Phase

**Phase**: [FILL IN: Business / Machine / Assembly / Delivery]

**Active Agents**: [FILL IN - which agent roles are primary in this phase]

## Tech Stack

- **Backend**: [FILL IN]
- **Frontend**: [FILL IN]
- **Database**: [FILL IN]
- **API Style**: [FILL IN]

See `.bmad/tech-stack.md` for full details and rationale.

## Key Constraints

[FILL IN - list any hard constraints or SLAs]

## Code Generation Guidelines

- Use migrations for schema changes (never raw SQL)
- Follow naming conventions in `.bmad/team-conventions.md`
- All new endpoints require API documentation
- Test coverage: [FILL IN - required coverage percentage]

## Domain Terminology

[FILL IN - key domain terms]
- **Term 1**: Definition
- **Term 2**: Definition

## Agent Integration

When task aligns with a BMAD agent role, read `agents/<role>/SKILL.md` first.

## Team Contact

**Tech Lead**: [FILL IN]
**Communication**: [FILL IN - Slack, email, etc.]
