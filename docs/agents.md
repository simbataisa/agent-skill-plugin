# Agent Team & Roster

The 13 specialized AI agents that make up the BMAD squad — their skill files, BMAD phase, and roles.

## Table of Contents

- [Agent Team](#agent-team)

---

## Agent Team

| Agent                    | Skill File                             | BMAD Phase     | Role                                                                                                    |
| ------------------------ | -------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------- |
| **BMAD Orchestrator**    | `agents/bmad/SKILL.md`                 | All Phases     | Routes work to the right sub-agent; entry point for squad prompts                                       |
| **Product Owner**        | `agents/product-owner/SKILL.md`        | Analysis       | Voice of the Business — BRD, high-level PRD, MVP scope (runs first)                                     |
| **Business Analyst**     | `agents/business-analyst/SKILL.md`     | Analysis       | Requirements analyst — deep-dives BRD/PRD, produces requirements analysis                               |
| **Enterprise Architect** | `agents/enterprise-architect/SKILL.md` | Solutioning    | High-level enterprise arch BEFORE SA — cloud infra, compliance, CI/CD                                   |
| **UX/UI Designer**       | `agents/ux-designer/SKILL.md`          | Solutioning    | Personas, journeys, wireframes, **`docs/ux/DESIGN.md` (Google Stitch format)**, a11y (parallel with EA) |
| **Solution Architect**   | `agents/solution-architect/SKILL.md`   | Solutioning    | Detailed solution design using EA + UX outputs — APIs, data models, ADRs                                |
| **InfoSec Architect**    | `agents/infosec-architect/SKILL.md`    | Solutioning    | Threat modelling, controls, privacy-by-design, supply-chain, IR readiness                               |
| **DevSecOps Engineer**   | `agents/devsecops-engineer/SKILL.md`   | All Phases     | Pipelines, IaC, SLOs, FinOps, reliability & recovery                                                    |
| **Tech Lead**            | `agents/tech-lead/SKILL.md`            | All Phases     | Orchestration, sprint planning, code review, risk, release readiness                                    |
| **Tester & QE**          | `agents/tester-qe/SKILL.md`            | All Phases     | Test strategy, quality gates, security testing, UI automation                                           |
| **Backend Engineer**     | `agents/backend-engineer/SKILL.md`     | Implementation | APIs, data layers, event-driven services, authN/Z, idempotency                                          |
| **Frontend Engineer**    | `agents/frontend-engineer/SKILL.md`    | Implementation | React/TypeScript, perf budgets, feature flags, i18n                                                     |
| **Mobile Engineer**      | `agents/mobile-engineer/SKILL.md`      | Implementation | iOS/Android, offline, app-size, crash reporting                                                         |

---

[← Back to README](../README.md)  ·  [Agents](agents.md)  ·  [Architecture](architecture.md)  ·  [Workflows](workflows.md)  ·  [Tooling](tooling.md)  ·  [Adoption](adoption.md)
