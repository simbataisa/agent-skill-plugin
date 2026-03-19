# BMAD SDLC Agents: Two-Layer Agent Architecture

**BMAD** (Breakthrough Method of Agile AI-Driven Development) is an enterprise methodology for delivering software through a cross-functional squad of 10 specialized AI agents. This repository implements the **two-layer architecture**: a global layer with reusable agent skills and shared resources, plus a project layer with context files checked into each project repo.

Install the global layer once across all tools, then scaffold `.bmad/` context files into each project. Agents dynamically load project-specific knowledge from `.bmad/` combined with shared resources, creating a cohesive, context-aware squad.

---

## Agent Team

| Agent | Skill File | BMAD Phase | Role |
|-------|-----------|-----------|------|
| **Business Analyst** | `agents/business-analyst/SKILL.md` | Analysis | Problem exploration, stakeholder analysis, project brief |
| **Product Owner** | `agents/product-owner/SKILL.md` | Planning | PRD, backlog prioritization, artifact alignment |
| **Solution Architect** | `agents/solution-architect/SKILL.md` | Solutioning | Service decomposition, API contracts, data models, ADRs |
| **Enterprise Architect** | `agents/enterprise-architect/SKILL.md` | Solutioning | Cloud infra, compliance, observability, CI/CD, FinOps |
| **UX/UI Designer** | `agents/ux-designer/SKILL.md` | Solutioning | Personas, journeys, wireframes, design system, a11y |
| **Tech Lead** | `agents/tech-lead/SKILL.md` | All Phases | Orchestration, code review, risk, release readiness |
| **Tester & QE** | `agents/tester-qe/SKILL.md` | All Phases | Test strategy, quality gates, security testing |
| **Backend Engineer** | `agents/backend-engineer/SKILL.md` | Implementation | APIs, data layers, event-driven services |
| **Frontend Engineer** | `agents/frontend-engineer/SKILL.md` | Implementation | React/TypeScript, state management, a11y |
| **Mobile Engineer** | `agents/mobile-engineer/SKILL.md` | Implementation | iOS/Android, native APIs, mobile architecture |

---

## Two-Layer Architecture

### Global Layer
**Install once.** Available in all projects.

- **`agents/`** – 10 specialized agent skills (as markdown files)
- **`shared/`** – Company-wide context, references, and templates
  - `BMAD-SHARED-CONTEXT.md` – Organization context, principles, standards
  - `references/technology-radar.md` – Technology choices, maturity tiers
  - `templates/` – PRD, ADR, story, test strategy, project brief, handoff log templates

### Project Layer
**Copy per project.** Checked into each project's git repo.

- **`.bmad/`** – Project-specific context files
  - `PROJECT-CONTEXT.md` – Project vision, goals, stakeholders, timeline
  - `tech-stack.md` – Technologies, versions, dependencies, build setup
  - `team-conventions.md` – Code style, naming, patterns, architecture rules
  - `domain-glossary.md` – Business domain terms, concepts, entities
  - `handoff-log.md` – Record of handoffs between agents/humans

- **`docs/`** – Project documentation
  - `architecture/` – System design, decision records, diagrams
  - `stories/` – User stories, epics, acceptance criteria
  - `testing/` – Test plans, test cases, coverage goals
  - `ux/` – Personas, journeys, wireframes, design specs

### Agent Context Loading Order
When an agent runs, it loads context in this order (later overrides earlier):

1. `shared/BMAD-SHARED-CONTEXT.md` (baseline)
2. `.bmad/PROJECT-CONTEXT.md` (project goals, stakeholders)
3. `.bmad/tech-stack.md` (technology choices)
4. `.bmad/team-conventions.md` (project rules and standards)
5. User prompt (immediate task)

This creates project-aware agents that respect global conventions while adapting to project specifics.

---

## Quick Start (3 Steps)

### Step 1: Install Global Layer
```bash
bash scripts/install-global.sh
```
Copies all agent skills, commands, hooks, and shared resources to tool-specific global directories. Runs once per machine.

