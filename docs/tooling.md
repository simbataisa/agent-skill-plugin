# Tool Setup & Sample Prompts

Per-tool installation paths, auto-loading wiring snippets, single-agent invocation samples, and the full multi-turn squad prompt for coordinating all 13 agents end-to-end.

## Table of Contents

- [Wiring Up Auto-Loading (.bmad/ → Your AI Tool)](#wiring-up-auto-loading-bmad--your-ai-tool)
- [Setup Guide by Tool](#setup-guide-by-tool)
- [Tool Install Paths Reference](#tool-install-paths-reference)
- [Sample Prompts](#sample-prompts)
- [Squad Prompt](#squad-prompt)

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

| Command                 | Role                                                   |
| ----------------------- | ------------------------------------------------------ |
| `/product-owner`        | BRD, high-level PRD, MVP scope (first agent)           |
| `/business-analyst`     | Requirements analysis from BRD/PRD (second agent)      |
| `/enterprise-architect` | Enterprise arch — cloud infra, compliance, CI/CD       |
| `/ux-designer`          | Wireframes, design system, accessibility (parallel EA) |
| `/solution-architect`   | Detailed solution design — APIs, data models, ADRs     |
| `/tech-lead`            | Orchestration, sprint planning, code review, risk      |
| `/tester-qe`            | Test strategy, quality gates, UI automation            |
| `/backend-engineer`     | APIs, services, data layers                            |
| `/frontend-engineer`    | React/TypeScript, components, a11y                     |
| `/mobile-engineer`      | iOS/Android, native architecture                       |
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

### Gemini CLI — `~/.gemini/skills/` + `~/.gemini/agents/` + project `GEMINI.md`

Global skills install to `~/.gemini/skills/<agent-name>/SKILL.md` (same folder-per-skill convention as Claude Code), and 13 native subagents install to `~/.gemini/agents/<agent-name>.md` (invocable with `@<name>` and manageable via `/agents`). Project-level wiring uses a `GEMINI.md` at the project root:

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

### Kiro (AWS) — `AGENTS.md` + `.kiro/steering/`

Kiro reads `AGENTS.md` at the project root automatically. It also reads `.kiro/steering/*.md` files. BMAD commands are installed as steering files with `inclusion: manual`, making them available as `/bmad-status`, `/handoff`, etc. in Kiro chat.

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

### Codex CLI (OpenAI) — `AGENTS.md`

```markdown
## BMAD Project Context

At the start of every conversation, read these files:

- `.bmad/PROJECT-CONTEXT.md` — vision, goals, stakeholders, constraints
- `.bmad/tech-stack.md` — technology stack, versions, dependencies
- `.bmad/team-conventions.md` — code style, naming conventions, patterns
- `.bmad/domain-glossary.md` — business domain terminology
- `.bmad/handoff-log.md` — recent agent decisions and handoffs

## Available BMAD Agents (skills)

| Skill ($ invoke)        | Role                                                    |
| ----------------------- | ------------------------------------------------------- |
| `$product-owner`        | BRD, PRD, MVP scope (first agent)                       |
| `$business-analyst`     | Requirements analysis from BRD/PRD (second agent)       |
| `$enterprise-architect` | Enterprise arch — cloud infra, compliance, CI/CD (W3 ∥) |
| `$ux-designer`          | Wireframes, design system, accessibility (W3 ∥ EA)      |
| `$solution-architect`   | Detailed solution design — APIs, data models, ADRs      |
| `$tech-lead`            | Orchestration, code review, risk                        |
| `$tester-qe`            | Test strategy, quality gates                            |
| `$backend-engineer`     | APIs, services, data layers                             |
| `$frontend-engineer`    | React/TypeScript, components, a11y                      |
| `$mobile-engineer`      | iOS/Android, native architecture                        |

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
# → Skills    → ~/.claude/skills/    (role knowledge bodies — progressive disclosure in main session)
# → Subagents → ~/.claude/agents/    (13 BMAD roles registered for the Task/Agent tool, isolated context)
# → Commands  → ~/.claude/commands/  (slash commands: /bmad-status, /new-story, etc.)
# → Hooks     → ~/.claude/hooks/     (PreToolUse / PostToolUse / Stop guards)
```

> **Skills vs. Subagents (Claude Code).** Claude Code treats these as two distinct primitives and BMAD deploys both:
>
> - **`~/.claude/skills/<role>/SKILL.md`** — the full, authoritative role body. Loaded inline in the main session via progressive disclosure when a slash command runs or the model decides the skill is relevant.
> - **`~/.claude/agents/<role>.md`** — a thin YAML-frontmatter pointer (`name`, `description`, `tools`, `model`) that registers the role as a callable subagent. This is what the `Task`/`Agent` tool looks up when Tech Lead spawns Backend Engineer, etc. The subagent runs in an **isolated context window** and, on completion, returns a summary to the main agent. Without these files you will see `Error: Agent type 'backend-engineer' not found`.
>
> The subagent `.md` points at the skill body (`~/.claude/skills/<role>/SKILL.md`) for its full workflow, so the two layers stay in sync.

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
/bmad:status        /new-story          /new-adr
/handoff            /new-epic           /sprint-plan
/bmad:eval          /bmad:eval --auto   (--auto skips the interview; hook-driven)
```

**Optional — auto-eval on workflow completion.** Install the per-repo hook bundle once
to record `/bmad:eval --auto` automatically on `git pull`/`git merge`, on sprint-results
writes, and on Yolo worktree cleanup. See *Productivity Evaluation* in [adoption.md](adoption.md#productivity-evaluation):

```bash
bash /path/to/bmad-sdlc-agents/hooks/install-project-hooks.sh
```

---

### Codex CLI (OpenAI)

**Global Install (once)**

```bash
bash scripts/install-global.sh
# → Skills → ~/.codex/skills/<agent>/SKILL.md  (invoke: $business-analyst, etc.)
# → Prompts → ~/.codex/prompts/                (slash commands: /bmad-status, /handoff, etc.)
```

**Project Install (per project, run from project root)**

```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project"
# → .bmad/                 project context files (commit to git)
# → AGENTS.md              auto-loads .bmad/ at session start
# → .codex/skills/         project-local copies of all agent skills
# → .codex/prompts/        project-local slash commands
```

After scaffolding, open your project in Codex CLI and invoke agents with `$` prefix, commands with `/`:

```
$business-analyst   $product-owner      $solution-architect
$enterprise-architect  $ux-designer     $tech-lead
$tester-qe          $backend-engineer   $frontend-engineer   $mobile-engineer
/bmad-status        /new-story          /new-adr
/handoff            /new-epic           /sprint-plan
/bmad-eval
```

---

### Kiro (AWS)

**Global Install (once)**

```bash
bash scripts/install-global.sh
# → Skills → ~/.kiro/skills/<agent>/SKILL.md    (activate by description match)
# → Steering → ~/.kiro/steering/                (auto/manual inclusion files)
# → Commands → ~/.kiro/steering/ (inclusion: manual → /bmad-status, /handoff, etc.)
```

**Project Install (per project, run from project root)**

```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project"
# → .bmad/                  project context files (commit to git)
# → AGENTS.md               auto-loaded by Kiro at session start
# → .kiro/skills/           project-local agent skills
# → .kiro/steering/         project-local steering + slash commands
```

After scaffolding, open your project in Kiro. Skills activate by description match. Commands are available as slash commands:

```
/bmad-status        /new-story          /new-adr
/handoff            /new-epic           /sprint-plan
/bmad-eval
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

### Trae IDE (ByteDance)

Trae's rules system is the closest analogue to Cursor/Windsurf: markdown files in `~/.trae/rules/` (user scope) and `.trae/rules/` (project scope) are auto-loaded by the AI as always-on guidelines. BMAD installs every role body as its own rule file so you can address any agent by role.

**Global Install (once)**

```bash
bash scripts/install-global.sh
# → ~/.trae/rules/<role>.md                       13 agent bodies + shared context (one per role)
# → ~/.trae/rules/000-bmad-framework.md           Framework overview (roster + phases + artifacts)
# → ~/.trae/rules/user_rules.md                   Mirror of the framework (for Trae versions
#                                                  that only auto-load user_rules.md)
# → ~/.trae/rules/001-karpathy-principles.md      Engineering-discipline rulebook
# → ~/.trae/rules/002-a2ui-reference.md           Agent-driven UI reference (PO/EA/SA/UX/InfoSec)
# → ~/.trae/rules/bmad-commands/<agent>/<cmd>.md  Per-agent commands as rules
# → ~/.trae/skills/<role>/                        references/ + templates/ copied alongside
# → ~/.trae/BMAD-SHARED-CONTEXT.md                Fallback shared context
```

**Project Install (per project, run from project root)**

```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project"
# → .bmad/                project context files (commit to git)
# → .trae/rules/          project-scope rules (generated if your scaffold targets Trae)
```

**Invoking agents:**

- Address agents by role in your prompt: _"Acting as the Backend Engineer, implement BE-001…"_
- Or reference a command file directly: _"Run the `backend-engineer:implement-story` rule on story BE-001."_
- The 13 role rule files stay resident across every Trae session, so the agent always knows which role it's playing.

**MCP servers:** edit `~/.trae/mcp.json` (or use Settings → MCP & Agents) to connect MCP servers such as Playwright, GitHub, Linear, etc. Trae supports both stdio and SSE transports.

> **Single-session caveat.** Trae is single-session like Windsurf — there is no native subagent spawning. For Wave E2 (BE ∥ FE ∥ ME parallelism) open multiple Trae windows and let Tech Lead coordinate via `.bmad/signals/` sentinel files.

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

Gemini CLI now has **native subagent support** (markdown-defined agents under `.gemini/agents/*.md` with isolated context windows and `@<name>` invocation). BMAD installs both surfaces so you can choose per task:

- **Subagents** (`~/.gemini/agents/*.md`) — invoked with `@backend-engineer …`, isolated context, per-role tool allow-list, token-efficient.
- **Extensions / skills** (`~/.gemini/extensions/bmad-*/`) — invoked with `/bmad-<agent>:<cmd>` slash commands, share the main session's context.

**Global Install (once)**

```bash
bash scripts/install-global.sh
# → ~/.gemini/agents/<agent>.md              (13 native subagents — NEW)
# → ~/.gemini/extensions/bmad-<agent>/       (one extension per role)
#     ├── gemini-extension.json
#     ├── GEMINI.md                          @-imports the skills below
#     └── skills/<cmd>/SKILL.md              /bmad-<agent>:<cmd> slash commands
# → ~/.gemini/KARPATHY-PRINCIPLES.md         engineering-discipline reference
```

Register extensions after first install:

```bash
for ext in ~/.gemini/extensions/bmad-*/; do gemini extensions install "$ext"; done
```

**Project Install (per project, run from project root)**

```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project"
# → .bmad/       project context files (commit to git)
# → GEMINI.md    auto-loads .bmad/ at session start
# → .gemini/agents/  (optional) project-local subagents that override ~/.gemini/agents
```

**Invoking agents:**

```text
# Native subagent — isolated context, auto-delegatable
@backend-engineer implement story BE-001

# Explicit subagent for a clarifying phase
@product-owner draft BRD for the new billing flow

# Slash-command skill (shares main session context)
/bmad-tech-lead:code-review

# Manage subagents interactively
/agents
```

**Subagent notes:**

- Each subagent runs in its own context window — the main session stays lean.
- Subagents cannot call other subagents. The BMAD orchestrator subagent (`@bmad`) gives routing advice; the main agent is responsible for chaining delegations (Wave 1 → Wave 2 → …).
- Tool access is per-subagent (see `tools:` in each `.md` file). Engineers get write + shell; analysts get read + web + MCP.
- The four Karpathy principles are embedded in every subagent body and cross-referenced to `~/.gemini/KARPATHY-PRINCIPLES.md`.

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

| Tool           | Global Path                         | Project Path                      |
| -------------- | ----------------------------------- | --------------------------------- |
| Claude Code    | `~/.claude/skills/`                 | `.claude/skills/`                 |
| Cowork         | `~/.skills/skills/`                 | `.bmad/` (auto-detected)          |
| Cursor         | `~/.cursor/rules/`                  | `.cursor/rules/`                  |
| Windsurf       | `~/.windsurf/rules/`                | `.windsurfrules`                  |
| Trae IDE       | `~/.trae/rules/`                    | `.trae/rules/`                    |
| GitHub Copilot | `~/.github/copilot-instructions.md` | `.github/copilot-instructions.md` |
| Gemini CLI     | `~/.gemini/skills/`                 | `GEMINI.md`                       |
| OpenCode       | `~/.opencode/instructions.md`       | `AGENTS.md`                       |
| Aider          | `~/.aider.conventions.md`           | `.aider.conf.yml`                 |

---

## Sample Prompts

> **After running `install-global.sh` and `scaffold-project.sh`**, agents are already installed in your tool and `.bmad/` is already in your project. Just use the slash command — no need to reference any file paths.

> **⚠ Avoiding Skill Conflicts (Claude Code):** If you have other plugins installed (e.g. superpowers, general planners), always invoke BMAD agents via their **explicit slash command** (`/business-analyst`, `/solution-architect`, etc.). Never use prose-only prompts like "Acting as the Business Analyst…" in Claude Code — without the slash command, another installed skill may intercept the request. The `CLAUDE.md` generated by `scaffold-project.sh` also instructs Claude to prefer BMAD over other skills for this project.

### Using a Single Agent (Claude Code)

**Product Owner — create BRD and PRD:**

```
/product-owner Review .bmad/PROJECT-CONTEXT.md. Elicit business requirements,
define MVP scope, and create the BRD and PRD for this project.
```

**Business Analyst — requirements analysis:**

```
/business-analyst Read docs/brd.md and docs/prd.md. Perform deep requirements
analysis: stakeholder analysis, gap analysis, business rules, use cases, and
user stories with Given-When-Then acceptance criteria.
```

**Enterprise Architect — infrastructure design:**

```
/enterprise-architect Read docs/analysis/requirements-analysis.md. Define
cloud infrastructure, compliance controls, CI/CD pipeline, and observability.
Save to docs/architecture/enterprise-architecture.md.
```

**UX Designer — wireframes and design system:**

```
/ux-designer Read docs/analysis/requirements-analysis.md and docs/ux/.
Select wireframe mode when prompted, then create wireframes and a design system.
```

**Solution Architect — detailed solution design:**

```
/solution-architect Read docs/architecture/enterprise-architecture.md and docs/ux/.
Propose a solution architecture with service boundaries, API contracts, and data models.
Record every architectural decision as an ADR in docs/architecture/adr/.
```

**Backend Engineer — implementation:**

```
/backend-engineer Read docs/architecture/sprint-1-kickoff.md and docs/architecture/solution-architecture.md.
Implement all backend stories assigned to you. Follow .bmad/tech-stack.md conventions.
```

**QE test strategy:**

```
/tester-qe Read docs/analysis/requirements-analysis.md, docs/stories/, and docs/architecture/.
Propose a comprehensive test strategy with test types, coverage goals, and security testing.
```

### Using a Single Agent (Codex CLI)

Invoke agents with the `$` prefix. Codex matches skills by name:

```
$product-owner Review .bmad/PROJECT-CONTEXT.md. Create the BRD and PRD for this project.
```

```
$business-analyst Read docs/brd.md and docs/prd.md. Perform deep requirements analysis
and produce docs/analysis/requirements-analysis.md.
```

```
$solution-architect Read docs/architecture/enterprise-architecture.md and docs/ux/.
Propose solution architecture with service boundaries, API contracts, and data models.
```

```
$ux-designer Read docs/analysis/requirements-analysis.md. Select wireframe mode
when prompted, then create wireframes and a design system. Save to docs/ux/.
```

### Using a Single Agent (Kiro)

Kiro skills activate by description match. Just describe the task — Kiro selects the matching BMAD agent automatically. You can also use slash commands for BMAD operations:

```
As product owner, review .bmad/PROJECT-CONTEXT.md. Elicit business requirements
and create the BRD and PRD for this project.
```

```
As business analyst, read docs/brd.md and docs/prd.md. Perform deep requirements
analysis and produce docs/analysis/requirements-analysis.md.
```

```
As solution architect, read docs/architecture/enterprise-architecture.md and docs/ux/.
Propose system architecture with service boundaries, API contracts, and data models.
```

```
/bmad-status
```

### Using a Single Agent (Cursor / Windsurf / Trae / Copilot / Gemini / OpenCode / Aider)

Agents are already loaded via your global rules file. Just address the agent by role in your prompt — the tool has all agent definitions in context:

> **Gemini CLI users:** you can also invoke any role as a native subagent, e.g. `@product-owner review .bmad/PROJECT-CONTEXT.md …`, which runs the role in an isolated context window.

```
Acting as the Product Owner, review .bmad/PROJECT-CONTEXT.md. Elicit business requirements
and create the BRD (docs/brd.md) and PRD (docs/prd.md) for this project.
```

```
Acting as the Business Analyst, read docs/brd.md and docs/prd.md. Perform deep
requirements analysis and produce docs/analysis/requirements-analysis.md.
```

```
Acting as the Solution Architect, read docs/architecture/enterprise-architecture.md
and docs/ux/. Propose system architecture with service boundaries, API contracts,
and data models. Use .bmad/tech-stack.md.
```

### Squad Mode: All Agents Together

See the **Squad Prompt** section below to run all 13 agents in a single session.

---

## Squad Prompt

Use this mega-prompt to coordinate all agents. **Agents and project context are pre-loaded** — no file paths needed.

> **⚠ Critical — Claude Code users:** Do NOT paste the squad prompt as a single block of text. That triggers skill-matching on the whole message, and any other installed planning/analysis plugin (e.g. superpowers) will intercept it. Each agent must be invoked in its own turn with an explicit slash command.
>
> Also: if you have a plugin with `PostToolUse` or `Stop` hooks that inject follow-up instructions (e.g. the thedotmack superpowers plugin), those hooks fire _below_ the skill layer and override BMAD regardless of what slash command you use. **Disable any non-BMAD planning plugins before running a BMAD session** (Claude Code → Settings → Plugins).

### Claude Code — One Agent Per Turn

Run each agent in a **separate** Claude Code message starting with its slash command.
Each agent's skill automatically pauses after completing its work and asks for your review.
Reply `refine: [feedback]` to iterate with the same agent, or `next` to advance.

---

#### 🗂 Phase 1 — Plan (Turns 1–10)

**Turn 1 — Product Owner:**

```
/product-owner
Review .bmad/PROJECT-CONTEXT.md. Elicit business requirements from stakeholders.
Create the BRD capturing business goals, constraints, regulatory requirements, and data classification.
Translate BRD into a PRD with features, user personas, MVP scope, and success criteria.
Save BRD to docs/brd.md and PRD to docs/prd.md.
[Your project description here]
```

**Turn 2 — Business Analyst:**

```
/business-analyst
Read docs/brd.md and docs/prd.md.
Perform deep requirements analysis: stakeholder analysis, gap analysis, business rules documentation,
feasibility assessment, use cases, and user stories with Given-When-Then acceptance criteria.
Save to docs/analysis/requirements-analysis.md. Save stories to docs/stories/.
```

**Turn 3 — Enterprise Architect:**

```
/enterprise-architect
Read docs/analysis/requirements-analysis.md.
Define enterprise architecture: cloud infrastructure topology, multi-environment deployment,
compliance controls, disaster recovery, CI/CD pipeline, and observability.
Save to docs/architecture/enterprise-architecture.md.
```

**Turn 4 — UX Designer:**

```
/ux-designer
Read docs/analysis/requirements-analysis.md and docs/brd.md.
Select wireframe mode (ASCII / Pencil / Figma) — you will be prompted to choose.
Create personas, user journeys, information architecture, wireframes, and a design system.
Save to docs/ux/ and record design tool choice in .bmad/ux-design-master.md.
```

**Turn 5 — Solution Architect:**

```
/solution-architect
Read docs/architecture/enterprise-architecture.md and docs/ux/.
Design detailed solution architecture within EA boundaries: service decomposition,
API contracts, data models, ADRs, integration patterns, and technology justification.
Save to docs/architecture/solution-architecture.md and ADRs to docs/architecture/adr/.
```

**Turn 6 — Tech Lead (sequencing):**

```
/tech-lead
Review all planning artifacts:
- docs/brd.md, docs/prd.md, docs/analysis/requirements-analysis.md
- docs/architecture/ (enterprise-architecture.md, solution-architecture.md, all ADRs)
- docs/stories/, docs/ux/

Sequence stories into sprint batches. Identify:
1. Which stories each engineer must implement first (dependencies)
2. Any missing specs or unresolved ADRs that would block implementation
3. Acceptance criteria gaps needing clarification before coding starts
Save sprint plan to docs/architecture/sprint-plan.md.
```

**Turn 7 — Backend Engineer (spec):**

```
/backend-engineer
Read docs/architecture/sprint-plan.md, docs/architecture/solution-architecture.md, and docs/architecture/adr/.
Write the backend implementation spec:
- API endpoint contracts (routes, request/response schemas)
- Data access layer patterns and repository interfaces
- Event/message contracts if applicable
Save to docs/architecture/backend-implementation-spec.md.
Do NOT write application code yet — output spec only.
```

**Turn 8 — Frontend Engineer (spec):**

```
/frontend-engineer
Read docs/ux/ (wireframes and design system from .bmad/ux-design-master.md if Pencil/Figma), docs/architecture/sprint-plan.md, and docs/architecture/backend-implementation-spec.md.
Write the frontend implementation spec:
- Component tree and responsibility breakdown
- State management approach
- API contract consumption patterns
- Accessibility and responsive requirements
Save to docs/architecture/frontend-implementation-spec.md.
Do NOT write application code yet — output spec only.
```

**Turn 9 — Mobile Engineer (spec):**

```
/mobile-engineer
Read docs/ux/ and docs/architecture/sprint-plan.md.
Write the mobile implementation spec:
- Native vs. cross-platform decision with rationale
- Screen-to-component mapping
- Device constraints and offline handling strategy
Save to docs/architecture/mobile-implementation-spec.md.
Do NOT write application code yet — output spec only.
```

**Turn 10 — Tester & QE (strategy):**

```
/tester-qe
Read all planning artifacts (docs/stories/, docs/architecture/, docs/ux/).
Write a test strategy covering unit, integration, e2e, security, and performance.
Define quality gates and acceptance criteria per story.
Save to docs/testing/test-strategy.md.
Do NOT write test code yet — output strategy only.
```

**After each turn — log the handoff:**

```
/handoff
```

**Gate before Phase 2 — confirm all planning artifacts exist:**

```
/bmad-status
```

> All 8 artifact paths must show ✅ before starting Phase 2.

---

#### ⚙️ Phase 2 — Execute (Turns 11–15)

> **Prerequisite:** `/bmad-status` shows ✅ on all 8 paths. ADRs are now locked.

**Turn 11 — Tech Lead (execution kickoff):**

```
/tech-lead
Read docs/architecture/sprint-plan.md. Extract Sprint 1 stories.
Produce a kickoff doc listing each story with its assigned engineer role
(backend / frontend / mobile). Declare all ADRs locked.
Save to docs/architecture/sprint-1-kickoff.md.
```

**Turn 12 — Backend Engineer (implement):**

```
/backend-engineer
Read docs/architecture/sprint-1-kickoff.md — find all stories assigned to backend.
Read docs/architecture/backend-implementation-spec.md for API contracts and patterns.
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md

For each assigned story:
1. Implement API endpoints per the spec
2. Write data access layer code
3. Add inline documentation
4. Note any unavoidable spec deviations: // DEVIATION: [reason]
```

**Turn 13 — Frontend Engineer (implement):**

```
/frontend-engineer
Read docs/architecture/sprint-1-kickoff.md — find all stories assigned to frontend.
Read docs/architecture/frontend-implementation-spec.md for component tree and state.
Read docs/ux/ for wireframes and design system (locked — do not redesign).
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md

For each assigned story:
1. Build components per the frontend spec
2. Wire up state management and API calls
3. Apply accessibility and responsive rules from docs/ux/
```

**Turn 14 — Mobile Engineer (implement):**

```
/mobile-engineer
Read docs/architecture/sprint-1-kickoff.md — find all stories assigned to mobile.
Read docs/architecture/mobile-implementation-spec.md for screen mapping and constraints.
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md

For each assigned story:
1. Implement screens per the mobile spec
2. Apply device constraint handling
3. Wire up API calls per the backend contracts
```

**Turn 15 — Tester & QE (write and run tests):**

```
/tester-qe
Read docs/architecture/sprint-1-kickoff.md for the full Sprint 1 story list.
Read docs/testing/test-strategy.md for quality gates and acceptance criteria.

For each story:
1. Write unit tests per the quality gates
2. Write integration tests for API contracts
3. Flag any acceptance criteria from docs/stories/ that are NOT met
4. Save test results to docs/testing/sprint-1-results.md
```

**Log Phase 1 → Phase 2 handoffs:**

```
/handoff tl be
/handoff tl fe
/handoff tl me
```

**Final status check:**

```
/bmad-status
```

---

#### 🔁 Sprint Continuation (Sprint N+1, N+2, …)

> After Tester-QE completes Sprint N and you type `next` to accept. Replace `N` throughout.

**Step 1 — Close out the sprint:**

If you've installed the per-repo eval hooks (see Productivity Evaluation in [adoption.md](adoption.md#productivity-evaluation)), the sprint-results write already triggered `/bmad:eval --auto` for you. Run the interactive form only if you want to add manual notes:

```
/bmad:eval
```

**Step 2 — Tech Lead: review + kick off Sprint N+1:**

```
/tech-lead
Sprint N is complete. Read docs/testing/sprint-N-results.md.
Identify unmet acceptance criteria and carry-over stories.
Read docs/architecture/sprint-plan.md — extract Sprint N+1 stories.
List each story with its assigned engineer role. Lock any new ADRs.
Save to docs/architecture/sprint-N+1-kickoff.md.
```

**Step 3 — Backend Engineer:**

```
/backend-engineer
Read docs/architecture/sprint-N+1-kickoff.md — find all stories assigned to backend.
Read docs/architecture/backend-implementation-spec.md for patterns.
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md
Implement assigned stories. Mark deviations: // DEVIATION: [reason]
```

**Step 4 — Frontend Engineer:**

```
/frontend-engineer
Read docs/architecture/sprint-N+1-kickoff.md — find all stories assigned to frontend.
Read docs/architecture/frontend-implementation-spec.md + docs/ux/.
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md
Build UI components and wire up API calls. Mark deviations: // DEVIATION: [reason]
```

**Step 5 — Mobile Engineer:**

```
/mobile-engineer
Read docs/architecture/sprint-N+1-kickoff.md — find all stories assigned to mobile.
Read docs/architecture/mobile-implementation-spec.md.
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md
Write screens and wire up API calls. Mark deviations: // DEVIATION: [reason]
```

**Step 6 — Tester-QE:**

```
/tester-qe
Read docs/architecture/sprint-N+1-kickoff.md for the full story list.
Read docs/testing/test-strategy.md for quality gates.
Write and run tests. Flag unmet criteria.
Save results to docs/testing/sprint-N+1-results.md.
```

---

### Codex CLI — One Agent Per Turn

Same two-phase pattern as Claude Code. Use `$` prefix for skills, `/` for commands.
The review gate is built into each agent's skill — no need to add it to the prompt.

#### 🗂 Phase 1 — Plan

Follow the Claude Code Phase 1 turns exactly, replacing `/` with `$` for each skill invocation:

```
$business-analyst    $product-owner       $solution-architect
$ux-designer         $enterprise-architect $tech-lead
$backend-engineer    $frontend-engineer   $mobile-engineer    $tester-qe
```

The task description for each turn is identical to the Claude Code section above.
After each turn: `/handoff`. After Turn 10: `/bmad-status`.

#### ⚙️ Phase 2 — Execute

Follow the Claude Code Phase 2 turns exactly, replacing `/` with `$`:

```
$tech-lead  (kickoff)  →  $backend-engineer  →  $frontend-engineer
$mobile-engineer  →  $tester-qe
```

#### 🔁 Sprint Continuation (Sprint N+1, N+2, …)

Follow the Claude Code Sprint Continuation steps exactly, replacing `/` with `$`:

```
$bmad-eval                  # close out Sprint N
$tech-lead                  # review results + kick off Sprint N+1
$backend-engineer           # implement Sprint N+1 backend stories
$frontend-engineer          # implement Sprint N+1 frontend stories
$mobile-engineer            # implement Sprint N+1 mobile screens
$tester-qe                  # test Sprint N+1, save sprint-N+1-results.md
```

Use the same task descriptions from the Claude Code Sprint Continuation section above,
replacing `/` with `$` in all skill invocations.

### Kiro — Description-Driven

Kiro activates skills by description match. Prefix each turn with the agent's role.
The review gate is built into each agent's skill.

#### 🗂 Phase 1 — Plan

**Turn 1 — Product Owner:**

```
As product owner, review .bmad/PROJECT-CONTEXT.md. Elicit business requirements.
Create the BRD (business goals, constraints, regulatory requirements, data classification)
and PRD (features, personas, MVP scope, success criteria, epics).
Save to docs/brd.md and docs/prd.md.
[Your project description here]
```

**Turn 2 — Business Analyst:**

```
As business analyst, read docs/brd.md and docs/prd.md.
Perform deep requirements analysis: stakeholder analysis, gap analysis, business rules,
feasibility, use cases, and user stories with Given-When-Then acceptance criteria.
Save to docs/analysis/requirements-analysis.md and docs/stories/.
```

**Turn 3 — Enterprise Architect:**

```
As enterprise architect, read docs/analysis/requirements-analysis.md.
Define enterprise architecture: cloud infrastructure, multi-environment deployment,
compliance controls, DR strategy, CI/CD pipeline, and observability.
Save to docs/architecture/enterprise-architecture.md.
```

**Turn 4 — UX Designer:**

```
As UX designer, read docs/analysis/requirements-analysis.md.
Select wireframe mode when prompted (ASCII / Pencil / Figma).
Create personas, user journeys, information architecture, wireframes, and design system.
Record tool choice in .bmad/ux-design-master.md. Save to docs/ux/.
```

**Turn 5 — Solution Architect:**

```
As solution architect, read docs/architecture/enterprise-architecture.md and docs/ux/.
Design detailed solution within EA boundaries: service decomposition, API contracts,
data models, ADRs, and integration patterns.
Save to docs/architecture/solution-architecture.md and docs/architecture/adr/.
```

**Turn 6 — Tech Lead (sequencing):**

```
As tech lead, review all planning artifacts in docs/. Sequence stories into sprint batches.
Identify dependencies and missing specs. Save to docs/architecture/sprint-plan.md.
```

**Turn 7 — Backend Engineer (spec):**

```
As backend engineer, read sprint-plan.md and all ADRs. Write the backend implementation
spec: API contracts, data access patterns, event contracts.
Save to docs/architecture/backend-implementation-spec.md. No code yet.
```

**Turn 8 — Frontend Engineer (spec):**

```
As frontend engineer, read docs/ux/, sprint-plan.md, and backend-implementation-spec.md.
Write the frontend implementation spec: component tree, state management, API consumption.
Save to docs/architecture/frontend-implementation-spec.md. No code yet.
```

**Turn 9 — Mobile Engineer (spec):**

```
As mobile engineer, read docs/ux/ and sprint-plan.md. Write the mobile implementation spec:
platform decision, screen mapping, device constraints.
Save to docs/architecture/mobile-implementation-spec.md. No code yet.
```

**Turn 10 — Tester & QE (strategy):**

```
As tester and QE engineer, read all planning artifacts. Write a test strategy: unit,
integration, e2e, security, performance quality gates, acceptance criteria per story.
Save to docs/testing/test-strategy.md. No test code yet.
```

Use `/bmad-status` after Turn 10. Use `/handoff` between turns.

#### ⚙️ Phase 2 — Execute

> Start only after `/bmad-status` confirms all 8 artifact paths are ✅.

**Turn 11 — Tech Lead (kickoff):**

```
As tech lead, planning is approved. Read docs/architecture/sprint-plan.md.
Extract Sprint 1 stories. Produce a kickoff doc listing each story with its assigned
engineer role (backend / frontend / mobile). Declare all ADRs locked.
Save to docs/architecture/sprint-1-kickoff.md.
```

**Turn 12 — Backend Engineer (implement):**

```
As backend engineer, read docs/architecture/sprint-1-kickoff.md — find all stories
assigned to backend. Read docs/architecture/backend-implementation-spec.md for API
contracts and patterns. Follow .bmad/tech-stack.md and .bmad/team-conventions.md.
Implement each assigned story. Mark deviations: // DEVIATION: [reason]
```

**Turn 13 — Frontend Engineer (implement):**

```
As frontend engineer, read docs/architecture/sprint-1-kickoff.md — find all stories
assigned to frontend. Read docs/architecture/frontend-implementation-spec.md for
component tree and state. Read docs/ux/ for wireframes (locked — do not redesign).
Follow .bmad/tech-stack.md and .bmad/team-conventions.md.
Build UI components and wire up API calls. Mark deviations: // DEVIATION: [reason]
```

**Turn 14 — Mobile Engineer (implement):**

```
As mobile engineer, read docs/architecture/sprint-1-kickoff.md — find all stories
assigned to mobile. Read docs/architecture/mobile-implementation-spec.md for screen
mapping and constraints. Follow .bmad/tech-stack.md and .bmad/team-conventions.md.
Write mobile screens and wire up API calls. Mark deviations: // DEVIATION: [reason]
```

**Turn 15 — Tester & QE (write and run tests):**

```
As tester and QE engineer, read docs/architecture/sprint-1-kickoff.md for the full
Sprint 1 story list. Read docs/testing/test-strategy.md for quality gates.
Write and run unit + integration tests for every Sprint 1 story.
Flag unmet acceptance criteria. Save results to docs/testing/sprint-1-results.md.
```

#### 🔁 Sprint Continuation (Sprint N+1, N+2, …)

> After Tester-QE accepts Sprint N and you type `next`. Replace `N` throughout.

**Close out Sprint N:**

```
As the BMAD eval collector, run /bmad-eval to log Sprint N metrics.
```

**Tech Lead — Sprint N+1 Kickoff:**

```
As tech lead, Sprint N is complete. Read docs/testing/sprint-N-results.md for
carry-overs. Read docs/architecture/sprint-plan.md — extract Sprint N+1 stories.
List each story with its assigned engineer role. Lock any new ADRs.
Save to docs/architecture/sprint-N+1-kickoff.md.
```

**Backend Engineer — Sprint N+1:**

```
As backend engineer, read docs/architecture/sprint-N+1-kickoff.md — find all stories
assigned to backend. Read docs/architecture/backend-implementation-spec.md for patterns.
Follow .bmad/tech-stack.md. Implement assigned stories. Mark deviations: // DEVIATION: [reason]
```

**Frontend Engineer — Sprint N+1:**

```
As frontend engineer, read docs/architecture/sprint-N+1-kickoff.md — find all stories
assigned to frontend. Read docs/architecture/frontend-implementation-spec.md + docs/ux/.
Build UI components and wire up API calls. Mark deviations: // DEVIATION: [reason]
```

**Mobile Engineer — Sprint N+1:**

```
As mobile engineer, read docs/architecture/sprint-N+1-kickoff.md — find all stories
assigned to mobile. Read docs/architecture/mobile-implementation-spec.md.
Write screens and wire up API calls. Mark deviations: // DEVIATION: [reason]
```

**Tester & QE — Sprint N+1:**

```
As tester and QE engineer, read docs/architecture/sprint-N+1-kickoff.md for the full
story list. Read docs/testing/test-strategy.md for quality gates.
Write and run tests. Flag unmet criteria. Save to docs/testing/sprint-N+1-results.md.
```

### Cursor / Windsurf / Trae / Copilot / Gemini / OpenCode / Aider

All agent skills are loaded from your global rules file. Select the prompt set that matches your work type below. Each agent follows its built-in Completion Protocol — it prints a `✅` review summary and waits. Reply `next` to advance or `refine: [feedback]` to iterate.

> **Claude Code / Codex / Kiro users:** Run each agent block as a separate turn using its `/slash-command` (or `$` / description prefix) instead of pasting the whole prompt at once.

**Key design principle:** Prompt A (Plan) saves all artifacts to known file paths. Prompt B (Execute) tells each agent to **read those files directly** — no manual copy-paste between prompts. The Tech Lead's kickoff doc is the bridge: it reads the plan, assigns stories per engineer, and saves a kickoff file that every execution agent reads.

---

#### 🏗 New Project

Use when starting a project from scratch. Full 13-agent planning → multi-sprint execution.

**Prompt A — Plan (13 agents, no code):**

```
# BMAD Squad: New Project Plan

You are a squad of 13 specialized AI agents organized into parallel execution waves.
All agent skills are loaded. The project context is in .bmad/ — read it before starting.
OUTPUT ONLY DOCUMENTATION — do NOT write any application code yet.

Each agent must follow its built-in Completion Protocol: run the quality gate, save
outputs, print the ✅ review summary, and wait for my reply.
Agents in the same wave run in PARALLEL — spawn them together.
Only advance to the next wave when ALL agents in the current wave reply 'next'.

---

## Wave 1 — Product Owner
Review .bmad/PROJECT-CONTEXT.md. Elicit business requirements from stakeholders.
Create the BRD (business goals, constraints, regulatory requirements, data classification)
and the PRD (features, user personas, MVP scope, success criteria, epics).
Save BRD to docs/brd.md and PRD to docs/prd.md.
[Describe the project goal here]

## Wave 2 — Business Analyst
Read docs/brd.md and docs/prd.md.
Perform deep requirements analysis: stakeholder analysis, gap analysis, business rules,
feasibility, use cases, and user stories with Given-When-Then acceptance criteria.
Save to docs/analysis/requirements-analysis.md. Save stories to docs/stories/.

## Wave 3 ∥ — Enterprise Architect + UX Designer (parallel)
**Spawn both agents simultaneously — both read docs/analysis/requirements-analysis.md independently.**

### Enterprise Architect
Read docs/analysis/requirements-analysis.md.
Define enterprise architecture: cloud infrastructure topology, multi-environment deployment,
compliance controls, disaster recovery, CI/CD pipeline, and observability.
Save to docs/architecture/enterprise-architecture.md.

### UX Designer
Read docs/analysis/requirements-analysis.md.
Select wireframe mode when prompted (ASCII / Pencil / Figma — Pencil is default if connected).
Create personas, user journeys, information architecture, wireframes, and a design system.
Record design tool choice in .bmad/ux-design-master.md. Save design artifacts to docs/ux/.

## Wave 4 — Solution Architect
**Wait for BOTH Enterprise Architect and UX Designer to complete.**
Read docs/architecture/enterprise-architecture.md and docs/ux/ (design system, wireframes).
Design the detailed technical solution within EA boundaries: service decomposition,
API contracts, data models, ADRs, and integration patterns.
Save to docs/architecture/solution-architecture.md and ADRs to docs/architecture/adr/.

## Wave 5 — Tech Lead (sequencing)
**Wait for Solution Architect to complete.**
Review all planning artifacts (brd.md, prd.md, requirements-analysis.md, enterprise-architecture.md,
solution-architecture.md, all ADRs, docs/stories/, docs/ux/).
Sequence stories into sprint batches. Identify dependencies and spec gaps.
Save to docs/architecture/sprint-plan.md.

## Wave 6 ∥ — Backend + Frontend + Mobile Engineer (parallel, spec only — no code)
**Spawn all three agents simultaneously — they read sprint-plan.md independently.**

### Backend Engineer
Read sprint-plan.md and all ADRs. Write backend implementation spec: API contracts,
data access patterns, event contracts. Save to docs/architecture/backend-implementation-spec.md.

### Frontend Engineer
Read docs/ux/, sprint-plan.md, backend-implementation-spec.md. Write frontend spec:
component tree, state management, API consumption. Save to docs/architecture/frontend-implementation-spec.md.

### Mobile Engineer
Read docs/ux/ and sprint-plan.md. Write mobile spec: platform decision, screen mapping,
device constraints. Save to docs/architecture/mobile-implementation-spec.md.

## Wave 7 — Tester & QE (strategy only — no test code)
**Wait for ALL three engineer specs to complete.**
Read all planning artifacts. Write a test strategy: unit, integration, e2e, security,
performance quality gates, acceptance criteria per story. Save to docs/testing/test-strategy.md.
```

> ✅ Before Prompt B: run `/bmad-status` — all 8 artifact paths must be present.

**Prompt B — Execute (Sprint 1):**

```
# BMAD Squad: Sprint 1 Implementation

All planning is approved. All ADRs are locked — do NOT reopen architectural decisions.
Each agent must follow its built-in Completion Protocol: print the ✅ review summary
and wait for my reply. Agents in the same wave run in PARALLEL.
Only advance to the next wave when ALL agents in the current wave complete.

## Wave E1 — Tech Lead (execution kickoff)
Read docs/architecture/sprint-plan.md. Extract Sprint 1 stories. Produce a kickoff doc
listing each story with its assigned engineer role (backend / frontend / mobile).
Declare all ADRs locked. Save to docs/architecture/sprint-1-kickoff.md.

## Wave E2 ∥ — Backend + Frontend + Mobile Engineer (parallel)
**Spawn all three agents simultaneously — they read the kickoff doc independently.**

### Backend Engineer
Read docs/architecture/sprint-1-kickoff.md — find all stories assigned to backend.
Read docs/architecture/backend-implementation-spec.md for API contracts and patterns.
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md
Implement each assigned story. Mark deviations: // DEVIATION: [reason]

### Frontend Engineer
Read docs/architecture/sprint-1-kickoff.md — find all stories assigned to frontend.
Read docs/architecture/frontend-implementation-spec.md for component tree and state.
Read docs/ux/ for wireframes and design system.
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md
Build UI components and wire up API calls. Mark deviations: // DEVIATION: [reason]

### Mobile Engineer
Read docs/architecture/sprint-1-kickoff.md — find all stories assigned to mobile.
Read docs/architecture/mobile-implementation-spec.md for screen mapping and constraints.
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md
Write mobile screens and wire up API calls. Mark deviations: // DEVIATION: [reason]

## Wave E3 — Tester & QE
**Wait for ALL three engineers to complete before starting.**
Read docs/architecture/sprint-1-kickoff.md for the full Sprint 1 story list.
Read docs/testing/test-strategy.md for quality gates and acceptance criteria.
Write and run unit + integration tests for every Sprint 1 story.
Flag any unmet acceptance criteria. Save results to docs/testing/sprint-1-results.md.
```

**Prompt C — Sprint N+1 Continuation:**

> After Tester-QE accepts Sprint N and you type `next`. Replace `N` throughout.

```
# BMAD Squad: Sprint N+1 Implementation

Sprint N is complete. ADRs remain locked.
Each agent must follow its built-in Completion Protocol: print the ✅ review summary
and wait for my reply. Agents in the same wave run in PARALLEL.

## Wave E1 — Tech Lead — Sprint N+1 Kickoff
Read docs/testing/sprint-N-results.md for carry-overs and unmet criteria.
Read docs/architecture/sprint-plan.md — extract Sprint N+1 stories.
List each story with its assigned engineer role. Lock any new ADRs.
Save to docs/architecture/sprint-N+1-kickoff.md.

## Wave E2 ∥ — Backend + Frontend + Mobile Engineer (parallel)
**Spawn all three simultaneously after Tech Lead completes.**

### Backend Engineer
Read docs/architecture/sprint-N+1-kickoff.md — find all stories assigned to backend.
Read docs/architecture/backend-implementation-spec.md for patterns.
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md
Implement assigned stories. Mark deviations: // DEVIATION: [reason]

### Frontend Engineer
Read docs/architecture/sprint-N+1-kickoff.md — find all stories assigned to frontend.
Read docs/architecture/frontend-implementation-spec.md + docs/ux/.
Build UI components and wire up API calls. Mark deviations: // DEVIATION: [reason]

### Mobile Engineer
Read docs/architecture/sprint-N+1-kickoff.md — find all stories assigned to mobile.
Read docs/architecture/mobile-implementation-spec.md.
Write screens and wire up API calls. Mark deviations: // DEVIATION: [reason]

## Wave E3 — Tester & QE
**Wait for ALL three engineers to complete.**
Read docs/architecture/sprint-N+1-kickoff.md for the full story list.
Read docs/testing/test-strategy.md for quality gates.
Write and run tests. Flag unmet criteria. Save to docs/testing/sprint-N+1-results.md.
```

> 💡 If the per-repo eval hooks aren't installed, run `/bmad:eval` first to log Sprint N metrics before starting Prompt C. Otherwise the sprint-results write already triggered an auto-eval — see [Productivity Evaluation](adoption.md#productivity-evaluation).

---

#### ✨ Feature Request / Enhancement

Use when adding a new capability to an existing project. Enterprise architecture is already defined, so PO defines the feature brief, BA performs impact analysis, then SA and UX run in parallel. Full EA wave is not needed unless the feature requires major infrastructure changes.

**Prompt A — Plan (5 agents, no code):**

```
# BMAD Squad: Feature Plan

You are a squad of specialized AI agents organized into parallel execution waves.
All agent skills are loaded. Read .bmad/PROJECT-CONTEXT.md and existing docs/ first.
OUTPUT ONLY DOCUMENTATION — do NOT write any code yet.

Each agent must follow its built-in Completion Protocol: run the quality gate, save
outputs, print the ✅ review summary, and wait for my reply.
Agents in the same wave run in PARALLEL — spawn them together.

Feature: [describe the feature or paste the request here]

---

## Wave 1 — Product Owner
Read docs/brd.md and docs/prd.md to understand existing business requirements and scope.
Define the feature brief: business case, user value, success criteria, and constraints.
Write new epics/stories at the title + MoSCoW level. Save feature brief to
docs/features/[feature-name]-brief.md and update docs/prd.md with the new epic.

## Wave 2 — Business Analyst (impact analysis)
Read docs/features/[feature-name]-brief.md and existing docs/analysis/ and docs/stories/.
Analyze:
- Stakeholder impact — who is affected and what are their concerns
- Affected systems and services — what existing functionality changes
- Data flow changes — new data paths, storage, or processing
- Regulatory/compliance implications
- Risks, constraints, and dependencies on external systems
- Success metrics for the feature
Write detailed user stories with Given-When-Then acceptance criteria.
Save impact analysis to docs/analysis/[feature-name]-impact.md. Save stories to docs/stories/[feature-name]/.

## Wave 3 ∥ — Solution Architect + UX Designer (parallel)
**Spawn both agents simultaneously — both read PO's feature brief and BA's impact analysis independently.**
[Skip UX if no UI impact. Skip SA if no architecture changes needed.]

### Solution Architect
Read docs/features/[feature-name]-brief.md, docs/analysis/[feature-name]-impact.md, and docs/architecture/.
Assess architectural impact: new endpoints, data model changes, service boundary
changes, third-party integrations. Create or update ADRs in docs/architecture/adr/.
Update docs/architecture/solution-architecture.md if needed.

### UX Designer
Read docs/features/[feature-name]-brief.md, docs/analysis/[feature-name]-impact.md, and docs/ux/.
Open the master design file from .bmad/ux-design-master.md. Add a new page/frame for this feature.
Design wireframes and user flows for new or updated screens. Save specs to docs/ux/[feature-name]/.

## Wave 4 — Tech Lead
**Wait for BOTH Solution Architect and UX Designer (W3) to complete.**
Read docs/stories/[feature-name]/, all updated ADRs, and docs/ux/[feature-name]/ if
present. Break down stories by engineer role (backend / frontend / mobile). Estimate
effort. Identify dependencies. Save the feature execution plan to
docs/architecture/[feature-name]-plan.md — this file must list every story with its
assigned engineer role, referenced spec, and any ADRs to follow.

## Wave 5 — Tester & QE
Read docs/stories/[feature-name]/ and the acceptance criteria within each story.
Write test cases: unit, integration, regression impact on existing features.
Update docs/testing/test-strategy.md with the feature's test section.
```

**Prompt B — Execute:**

```
# BMAD Squad: Feature Implementation

Feature planning is approved. ADRs are locked for this feature.
Each agent must follow its built-in Completion Protocol: print the ✅ review summary
and wait for my reply. Agents in the same wave run in PARALLEL.

## Wave E1 — Tech Lead — Kickoff
Scan docs/architecture/ for the most recent *-plan.md file (created by Prompt A).
Read it. Confirm story assignments per engineer. Lock all feature ADRs.
Print the full assignment summary including the feature name and plan path so all
subsequent agents know exactly which files to read.

## Wave E2 ∥ — Backend + Frontend + Mobile Engineer (parallel)
**Spawn all three simultaneously after Tech Lead completes.**

### Backend Engineer
Read the feature plan identified by Tech Lead — find all stories assigned to backend.
Read docs/architecture/solution-architecture.md and any referenced ADRs for API
contracts and data model changes.
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md
Implement each assigned story. Mark deviations: // DEVIATION: [reason]

### Frontend Engineer
Read the feature plan identified by Tech Lead — find all stories assigned to frontend.
Read the feature's UX folder in docs/ux/ for wireframes and interaction specs.
Read docs/architecture/solution-architecture.md for API contracts.
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md
Build feature UI. Mark deviations: // DEVIATION: [reason]

### Mobile Engineer
Read the feature plan identified by Tech Lead — find all stories assigned to mobile.
Read docs/architecture/mobile-implementation-spec.md and any referenced ADRs.
Stack: .bmad/tech-stack.md  |  Style: .bmad/team-conventions.md
Write feature mobile screens. Mark deviations: // DEVIATION: [reason]

## Wave E3 — Tester & QE
**Wait for ALL three engineers to complete.**
Read the feature plan identified by Tech Lead for the complete story list.
Read the feature's story folder in docs/stories/ for acceptance criteria per story.
Read docs/testing/test-strategy.md for quality gates and regression scope.
Write and run tests. Verify all acceptance criteria. Flag regressions.
Save results to docs/testing/ with the feature name prefix.
```

> In a continuing session the agents will find the correct files automatically. If starting
> a new session, tell the Tech Lead which feature plan to read (e.g. `docs/architecture/payment-retry-plan.md`).

---

#### 🐛 Bug Fix

Use when investigating and resolving a reported defect. Starts with diagnosis before any fix code.

**Prompt A — Diagnose (2 agents):**

```
# BMAD Squad: Bug Diagnosis

Two agents will investigate this bug. Each must follow its built-in Completion
Protocol: print the ✅ review summary and wait for my reply before the next agent.

Bug report: [paste bug description, error message, or ticket here]

---

## Agent 1 — Tester & QE
Reproduce the bug using the report above and the codebase. Document:
- Exact reproduction steps
- Actual vs expected behavior
- Affected user stories or features (cross-ref docs/stories/)
- Root-cause hypotheses (at least 2)
- Regression risk: what else could be affected
Choose a short bug-id slug (e.g. auth-timeout, cart-double-charge).
Save bug report to docs/testing/bugs/[bug-id].md.

## Agent 2 — Tech Lead
Read the bug report saved by Tester-QE — scan docs/testing/bugs/ for the most recent
.md file created in this session. Also read the relevant source files.
Confirm the root cause. Define the minimal safe fix: which files change, what changes,
what must NOT change. Identify the engineer role needed (backend / frontend / mobile).
Assess regression scope. Save fix plan to docs/testing/bugs/[bug-id]-fix-plan.md.
```

**Prompt B — Fix & Verify:**

```
# BMAD Squad: Bug Fix Implementation

Root cause confirmed. Fix plan is approved.
Each agent must follow its built-in Completion Protocol: print the ✅ review summary
and wait for my reply. Only proceed when I reply 'next'.

## [Backend / Frontend / Mobile] Engineer
Scan docs/testing/bugs/ for the most recent *-fix-plan.md file.
Read the fix plan. Apply the targeted fix only — no unrelated refactoring.
Mark every changed line: // FIX: [bug-id]

## Tester & QE
Read the bug report from docs/testing/bugs/ (the .md file without -fix-plan suffix).
Re-run the reproduction steps — confirm the bug is fixed.
Run regression tests for all areas identified in the fix plan.
Save verification results to docs/testing/bugs/[bug-id]-verified.md.
```

> In a continuing session the agents will find the correct files automatically. If starting
> a new session, replace `[bug-id]` with the slug from Prompt A (e.g. `auth-timeout`).

---

#### 🚨 Hotfix (Production Emergency)

Use when a critical production issue needs the fastest possible resolution. Assess, fix, smoke test in one session — no planning docs.

**Single Prompt — Assess, Fix, Verify:**

```
# BMAD Squad: Production Hotfix

PRODUCTION EMERGENCY. Three agents work in strict sequence.
Each agent must follow its built-in Completion Protocol: print the ✅ review summary
and wait for my reply. Only proceed when I reply 'next'.

Issue: [describe production symptoms, error logs, or incident report here]

---

## Agent 1 — Tech Lead
Read the issue above and relevant source files. Identify root cause. Define the
smallest safe fix (no refactoring, no scope creep). Confirm rollback plan.
Identify the engineer role needed (backend / frontend / mobile).
Save assessment to docs/testing/hotfixes/[date]-[issue].md.

## Agent 2 — [Backend / Frontend / Mobile] Engineer
Read the most recent assessment in docs/testing/hotfixes/.
Implement the fix exactly as scoped.
Mark every changed line: // HOTFIX: [date]-[issue]
Do NOT refactor, rename, or clean up anything outside the fix scope.

## Agent 3 — Tester & QE
Read the assessment in docs/testing/hotfixes/ and the engineer's changes.
Smoke test only — verify the critical path is unbroken.
Confirm the production symptom is resolved.
Save results to docs/testing/hotfixes/[date]-[issue]-verified.md.
```

---

#### 📋 Backlog Item / Tech Debt / Chore

Use for known stories already in the backlog, dependency upgrades, refactors, or maintenance tasks that don't need full architecture review.

**Prompt A — Refine (3 agents, no code):**

```
# BMAD Squad: Backlog Refinement

Three agents will refine and plan this work item. Each must follow its built-in
Completion Protocol: print the ✅ review summary and wait for my reply.

Work item: [paste story, tech debt description, or chore here]

---

## Agent 1 — Product Owner
Read the work item and docs/prd.md. Choose a short story-id slug (e.g. upgrade-redis,
refactor-auth-middleware). Clarify scope: write or refine the story with unambiguous
acceptance criteria and explicit out-of-scope boundaries.
Save refined story to docs/stories/[story-id].md.

## Agent 2 — Business Analyst (requirements clarification)
Read the refined story saved by Product Owner — scan docs/stories/ for the most recent
.md file. Analyze requirements clarity, stakeholder impact, risks, and dependencies.
Verify acceptance criteria are unambiguous. Flag any regulatory implications.
Save to docs/analysis/[story-id]-analysis.md.

## Agent 3 — Tech Lead
Read the refined story saved by the Product Owner and the analysis saved by BA —
scan docs/stories/ and docs/analysis/ for the most recent files. Also read relevant source files.
Produce a technical breakdown: affected files, implementation approach, estimated
effort, dependencies, risks. Identify the engineer role needed (backend / frontend / mobile).
Flag any ADR implications. Save to docs/architecture/[story-id]-notes.md.
```

**Prompt B — Execute:**

```
# BMAD Squad: Backlog Item Implementation

Story is refined and technical breakdown is approved.
Each agent must follow its built-in Completion Protocol: print the ✅ review summary
and wait for my reply. Only proceed when I reply 'next'.

## [Backend / Frontend / Mobile] Engineer
Scan docs/architecture/ for the most recent *-notes.md file.
Read the tech notes and the linked story in docs/stories/.
Implement per the approach defined. Follow .bmad/tech-stack.md and
.bmad/team-conventions.md. Mark deviations: // DEVIATION: [reason]

## Tester & QE
Read the story file linked in the tech notes — find acceptance criteria.
Write and run targeted tests. Verify all criteria are met.
Save results to docs/testing/[story-id]-results.md.
```

> In a continuing session the agents will find the correct files automatically. If starting
> a new session, replace `[story-id]` with the slug from Prompt A (e.g. `upgrade-redis`).

---

[← Back to README](../README.md)  ·  [Agents](agents.md)  ·  [Architecture](architecture.md)  ·  [Workflows](workflows.md)  ·  [Tooling](tooling.md)  ·  [Adoption](adoption.md)
