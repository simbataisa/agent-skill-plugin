# BMAD SDLC Framework (Trae IDE)

The BMAD method structures software delivery through four distinct phases and specialized agent roles, ensuring quality, consistency, and accountability across projects.

> **How Trae reads this file.** Trae treats markdown files in `~/.trae/rules/` (user scope) and `.trae/rules/` (project scope) as always-on guidelines for the AI. If your Trae version only auto-loads `user_rules.md`, this content is also installed at that path — both copies point at the same skill bodies under `~/.trae/skills/`.

## The Four BMAD Phases

1. **Business Planning (B)**: Define requirements, user stories, and project constraints with Product Owner and Business Analyst
2. **Machine Learning / Architecture (M)**: Design system architecture, tech stack, and API contracts with Enterprise Architect, Solution Architect, and UX Designer
3. **Assembly (A)**: Implement features, write code, and conduct reviews with Backend Engineer, Frontend Engineer, Mobile Engineer, and Tech Lead
4. **Delivery (D)**: Test, document, deploy, and monitor with Tester/QE, DevSecOps, and InfoSec Architect

## BMAD Agent Roster

| Agent Role | Primary Responsibility | When to Invoke | Skill File |
|---|---|---|---|
| **Product Owner** | BRD/PRD/epics, success metrics, MVP scope | Start of any new feature/product | `agents/product-owner/SKILL.md` |
| **Business Analyst** | Stories (GWT), use cases, NFRs, traceability | After PO artifacts exist; flags tech risks but does NOT design | `agents/business-analyst/SKILL.md` |
| **Enterprise Architect** | Cloud/compliance/CI-CD strategy, tech radar | Before Solution Architect; sets enterprise guardrails | `agents/enterprise-architect/SKILL.md` |
| **Solution Architect** | API contracts, data models, ADRs, SLOs | After EA + UX; designs inside EA guardrails | `agents/solution-architect/SKILL.md` |
| **UX Designer** | Personas, journeys, wireframes, WCAG 2.2 AA specs | Parallel with Enterprise Architect during Solutioning | `agents/ux-designer/SKILL.md` |
| **InfoSec Architect** | Threat model, controls, PbD, supply-chain integrity | Parallel with Solution Architect | `agents/infosec-architect/SKILL.md` |
| **DevSecOps Engineer** | CI/CD, IaC, SLO/SLI, FinOps, scan gates | Alongside SA or during Implementation | `agents/devsecops-engineer/SKILL.md` |
| **Tech Lead** | Sprint kickoff, story sequencing, code review, release sign-off | Before each sprint; after BE/FE/ME branches are ready | `agents/tech-lead/SKILL.md` |
| **Backend Engineer** | Services, APIs, data layer, auth, events | Wave E2 backend work | `agents/backend-engineer/SKILL.md` |
| **Frontend Engineer** | Web UI, Core Web Vitals, bundles, a11y | Wave E2 frontend work | `agents/frontend-engineer/SKILL.md` |
| **Mobile Engineer** | iOS/Android/cross-platform, offline/sync, crash | Wave E2 mobile work | `agents/mobile-engineer/SKILL.md` |
| **Tester / QE** | Risk-based test plan, flake quarantine, quality gate | After BE∥FE∥ME complete (Wave E3); bug diagnosis | `agents/tester-qe/SKILL.md` |
| **BMAD Router** | Scan project state, recommend next agent | Start of work, or when next step is unclear | `agents/bmad/SKILL.md` |

## How to Invoke BMAD Agents

Trae is a single-session agent (no native subagent spawning). To act as a specific BMAD role:

1. Read the corresponding `~/.trae/skills/<role-name>/SKILL.md` first
2. Follow the agent's mandate, scope boundaries, and quality gate
3. Ask clarifying questions if the request conflicts with the agent's scope (especially BA → EA/SA, EA → SA)
4. Coordinate handoffs by appending a one-line entry to `.bmad/handoff-log.md` and writing the role sentinel under `.bmad/signals/`

## Context Loading Order

Always load project context in this sequence before producing any artifact:

1. `.bmad/PROJECT-CONTEXT.md` — project goals and constraints
2. `.bmad/tech-stack.md` — confirmed technology choices (never re-debate these)
3. `.bmad/team-conventions.md` — naming, branching, style
4. `.bmad/domain-glossary.md` — business terminology
5. `.bmad/ux-design-master.md` — design tool + master file path (UX roles only)
6. `.bmad/handoff-log.md` — what the previous agent handed off to you

Fallback: `~/.trae/BMAD-SHARED-CONTEXT.md` (deployed by `install-global.sh`).

## BMAD Artifact Directory Convention

All BMAD artifacts live under `docs/`:

```
docs/
├── analysis/            # Requirements analysis, use cases, impact (BA)
├── stories/             # User stories (BA)
├── architecture/
│   └── adr/             # Architecture Decision Records (EA / SA)
├── ux/
├── api-specs/
├── security/            # Threat models, control mappings (InfoSec)
├── operations/          # Runbooks, SLOs (DevSecOps)
└── testing/             # Test plans, quality-gate reports (QE)
```

## Critical First Step

If `.bmad/PROJECT-CONTEXT.md` exists in this project, load it before proceeding with any task.