### Step 2: Scaffold New Project
```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project Name"
```
Creates `.bmad/` context files, installs project-level agents, and generates a tool-specific instruction file (e.g. `CLAUDE.md`) that tells your AI tool to auto-load `.bmad/` at the start of every session.

### Step 3: Fill Project Context
Edit `.bmad/PROJECT-CONTEXT.md` and `.bmad/tech-stack.md` with your project details. The instruction file and all agents will pick these up automatically on the next session.

---

## Wiring Up Auto-Loading (.bmad/ → Your AI Tool)

Every AI coding tool reads a special instruction file at session start. Add the BMAD context block below to whichever file your tool uses. **`scaffold-project.sh` generates this automatically** — these snippets are here if you need to add it manually or update an existing file.

### Claude Code — `CLAUDE.md`

```markdown
## BMAD Project Context

At the start of every conversation, read these files to understand this project:

- `.bmad/PROJECT-CONTEXT.md` — vision, goals, stakeholders, constraints
- `.bmad/tech-stack.md` — technology stack, versions, dependencies
- `.bmad/team-conventions.md` — code style, naming conventions, patterns
- `.bmad/domain-glossary.md` — business domain terminology
- `.bmad/handoff-log.md` — recent agent decisions and handoffs

## Available BMAD Agents (slash commands)

| Command | Role |
|---------|------|
| `/business-analyst` | Discovery, stakeholder analysis, project brief |
| `/product-owner` | PRD, backlog, user stories |
| `/solution-architect` | System design, APIs, ADRs |
| `/enterprise-architect` | Cloud infra, compliance, CI/CD |
| `/ux-designer` | Wireframes, design system, accessibility |
| `/tech-lead` | Orchestration, code review, risk |
| `/tester-qe` | Test strategy, quality gates |
| `/backend-engineer` | APIs, services, data layers |
| `/frontend-engineer` | React/TypeScript, components, a11y |
| `/mobile-engineer` | iOS/Android, native architecture |
```

### Cursor — `.cursor/rules/001-project-context.mdc`

```markdown
---
description: BMAD project context — load at the start of every conversation
alwaysApply: true
---

## BMAD Project Context

Read these files before responding to any request in this project:

- `.bmad/PROJECT-CONTEXT.md` — vision, goals, stakeholders, constraints
- `.bmad/tech-stack.md` — technology stack, versions, dependencies
- `.bmad/team-conventions.md` — code style, naming conventions, patterns
- `.bmad/domain-glossary.md` — business domain terminology
- `.bmad/handoff-log.md` — recent agent decisions and handoffs

Apply all conventions from `team-conventions.md` when writing or reviewing code.
```

### Windsurf — `.windsurfrules`

```markdown
## BMAD Project Context

At the start of every conversation, read these files:

- `.bmad/PROJECT-CONTEXT.md` — vision, goals, stakeholders, constraints
- `.bmad/tech-stack.md` — technology stack, versions, dependencies
- `.bmad/team-conventions.md` — code style, naming conventions, patterns
- `.bmad/domain-glossary.md` — business domain terminology
- `.bmad/handoff-log.md` — recent agent decisions and handoffs

Apply all conventions from `team-conventions.md` when writing or reviewing code.
```

### GitHub Copilot — `.github/copilot-instructions.md`

```markdown
## BMAD Project Context

This project uses the BMAD SDLC framework. At the start of each session, read:

- `.bmad/PROJECT-CONTEXT.md` — vision, goals, stakeholders, constraints
- `.bmad/tech-stack.md` — technology stack, versions, dependencies
- `.bmad/team-conventions.md` — code style, naming conventions, patterns
- `.bmad/domain-glossary.md` — business domain terminology
- `.bmad/handoff-log.md` — recent agent decisions and handoffs

Always apply the conventions in `team-conventions.md` when generating code.
```

### Gemini CLI — `GEMINI.md`

```markdown
## BMAD Project Context

At the start of every conversation, read these files:

- `.bmad/PROJECT-CONTEXT.md` — vision, goals, stakeholders, constraints
- `.bmad/tech-stack.md` — technology stack, versions, dependencies
- `.bmad/team-conventions.md` — code style, naming conventions, patterns
- `.bmad/domain-glossary.md` — business domain terminology
- `.bmad/handoff-log.md` — recent agent decisions and handoffs

Apply all conventions from `team-conventions.md` when writing or reviewing code.
```

