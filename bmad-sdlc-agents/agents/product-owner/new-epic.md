---
description: "[Product Owner] Kick off a new BMAD epic — orchestrates all agents through Analysis → Planning → Solutioning → Implementation for a new feature or capability."
argument-hint: "[epic name or description]"
---

You are the BMAD Squad orchestrator. Kick off a full BMAD epic for: **$ARGUMENTS**

## Phase 0: Context Loading
1. Read `.bmad/PROJECT-CONTEXT.md` — understand project context and current phase
2. Read `.bmad/tech-stack.md` — note confirmed technologies (do not re-decide these)
3. Read `.bmad/team-conventions.md` — follow team standards throughout

## Phase 1: Analysis (Business Analyst)
Load `agents/business-analyst/SKILL.md` and:
- Define the problem space for this epic
- Identify affected user personas
- Document business rules and constraints
- Output: `docs/project-brief.md` (or append epic section if file exists)

**Checkpoint:** Present Phase 1 output. Ask: "Shall I proceed to Planning, or do you want to refine the analysis?"

## Phase 2: Planning (Product Owner)
Load `agents/product-owner/SKILL.md` and:
- Create or update `docs/prd.md` with the epic's requirements
- Define acceptance criteria for each feature
- Prioritize stories using RICE scoring
- Output: PRD section + story list with priorities

**Checkpoint:** Present Phase 2 output. Ask: "Shall I proceed to Solutioning?"

## Phase 3: Solutioning (Solution Architect + UX Designer)
Load `agents/solution-architect/SKILL.md` and:
- Design the technical approach (reference technology-radar.md for stack decisions)
- Create/update `docs/architecture/solution-architecture.md`
- Generate any new ADRs for decisions made

Then load `agents/ux-designer/SKILL.md` and:
- Run Design Preferences Elicitation if not done
- Produce wireframes and UI spec for the epic's screens

**Checkpoint:** Present Phase 3 output. Ask: "Shall I proceed to creating implementation stories?"

## Phase 4: Implementation Stories (Tech Lead)
Load `agents/tech-lead/SKILL.md` and:
- Break the epic into implementation stories
- Add technical context, DoD, and dependencies to each story
- Save stories to `docs/stories/`
- Assign stories to: backend-engineer, frontend-engineer, mobile-engineer as appropriate

## Final: Handoff Log
Append a handoff entry to `.bmad/handoff-log.md` summarizing the epic kickoff.

Present a summary: Epic name, phase reached, artifacts created, stories generated, next action.
