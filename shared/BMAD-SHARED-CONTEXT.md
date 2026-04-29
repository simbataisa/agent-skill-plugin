# BMAD Method — Shared Context for All Agents

## What is BMAD?

BMAD (Breakthrough Method of Agile AI-Driven Development) is a structured, agent-orchestrated approach to the software development lifecycle. Instead of unstructured AI prompting, BMAD uses specialized agent personas that collaborate through explicit artifact handoffs, ensuring context preservation, traceability, and quality across the entire SDLC.

## BMAD Four-Phase Cycle

1. **Analysis** — Explore the problem space, capture constraints, produce a Project Brief
2. **Planning** — Transform the brief into a PRD with functional/non-functional requirements, epics, and stories
3. **Solutioning** — Design architecture, define technical specifications, create detailed implementation stories
4. **Implementation** — Build, test, review, and deliver working software

## Work Types

Choose the squad prompt set that matches the nature of the work:

| Work Type | Prompt Set | Key Agents | When to Use |
|-----------|-----------|------------|-------------|
| **New Project** | A → B → C | All agents — planning + security + execution | Greenfield project from scratch |
| **Feature / Enhancement** | A → B | PO → SA → UX → InfoSec (delta) → TL → DevSecOps → TQE + execution | New capability on an existing project |
| **Bug Fix** | A → B | TQE diagnose → TL root cause → fix + verify | Defect in existing functionality |
| **Hotfix** | Single prompt | TL + engineer + TQE | Critical production emergency |
| **Backlog / Tech Debt** | A → B | PO refine → TL breakdown + execution | Known story, chore, or refactor |
| **Security Review** | Single prompt | InfoSec Architect + DevSecOps Engineer | Compliance audit, threat model refresh, security gate review |

Full prompt templates for all work types are in `bmad-sdlc-agents/README.md` under **Squad Prompt**.

## Collaborative Handoff Model

Agents operate in a collaborative/iterative mode:

- Any agent can request input from another agent at any point
- Artifacts are the contract — agents read and refine shared artifacts rather than relying on chat context
- Feedback loops are encouraged (e.g., Architect refines based on BA feedback, Tech Lead reviews stories before dev starts)
- All artifacts live in a shared `docs/` directory within the project

## Agent Roster

| Agent | Phase | Primary Responsibility |
|-------|-------|-----------------------|
| Product Owner | Analysis / Planning | BRD, PRD, epic definition, RICE prioritisation, business value |
| Business Analyst | Analysis | Deep requirements analysis, user stories, acceptance criteria, use cases |
| InfoSec Architect | Solutioning | Threat modelling (STRIDE/PASTA), IAM design, compliance mapping, risk register, incident response |
| Enterprise Architect | Solutioning | Cloud infra, compliance architecture, observability, CI/CD, FinOps, technology radar |
| UX/UI Designer | Solutioning | Personas, user journeys, wireframes, design system, accessibility |
| Solution Architect | Solutioning | Service decomposition, API contracts, data models, ADRs, integration specs |
| Tech Lead | All Phases | Orchestration, sprint planning, code review via worktree, risk, release readiness |
| DevSecOps Engineer | Implementation | SAST/DAST, container security, IaC scanning, secrets management, security pipeline gates |
| Backend Engineer | Implementation | APIs, data layers, event-driven services |
| Frontend Engineer | Implementation | React/TypeScript components, state management, accessibility |
| Mobile Engineer | Implementation | iOS, Android, React Native, Flutter, offline-first |
| Tester & QE | Implementation | Test strategy, test cases, E2E automation, quality gates, pre-release sign-off |

## Worktree Workflow & Multi-Agent Merge

Every BMAD agent that writes code or artefacts works inside an **isolated git worktree** (`../bmad-<role>-work`) on a dedicated branch (`<role>/<sprint-or-feature>`). This keeps the main working tree clean, lets parallel agents run without stepping on each other, and gives the human a clear branch boundary for review.

**End-of-job protocol (every agent):**

1. **Request human review.** Print a structured summary with branch name, diffstat, top files changed, commit count, and test status. The human replies `approve` (proceed), `refine: <notes>` (revise), or `defer` (leave the worktree open).
2. **Merge to main on approval.** Refresh main, detect whether a peer agent already merged. If main hasn't moved → fast-forward merge. If main has moved → rebase the role branch onto the latest main.
3. **Resolve conflicts cooperatively (multi-agent rule).** When the rebase produces conflicts:
   - Conflicts in **my-domain** files → resolve solo, run my tests, commit.
   - Conflicts in **another role's owned scope** OR **shared / cross-domain files** (lockfiles, OpenAPI specs, build configs, integration tests) → write `.bmad/signals/conflict-<my-role>-needs-<peer-role>-review`, request peer review (via the Agent tool on Claude Code / Kiro autonomous mode, or via human prompt elsewhere). **Do not complete the merge until the peer or human signs off.**
   - Conflicts in **sequenced files** (DB migrations, IaC) → escalate to Tech Lead. Never resolve solo.