### OpenCode — `AGENTS.md`

```markdown
## BMAD Project Context

At the start of every conversation, read these files:

- `.bmad/PROJECT-CONTEXT.md` — vision, goals, stakeholders, constraints
- `.bmad/tech-stack.md` — technology stack, versions, dependencies
- `.bmad/team-conventions.md` — code style, naming conventions, patterns
- `.bmad/domain-glossary.md` — business domain terminology
- `.bmad/handoff-log.md` — recent agent decisions and handoffs

Apply all conventions from `team-conventions.md` when writing or reviewing code.
```

### Aider — `.aider.conventions.md`

```markdown
## BMAD Project Context

At the start of every conversation, read these files:

- `.bmad/PROJECT-CONTEXT.md` — vision, goals, stakeholders, constraints
- `.bmad/tech-stack.md` — technology stack, versions, dependencies
- `.bmad/team-conventions.md` — code style, naming conventions, patterns
- `.bmad/domain-glossary.md` — business domain terminology
- `.bmad/handoff-log.md` — recent agent decisions and handoffs

Apply all conventions from `team-conventions.md` when writing or reviewing code.
```

Then reference it in `.aider.conf.yml`:
```yaml
conventions-file: .aider.conventions.md
```

---

## Setup Guide by Tool

### Claude Code (Local CLI)

**Global Install (once)**
```bash
bash scripts/install-global.sh
# → Agents → ~/.claude/skills/          (slash commands: /business-analyst, etc.)
# → Commands → ~/.claude/commands/       (slash commands: /bmad-status, /new-story, etc.)
# → Hooks → ~/.claude/hooks/             (PreToolUse / PostToolUse / Stop guards)
```

**Project Install (per project, run from project root)**
```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project"
# → .bmad/                 project context files (commit to git)
# → CLAUDE.md              auto-loads .bmad/ at session start
# → .claude/skills/        project-local copies of all agents
# → .claude/commands/      project-local slash commands
# → .claude/hooks/         project-level hook scripts
```

After scaffolding, open your project in Claude Code and use slash commands directly — all context is pre-loaded:
```
/business-analyst   /product-owner      /solution-architect
/enterprise-architect  /ux-designer     /tech-lead
/tester-qe          /backend-engineer   /frontend-engineer   /mobile-engineer
/bmad-status        /new-story          /new-adr
/handoff            /new-epic           /sprint-plan
```

---

### Cowork (Claude Desktop)

**Global Install (once)**
```bash
bash scripts/install-global.sh
# → Agents → ~/.skills/skills/  (auto-discoverable by description)
```

**Project Install (per project, run from project root)**
```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project"
# → .bmad/      project context files (commit to git)
# → CLAUDE.md   auto-loads .bmad/ at session start
```

Agents detect `.bmad/` automatically. No additional config needed.

---

### Cursor

**Global Install (once)**
```bash
bash scripts/install-global.sh
# → Agents + global rules → ~/.cursor/rules/
```

**Project Install (per project, run from project root)**
```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project"
# → .bmad/                                    project context files (commit to git)
# → .cursor/rules/001-project-context.mdc     auto-loads .bmad/ (alwaysApply: true)
# → .cursor/rules/002-tech-stack.mdc          code generation rules
```

Address agents by role in your prompt: "Acting as the Solution Architect, …"

---

### Windsurf

**Global Install (once)**
```bash
bash scripts/install-global.sh
# → Agents + global rules → ~/.windsurf/rules/
```

**Project Install (per project, run from project root)**
```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project"
# → .bmad/           project context files (commit to git)
# → .windsurfrules   auto-loads .bmad/ at session start
```

Address agents by role in your prompt: "Acting as the Backend Engineer, …"

---

### GitHub Copilot

**Global Install (once)**
```bash
bash scripts/install-global.sh
# → Agents → ~/.github/copilot-instructions.md
```

