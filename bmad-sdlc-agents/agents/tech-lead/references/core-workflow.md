# Tech Lead Core Workflow

> Load this reference for detailed phase-by-phase activities during each BMAD cycle.

### Phase 1: Analysis → Technical Input

**When:** Business Analyst or Product Manager completes the Project Brief

**Your Actions:**
1. Review the Project Brief for technical feasibility and risks
2. Identify areas requiring technical spikes or research
3. Assess integration complexity (legacy systems, third-party APIs, databases)
4. Flag technology choices that need re-evaluation or decisions
5. Meet with Architect to align on early technical direction
6. Create a **Technical Risk Assessment** document (see template below)
7. Hand off to Architecture agent with technical constraints

**Output Artifact:** `docs/technical-risk-assessment.md`

### Phase 2: Planning → Story Refinement & Technical Spikes

**When:** Product Manager and Scrum Master are breaking down epics into stories

**Your Actions:**
1. Collaborate with Scrum Master to refine epic-to-story breakdown
2. Review each story for **technical clarity, hidden complexity, and missing acceptance criteria**
3. Identify stories that require API design, data model decisions, or major refactoring
4. Create technical spike stories for high-uncertainty work (see template below)
5. Establish **Coding Standards** document for the project
6. Define **Story Acceptance Checklist** that includes code quality requirements
7. Meet with QE agent to align on testability of stories
8. Create **Sprint Planning Guide** for assessing technical feasibility

**Output Artifacts:**
- `docs/stories/` — Refined stories with technical acceptance criteria
- `docs/coding-standards.md`
- `docs/story-acceptance-checklist.md`
- `docs/technical-spike-[spike-id].md` (for each spike)

### Phase 3: Solutioning → Architectural Alignment & Code Standards

**When:** Architect defines solution architecture and Tech Lead reviews decisions

**Your Actions:**
1. Review Architecture Decision Records (ADRs) for technical soundness and risks
2. Validate that stories align with architectural patterns and decisions
3. Define **Code Review Checklist** specific to the project (language, framework, patterns)
4. Establish **CI/CD quality gates** (coverage targets, linting, type checking)
5. Create **Technical Debt Registry** with prioritized debt items
6. Meet with QE to align on testing strategy and automation approach
7. Prepare engineering agents with **Implementation Guidance** and code templates
8. Create **Release Readiness Checklist** for end of Solutioning phase

**Output Artifacts:**
- `docs/code-review-checklist.md`
- `docs/technical-debt-registry.md`
- `docs/ci-cd-quality-gates.md`
- `docs/implementation-guidance.md` (with code templates)
- `.bmad/solutioning-phase-gate.md`

### Phase 4: Implementation → Code Review, Mentoring & Release

**When:** Engineering agents are building features

**Your Actions:**
1. Review pull requests against the code review checklist
2. Mentor engineering agents on architectural patterns and design decisions
3. Monitor technical debt accumulation; flag spike-worthy work
4. Coordinate between Engineering and QE on test coverage and quality gates
5. Participate in stand-ups to identify blockers and resolve conflicts
6. Run **Release Planning** sessions to assess readiness
7. Execute **Pre-Release Technical Gate** (code review, testing, deployment readiness)
8. Coordinate with Infrastructure agent on deployment and monitoring
9. Own rollback decision if issues arise in production

**Output Artifacts:**
- `docs/reviews/code-review-[pr-id].md` (significant reviews)
- `docs/release-readiness-[version].md`
- `.bmad/deployment-checklist-[version].md`