4. **Clean up.** `git worktree remove ../bmad-<role>-work` and `git branch -d <role>/<sprint-or-feature>`. Print the cleanup summary.

The full protocol with bash recipes lives in [`shared/references/worktree-close-out.md`](references/worktree-close-out.md). Every agent's SKILL.md links to it from its `## Worktree Close-out & Merge` section.

**Concurrent-merge invariant:** when BE ∥ FE ∥ ME run in parallel during Wave E2 (or any other parallel-agent wave), the **first** agent to merge always succeeds cleanly. The **second and third** to arrive at the merge gate are responsible for the rebase + conflict resolution — that is the cost of running concurrently. If the second/third agent isn't confident in a resolution that touches another role's scope, they ask that role's agent (or Tech Lead) to review *before* completing the merge. No agent ever silently overwrites another agent's work.

## Standard Artifact Directory Structure

```
project-root/
├── docs/
│   ├── project-brief.md          # Analysis phase output
│   ├── prd.md                    # Product Requirements Document
│   ├── architecture/
│   │   ├── solution-architecture.md
│   │   ├── enterprise-architecture.md
│   │   ├── adr/                  # Architecture Decision Records
│   │   │   └── ADR-001-*.md
│   │   └── diagrams/
│   ├── ux/                       # UX/UI Designer outputs
│   │   ├── personas.md
│   │   ├── user-journeys.md
│   │   ├── information-architecture.md
│   │   ├── DESIGN.md             # Google Stitch DESIGN.md — authoritative design system
│   │   ├── ui-spec.md
│   │   ├── accessibility-audit.md
│   │   └── wireframes/
│   ├── stories/
│   │   ├── epic-1/
│   │   │   ├── story-1.1.md
│   │   │   └── story-1.2.md
│   │   └── epic-2/
│   ├── testing/
│   │   ├── test-strategy.md      # TQE strategy (all work types)
│   │   ├── sprint-N-results.md   # Per-sprint test results
│   │   ├── bugs/                 # Bug fix reports (bug-report-template.md)
│   │   │   └── [bug-id].md
│   │   └── hotfixes/             # Hotfix assessments (hotfix-template.md)
│   │       └── [date]-[issue].md
│   ├── tech-specs/
│   │   ├── api-spec.md
│   │   ├── data-model.md
│   │   └── integration-spec.md
│   ├── security/                 # InfoSec Architect + DevSecOps outputs
│   │   ├── threat-model.md       # STRIDE threat model and DFD
│   │   ├── security-architecture.md  # Controls, IAM, encryption, network
│   │   ├── risk-register.md      # Risks, CVSS scores, owners, mitigations
│   │   ├── iam-design.md         # Roles, permissions, federation, MFA policy
│   │   ├── compliance-mapping.md # SOC2 / GDPR / HIPAA / PCI-DSS control map
│   │   ├── data-classification.md
│   │   ├── incident-response-plan.md
│   │   ├── security-policies.md
│   │   ├── devsecops-pipeline.md # CI/CD security gate configuration
│   │   ├── sast-dast-report.md   # Scan findings and triage
│   │   ├── secrets-management.md # Vault / Secrets Manager strategy
│   │   ├── container-security.md # Image hardening and runtime policies
│   │   ├── iac-security-report.md
│   │   ├── dependency-audit.md
│   │   └── security-gate-results.md  # Pre-release sign-off
│   └── reviews/
│       ├── code-review-checklist.md
│       └── architecture-review.md
├── src/                          # Source code
├── tests/                        # Test code
└── .bmad/                        # BMAD config and state
    ├── project-state.md          # Current phase, blockers, decisions
    ├── handoff-log.md            # Record of agent-to-agent handoffs
    └── signals/
        ├── po-done               # PO sentinel
        ├── ba-done               # BA sentinel
        ├── infosec-done          # InfoSec Architect sentinel
        ├── ea-done               # Enterprise Architect sentinel
        ├── ux-done               # UX Designer sentinel
        ├── sa-done               # Solution Architect sentinel
        ├── tl-plan-done          # Tech Lead sprint kickoff sentinel
        ├── devsecops-done        # DevSecOps Engineer sentinel
        ├── E2-be-done            # TL-approved BE implementation
        ├── E2-fe-done            # TL-approved FE implementation
        ├── E2-me-done            # TL-approved ME implementation
        └── autonomous-mode       # Skip human review gates (autonomous orchestration)
```

## Artifact Versioning

All artifacts are markdown files under version control. When an agent modifies an artifact:

1. Note what changed and why at the top of the file in a changelog section
2. Log the handoff in `.bmad/handoff-log.md`
3. Reference the specific artifact version when handing off to the next agent

## Enterprise System Conventions

Since these agents target enterprise systems (microservices, cloud infrastructure, complex integrations):

- Always consider non-functional requirements: scalability, security, observability, compliance
- Document integration points and contract boundaries explicitly
- Use Architecture Decision Records (ADRs) for significant technical choices
- Consider multi-environment deployment (dev, staging, prod)
- Address cross-cutting concerns: authentication, authorization, logging, monitoring, rate limiting