**Project Install (per project, run from project root)**
```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project"
# → .bmad/                               project context files (commit to git)
# → .github/copilot-instructions.md      auto-loads .bmad/ at session start
```

Address agents by role: "Acting as the Product Owner, …"

---

### Gemini CLI

**Global Install (once)**
```bash
bash scripts/install-global.sh
# → Agents + global rules → ~/.gemini/GEMINI.md
```

**Project Install (per project, run from project root)**
```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project"
# → .bmad/       project context files (commit to git)
# → GEMINI.md    auto-loads .bmad/ at session start
```

Address agents by role: "Acting as the Enterprise Architect, …"

---

### OpenCode

**Global Install (once)**
```bash
bash scripts/install-global.sh
# → Agents + global rules → ~/.opencode/instructions.md
```

**Project Install (per project, run from project root)**
```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project"
# → .bmad/      project context files (commit to git)
# → AGENTS.md   auto-loads .bmad/ at session start
```

Address agents by role: "Acting as the Tech Lead, …"

---

### Aider

**Global Install (once)**
```bash
bash scripts/install-global.sh
# → Agents + global conventions → ~/.aider.conventions.md
```

**Project Install (per project, run from project root)**
```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project"
# → .bmad/                    project context files (commit to git)
# → .aider.conventions.md     auto-loads .bmad/ at session start
```

Reference in `.aider.conf.yml`:
```yaml
conventions-file: .aider.conventions.md
```

---

## Tool Install Paths Reference

| Tool | Global Path | Project Path |
|------|-------------|--------------|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| Cowork | `~/.skills/skills/` | `.bmad/` (auto-detected) |
| Cursor | `~/.cursor/rules/` | `.cursor/rules/` |
| Windsurf | `~/.windsurf/rules/` | `.windsurfrules` |
| GitHub Copilot | `~/.github/copilot-instructions.md` | `.github/copilot-instructions.md` |
| Gemini CLI | `~/.gemini/GEMINI.md` | `GEMINI.md` |
| OpenCode | `~/.opencode/instructions.md` | `AGENTS.md` |
| Aider | `~/.aider.conventions.md` | `.aider.conf.yml` |

---

## Project Scaffold Files

After running `scaffold-project.sh`, the `.bmad/` directory contains:

| File | When to Fill In | Purpose |
|------|-----------------|---------|
| `PROJECT-CONTEXT.md` | Before first sprint | Project vision, goals, stakeholders, constraints, timeline |
| `tech-stack.md` | Before architecture decisions | Languages, frameworks, databases, cloud platform, CI/CD |
| `team-conventions.md` | Before first code review | Code style, naming conventions, architecture patterns, PR process |
| `domain-glossary.md` | During analysis phase | Business domain terminology, entities, relationships |
| `handoff-log.md` | Ongoing | Record of work handed off between agents or to humans |

**Tip:** Fill `PROJECT-CONTEXT.md` and `tech-stack.md` first. Other files populate based on these.

---

## Sample Prompts

> **After running `install-global.sh` and `scaffold-project.sh`**, agents are already installed in your tool and `.bmad/` is already in your project. Just use the slash command — no need to reference any file paths.

> **⚠ Avoiding Skill Conflicts (Claude Code):** If you have other plugins installed (e.g. superpowers, general planners), always invoke BMAD agents via their **explicit slash command** (`/business-analyst`, `/solution-architect`, etc.). Never use prose-only prompts like "Acting as the Business Analyst…" in Claude Code — without the slash command, another installed skill may intercept the request. The `CLAUDE.md` generated by `scaffold-project.sh` also instructs Claude to prefer BMAD over other skills for this project.

### Using a Single Agent (Claude Code)

**Get a project brief from Business Analyst:**
```
/business-analyst Generate a concise project brief including stakeholders, success
criteria, and constraints, based on the project context.
```

**Ask Solution Architect for system design:**
```
/solution-architect Propose a system architecture with service boundaries, API contracts,
and data models. Reference the PRD in docs/stories/ and tech-stack.md.
```

**Request UX/UI wireframes:**
```
/ux-designer Create wireframes and a design spec for the checkout flow, based on user
personas in docs/ux/ and the PRD in docs/stories/.
```

