---
description: "[Product Owner] Kick off a new BMAD epic — orchestrates all agents through Analysis → Planning → Solutioning → Implementation for a new feature or capability."
argument-hint: "[epic name or description]"
---

You are the BMAD Squad orchestrator. Kick off a full BMAD epic for: **$ARGUMENTS**

The four-phase BMAD cycle is **Analysis → Planning → Solutioning → Implementation**. The phase ordering below matches the canonical flow in `agents/product-owner/SKILL.md`, `agents/business-analyst/SKILL.md`, and `shared/BMAD-SHARED-CONTEXT.md`: the Product Owner produces the business mandate (BRD + PRD) first, then the Business Analyst performs deep requirements analysis and authors user stories, then Solutioning, then Tech Lead breaks work into implementation stories.

## Phase 0: Context Loading
1. Read `.bmad/PROJECT-CONTEXT.md` — understand project context and current phase
2. Read `.bmad/tech-stack.md` — note confirmed technologies (do not re-decide these)
3. Read `.bmad/team-conventions.md` — follow team standards throughout

## Phase 1: Analysis — Business Mandate (Product Owner)
Load `agents/product-owner/SKILL.md` and:
- Elicit business goals, stakeholders, constraints, success criteria
- Produce `docs/brd.md` (Business Requirements Document)
- Produce `docs/prd.md` (high-level Product Requirements Document — features in business terms, **not** user stories)
- Define MVP scope

**Checkpoint:** Present Phase 1 outputs (BRD + PRD). Ask: "Shall I proceed to Planning (Business Analyst deep analysis), or do you want to refine the BRD/PRD?"

## Phase 2: Planning — Requirements Analysis & User Stories (Business Analyst)
Load `agents/business-analyst/SKILL.md` and:
- Read `docs/brd.md` + `docs/prd.md` as input (both required — do not proceed without them)
- Perform stakeholder analysis, gap analysis, business-rules documentation, feasibility assessment, process modeling
- Produce `docs/analysis/requirements-analysis.md` — functional + non-functional requirements with traceability matrix
- **Author user stories** with Given-When-Then acceptance criteria, business rules, and DoD. Save to `docs/stories/STORY-[N]-[slug].md`. **Stories go only in `docs/stories/` — never `.bmad/stories/`.**
- Output: requirements analysis document + user story set

**Checkpoint:** Present Phase 2 outputs (requirements analysis + story set). Ask: "Shall I proceed to Solutioning (Solution Architect ∥ UX Designer, in parallel)?"

## Phase 3: Solutioning (Solution Architect ∥ UX Designer)
Load `agents/solution-architect/SKILL.md` and:
- Design the technical approach (reference technology-radar.md for stack decisions)
- Create/update `docs/architecture/solution-architecture.md`
- Generate any new ADRs for decisions made

**In parallel**, load `agents/ux-designer/SKILL.md` and:
- Run Design Preferences Elicitation if not done
- Produce wireframes and UI spec for the epic's screens
- Save to `docs/ux/`

**Checkpoint:** Present Phase 3 outputs. Ask: "Shall I proceed to Implementation-story breakdown (Tech Lead)?"

## Phase 4: Implementation Stories (Tech Lead)
Load `agents/tech-lead/SKILL.md` and:
- Read `docs/stories/` (BA's user stories) + `docs/architecture/` + `docs/ux/`
- Refine each user story into an implementation story with technical context, dependencies, DoD, and assignment
- Keep refined stories in `docs/stories/` (alongside BA's authored ones — do not duplicate path)
- Assign to: backend-engineer, frontend-engineer, mobile-engineer as appropriate

## Final: Handoff Log
Append a handoff entry to `.bmad/handoff-log.md` summarizing the epic kickoff.

Present a summary: epic name, phase reached, artifacts created, stories generated, next action.

## Guardrails

- **Never let PO author user stories.** If the user asks for stories during Phase 1, stop and explain that stories come from the Business Analyst in Phase 2, after the BRD + PRD are in place.
- **Never skip Phase 2.** Jumping from Phase 1 (PRD) directly to Phase 3 (Solutioning) leaves the team without the requirements analysis and user stories that EA/UX/SA all depend on.
- **Story paths:** every story file in this flow lives under `docs/stories/`. `.bmad/` is the project-config and signal directory (PROJECT-CONTEXT.md, tech-stack.md, handoff-log.md, signals/) — it is not an output path for stories or analysis.
