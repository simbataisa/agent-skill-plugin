# BMAD Framework for Gemini CLI

Gemini CLI instructions for BMAD framework integration.

## BMAD Framework Overview

BMAD structures software delivery through four phases: Business Planning (B), Machine/Architecture (M), Assembly (A), and Delivery (D). Each phase involves specialized agent roles.

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

## How to Invoke Agents

When a task aligns with a BMAD role:
1. Read the corresponding `agents/<role>/SKILL.md`
2. Follow the agent's mandate and constraints
3. Coordinate with other agents as needed

## Context Loading Order

1. `.bmad/PROJECT-CONTEXT.md` – current project status
2. `.bmad/tech-stack.md` – technology decisions
3. `.bmad/team-conventions.md` – coding standards
4. `shared/BMAD-SHARED-CONTEXT.md` – organization standards (if available)

## BMAD Artifact Convention

Artifacts are stored in `docs/`:
```
docs/
├── requirements/
├── architecture/
├── design/
├── api-specs/
└── test-plans/
```

## Critical First Step

If `.bmad/PROJECT-CONTEXT.md` exists, load it before proceeding.
