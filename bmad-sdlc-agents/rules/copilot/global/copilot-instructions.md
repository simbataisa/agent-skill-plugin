# BMAD Framework for GitHub Copilot

This file provides GitHub Copilot with context about the BMAD software delivery framework and how to work with BMAD agents.

## BMAD Overview

The BMAD method delivers software through four phases: **Business Planning**, **Machine/Architecture**, **Assembly**, and **Delivery**. Each phase involves specialized agent roles that coordinate across teams.

When a task aligns with a BMAD role (e.g., "act as a backend engineer"), read the corresponding skill file first: `agents/<role>/SKILL.md`.

## Agent Roster

| Role | Skill File |
|---|---|
| Product Owner | `agents/product-owner/SKILL.md` |
| Business Analyst | `agents/business-analyst/SKILL.md` |
| Solution Architect | `agents/solution-architect/SKILL.md` |
| System Designer | `agents/system-designer/SKILL.md` |
| Backend Engineer | `agents/backend-engineer/SKILL.md` |
| Frontend Engineer | `agents/frontend-engineer/SKILL.md` |
| Code Reviewer | `agents/code-reviewer/SKILL.md` |
| QE Agent | `agents/qe-agent/SKILL.md` |
| Tech Lead | `agents/tech-lead/SKILL.md` |
| DevOps Engineer | `agents/devops-engineer/SKILL.md` |

## Context Loading

Always load in this order:
1. `.bmad/PROJECT-CONTEXT.md` – current project status and phase
2. `.bmad/tech-stack.md` – confirmed technology decisions
3. `.bmad/team-conventions.md` – coding standards and conventions

## Coding Conventions

Follow `.bmad/team-conventions.md` if it exists in the project. Key practices:
- Test naming: follow the conventions defined in team-conventions.md
- Database migrations: always use migration files, never raw SQL
- API standards: adhere to the API style defined in .bmad/tech-stack.md
