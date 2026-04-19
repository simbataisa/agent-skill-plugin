# BMAD SDLC Framework (Windsurf)

The BMAD method structures software delivery through four distinct phases and specialized agent roles, ensuring quality, consistency, and accountability across projects.

## The Four BMAD Phases

1. **Business Planning (B)**: Define requirements, user stories, and project constraints with Product Owner and Business Analyst
2. **Machine Learning / Architecture (M)**: Design system architecture, tech stack, and API contracts with Solution Architect and System Designer
3. **Assembly (A)**: Implement features, write code, and conduct reviews with Backend Engineer, Frontend Engineer, and Code Reviewer
4. **Delivery (D)**: Test, document, deploy, and monitor with QE Agent, Tech Lead, and DevOps Engineer

## BMAD Agent Roster

| Agent Role | Primary Responsibility | When to Invoke | Skill File |
|---|---|---|---|
| **Product Owner** | Define requirements, manage backlog, prioritize stories | Questions about what to build, prioritization | `agents/product-owner/SKILL.md` |
| **Business Analyst** | Clarify requirements, write acceptance criteria, stakeholder liaison | Need to clarify business logic or acceptance criteria | `agents/business-analyst/SKILL.md` |
| **Solution Architect** | Design system architecture, make tech decisions, define API contracts | Questions about system design, scalability, architecture | `agents/solution-architect/SKILL.md` |
| **System Designer** | Detail design specs, ERD, sequence diagrams, component design | Need detailed design before implementation | `agents/system-designer/SKILL.md` |
| **Backend Engineer** | Implement backend services, data models, business logic | Building APIs, services, data layers | `agents/backend-engineer/SKILL.md` |
| **Frontend Engineer** | Implement UI/UX, client logic, state management | Building user interfaces, web/mobile clients | `agents/frontend-engineer/SKILL.md` |
| **Code Reviewer** | Review code quality, suggest improvements, approve merges | Code review requests, quality assurance before merge | `agents/code-reviewer/SKILL.md` |
| **QE Agent** | Write and run tests, verify acceptance criteria, catch regressions | Test planning, E2E test writing, quality verification | `agents/qe-agent/SKILL.md` |
| **Tech Lead** | Coordinate handoffs, manage technical debt, oversee releases | Handoff coordination, release planning, technical decisions | `agents/tech-lead/SKILL.md` |
| **DevOps Engineer** | Manage infrastructure, CI/CD, monitoring, deployments | Infrastructure, deployment, monitoring questions | `agents/devops-engineer/SKILL.md` |

## How to Invoke BMAD Agents

When asked to act as a specific BMAD role:
1. Read the corresponding `agents/<role-name>/SKILL.md` file first
2. Follow the agent's mandate, constraints, and best practices
3. Ask clarifying questions if the request conflicts with the agent's scope
4. Coordinate with other agents as needed

## Context Loading Order

Always load project context in this sequence:
1. `.bmad/PROJECT-CONTEXT.md` – Project-specific overrides and current status
2. `.bmad/tech-stack.md` – Confirmed technology decisions
3. `.bmad/team-conventions.md` – Coding standards and naming conventions
4. `shared/BMAD-SHARED-CONTEXT.md` – Organization-wide standards (if available)

## BMAD Artifact Directory Convention

All BMAD artifacts (requirements docs, architecture decisions, design specs, test plans) should be stored in:
```
docs/
├── analysis/          # Requirements analysis, use cases, impact (BA)
├── stories/           # User stories (BA)
├── architecture/
├── ux/
├── api-specs/
└── testing/
```

## Critical First Step

If `.bmad/PROJECT-CONTEXT.md` exists in this project, load it before proceeding with any task.
