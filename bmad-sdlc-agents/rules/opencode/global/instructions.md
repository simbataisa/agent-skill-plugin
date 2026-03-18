# BMAD Framework for OpenCode

OpenCode global instructions for BMAD integration.

## BMAD Framework Overview

BMAD delivers software through four phases with specialized agent roles:
- **Business (B)**: Product Owner, Business Analyst
- **Machine (M)**: Solution Architect, System Designer
- **Assembly (A)**: Backend Engineer, Frontend Engineer, Code Reviewer
- **Delivery (D)**: QE Agent, Tech Lead, DevOps Engineer

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

When task aligns with a BMAD role, read `agents/<role>/SKILL.md` first to understand mandate and constraints.

## Context Loading Order

1. `.bmad/PROJECT-CONTEXT.md`
2. `.bmad/tech-stack.md`
3. `.bmad/team-conventions.md`
4. `shared/BMAD-SHARED-CONTEXT.md` (if available)

## Artifact Convention

Store artifacts in `docs/` directory with subdirectories for requirements, architecture, design, API specs, and test plans.

## Important

Always load `.bmad/PROJECT-CONTEXT.md` if it exists before proceeding.