**Backend Engineer implementation plan:**
```
/backend-engineer Create a sprint-level implementation plan for the payment service,
referencing the architecture decisions in docs/architecture/ and tech-stack.md.
```

**QE test strategy:**
```
/tester-qe Propose a comprehensive test strategy with test types, coverage goals, and
security testing approach, based on docs/stories/ and tech-stack.md.
```

### Using a Single Agent (Cursor / Windsurf / Copilot / Gemini / OpenCode / Aider)

Agents are already loaded via your global rules file. Just address the agent by role in your prompt — the tool has all agent definitions in context:

```
Acting as the Business Analyst, generate a concise project brief including stakeholders,
success criteria, and constraints based on .bmad/PROJECT-CONTEXT.md.
```

```
Acting as the Solution Architect, propose a system architecture with service boundaries,
API contracts, and data models. Use .bmad/tech-stack.md and docs/stories/.
```

### Squad Mode: All Agents Together

See the **Squad Prompt** section below to run all 10 agents in a single session.

---

## Squad Prompt

Use this mega-prompt to coordinate all agents. **Agents and project context are pre-loaded** — no file paths needed.

> **Claude Code users:** The squad prompt below names each agent with their slash command in parentheses, e.g. `(/business-analyst)`. Work through agents one at a time — start a turn with the slash command to explicitly select the skill, then paste your instruction. This prevents other installed skills from intercepting.

### Claude Code

Paste into a new Claude Code session in your project root, then invoke each agent with its slash command as you work through the phases:

```
# BMAD Squad: Full Project Analysis & Design

The BMAD agent squad is already installed. The project context is in .bmad/.
Coordinate all 10 agents across the following phases:

## Project Context (already loaded via CLAUDE.md)
- .bmad/PROJECT-CONTEXT.md — project vision and goals
- .bmad/tech-stack.md — technology choices
- .bmad/team-conventions.md — project rules and standards

## Analysis Phase (Business Analyst → Product Owner)
**Business Analyst** (`/business-analyst`):
- Review .bmad/PROJECT-CONTEXT.md
- Identify stakeholders, constraints, risks
- Generate project brief — output to docs/project-brief.md

**Product Owner** (`/product-owner`):
- Take Business Analyst brief
- Create PRD with prioritized user stories
- Output to docs/stories/ and docs/prd.md

## Solutioning Phase (Solution Architect → UX Designer → Enterprise Architect)
**Solution Architect** (`/solution-architect`):
- Take PRD and tech-stack.md
- Propose system architecture, service boundaries
- Define API contracts, data models
- Create ADRs — output to docs/architecture/

**UX Designer** (`/ux-designer`):
- Work from PRD and user personas
- Create wireframes, user journeys, design system
- Output to docs/ux/

**Enterprise Architect** (`/enterprise-architect`):
- Review Solution Architect proposal
- Propose cloud infrastructure, CI/CD, monitoring
- Address compliance, cost optimization
- Output to docs/architecture/

## Implementation Phase (Tech Lead → Backend → Frontend → Mobile)
**Tech Lead** (`/tech-lead`):
- Coordinate backend, frontend, mobile teams
- Identify integration points, flag risks and dependencies
- Review for architectural consistency

**Backend Engineer** (`/backend-engineer`):
- Take architecture ADRs and tech-stack.md
- Design API endpoints, data access layer, event-driven services
- Output to docs/architecture/

**Frontend Engineer** (`/frontend-engineer`):
- Take UX wireframes and tech-stack.md
- Design component architecture, state management, accessibility strategy
- Output to docs/ux/

**Mobile Engineer** (`/mobile-engineer`):
- Take UX wireframes and tech-stack.md
- Decide native vs. cross-platform, mobile architecture, device/network constraints
- Output to docs/ux/

## Quality & Testing
**Tester & QE** (`/tester-qe`):
- Take all artifacts (stories, architecture, designs, code plans)
- Propose test strategy (unit, integration, e2e, security, performance)
- Define quality gates — output to docs/testing/

## Handoff & Documentation
All agents:
- Use `/handoff` to log each agent transition — it creates a numbered file in `.bmad/handoffs/` and updates the master index
- Update `.bmad/domain-glossary.md` with new business terms
- Never write directly to `.bmad/handoff-log.md` — use `/handoff` instead

## Output Format
- **Analysis Artifacts:** project-brief, backlog, user stories (docs/stories/)
- **Architecture Artifacts:** ADRs, API specs, data models (docs/architecture/)
- **Design Artifacts:** Wireframes, personas, journeys (docs/ux/)
- **Implementation Plans:** Service breakdown, sprint-level tasks, integration checklist
- **Testing Artifacts:** Test strategy, test plan, automation roadmap (docs/testing/)

---

## Your Task

[Insert your project task here. Examples:]
- Analyze this new market opportunity and produce PRD + architecture design
- Design a microservices migration strategy for our monolith
- Build a complete design-to-code workflow for a new feature
- Plan Q2 development with risk assessment and sprint breakdown
```

