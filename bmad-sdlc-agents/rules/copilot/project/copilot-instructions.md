# Project-Specific Copilot Instructions

Customize this file for each project. Place at `.github/copilot-instructions.md`.

## Project Information

**Project Name**: [FILL IN]

**Description**: [FILL IN - 1-2 sentences about what this project does]

## Current BMAD Phase

We are in the **[FILL IN: Business / Machine / Assembly / Delivery]** phase.

## Tech Stack

- **Backend**: [FILL IN]
- **Frontend**: [FILL IN]
- **Database**: [FILL IN]
- **API Style**: [FILL IN]

**Always check `.bmad/tech-stack.md` before suggesting a technology.**

## Code Generation Rules

- [FILL IN - any specific rules, e.g., "Always use the /utils folder for helper functions"]
- [FILL IN - naming conventions, e.g., "Prefix test files with 'test.', not '.test'"]
- Use migrations for schema changes (never raw SQL)
- Follow the conventions in `.bmad/team-conventions.md`

## Domain Terms

[FILL IN - Define key domain vocabulary]
- **Term 1**: Definition
- **Term 2**: Definition

## Agent Integration

When a task aligns with a BMAD agent role, Copilot should read the agent's SKILL.md file to understand constraints and best practices.

Example: "Act as Backend Engineer" → Read `agents/backend-engineer/SKILL.md`

## Communication

**Tech Lead**: [FILL IN - Name/Role]
**Slack Channel**: [FILL IN - or other communication channel]