### Cursor / Windsurf / Copilot / Gemini / OpenCode / Aider

All agent definitions are already loaded in your global rules file. Address each agent by role directly:

```
# BMAD Squad: Full Project Analysis & Design

You are a squad of 10 specialized AI agents. All agent skills are already loaded.
The project context is in .bmad/ — read it before starting.

## Analysis Phase
Acting as the Business Analyst: review .bmad/PROJECT-CONTEXT.md, identify stakeholders,
constraints, and risks, then generate a project brief.

Acting as the Product Owner: take the project brief and create a PRD with prioritized
user stories. Save to docs/stories/.

## Solutioning Phase
Acting as the Solution Architect: propose system architecture, service boundaries, API
contracts, and data models using .bmad/tech-stack.md. Record decisions as ADRs in
docs/architecture/adr/.

Acting as the UX Designer: create wireframes and user journeys based on the PRD and
personas. Save to docs/ux/.

Acting as the Enterprise Architect: propose cloud infrastructure, CI/CD pipeline,
monitoring, and compliance controls. Save to docs/architecture/.

## Implementation Phase
Acting as the Tech Lead: coordinate backend, frontend, and mobile plans. Flag risks and
integration dependencies.

Acting as the Backend Engineer: design API endpoints, data layers, and event-driven
services from the ADRs and tech-stack.md.

Acting as the Frontend Engineer: design component architecture and state management from
the UX wireframes and tech-stack.md.

Acting as the Mobile Engineer: design mobile architecture and decide native vs.
cross-platform from the UX wireframes and tech-stack.md.

## Quality & Testing
Acting as the Tester & QE: produce a test strategy covering unit, integration, e2e,
security, and performance. Save to docs/testing/.

## Handoff
All agents: use the `/handoff` command (Claude Code) or `Acting as Team: log handoff from [from-agent] to [to-agent]` (other tools) to record agent transitions in `.bmad/handoffs/`. Update `.bmad/domain-glossary.md` with new business terms.

---

## Your Task

[Insert your project task here]
```

---

## File Organization

```
bmad-sdlc-agents/
├── agents/                                 # Global: 10 agent skills
│   ├── business-analyst/SKILL.md
│   ├── product-owner/SKILL.md
│   ├── solution-architect/SKILL.md
│   ├── enterprise-architect/SKILL.md
│   ├── ux-designer/SKILL.md
│   ├── tech-lead/SKILL.md
│   ├── tester-qe/SKILL.md
│   ├── backend-engineer/SKILL.md
│   ├── frontend-engineer/SKILL.md
│   └── mobile-engineer/SKILL.md
│
├── shared/                                 # Global: resources for all projects
│   ├── BMAD-SHARED-CONTEXT.md
│   ├── references/
│   │   └── technology-radar.md
│   └── templates/
│       ├── prd-template.md
│       ├── adr-template.md
│       ├── story-template.md
│       ├── test-strategy-template.md
│       ├── project-brief-template.md
│       └── handoff-log-template.md
│
├── project-scaffold/                       # Template for new projects
│   ├── .bmad/
│   │   ├── PROJECT-CONTEXT.md
│   │   ├── tech-stack.md
│   │   ├── team-conventions.md
│   │   ├── domain-glossary.md
│   │   └── handoff-log.md
│   └── docs/
│       ├── architecture/
│       ├── stories/
│       ├── testing/
│       └── ux/
│
└── scripts/
    ├── install-global.sh                   # Copy agents/ + shared/ to tool directories
    ├── scaffold-project.sh                 # Create .bmad/ + project symlinks
    └── update.sh                           # Update global + all projects
```

---

## Integration Guide

### How Agents Use Context
When you invoke an agent in any tool, it automatically:

1. **Detects** `.bmad/PROJECT-CONTEXT.md` in the current project
2. **Loads** its skill from `agents/<agent-name>/SKILL.md`
3. **Reads** `.bmad/tech-stack.md` and `.bmad/team-conventions.md` for project specifics
4. **Falls back** to `shared/BMAD-SHARED-CONTEXT.md` for company standards
5. **Applies** context to your prompt and generates project-aware responses

### Continuous Integration
The `scripts/update.sh` pulls the latest agent skills and shared resources, then:
- Rebuilds global tool directories
- Refreshes all project `.bmad/` symlinks
- Preserves project-specific overrides

### Version Control
- **Commit to git:** `.bmad/` directory (context files are project-specific)
- **Commit to git:** `docs/` directory (all artifacts)
- **Do not commit:** Global `~/.claude/`, `~/.skills/`, `~/.cursor/`, etc. (manage with `install-global.sh`)
- **Do not commit:** Tool-specific config files unless project-managed

---

## Common Workflows

### Onboarding a New Team Member
```bash
# Clone project repo (includes .bmad/)
git clone <project-repo>

# Install global agents (once per machine)
bash /path/to/bmad-sdlc-agents/scripts/install-global.sh

# New team member can now:
# - Load agents in their favorite tool
# - Access project context from .bmad/
# - Collaborate with squad prompts
```

### Starting a New Project
```bash
# Scaffold the project
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "New Platform"

# Add to your project repo
git add .bmad/ docs/ .claude/ .cursor/ # (as needed per tool)
git commit -m "Add BMAD project scaffold"

# Fill in context files
# Edit: .bmad/PROJECT-CONTEXT.md, .bmad/tech-stack.md
```

### Running Full Squad Analysis
Copy the **Squad Prompt** above into your tool, update the task section, and run. All 10 agents coordinate on analysis, design, and planning.

### Updating Agents Across All Projects
```bash
# Pull latest agents and shared resources
bash /path/to/bmad-sdlc-agents/scripts/update.sh

# All projects instantly have access to updated agents
# Project context files are preserved
```

---

## FAQ

**Q: Where do agents live?**
A: Source files live in `agents/` in this repo. After running `install-global.sh` they are deployed to your tool (e.g. `~/.claude/skills/` for Claude Code). You invoke them with a slash command (`/solution-architect`) or by addressing the agent by role — no file paths needed.

**Q: Where does project context live?**
A: In `.bmad/` (per project, checked into git). Each project has its own `.bmad/PROJECT-CONTEXT.md`, `tech-stack.md`, etc.

**Q: Do I need to install globally?**
A: Yes, once per machine. Then scaffold each project. Agents find `.bmad/` files automatically.

**Q: Can I customize agents per project?**
A: Yes. Copy an agent skill to `.claude/skills/` or `.cursor/rules/` and edit it for project-specific tweaks.

**Q: How do I version agents?**
A: Keep `agents/` in the BMAD repository. Use `scripts/update.sh` to refresh. Project context (`.bmad/`) versions with your project.

**Q: Can multiple teams use different tech stacks?**
A: Absolutely. Each project has its own `tech-stack.md`, so agents adapt to TypeScript, Python, Kotlin, etc.

---

## Support & Contributing

For issues, enhancements, or new agents, open an issue in the BMAD repository.

To contribute an agent or template, see the contribution guidelines in `CONTRIBUTING.md`.

---

**Last updated:** 2026-03-18
**BMAD Version:** 2.0 (Two-Layer Architecture)
